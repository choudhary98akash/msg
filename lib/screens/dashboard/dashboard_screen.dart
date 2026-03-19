import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/formatters.dart';
import '../../config/theme.dart';
import '../customer/customer_list_screen.dart';
import '../booking/booking_form_screen.dart';
import '../payment/payment_list_screen.dart';
import '../quotation/quotation_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _recentActivity = [];
  double _totalReceived = 0;
  double _totalReceivable = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _dbService.getDashboardStats();
      final activity = await _dbService.getRecentActivity();
      final received = await _dbService.getTotalReceivedAmount();
      final receivable = await _dbService.getTotalReceivableAmount();

      if (mounted) {
        setState(() {
          _stats = stats;
          _recentActivity = activity;
          _totalReceived = received;
          _totalReceivable = receivable;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M.S. Group Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildFinancialSummary(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Customers',
          _stats['customers']?.toString() ?? '0',
          Icons.people,
          AppTheme.primaryColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerListScreen()),
          ).then((_) => _loadData()),
        ),
        _buildStatCard(
          'Active Bookings',
          _stats['bookings']?.toString() ?? '0',
          Icons.home_work,
          AppTheme.secondaryColor,
          () {},
        ),
        _buildStatCard(
          'Payments',
          _stats['payments']?.toString() ?? '0',
          Icons.payment,
          AppTheme.accentColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentListScreen()),
          ).then((_) => _loadData()),
        ),
        _buildStatCard(
          'Pending Quotations',
          _stats['quotations']?.toString() ?? '0',
          Icons.description,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuotationListScreen()),
          ).then((_) => _loadData()),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final pending = _totalReceivable - _totalReceived;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Financial Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildFinancialRow('Total Receivable', _totalReceivable, Colors.orange),
            const SizedBox(height: 8),
            _buildFinancialRow('Amount Received', _totalReceived, Colors.green),
            const Divider(height: 24),
            _buildFinancialRow('Pending Amount', pending, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          Formatters.formatCurrency(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: AppTheme.accentColor),
                SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Add Customer',
                    Icons.person_add,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerListScreen()),
                    ).then((_) => _loadData()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'New Booking',
                    Icons.add_home,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingFormScreen()),
                    ).then((_) => _loadData()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Add Payment',
                    Icons.payment,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentListScreen()),
                    ).then((_) => _loadData()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Create Quote',
                    Icons.description,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuotationListScreen()),
                    ).then((_) => _loadData()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentListScreen()),
                  ).then((_) => _loadData()),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(height: 16),
            if (_recentActivity.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...(_recentActivity.take(5).map((payment) => _buildActivityItem(payment))),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> payment) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
        child: const Icon(Icons.payment, color: AppTheme.secondaryColor, size: 20),
      ),
      title: Text(payment['customer_name'] ?? 'Unknown'),
      subtitle: Text(
        '${payment['plot_number']} - ${Formatters.formatPaymentType(payment['payment_type'])}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.formatCurrency((payment['amount'] as num).toDouble()),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            Formatters.formatDate(DateTime.parse(payment['payment_date'])),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
