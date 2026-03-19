import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../services/database_service.dart';
import '../../models/quotation_model.dart';
import '../../utils/formatters.dart';
import '../../config/theme.dart';
import 'quotation_form_screen.dart';
import 'quotation_detail_screen.dart';

class QuotationListScreen extends StatefulWidget {
  const QuotationListScreen({super.key});

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;

  List<QuotationModel> _allQuotations = [];
  List<QuotationModel> _filteredQuotations = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadQuotations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final statuses = ['all', 'pending', 'accepted', 'expired'];
    setState(() => _filterStatus = statuses[_tabController.index]);
    _filterQuotations();
  }

  void _filterQuotations() {
    if (_filterStatus == 'all') {
      _filteredQuotations = _allQuotations;
    } else if (_filterStatus == 'expired') {
      _filteredQuotations = _allQuotations.where((q) => q.isExpired).toList();
    } else {
      _filteredQuotations = _allQuotations.where((q) => q.status == _filterStatus).toList();
    }
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    try {
      final quotations = await _dbService.getAllQuotations();
      if (mounted) {
        setState(() {
          _allQuotations = quotations;
          _filteredQuotations = quotations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quotations: $e')),
        );
      }
    }
  }

  Future<void> _deleteQuotation(QuotationModel quotation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: const Text('Are you sure you want to delete this quotation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.deleteQuotation(quotation.id!);
      _loadQuotations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotations'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredQuotations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No quotations found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadQuotations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredQuotations.length,
                    itemBuilder: (context, index) {
                      final quotation = _filteredQuotations[index];
                      return _buildQuotationCard(quotation);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuotationFormScreen()),
        ).then((_) => _loadQuotations()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuotationCard(QuotationModel quotation) {
    final statusColor = _getStatusColor(quotation);
    final isExpired = quotation.isExpired;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuotationDetailScreen(quotation: quotation),
                ),
              ).then((_) => _loadQuotations()),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: Icons.visibility,
              label: 'View',
            ),
            SlidableAction(
              onPressed: (_) => _deleteQuotation(quotation),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuotationDetailScreen(quotation: quotation),
              ),
            ).then((_) => _loadQuotations()),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        quotation.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isExpired ? 'EXPIRED' : quotation.status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.home, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Plot ${quotation.plotNumber}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          quotation.location ?? 'N/A',
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.formatArea(quotation.totalArea),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        Formatters.formatCurrency(quotation.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  if (quotation.validUntil != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        isExpired
                            ? 'Expired on ${Formatters.formatDate(quotation.validUntil!)}'
                            : 'Valid until ${Formatters.formatDate(quotation.validUntil!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isExpired ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(QuotationModel quotation) {
    if (quotation.isExpired) return Colors.red;
    switch (quotation.status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
