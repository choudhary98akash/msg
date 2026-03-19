import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/customer_model.dart';
import '../../utils/validators.dart';
import '../../config/constants.dart';

class EditCustomerScreen extends StatefulWidget {
  final CustomerModel customer;

  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _occupationController;
  late final TextEditingController _relationNameController;
  late final TextEditingController _relationTypeController;

  DateTime? _dob;
  bool _isLoading = false;
  bool _phoneExists = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _emailController = TextEditingController(text: widget.customer.email);
    _addressController = TextEditingController(text: widget.customer.address);
    _occupationController = TextEditingController(text: widget.customer.occupation);
    _relationNameController = TextEditingController(text: widget.customer.relationName);
    _relationTypeController = TextEditingController(text: widget.customer.relationType);
    _dob = widget.customer.dob;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _relationNameController.dispose();
    _relationTypeController.dispose();
    super.dispose();
  }

  Future<void> _checkPhone() async {
    if (_phoneController.text.length >= 10) {
      final exists = await _dbService.phoneExists(_phoneController.text, excludeId: widget.customer.id);
      setState(() => _phoneExists = exists);
    }
  }

  Future<void> _selectDob() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (date != null) {
      setState(() => _dob = date);
    }
  }

  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_phoneExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number already exists'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customer = widget.customer.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        dob: _dob,
        occupation: _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
        relationName: _relationNameController.text.trim().isEmpty ? null : _relationNameController.text.trim(),
        relationType: _relationTypeController.text.trim().isEmpty ? null : _relationTypeController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _dbService.updateCustomer(customer);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer updated successfully')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.person)),
              validator: Validators.validateName,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone *', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
              onChanged: (_) => _checkPhone(),
            ),
            if (_phoneExists)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Phone number already exists', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _occupationController,
              decoration: const InputDecoration(labelText: 'Occupation', prefixIcon: Icon(Icons.work)),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDob,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.cake)),
                child: Text(_dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Select date'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _relationNameController,
              decoration: const InputDecoration(labelText: 'Emergency Contact Name', prefixIcon: Icon(Icons.emergency)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _relationTypeController.text.isEmpty ? null : _relationTypeController.text,
              decoration: const InputDecoration(labelText: 'Relation Type', prefixIcon: Icon(Icons.family_restroom)),
              items: AppConstants.relationTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) => setState(() => _relationTypeController.text = value ?? ''),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateCustomer,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Update Customer'),
            ),
          ],
        ),
      ),
    );
  }
}
