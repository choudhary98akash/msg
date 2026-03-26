import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/formatters.dart';
import '../../config/theme.dart';
import '../customer/customer_list_screen.dart';
import '../customer/add_customer_screen.dart';
import '../booking/booking_form_screen.dart';
import '../booking/booking_list_screen.dart';
import '../payment/payment_list_screen.dart';
import '../payment/add_payment_screen.dart';
import '../quotation/quotation_list_screen.dart';
import '../quotation/quotation_form_screen.dart';

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
                    _buildWelcomeHeader(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    _buildFinancialSummary(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildRecentActivity(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'M.S. Group Properties',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your plots & customers efficiently',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_work,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: MediaQuery.of(context).size.width > 360 ? 1.4 : 1.2,
          children: [
            _buildStatCard(
              'Customers',
              _stats['customers']?.toString() ?? '0',
              'Total registered',
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
              'Plot bookings',
              Icons.home_work,
              AppTheme.secondaryColor,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingListScreen()),
              ).then((_) => _loadData()),
            ),
            _buildStatCard(
              'Payments',
              _stats['payments']?.toString() ?? '0',
              'Total records',
              Icons.payment,
              const Color(0xFF1976D2),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentListScreen()),
              ).then((_) => _loadData()),
            ),
            _buildStatCard(
              'Quotations',
              _stats['quotations']?.toString() ?? '0',
              'Pending quotes',
              Icons.description,
              const Color(0xFF7B1FA2),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuotationListScreen()),
              ).then((_) => _loadData()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.grey.shade400, size: 14),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
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
    final collectionPercentage = _totalReceivable > 0
        ? (_totalReceived / _totalReceivable * 100).toStringAsFixed(1)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Financial Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFinancialItem(
                        'Total Receivable',
                        _totalReceivable,
                        Icons.account_balance,
                        const Color(0xFFFF9800),
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildFinancialItem(
                        'Received',
                        _totalReceived,
                        Icons.check_circle,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildFinancialItem(
                        'Pending',
                        pending,
                        Icons.pending_actions,
                        const Color(0xFFF44336),
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildCollectionRate(
                        '$collectionPercentage%',
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialItem(
      String label, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          Formatters.formatCurrency(amount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionRate(String percentage, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          percentage,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Collection Rate',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.flash_on, color: AppTheme.primaryColor, size: 20),
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
        ),
        Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Add Customer',
                        Icons.person_add,
                        'New registration',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddCustomerScreen()),
                        ).then((_) => _loadData()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'New Booking',
                        Icons.home_work,
                        'Book a plot',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BookingFormScreen()),
                        ).then((_) => _loadData()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Add Payment',
                        Icons.payment,
                        'Record payment',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddPaymentScreen()),
                        ).then((_) => _loadData()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Create Quote',
                        Icons.description,
                        'Generate quotation',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const QuotationFormScreen()),
                        ).then((_) => _loadData()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: AppTheme.primaryColor, size: 20),
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
        ),
        Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          child: _recentActivity.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No recent activity',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivity.take(5).length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final payment = _recentActivity[index];
                    return _buildActivityItem(payment);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> payment) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            const Icon(Icons.payment, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        payment['customer_name'] ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Plot ${payment['plot_number']} - ${Formatters.formatPaymentType(payment['payment_type'])}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              Formatters.formatCurrency((payment['amount'] as num).toDouble()),
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            Formatters.formatDate(DateTime.parse(payment['payment_date'])),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
