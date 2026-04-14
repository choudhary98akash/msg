import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../services/database_service.dart';
import '../../models/payment_model.dart';
import '../../models/booking_model.dart';
import '../../models/customer_model.dart';
import '../../utils/formatters.dart';
import '../../config/theme.dart';
import 'add_payment_screen.dart';

class PaymentListScreen extends StatefulWidget {
  final bool inStandaloneMode;

  const PaymentListScreen({
    super.key,
    this.inStandaloneMode = true,
  });

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<PaymentModel> _allPayments = [];
  List<PaymentModel> _filteredPayments = [];
  Map<int, BookingModel> _bookings = {};
  Map<int, CustomerModel> _customers = {};
  bool _isLoading = true;
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPayments() {
    List<PaymentModel> baseList = _searchQuery.isEmpty
        ? _allPayments
        : _allPayments.where((p) {
            final booking = _bookings[p.bookingId];
            final customer =
                booking != null ? _customers[booking.customerId] : null;
            final customerName = customer?.name.toLowerCase() ?? '';
            final plotNumber = booking?.plotNumber.toLowerCase() ?? '';
            final receiptNumber = (p.receiptNumber ?? '').toLowerCase();
            final query = _searchQuery.toLowerCase();
            return customerName.contains(query) ||
                plotNumber.contains(query) ||
                receiptNumber.contains(query);
          }).toList();

    if (_filterType == 'all') {
      _filteredPayments = baseList;
    } else {
      _filteredPayments = baseList
          .where((p) => p.paymentType.toLowerCase() == _filterType)
          .toList();
    }
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final payments = await _dbService.getAllPayments();
      final bookings = <int, BookingModel>{};
      final customers = <int, CustomerModel>{};

      for (final payment in payments) {
        if (!bookings.containsKey(payment.bookingId)) {
          final booking = await _dbService.getBooking(payment.bookingId);
          if (booking != null) {
            bookings[payment.bookingId] = booking;
            if (!customers.containsKey(booking.customerId)) {
              final customer = await _dbService.getCustomer(booking.customerId);
              if (customer != null) {
                customers[booking.customerId] = customer;
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _allPayments = payments;
          _filteredPayments = payments;
          _bookings = bookings;
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payments: $e')),
        );
      }
    }
  }

  Future<void> _deletePayment(PaymentModel payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text(
            'Are you sure you want to delete this payment? Receipt will be lost.'),
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
      await _dbService.deletePayment(payment.id!);
      _loadPayments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment deleted successfully')),
        );
      }
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip('All', 'all'),
          const SizedBox(width: 8),
          _buildChip('Token', 'token'),
          const SizedBox(width: 8),
          _buildChip('Down', 'down payment'),
          const SizedBox(width: 8),
          _buildChip('EMI', 'emi'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filterType = value;
        });
        _filterPayments();
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Search and Filter
        Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _filterPayments();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by customer, plot or receipt...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppTheme.primaryColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _filterPayments();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              _buildFilterChips(),
            ],
          ),
        ),
        // Stats row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredPayments.length} ${_filteredPayments.length == 1 ? 'Payment' : 'Payments'}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              if (!_isLoading && _filteredPayments.isNotEmpty)
                Text(
                  'Total: ${Formatters.formatCurrency(_filteredPayments.fold<double>(0, (sum, p) => sum + p.amount))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPayments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPayments,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: _filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = _filteredPayments[index];
                          return _buildPaymentCard(payment);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inStandaloneMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payments'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPayments,
            ),
          ],
        ),
        body: _buildContent(),
      );
    }

    return Container(
      color: AppTheme.backgroundColor,
      child: _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchQuery.isEmpty ? Icons.payment : Icons.search_off,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isEmpty ? 'No Payments Yet' : 'No Results Found',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isEmpty
                    ? 'Start by adding your first payment'
                    : 'Try a different search term',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              if (_searchQuery.isEmpty)
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
                  ).then((_) => _loadPayments()),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Payment'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    final booking = _bookings[payment.bookingId];
    final customer = booking != null ? _customers[booking.customerId] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => _deletePayment(payment),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(12)),
            ),
          ],
        ),
        child: Card(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddPaymentScreen(payment: payment)),
            ).then((_) => _loadPayments()),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getPaymentIcon(payment.paymentType),
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer?.name ?? 'Unknown Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.home,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Plot ${booking?.plotNumber ?? "N/A"}',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPaymentColor(payment.paymentType)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    Formatters.formatPaymentType(
                                        payment.paymentType),
                                    style: TextStyle(
                                      color:
                                          _getPaymentColor(payment.paymentType),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.formatCurrency(payment.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatDate(payment.paymentDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentDetail(
                          Icons.receipt_long,
                          'Receipt: ${payment.receiptNumber ?? "N/A"}',
                        ),
                      ),
                      Expanded(
                        child: _buildPaymentDetail(
                          Icons.account_balance,
                          Formatters.formatPaymentMode(payment.paymentMode),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getPaymentColor(String type) {
    switch (type.toLowerCase()) {
      case 'token':
        return const Color(0xFFFF9800);
      case 'down payment':
        return const Color(0xFF1976D2);
      case 'emi':
        return const Color(0xFF388E3C);
      case 'final payment':
        return const Color(0xFF7B1FA2);
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'token':
        return Icons.token;
      case 'down payment':
        return Icons.payment;
      case 'emi':
        return Icons.calendar_month;
      case 'final payment':
        return Icons.check_circle;
      default:
        return Icons.money;
    }
  }
}
