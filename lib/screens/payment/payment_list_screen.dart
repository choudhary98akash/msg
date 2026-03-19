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
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;
  
  List<PaymentModel> _allPayments = [];
  List<PaymentModel> _filteredPayments = [];
  Map<int, BookingModel> _bookings = {};
  Map<int, CustomerModel> _customers = {};
  bool _isLoading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final types = ['all', 'token', 'down payment', 'emi', 'final payment'];
    setState(() => _filterType = types[_tabController.index]);
    _filterPayments();
  }

  void _filterPayments() {
    if (_filterType == 'all') {
      _filteredPayments = _allPayments;
    } else {
      _filteredPayments = _allPayments.where((p) => p.paymentType.toLowerCase() == _filterType).toList();
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
        content: const Text('Are you sure you want to delete this payment? Receipt will be lost.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Token'),
            Tab(text: 'Down Payment'),
            Tab(text: 'EMI'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredPayments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No payments found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredPayments.length,
                    itemBuilder: (context, index) {
                      final payment = _filteredPayments[index];
                      return _buildPaymentCard(payment);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
        ).then((_) => _loadPayments()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    final booking = _bookings[payment.bookingId];
    final customer = booking != null ? _customers[booking.customerId] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _deletePayment(payment),
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
              MaterialPageRoute(builder: (_) => AddPaymentScreen(payment: payment)),
            ).then((_) => _loadPayments()),
            leading: CircleAvatar(
              backgroundColor: _getPaymentColor(payment.paymentType).withOpacity(0.2),
              child: Icon(
                _getPaymentIcon(payment.paymentType),
                color: _getPaymentColor(payment.paymentType),
              ),
            ),
            title: Text(customer?.name ?? 'Unknown Customer'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plot ${booking?.plotNumber ?? "N/A"} - ${Formatters.formatPaymentType(payment.paymentType)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  payment.receiptNumber ?? 'No receipt',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(payment.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                ),
                Text(
                  Formatters.formatDate(payment.paymentDate),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        ),
      ),
    );
  }

  Color _getPaymentColor(String type) {
    switch (type.toLowerCase()) {
      case 'token':
        return Colors.orange;
      case 'down payment':
        return Colors.blue;
      case 'emi':
        return Colors.green;
      case 'final payment':
        return Colors.purple;
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
