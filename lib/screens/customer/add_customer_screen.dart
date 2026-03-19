import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/customer_model.dart';
import '../../models/nominee_model.dart';
import '../../models/id_proof_model.dart';
import '../../utils/validators.dart';
import '../../config/constants.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();
  final _relationNameController = TextEditingController();
  final _relationTypeController = TextEditingController();
  final _nomineeNameController = TextEditingController();
  final _nomineePhoneController = TextEditingController();
  final _nomineeRelationController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();

  DateTime? _dob;
  bool _isLoading = false;
  bool _phoneExists = false;

  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _relationNameController.dispose();
    _relationTypeController.dispose();
    _nomineeNameController.dispose();
    _nomineePhoneController.dispose();
    _nomineeRelationController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _checkPhone() async {
    if (_phoneController.text.length >= 10) {
      final exists = await _dbService.phoneExists(_phoneController.text);
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

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_phoneExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number already exists'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customer = CustomerModel(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        dob: _dob,
        occupation: _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
        relationName: _relationNameController.text.trim().isEmpty ? null : _relationNameController.text.trim(),
        relationType: _relationTypeController.text.trim().isEmpty ? null : _relationTypeController.text.trim(),
      );

      final customerId = await _dbService.insertCustomer(customer);

      if (_nomineeNameController.text.trim().isNotEmpty) {
        final nominee = NomineeModel(
          customerId: customerId,
          name: _nomineeNameController.text.trim(),
          phone: _nomineePhoneController.text.trim().isEmpty ? null : _nomineePhoneController.text.trim(),
          relation: _nomineeRelationController.text.trim().isEmpty ? null : _nomineeRelationController.text.trim(),
          aadhar: _aadharController.text.trim().isEmpty ? null : _aadharController.text.trim(),
        );
        await _dbService.insertNominee(nominee);
      }

      if (_aadharController.text.trim().isNotEmpty) {
        final idProof = IdProofModel(
          customerId: customerId,
          type: 'Aadhar Card',
          number: _aadharController.text.trim(),
        );
        await _dbService.insertIdProof(idProof);
      }

      if (_panController.text.trim().isNotEmpty) {
        final idProof = IdProofModel(
          customerId: customerId,
          type: 'PAN Card',
          number: _panController.text.trim(),
        );
        await _dbService.insertIdProof(idProof);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer added successfully')),
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
      appBar: AppBar(title: const Text('Add Customer')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _saveCustomer();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_currentStep == 2 ? 'Save' : 'Continue'),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Basic Info'),
              content: _buildBasicInfoStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('KYC Details'),
              content: _buildKycStep(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Nominee'),
              content: _buildNomineeStep(),
              isActive: _currentStep >= 2,
              state: StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
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
      ],
    );
  }

  Widget _buildKycStep() {
    return Column(
      children: [
        TextFormField(
          controller: _aadharController,
          decoration: const InputDecoration(labelText: 'Aadhar Number', prefixIcon: Icon(Icons.badge)),
          keyboardType: TextInputType.number,
          validator: Validators.validateAadhar,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _panController,
          decoration: const InputDecoration(labelText: 'PAN Number', prefixIcon: Icon(Icons.credit_card)),
          textCapitalization: TextCapitalization.characters,
          validator: Validators.validatePan,
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
      ],
    );
  }

  Widget _buildNomineeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nominee Details (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nomineeNameController,
          decoration: const InputDecoration(labelText: 'Nominee Name', prefixIcon: Icon(Icons.person)),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nomineePhoneController,
          decoration: const InputDecoration(labelText: 'Nominee Phone', prefixIcon: Icon(Icons.phone)),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _nomineeRelationController.text.isEmpty ? null : _nomineeRelationController.text,
          decoration: const InputDecoration(labelText: 'Relation', prefixIcon: Icon(Icons.family_restroom)),
          items: AppConstants.relationTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
          onChanged: (value) => setState(() => _nomineeRelationController.text = value ?? ''),
        ),
      ],
    );
  }
}
