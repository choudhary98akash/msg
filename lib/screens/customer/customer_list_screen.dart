import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../services/database_service.dart';
import '../../models/customer_model.dart';
import '../../utils/formatters.dart';
import '../../config/theme.dart';
import 'customer_detail_screen.dart';
import 'add_customer_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<CustomerModel> _customers = [];
  List<CustomerModel> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _dbService.getAllCustomers();
      if (mounted) {
        setState(() {
          _customers = customers;
          _filteredCustomers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customers: $e')),
        );
      }
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((c) {
          final nameLower = c.name.toLowerCase();
          final phoneLower = (c.phone ?? '').toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) || phoneLower.contains(queryLower);
        }).toList();
      }
    });
  }

  Future<void> _deleteCustomer(CustomerModel customer) async {
    final hasBookings = await _dbService.customerHasBookings(customer.id!);
    final hasPayments = await _dbService.customerHasPayments(customer.id!);

    if (hasBookings) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete: Customer has active bookings'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (hasPayments) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete: Customer has payment history'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
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
      await _dbService.deleteCustomer(customer.id!);
      _loadCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: _filterCustomers,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredCustomers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No customers yet'
                            : 'No customers found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      if (_searchQuery.isEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Add your first customer',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCustomers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      return _buildCustomerCard(customer);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
        ).then((_) => _loadCustomers()),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
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
                  builder: (_) => CustomerDetailScreen(customer: customer),
                ),
              ).then((_) => _loadCustomers()),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: Icons.visibility,
              label: 'View',
            ),
            SlidableAction(
              onPressed: (_) => _deleteCustomer(customer),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerDetailScreen(customer: customer),
              ),
            ).then((_) => _loadCustomers()),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                customer.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(customer.name),
            subtitle: Text(
              customer.phone != null
                  ? Formatters.formatPhone(customer.phone!)
                  : 'No phone',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }
}
