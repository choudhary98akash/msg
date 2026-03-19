import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/customer_model.dart';
import '../../models/booking_model.dart';
import '../../utils/validators.dart';
import '../../utils/formatters.dart';
import '../../utils/calculator.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';

class BookingFormScreen extends StatefulWidget {
  final BookingModel? booking;

  const BookingFormScreen({super.key, this.booking});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  CustomerModel? _selectedCustomer;
  List<CustomerModel> _customers = [];
  bool _isLoading = false;

  final _plotNumberController = TextEditingController();
  final _blockController = TextEditingController();
  final _sectorController = TextEditingController();
  final _locationController = TextEditingController();
  final _lengthController = TextEditingController();
  final _breadthController = TextEditingController();
  final _areaController = TextEditingController();
  final _rateController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _downPaymentPercentController = TextEditingController(text: '20');
  final _downPaymentAmountController = TextEditingController();
  final _emiMonthsController = TextEditingController(text: '24');
  final _emiAmountController = TextEditingController();
  final _tokenAmountController = TextEditingController(text: '10000');
  final _remarksController = TextEditingController();

  DateTime _bookingDate = DateTime.now();
  DateTime? _tokenDate;
  bool _autoCalculate = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _setupListeners();

    if (widget.booking != null) {
      _populateFields(widget.booking!);
    }
  }

  void _setupListeners() {
    _lengthController.addListener(_calculateArea);
    _breadthController.addListener(_calculateArea);
    _rateController.addListener(_calculateTotalPrice);
    _downPaymentPercentController.addListener(_calculateDownPayment);
    _emiMonthsController.addListener(_calculateEmi);

    _lengthController.addListener(_onInputChanged);
    _breadthController.addListener(_onInputChanged);
    _rateController.addListener(_onInputChanged);
    _downPaymentPercentController.addListener(_onInputChanged);
    _emiMonthsController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (_autoCalculate && _lengthController.text.isNotEmpty && _breadthController.text.isNotEmpty) {
      _calculateAll();
    }
  }

  void _calculateArea() {
    final length = double.tryParse(_lengthController.text);
    final breadth = double.tryParse(_breadthController.text);
    if (length != null && breadth != null && length > 0 && breadth > 0) {
      final area = Calculator.calculateArea(length, breadth);
      _areaController.text = area.toStringAsFixed(2);
      _calculateTotalPrice();
    }
  }

  void _calculateTotalPrice() {
    final area = double.tryParse(_areaController.text);
    final rate = double.tryParse(_rateController.text);
    if (area != null && rate != null && area > 0 && rate > 0) {
      final totalPrice = Calculator.calculateTotalPrice(area, rate);
      _totalPriceController.text = totalPrice.toStringAsFixed(0);
      _calculateDownPayment();
    }
  }

  void _calculateDownPayment() {
    final totalPrice = double.tryParse(_totalPriceController.text);
    final percent = double.tryParse(_downPaymentPercentController.text);
    if (totalPrice != null && percent != null && totalPrice > 0) {
      final downPayment = Calculator.calculateDownPaymentAmount(totalPrice, percent);
      _downPaymentAmountController.text = downPayment.toStringAsFixed(0);
      _calculateEmi();
    }
  }

  void _calculateEmi() {
    final totalPrice = double.tryParse(_totalPriceController.text);
    final downPayment = double.tryParse(_downPaymentAmountController.text);
    final emiMonths = int.tryParse(_emiMonthsController.text);
    if (totalPrice != null && downPayment != null && emiMonths != null && totalPrice > 0) {
      final emi = Calculator.calculateEmiAmount(totalPrice, downPayment, emiMonths);
      _emiAmountController.text = emi > 0 ? emi.toStringAsFixed(0) : '0';
    }
  }

  void _calculateAll() {
    _calculateArea();
  }

  Future<void> _loadCustomers() async {
    final customers = await _dbService.getAllCustomers();
    setState(() => _customers = customers);
  }

  void _populateFields(BookingModel booking) {
    _plotNumberController.text = booking.plotNumber;
    _blockController.text = booking.block ?? '';
    _sectorController.text = booking.sector ?? '';
    _locationController.text = booking.location ?? '';
    _lengthController.text = booking.length.toString();
    _breadthController.text = booking.breadth.toString();
    _areaController.text = booking.totalArea.toString();
    _rateController.text = booking.ratePerGaj.toString();
    _totalPriceController.text = booking.totalPrice.toString();
    _downPaymentPercentController.text = booking.downPaymentPercent.toString();
    _downPaymentAmountController.text = booking.downPaymentAmount.toString();
    _emiMonthsController.text = booking.emiMonths.toString();
    _emiAmountController.text = booking.emiAmount.toString();
    _tokenAmountController.text = booking.tokenAmount.toString();
    _remarksController.text = booking.remarks ?? '';
    _bookingDate = booking.bookingDate;
    _tokenDate = booking.tokenDate;
    _autoCalculate = false;
  }

  Future<void> _selectDate({required bool isTokenDate}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isTokenDate ? (_tokenDate ?? DateTime.now()) : _bookingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        if (isTokenDate) {
          _tokenDate = date;
        } else {
          _bookingDate = date;
        }
      });
    }
  }

  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer'), backgroundColor: Colors.red),
      );
      return;
    }

    final downPayment = double.tryParse(_downPaymentAmountController.text) ?? 0;
    final totalPrice = double.tryParse(_totalPriceController.text) ?? 0;

    if (downPayment > totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Down payment cannot exceed total price'), backgroundColor: Colors.red),
      );
      return;
    }

    final emiAmount = double.tryParse(_emiAmountController.text) ?? 0;
    if (emiAmount > 0 && emiAmount < AppConstants.minEmiAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum EMI amount is ${AppConstants.minEmiAmount}'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final booking = BookingModel(
        customerId: _selectedCustomer!.id!,
        plotNumber: _plotNumberController.text.trim(),
        block: _blockController.text.trim().isEmpty ? null : _blockController.text.trim(),
        sector: _sectorController.text.trim().isEmpty ? null : _sectorController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        length: double.parse(_lengthController.text),
        breadth: double.parse(_breadthController.text),
        totalArea: double.parse(_areaController.text),
        ratePerGaj: double.parse(_rateController.text),
        totalPrice: double.parse(_totalPriceController.text),
        downPaymentPercent: double.parse(_downPaymentPercentController.text),
        downPaymentAmount: double.parse(_downPaymentAmountController.text),
        emiMonths: int.parse(_emiMonthsController.text),
        emiAmount: double.parse(_emiAmountController.text),
        tokenDate: _tokenDate,
        tokenAmount: double.parse(_tokenAmountController.text),
        bookingDate: _bookingDate,
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      );

      await _dbService.insertBooking(booking);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully')),
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

  @override
  void dispose() {
    _plotNumberController.dispose();
    _blockController.dispose();
    _sectorController.dispose();
    _locationController.dispose();
    _lengthController.dispose();
    _breadthController.dispose();
    _areaController.dispose();
    _rateController.dispose();
    _totalPriceController.dispose();
    _downPaymentPercentController.dispose();
    _downPaymentAmountController.dispose();
    _emiMonthsController.dispose();
    _emiAmountController.dispose();
    _tokenAmountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.booking != null ? 'Edit Booking' : 'New Booking')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCustomerSelector(),
            const SizedBox(height: 24),
            _buildSectionTitle('Plot Details'),
            const SizedBox(height: 8),
            _buildPlotDetails(),
            const SizedBox(height: 24),
            _buildSectionTitle('Dimensions & Pricing'),
            const SizedBox(height: 8),
            _buildDimensions(),
            const SizedBox(height: 24),
            _buildSectionTitle('Payment Terms'),
            const SizedBox(height: 8),
            _buildPaymentTerms(),
            const SizedBox(height: 24),
            _buildSectionTitle('Dates'),
            const SizedBox(height: 8),
            _buildDates(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Remarks', prefixIcon: Icon(Icons.note)),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveBooking,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Booking'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor));
  }

  Widget _buildCustomerSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Customer *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<CustomerModel>(
              value: _selectedCustomer,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.person)),
              hint: const Text('Choose customer'),
              items: _customers.map((c) => DropdownMenuItem(
                value: c,
                child: Text('${c.name} - ${c.phone ?? "No phone"}'),
              )).toList(),
              onChanged: (value) => setState(() => _selectedCustomer = value),
              validator: (value) => value == null ? 'Please select a customer' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlotDetails() {
    return Column(
      children: [
        TextFormField(
          controller: _plotNumberController,
          decoration: const InputDecoration(labelText: 'Plot Number *', prefixIcon: Icon(Icons.home)),
          validator: Validators.validatePlotNumber,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _blockController, decoration: const InputDecoration(labelText: 'Block'))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _sectorController, decoration: const InputDecoration(labelText: 'Sector'))),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
        ),
      ],
    );
  }

  Widget _buildDimensions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _lengthController,
                decoration: const InputDecoration(labelText: 'Length (ft) *', prefixIcon: Icon(Icons.straighten)),
                keyboardType: TextInputType.number,
                validator: (v) => Validators.validateDimension(v, 'Length'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _breadthController,
                decoration: const InputDecoration(labelText: 'Breadth (ft) *', prefixIcon: Icon(Icons.straighten)),
                keyboardType: TextInputType.number,
                validator: (v) => Validators.validateDimension(v, 'Breadth'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Area (Gaj)', prefixIcon: Icon(Icons.square_foot)),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(labelText: 'Rate/Gaj *', prefixIcon: Icon(Icons.currency_rupee)),
                keyboardType: TextInputType.number,
                validator: Validators.validateRate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _totalPriceController,
          decoration: const InputDecoration(labelText: 'Total Price', prefixIcon: Icon(Icons.calculate)),
          keyboardType: TextInputType.number,
          readOnly: true,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPaymentTerms() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _downPaymentPercentController,
                decoration: const InputDecoration(labelText: 'Down Payment %', prefixIcon: Icon(Icons.percent)),
                keyboardType: TextInputType.number,
                validator: Validators.validateDownPaymentPercent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _downPaymentAmountController,
                decoration: const InputDecoration(labelText: 'Down Payment Amount', prefixIcon: Icon(Icons.currency_rupee)),
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emiMonthsController,
                decoration: const InputDecoration(labelText: 'EMI Months', prefixIcon: Icon(Icons.calendar_month)),
                keyboardType: TextInputType.number,
                validator: Validators.validateEmiMonths,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _emiAmountController,
                decoration: const InputDecoration(labelText: 'EMI Amount', prefixIcon: Icon(Icons.currency_rupee)),
                keyboardType: TextInputType.number,
                readOnly: true,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tokenAmountController,
          decoration: const InputDecoration(labelText: 'Token Amount *', prefixIcon: Icon(Icons.token)),
          keyboardType: TextInputType.number,
          validator: Validators.validateAmount,
        ),
      ],
    );
  }

  Widget _buildDates() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(isTokenDate: false),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Booking Date', prefixIcon: Icon(Icons.calendar_today)),
              child: Text(Formatters.formatDate(_bookingDate)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(isTokenDate: true),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Token Date', prefixIcon: Icon(Icons.event)),
              child: Text(_tokenDate != null ? Formatters.formatDate(_tokenDate!) : 'Select'),
            ),
          ),
        ),
      ],
    );
  }
}
