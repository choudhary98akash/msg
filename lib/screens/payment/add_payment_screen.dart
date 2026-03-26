import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/payment_model.dart';
import '../../models/booking_model.dart';
import '../../models/customer_model.dart';
import '../../utils/formatters.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../services/receipt_pdf_service.dart';

class AddPaymentScreen extends StatefulWidget {
  final PaymentModel? payment;

  const AddPaymentScreen({super.key, this.payment});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  final _receiptPdfService = ReceiptPdfService();

  BookingModel? _selectedBooking;
  List<BookingModel> _bookings = [];
  CustomerModel? _customer;
  bool _isLoading = false;

  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _chequeNumberController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _remarksController = TextEditingController();

  String _paymentType = 'EMI';
  String _paymentMode = 'Cash';
  DateTime _paymentDate = DateTime.now();

  bool get _isViewMode => widget.payment != null;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    if (widget.payment != null) {
      _populateFields(widget.payment!);
    }
  }

  void _populateFields(PaymentModel payment) {
    _amountController.text = payment.amount.toString();
    _bankNameController.text = payment.bankName ?? '';
    _chequeNumberController.text = payment.chequeNumber ?? '';
    _transactionIdController.text = payment.transactionId ?? '';
    _remarksController.text = payment.remarks ?? '';
    _paymentType = payment.paymentType;
    _paymentMode = payment.paymentMode;
    _paymentDate = payment.paymentDate;
  }

  Future<void> _loadBookings() async {
    final bookings = await _dbService.getAllBookings();
    setState(() => _bookings = bookings);

    if (widget.payment != null) {
      final booking = await _dbService.getBooking(widget.payment!.bookingId);
      if (booking != null) {
        await _selectBooking(booking);
      }
    }
  }

  Future<void> _selectBooking(BookingModel booking) async {
    final customer = await _dbService.getCustomer(booking.customerId);
    setState(() {
      _selectedBooking = booking;
      _customer = customer;
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _paymentDate = date);
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBooking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a booking'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_paymentDate.isAfter(DateTime.now())) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Future Date'),
          content: const Text('Payment date is in the future. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final receiptNumber = await _dbService.generateReceiptNumber();

      final payment = PaymentModel(
        bookingId: _selectedBooking!.id!,
        paymentType: _paymentType,
        amount: double.parse(_amountController.text),
        paymentDate: _paymentDate,
        paymentMode: _paymentMode,
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        chequeNumber: _chequeNumberController.text.trim().isEmpty
            ? null
            : _chequeNumberController.text.trim(),
        transactionId: _transactionIdController.text.trim().isEmpty
            ? null
            : _transactionIdController.text.trim(),
        receiptNumber: receiptNumber,
        status: _paymentDate.isAfter(DateTime.now()) ? 'pending' : 'completed',
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      final paymentId = await _dbService.insertPayment(payment);
      payment.id = paymentId;

      await _showReceiptDialog(payment);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment added successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePayment() async {
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
      await _dbService.deletePayment(widget.payment!.id!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment deleted successfully')),
        );
      }
    }
  }

  Future<void> _printReceipt() async {
    if (_customer == null || _selectedBooking == null) return;

    await _receiptPdfService.printReceipt(
      payment: widget.payment!,
      booking: _selectedBooking!,
      customer: _customer!,
      receiptNumber: widget.payment!.receiptNumber ?? '',
    );
  }

  Future<void> _shareReceipt() async {
    if (_customer == null || _selectedBooking == null) return;

    await _receiptPdfService.shareReceipt(
      payment: widget.payment!,
      booking: _selectedBooking!,
      customer: _customer!,
      receiptNumber: widget.payment!.receiptNumber ?? '',
    );
  }

  Future<void> _showReceiptDialog(PaymentModel payment) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.secondaryColor),
            ),
            const SizedBox(width: 12),
            const Text('Payment Added'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Number: ${payment.receiptNumber}'),
            const SizedBox(height: 8),
            Text('Amount: ${Formatters.formatCurrency(payment.amount)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'close'),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'print'),
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'share'),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );

    if (action == 'print' || action == 'share') {
      if (_customer != null && _selectedBooking != null) {
        if (action == 'print') {
          await _receiptPdfService.printReceipt(
            payment: payment,
            booking: _selectedBooking!,
            customer: _customer!,
            receiptNumber: payment.receiptNumber ?? '',
          );
        } else {
          await _receiptPdfService.shareReceipt(
            payment: payment,
            booking: _selectedBooking!,
            customer: _customer!,
            receiptNumber: payment.receiptNumber ?? '',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _chequeNumberController.dispose();
    _transactionIdController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isViewMode) {
      return _buildViewMode();
    }
    return _buildAddMode();
  }

  Widget _buildViewMode() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.home_work, 'Booking Info'),
                  const SizedBox(height: 12),
                  _buildViewBookingCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(Icons.payment, 'Payment Details'),
                  const SizedBox(height: 12),
                  _buildPaymentView(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildAddMode() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(Icons.home_work, 'Booking Selection'),
            const SizedBox(height: 12),
            _buildBookingSelector(),
            const SizedBox(height: 16),
            if (_selectedBooking != null && _customer != null) ...[
              _buildBookingInfo(),
              const SizedBox(height: 20),
            ],
            _buildSectionHeader(Icons.payment, 'Payment Details'),
            const SizedBox(height: 12),
            _buildPaymentDetails(),
            const SizedBox(height: 20),
            _buildSectionHeader(Icons.calendar_today, 'Payment Date'),
            const SizedBox(height: 12),
            _buildDateSelector(),
            const SizedBox(height: 20),
            _buildBankDetails(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _savePayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Payment'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildViewBookingCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  child: Icon(Icons.home_work,
                      color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plot ${_selectedBooking?.plotNumber ?? "N/A"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _selectedBooking?.location ?? 'N/A',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
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
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  radius: 20,
                  child: Text(
                    _customer?.name.isNotEmpty == true
                        ? _customer!.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customer?.name ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _customer?.phone ?? 'No phone',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentView() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
              'Payment Type',
              Formatters.formatPaymentType(_paymentType),
              Icons.category,
            ),
            const Divider(height: 20),
            _buildDetailRow(
              'Amount',
              Formatters.formatCurrency(
                  double.tryParse(_amountController.text) ?? 0),
              Icons.currency_rupee,
              valueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(height: 20),
            _buildDetailRow(
              'Date',
              Formatters.formatDate(_paymentDate),
              Icons.calendar_today,
            ),
            const Divider(height: 20),
            _buildDetailRow(
              'Payment Mode',
              Formatters.formatPaymentMode(_paymentMode),
              Icons.payment,
            ),
            if (_bankNameController.text.isNotEmpty) ...[
              const Divider(height: 20),
              _buildDetailRow(
                'Bank',
                _bankNameController.text,
                Icons.account_balance,
              ),
            ],
            if (_transactionIdController.text.isNotEmpty) ...[
              const Divider(height: 20),
              _buildDetailRow(
                'Transaction ID',
                _transactionIdController.text,
                Icons.receipt,
              ),
            ],
            if (_chequeNumberController.text.isNotEmpty) ...[
              const Divider(height: 20),
              _buildDetailRow(
                'Cheque Number',
                _chequeNumberController.text,
                Icons.confirmation_number,
              ),
            ],
            const Divider(height: 20),
            _buildDetailRow(
              'Receipt No.',
              widget.payment?.receiptNumber ?? 'N/A',
              Icons.receipt_long,
            ),
            if (_remarksController.text.isNotEmpty) ...[
              const Divider(height: 20),
              _buildDetailRow(
                'Remarks',
                _remarksController.text,
                Icons.note,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {TextStyle? valueStyle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: valueStyle ?? const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _printReceipt,
                icon: const Icon(Icons.print),
                label: const Text('Print'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareReceipt,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _deletePayment,
            icon: const Icon(Icons.delete),
            label: const Text('Delete Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSelector() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<BookingModel>(
          value: _selectedBooking,
          decoration: const InputDecoration(
            hintText: 'Choose booking',
          ),
          items: _bookings
              .map((b) => DropdownMenuItem(
                    value: b,
                    child: Text(
                      'Plot ${b.plotNumber} - ${b.location ?? "N/A"}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) _selectBooking(value);
          },
          validator: (value) =>
              value == null ? 'Please select a booking' : null,
        ),
      ),
    );
  }

  Widget _buildBookingInfo() {
    final booking = _selectedBooking!;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    _customer!.name.isNotEmpty
                        ? _customer!.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customer!.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _customer!.phone ?? 'No phone',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Price:'),
                Text(
                  Formatters.formatCurrency(booking.totalPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Down Payment:'),
                Text(Formatters.formatCurrency(booking.downPaymentAmount)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EMI Amount:'),
                Flexible(
                  child: Text(
                    '${Formatters.formatCurrency(booking.emiAmount)} x ${booking.emiMonths} months',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _paymentType,
              decoration: const InputDecoration(
                labelText: 'Payment Type *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AppConstants.paymentTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _paymentType = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMode,
              decoration: const InputDecoration(
                labelText: 'Payment Mode *',
                prefixIcon: Icon(Icons.payment),
              ),
              items: AppConstants.paymentModes
                  .map((mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(mode),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _paymentMode = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Payment Date',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Formatters.formatDate(_paymentDate)),
                if (_paymentDate.isAfter(DateTime.now()))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Future',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.accentColor),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankDetails() {
    final showBankDetails = ['Bank Transfer', 'Cheque', 'DD', 'RTGS', 'NEFT']
        .contains(_paymentMode);

    if (!showBankDetails) return const SizedBox();

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Bank Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
            ),
            const SizedBox(height: 16),
            if (_paymentMode == 'Cheque' || _paymentMode == 'DD')
              TextFormField(
                controller: _chequeNumberController,
                decoration: InputDecoration(
                  labelText: '$_paymentMode Number',
                  prefixIcon: const Icon(Icons.numbers),
                ),
              ),
            if (_paymentMode == 'Bank Transfer' ||
                _paymentMode == 'RTGS' ||
                _paymentMode == 'NEFT')
              TextFormField(
                controller: _transactionIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
