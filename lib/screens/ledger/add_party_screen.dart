import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/ledger_party_model.dart';
import '../../services/ledger_service.dart';

class AddPartyScreen extends StatefulWidget {
  final LedgerParty? party;

  const AddPartyScreen({super.key, this.party});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ledgerService = LedgerService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _notesController = TextEditingController();

  String _partyType = LedgerParty.typeDebtor;
  bool _isLoading = false;

  bool get isEditing => widget.party != null;

  @override
  void initState() {
    super.initState();
    if (widget.party != null) {
      _nameController.text = widget.party!.name;
      _phoneController.text = widget.party!.phone ?? '';
      _openingBalanceController.text = widget.party!.openingBalance.toString();
      _notesController.text = widget.party!.notes ?? '';
      _partyType = widget.party!.partyType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveParty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final party = LedgerParty(
        id: widget.party?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        partyType: _partyType,
        openingBalance: double.tryParse(_openingBalanceController.text) ?? 0,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.party?.createdAt,
      );

      if (isEditing) {
        await _ledgerService.updateParty(party);
      } else {
        await _ledgerService.addParty(party);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving party: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Party' : 'Add Party'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionCard(
              icon: Icons.person,
              title: 'Party Details',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _partyType,
                  decoration: const InputDecoration(
                    labelText: 'Party Type *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: LedgerParty.typeDebtor,
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward,
                              color: AppTheme.secondaryColor, size: 20),
                          SizedBox(width: 8),
                          Text('Debtor (Owes me)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: LedgerParty.typeCreditor,
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward,
                              color: AppTheme.errorColor, size: 20),
                          SizedBox(width: 8),
                          Text('Creditor (I owe)'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _partyType = value!);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.account_balance_wallet,
              title: 'Opening Balance',
              children: [
                TextFormField(
                  controller: _openingBalanceController,
                  decoration: const InputDecoration(
                    labelText: 'Opening Balance',
                    prefixIcon: Icon(Icons.currency_rupee),
                    hintText: '0.00',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set initial balance if party already owes you or you owe them',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.note,
              title: 'Notes',
              children: [
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    prefixIcon: Icon(Icons.note_outlined),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveParty,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Update Party' : 'Add Party'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
