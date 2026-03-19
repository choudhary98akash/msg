import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/payment_model.dart';
import '../../models/booking_model.dart';
import '../../models/customer_model.dart';
import '../../utils/validators.dart';
import '../../utils/formatters.dart';
import '../../config/constants.dart';
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
    final activeBookings = bookings.where((b) => b.status == 'active').toList();
    setState(() => _bookings = activeBookings);

    if (widget.payment != null) {
      final booking = await _dbService.getBooking(widget.payment!.bookingId);
      if (booking != null) {
        _selectBooking(booking);
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
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _paymentDate = date);
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBooking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a booking'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_paymentDate.isAfter(DateTime.now())) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Future Date'),
          content: const Text('Payment date is in the future. Mark as pending?'),
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
        bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
        chequeNumber: _chequeNumberController.text.trim().isEmpty ? null : _chequeNumberController.text.trim(),
        transactionId: _transactionIdController.text.trim().isEmpty ? null : _transactionIdController.text.trim(),
        receiptNumber: receiptNumber,
        status: _paymentDate.isAfter(DateTime.now()) ? 'pending' : 'completed',
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      );

      final paymentId = await _dbService.insertPayment(payment);
      payment.id = paymentId;

      if (mounted) {
        await _showReceiptDialog(payment);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment added successfully')),
        );
      }
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

  Future<void> _showReceiptDialog(PaymentModel payment) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Added'),
        content: Text('Receipt Number: ${payment.receiptNumber}'),
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
      if (_customer != null) {
        final receiptNumber = await _dbService.generateReceiptNumber();
        if (action == 'print') {
          await _receiptPdfService.printReceipt(
            payment: payment,
            booking: _selectedBooking!,
            customer: _customer!,
            receiptNumber: receiptNumber,
          );
        } else {
          await _receiptPdfService.shareReceipt(
            payment: payment,
            booking: _selectedBooking!,
            customer: _customer!,
            receiptNumber: receiptNumber,
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.payment != null ? 'Edit Payment' : 'Add Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBookingSelector(),
            const SizedBox(height: 16),
            if (_selectedBooking != null && _customer != null) _buildBookingInfo(),
            const SizedBox(height: 24),
            _buildPaymentTypeSelector(),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildPaymentModeSelector(),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 16),
            _buildBankDetails(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Remarks', prefixIcon: Icon(Icons.note)),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _savePayment,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSelector() {
    return DropdownButtonFormField<BookingModel>(
      value: _selectedBooking,
      decoration: const InputDecoration(labelText: 'Select Booking *', prefixIcon: Icon(Icons.home_work)),
      hint: const Text('Choose booking'),
      items: _bookings.map((b) => DropdownMenuItem(
        value: b,
        child: Text('Plot ${b.plotNumber} - ${b.location ?? "N/A"}'),
      )).toList(),
      onChanged: (value) {
        if (value != null) _selectBooking(value);
      },
      validator: (value) => value == null ? 'Please select a booking' : null,
    );
  }

  Widget _buildBookingInfo() {
    final booking = _selectedBooking!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_customer!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(_customer!.phone ?? 'No phone', style: TextStyle(color: Colors.grey[600])),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Price:'),
                Text(Formatters.formatCurrency(booking.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Down Payment:'),
                Text(Formatters.formatCurrency(booking.downPaymentAmount)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EMI:'),
                Text('${Formatters.formatCurrency(booking.emiAmount)} x ${booking.emiMonths}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    return DropdownButtonFormField<String>(
      value: _paymentType,
      decoration: const InputDecoration(labelText: 'Payment Type *', prefixIcon: Icon(Icons.category)),
      items: AppConstants.paymentTypes.map((type) => DropdownMenuItem(
        value: type,
        child: Text(type),
      )).toList(),
      onChanged: (value) => setState(() => _paymentType = value!),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(labelText: 'Amount *', prefixIcon: Icon(Icons.currency_rupee)),
      keyboardType: TextInputType.number,
      validator: Validators.validateAmount,
    );
  }

  Widget _buildPaymentModeSelector() {
    return DropdownButtonFormField<String>(
      value: _paymentMode,
      decoration: const InputDecoration(labelText: 'Payment Mode *', prefixIcon: Icon(Icons.payment)),
      items: AppConstants.paymentModes.map((mode) => DropdownMenuItem(
        value: mode,
        child: Text(mode),
      )).toList(),
      onChanged: (value) => setState(() => _paymentMode = value!),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Payment Date', prefixIcon: Icon(Icons.calendar_today)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Formatters.formatDate(_paymentDate)),
            if (_paymentDate.isAfter(DateTime.now()))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Future', style: TextStyle(fontSize: 12, color: Colors.orange)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetails() {
    final showBankDetails = ['Bank Transfer', 'Cheque', 'DD', 'RTGS', 'NEFT'].contains(_paymentMode);

    if (!showBankDetails) return const SizedBox();

    return Column(
      children: [
        TextFormField(
          controller: _bankNameController,
          decoration: const InputDecoration(labelText: 'Bank Name', prefixIcon: Icon(Icons.account_balance)),
        ),
        const SizedBox(height: 12),
        if (_paymentMode == 'Cheque' || _paymentMode == 'DD')
          TextFormField(
            controller: _chequeNumberController,
            decoration: InputDecoration(labelText: '${_paymentMode} Number', prefixIcon: const Icon(Icons.numbers)),
          ),
        if (_paymentMode == 'Bank Transfer' || _paymentMode == 'RTGS' || _paymentMode == 'NEFT')
          TextFormField(
            controller: _transactionIdController,
            decoration: const InputDecoration(labelText: 'Transaction ID', prefixIcon: Icon(Icons.receipt)),
          ),
      ],
    );
  }
}
