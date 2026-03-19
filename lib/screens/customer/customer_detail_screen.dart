import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/customer_model.dart';
import '../../models/nominee_model.dart';
import '../../models/id_proof_model.dart';
import '../../models/booking_model.dart';
import '../../models/payment_model.dart';
import '../../utils/formatters.dart';
import '../../config/theme.dart';
import 'edit_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  CustomerModel? _customer;
  List<NomineeModel> _nominees = [];
  List<IdProofModel> _idProofs = [];
  List<BookingModel> _bookings = [];
  Map<int, List<PaymentModel>> _paymentsByBooking = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final customer = await _dbService.getCustomer(widget.customer.id!);
      final nominees = await _dbService.getNominees(widget.customer.id!);
      final idProofs = await _dbService.getIdProofs(widget.customer.id!);
      final bookings = await _dbService.getBookingsForCustomer(widget.customer.id!);

      final paymentsByBooking = <int, List<PaymentModel>>{};
      for (final booking in bookings) {
        final payments = await _dbService.getPaymentsForBooking(booking.id!);
        paymentsByBooking[booking.id!] = payments;
      }

      if (mounted) {
        setState(() {
          _customer = customer;
          _nominees = nominees;
          _idProofs = idProofs;
          _bookings = bookings;
          _paymentsByBooking = paymentsByBooking;
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
        title: Text(_customer?.name ?? 'Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditCustomerScreen(customer: _customer!),
              ),
            ).then((_) => _loadData()),
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
                    _buildProfileCard(),
                    const SizedBox(height: 16),
                    _buildNomineesSection(),
                    const SizedBox(height: 16),
                    _buildIdProofsSection(),
                    const SizedBox(height: 16),
                    _buildBookingsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    _customer?.name.substring(0, 1).toUpperCase() ?? 'C',
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customer?.name ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (_customer?.occupation != null)
                        Text(
                          _customer!.occupation!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone, 'Phone', _customer?.phone ?? 'Not provided'),
            _buildInfoRow(Icons.email, 'Email', _customer?.email ?? 'Not provided'),
            _buildInfoRow(Icons.location_on, 'Address', _customer?.address ?? 'Not provided'),
            if (_customer?.dob != null)
              _buildInfoRow(Icons.cake, 'Date of Birth', Formatters.formatDate(_customer!.dob!)),
            if (_customer?.relationName != null)
              _buildInfoRow(Icons.family_restroom, '${_customer?.relationType}', _customer!.relationName!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNomineesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Nominees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 16),
            if (_nominees.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No nominees added', style: TextStyle(color: Colors.grey))),
              )
            else
              ...(_nominees.map((nominee) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
                  child: const Icon(Icons.person, color: AppTheme.secondaryColor),
                ),
                title: Text(nominee.name),
                subtitle: Text('${nominee.relation ?? "Relation"} - ${nominee.phone ?? "No phone"}'),
              ))),
          ],
        ),
      ),
    );
  }

  Widget _buildIdProofsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.badge, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('ID Proofs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 16),
            if (_idProofs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No ID proofs added', style: TextStyle(color: Colors.grey))),
              )
            else
              ...(_idProofs.map((proof) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                  child: const Icon(Icons.credit_card, color: AppTheme.accentColor),
                ),
                title: Text(proof.type),
                subtitle: Text(proof.number),
              ))),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.home_work, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 16),
            if (_bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No bookings yet', style: TextStyle(color: Colors.grey))),
              )
            else
              ...(_bookings.map((booking) => _buildBookingCard(booking))),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final payments = _paymentsByBooking[booking.id!] ?? [];
    final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final remaining = booking.totalPrice - totalPaid;
    final progress = totalPaid / booking.totalPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plot ${booking.plotNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.status == 'active'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  Formatters.formatStatus(booking.status),
                  style: TextStyle(
                    color: booking.status == 'active' ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${booking.location ?? ""} ${booking.block != null ? "Block ${booking.block}" : ""}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            'Area: ${Formatters.formatArea(booking.totalArea)}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid: ${Formatters.formatCurrency(totalPaid)}',
                style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 12),
              ),
              Text(
                'Remaining: ${Formatters.formatCurrency(remaining)}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          Text(
            'Total: ${Formatters.formatCurrency(booking.totalPrice)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${payments.length} payments made',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
