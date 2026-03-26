import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/quotation_model.dart';
import '../../utils/formatters.dart';
import '../../config/theme.dart';
import '../../services/quotation_pdf_service.dart';

class QuotationDetailScreen extends StatefulWidget {
  final QuotationModel quotation;

  const QuotationDetailScreen({super.key, required this.quotation});

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final QuotationPdfService _pdfService = QuotationPdfService();

  QuotationModel? _quotation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _quotation = widget.quotation;
    _loadQuotation();
  }

  Future<void> _loadQuotation() async {
    setState(() => _isLoading = true);
    try {
      final quotation = await _dbService.getQuotation(widget.quotation.id!);
      if (mounted) {
        if (quotation == null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation not found')),
          );
        } else {
          setState(() {
            _quotation = quotation;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_quotation == null) return;

    try {
      final updated = _quotation!.copyWith(status: status);
      await _dbService.updateQuotation(updated);
      _loadQuotation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generatePdf({required bool print}) async {
    if (_quotation == null) return;

    final quotationNumber = await _dbService.generateQuotationNumber();

    if (print) {
      await _pdfService.printQuotation(
          quotation: _quotation!, quotationNumber: quotationNumber);
    } else {
      await _pdfService.shareQuotation(
          quotation: _quotation!, quotationNumber: quotationNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotation Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'print':
                  _generatePdf(print: true);
                  break;
                case 'share':
                  _generatePdf(print: false);
                  break;
                case 'accept':
                  _updateStatus('accepted');
                  break;
                case 'reject':
                  _updateStatus('rejected');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'print',
                  child: ListTile(
                      leading: Icon(Icons.print), title: Text('Print'))),
              const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                      leading: Icon(Icons.share), title: Text('Share'))),
              const PopupMenuDivider(),
              if (_quotation?.status == 'pending') ...[
                const PopupMenuItem(
                    value: 'accept',
                    child: ListTile(
                        leading: Icon(Icons.check, color: Colors.green),
                        title: Text('Mark as Accepted'))),
                const PopupMenuItem(
                    value: 'reject',
                    child: ListTile(
                        leading: Icon(Icons.close, color: Colors.red),
                        title: Text('Mark as Rejected'))),
              ],
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotation == null
              ? const Center(child: Text('Quotation not found'))
              : RefreshIndicator(
                  onRefresh: _loadQuotation,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildCustomerCard(),
                        const SizedBox(height: 16),
                        _buildPlotCard(),
                        const SizedBox(height: 16),
                        _buildPricingCard(),
                        const SizedBox(height: 16),
                        _buildPaymentScheduleCard(),
                        if (_quotation?.remarks != null) ...[
                          const SizedBox(height: 16),
                          _buildRemarksCard(),
                        ],
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_quotation!.status);
    final isExpired = _quotation!.isExpired;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      color: statusColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? 'EXPIRED' : _quotation!.status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (_quotation!.validUntil != null)
                  Text(
                    isExpired
                        ? 'Expired on ${Formatters.formatDate(_quotation!.validUntil!)}'
                        : 'Valid until ${Formatters.formatDate(_quotation!.validUntil!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isExpired ? Colors.red : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(_quotation!.status),
                color: statusColor,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Customer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Name', _quotation!.customerName),
            if (_quotation!.phone != null)
              _buildInfoRow('Phone', _quotation!.phone!),
          ],
        ),
      ),
    );
  }

  Widget _buildPlotCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Plot Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                    child:
                        _buildInfoRow('Plot Number', _quotation!.plotNumber)),
                Expanded(
                    child: _buildInfoRow('Block', _quotation!.block ?? 'N/A')),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child:
                        _buildInfoRow('Sector', _quotation!.sector ?? 'N/A')),
                Expanded(
                    child: _buildInfoRow(
                        'Location', _quotation!.location ?? 'N/A')),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildInfoRow('Length', '${_quotation!.length} ft')),
                Expanded(
                    child:
                        _buildInfoRow('Breadth', '${_quotation!.breadth} ft')),
              ],
            ),
            _buildInfoRow(
                'Total Area', Formatters.formatArea(_quotation!.totalArea)),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    final downPayment =
        _quotation!.totalPrice * (_quotation!.downPaymentPercent / 100);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.currency_rupee,
                      color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pricing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Rate per Gaj',
                Formatters.formatCurrency(_quotation!.ratePerGaj)),
            _buildInfoRow('Total Price',
                Formatters.formatCurrency(_quotation!.totalPrice)),
            const Divider(height: 24),
            _buildInfoRow('Down Payment',
                '${_quotation!.downPaymentPercent.toStringAsFixed(0)}% (${Formatters.formatCurrency(downPayment)})'),
            _buildInfoRow(
                'Loan Amount',
                Formatters.formatCurrency(
                    _quotation!.totalPrice - downPayment)),
            _buildInfoRow('EMI',
                '${Formatters.formatCurrency(_quotation!.emiAmount)} x ${_quotation!.emiMonths} months'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total EMI Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  Formatters.formatCurrency(
                      _quotation!.emiAmount * _quotation!.emiMonths),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentScheduleCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.schedule, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF388E3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Immediate Payment', style: TextStyle(fontSize: 12)),
                      Text('Down Payment',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  Text(
                    Formatters.formatCurrency(_quotation!.downPaymentAmount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF388E3C)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monthly EMI', style: TextStyle(fontSize: 12)),
                      Text('${_quotation!.emiMonths} months',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 11)),
                    ],
                  ),
                  Text(
                    Formatters.formatCurrency(_quotation!.emiAmount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1976D2)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.note, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Remarks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(_quotation!.remarks ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_quotation!.status != 'pending' || _quotation!.isExpired) {
      return const SizedBox();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _updateStatus('rejected'),
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus('accepted'),
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF388E3C);
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return const Color(0xFFFF9800);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }
}
