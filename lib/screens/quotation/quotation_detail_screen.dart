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
        setState(() {
          _quotation = quotation;
          _isLoading = false;
        });
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
      await _pdfService.printQuotation(quotation: _quotation!, quotationNumber: quotationNumber);
    } else {
      await _pdfService.shareQuotation(quotation: _quotation!, quotationNumber: quotationNumber);
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
              const PopupMenuItem(value: 'print', child: ListTile(leading: Icon(Icons.print), title: Text('Print'))),
              const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share), title: Text('Share'))),
              const PopupMenuDivider(),
              if (_quotation?.status == 'pending') ...[
                const PopupMenuItem(value: 'accept', child: ListTile(leading: Icon(Icons.check, color: Colors.green), title: Text('Mark as Accepted'))),
                const PopupMenuItem(value: 'reject', child: ListTile(leading: Icon(Icons.close, color: Colors.red), title: Text('Mark as Rejected'))),
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
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    fontSize: 18,
                    color: statusColor,
                  ),
                ),
                if (_quotation!.validUntil != null)
                  Text(
                    isExpired
                        ? 'Expired on ${Formatters.formatDate(_quotation!.validUntil!)}'
                        : 'Valid until ${Formatters.formatDate(_quotation!.validUntil!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? Colors.red : Colors.grey,
                    ),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(_quotation!.status),
                color: statusColor,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 16),
            _infoRow('Name', _quotation!.customerName),
            if (_quotation!.phone != null) _infoRow('Phone', _quotation!.phone!),
          ],
        ),
      ),
    );
  }

  Widget _buildPlotCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.home, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Plot Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(child: _infoRow('Plot Number', _quotation!.plotNumber)),
                Expanded(child: _infoRow('Block', _quotation!.block ?? 'N/A')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _infoRow('Sector', _quotation!.sector ?? 'N/A')),
                Expanded(child: _infoRow('Location', _quotation!.location ?? 'N/A')),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(child: _infoRow('Length', '${_quotation!.length} ft')),
                Expanded(child: _infoRow('Breadth', '${_quotation!.breadth} ft')),
              ],
            ),
            _infoRow('Total Area', Formatters.formatArea(_quotation!.totalArea)),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    final downPayment = _quotation!.totalPrice * (_quotation!.downPaymentPercent / 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.currency_rupee, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 16),
            _infoRow('Rate per Gaj', Formatters.formatCurrency(_quotation!.ratePerGaj)),
            _infoRow('Total Price', Formatters.formatCurrency(_quotation!.totalPrice)),
            const Divider(height: 16),
            _infoRow('Down Payment', '${_quotation!.downPaymentPercent.toStringAsFixed(0)}% (${Formatters.formatCurrency(downPayment)})'),
            _infoRow('Loan Amount', Formatters.formatCurrency(_quotation!.totalPrice - downPayment)),
            _infoRow('EMI', '${Formatters.formatCurrency(_quotation!.emiAmount)} x ${_quotation!.emiMonths} months'),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total EMI Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  Formatters.formatCurrency(_quotation!.emiAmount * _quotation!.emiMonths),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Payment Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Immediate Payment:'),
                Text(
                  Formatters.formatCurrency(_quotation!.downPaymentAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monthly EMI:'),
                Text(
                  Formatters.formatCurrency(_quotation!.emiAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EMI Duration:'),
                Text('${_quotation!.emiMonths} months'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Remarks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 16),
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
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus('accepted'),
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
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
