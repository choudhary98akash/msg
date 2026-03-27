import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/quotation_model.dart';
import '../../models/customer_model.dart';
import '../../utils/validators.dart';
import '../../utils/calculator.dart';
import '../../config/theme.dart';

class QuotationFormScreen extends StatefulWidget {
  final QuotationModel? quotation;

  const QuotationFormScreen({super.key, this.quotation});

  @override
  State<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends State<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  List<CustomerModel> _customers = [];
  CustomerModel? _selectedCustomer;
  bool _isLoading = false;
  bool _isExistingCustomer = false;
  bool _isUpdatingDownPayment = false;

  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
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
  final _validityDaysController = TextEditingController(text: '30');
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _setupListeners();

    if (widget.quotation != null) {
      _populateFields(widget.quotation!);
    }
  }

  void _setupListeners() {
    _lengthController.addListener(_calculateArea);
    _breadthController.addListener(_calculateArea);
    _rateController.addListener(_calculateTotalPrice);
    _emiMonthsController.addListener(_calculateEmi);
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
      _calculateDownPaymentFromPercent();
    }
  }

  void _calculateDownPaymentFromPercent() {
    if (_isUpdatingDownPayment) return;
    _isUpdatingDownPayment = true;

    final totalPrice = double.tryParse(_totalPriceController.text) ?? 0;
    var percent = double.tryParse(_downPaymentPercentController.text) ?? 0;

    if (percent > 100) {
      percent = 100;
      _downPaymentPercentController.text = '100';
    }

    if (totalPrice > 0 && percent >= 0) {
      final amount = totalPrice * (percent / 100);
      _downPaymentAmountController.text = amount.toStringAsFixed(0);
      _calculateEmi();
    }

    _isUpdatingDownPayment = false;
  }

  void _calculateDownPaymentFromAmount() {
    if (_isUpdatingDownPayment) return;
    _isUpdatingDownPayment = true;

    final totalPrice = double.tryParse(_totalPriceController.text) ?? 0;
    var amount = double.tryParse(_downPaymentAmountController.text) ?? 0;

    if (totalPrice > 0 && amount > totalPrice) {
      amount = totalPrice;
      _downPaymentAmountController.text = amount.toStringAsFixed(0);
    }

    if (totalPrice > 0 && amount >= 0) {
      final percent = (amount / totalPrice) * 100;
      _downPaymentPercentController.text = percent.toStringAsFixed(2);
      _calculateEmi();
    }

    _isUpdatingDownPayment = false;
  }

  void _calculateEmi() {
    final totalPrice = double.tryParse(_totalPriceController.text) ?? 0;
    final downPayment = double.tryParse(_downPaymentAmountController.text) ?? 0;
    final emiMonths = int.tryParse(_emiMonthsController.text) ?? 0;
    if (totalPrice > 0 && downPayment >= 0 && emiMonths > 0) {
      final emi =
          Calculator.calculateEmiAmount(totalPrice, downPayment, emiMonths);
      _emiAmountController.text = emi > 0 ? emi.toStringAsFixed(0) : '0';
    }
  }

  Future<void> _loadCustomers() async {
    final customers = await _dbService.getAllCustomers();
    setState(() => _customers = customers);
  }

  void _populateFields(QuotationModel quotation) {
    _customerNameController.text = quotation.customerName;
    _phoneController.text = quotation.phone ?? '';
    _plotNumberController.text = quotation.plotNumber;
    _blockController.text = quotation.block ?? '';
    _sectorController.text = quotation.sector ?? '';
    _locationController.text = quotation.location ?? '';
    _lengthController.text = quotation.length.toString();
    _breadthController.text = quotation.breadth.toString();
    _areaController.text = quotation.totalArea.toString();
    _rateController.text = quotation.ratePerGaj.toString();
    _totalPriceController.text = quotation.totalPrice.toString();
    _downPaymentPercentController.text =
        quotation.downPaymentPercent.toString();
    _downPaymentAmountController.text = quotation.downPaymentAmount.toString();
    _emiMonthsController.text = quotation.emiMonths.toString();
    _emiAmountController.text = quotation.emiAmount.toString();
    _validityDaysController.text = quotation.validityDays.toString();
    _remarksController.text = quotation.remarks ?? '';

    if (quotation.customerId != null) {
      final customer =
          _customers.where((c) => c.id == quotation.customerId).firstOrNull;
      if (customer != null) {
        _selectedCustomer = customer;
        _isExistingCustomer = true;
      }
    }
  }

  Future<void> _saveQuotation() async {
    if (!_formKey.currentState!.validate()) return;

    final length = double.tryParse(_lengthController.text) ?? 0;
    final breadth = double.tryParse(_breadthController.text) ?? 0;
    final area = double.tryParse(_areaController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final downPaymentPercent =
        double.tryParse(_downPaymentPercentController.text) ?? 0;

    if (length <= 0 || breadth <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter valid dimensions'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Area cannot be zero'), backgroundColor: Colors.red),
      );
      return;
    }

    if (rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid rate'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (downPaymentPercent > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Down payment cannot exceed 100%'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final validityDays = int.tryParse(_validityDaysController.text) ?? 30;
      final validUntil = DateTime.now().add(Duration(days: validityDays));

      final quotation = QuotationModel(
        customerId: _selectedCustomer?.id,
        customerName: _isExistingCustomer
            ? _selectedCustomer!.name
            : _customerNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        plotNumber: _plotNumberController.text.trim(),
        block: _blockController.text.trim().isEmpty
            ? null
            : _blockController.text.trim(),
        sector: _sectorController.text.trim().isEmpty
            ? null
            : _sectorController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        length: length,
        breadth: breadth,
        totalArea: area,
        ratePerGaj: rate,
        totalPrice: double.parse(_totalPriceController.text),
        downPaymentPercent: downPaymentPercent,
        downPaymentAmount: double.parse(_downPaymentAmountController.text),
        emiMonths: int.parse(_emiMonthsController.text),
        emiAmount: double.parse(_emiAmountController.text),
        validityDays: validityDays,
        validUntil: validUntil,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      await _dbService.insertQuotation(quotation);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation created successfully')),
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
    _customerNameController.dispose();
    _phoneController.dispose();
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
    _validityDaysController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.quotation != null ? 'Edit Quotation' : 'Create Quotation'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCustomerSection(),
            const SizedBox(height: 20),
            _buildSectionHeader(Icons.home_work, 'Plot Details'),
            const SizedBox(height: 12),
            _buildPlotDetails(),
            const SizedBox(height: 20),
            _buildSectionHeader(Icons.straighten, 'Dimensions & Pricing'),
            const SizedBox(height: 12),
            _buildDimensions(),
            const SizedBox(height: 20),
            _buildSectionHeader(Icons.payment, 'Payment Terms'),
            const SizedBox(height: 12),
            _buildPaymentTerms(),
            const SizedBox(height: 20),
            _buildSectionHeader(Icons.timer, 'Validity'),
            const SizedBox(height: 12),
            _buildValidity(),
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
              onPressed: _isLoading ? null : _saveQuotation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Quotation'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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

  Widget _buildCustomerSection() {
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
                const Icon(Icons.person, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Customer Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('New Customer'),
                    selected: !_isExistingCustomer,
                    onSelected: (selected) {
                      if (selected) setState(() => _isExistingCustomer = false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Existing Customer'),
                    selected: _isExistingCustomer,
                    onSelected: (selected) {
                      if (selected) setState(() => _isExistingCustomer = true);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isExistingCustomer)
              DropdownButtonFormField<CustomerModel>(
                value: _selectedCustomer,
                decoration: const InputDecoration(hintText: 'Choose customer'),
                items: _customers
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.name} - ${c.phone ?? "No phone"}'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCustomer = value),
                validator: (value) => _isExistingCustomer && value == null
                    ? 'Please select a customer'
                    : null,
              )
            else ...[
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: Validators.validateName,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlotDetails() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _plotNumberController,
              decoration: const InputDecoration(
                labelText: 'Plot Number *',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: Validators.validatePlotNumber,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _blockController,
                    decoration: const InputDecoration(
                      labelText: 'Block',
                      prefixIcon: Icon(Icons.grid_view_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sectorController,
                    decoration: const InputDecoration(
                      labelText: 'Sector',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensions() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lengthController,
                    decoration: const InputDecoration(
                      labelText: 'Length (ft) *',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.validateDimension(v, 'Length'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _breadthController,
                    decoration: const InputDecoration(
                      labelText: 'Breadth (ft) *',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        Validators.validateDimension(v, 'Breadth'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Area (Gaj)',
                      prefixIcon: Icon(Icons.square_foot),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    decoration: const InputDecoration(
                      labelText: 'Rate/Gaj *',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                    validator: Validators.validateRate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalPriceController,
              decoration: const InputDecoration(
                labelText: 'Total Price',
                prefixIcon: Icon(Icons.calculate),
              ),
              keyboardType: TextInputType.number,
              readOnly: true,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTerms() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _downPaymentPercentController,
                    decoration: const InputDecoration(
                      labelText: 'Down Payment %',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateDownPaymentFromPercent(),
                    validator: (v) {
                      final percent = double.tryParse(v ?? '') ?? 0;
                      if (percent > 100) return 'Max 100%';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _downPaymentAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateDownPaymentFromAmount(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emiMonthsController,
                    decoration: const InputDecoration(
                      labelText: 'EMI Months',
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    keyboardType: TextInputType.number,
                    validator: Validators.validateEmiMonths,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _emiAmountController,
                    decoration: const InputDecoration(
                      labelText: 'EMI Amount',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidity() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _validityDaysController,
          decoration: const InputDecoration(
            labelText: 'Validity (Days)',
            prefixIcon: Icon(Icons.timer_outlined),
            helperText: 'Quotation will be valid for this many days',
          ),
          keyboardType: TextInputType.number,
        ),
      ),
    );
  }
}
