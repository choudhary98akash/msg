import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/ledger_party_model.dart';
import '../../models/ledger_transaction_model.dart';
import '../../services/ledger_service.dart';
import '../../services/ledger_pdf_service.dart';
import '../../utils/formatters.dart';
import 'add_party_screen.dart';

class PartyDetailScreen extends StatefulWidget {
  final LedgerParty party;

  const PartyDetailScreen({super.key, required this.party});

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  final LedgerService _ledgerService = LedgerService();
  List<LedgerTransaction> _transactions = [];
  double _totalGive = 0;
  double _totalTake = 0;
  double _balance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final transactions =
          await _ledgerService.getTransactions(widget.party.id!);
      final totalGive = await _ledgerService.getTotalGive(widget.party.id!);
      final totalTake = await _ledgerService.getTotalTake(widget.party.id!);
      final balance = await _ledgerService.getBalance(widget.party.id!);

      setState(() {
        _transactions = transactions;
        _totalGive = totalGive;
        _totalTake = totalTake;
        _balance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _showAddTransactionDialog({LedgerTransaction? transaction}) {
    final isEditing = transaction != null;
    final amountController = TextEditingController(
      text: isEditing ? transaction.amount.toString() : '',
    );
    final remarkController = TextEditingController(
      text: transaction?.remark ?? '',
    );
    DateTime selectedDate = transaction?.date ?? DateTime.now();
    String transactionType = transaction?.type ?? LedgerTransaction.typeTake;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEditing ? 'Edit Transaction' : 'Add Transaction',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Transaction Type',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      'You Gave',
                      LedgerTransaction.typeGive,
                      transactionType,
                      AppTheme.errorColor,
                      (type) => setModalState(() => transactionType = type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(
                      'You Took',
                      LedgerTransaction.typeTake,
                      transactionType,
                      AppTheme.secondaryColor,
                      (type) => setModalState(() => transactionType = type),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setModalState(() => selectedDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    Formatters.formatDate(selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarkController,
                decoration: const InputDecoration(
                  labelText: 'Remark (Optional)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a valid amount')),
                      );
                      return;
                    }

                    final trans = LedgerTransaction(
                      id: transaction?.id,
                      partyId: widget.party.id!,
                      type: transactionType,
                      amount: amount,
                      date: selectedDate,
                      remark: remarkController.text.trim().isEmpty
                          ? null
                          : remarkController.text.trim(),
                      createdAt: transaction?.createdAt,
                    );

                    if (isEditing) {
                      await _ledgerService.updateTransaction(trans);
                    } else {
                      await _ledgerService.addTransaction(trans);
                    }

                    if (mounted) {
                      Navigator.pop(ctx);
                      _loadData();
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Add Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    String label,
    String value,
    String selected,
    Color color,
    Function(String) onTap,
  ) {
    final isSelected = value == selected;
    return InkWell(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value == LedgerTransaction.typeGive
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTransaction(LedgerTransaction transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Delete this ${transaction.isGive ? "Gave" : "Took"} transaction of ${Formatters.formatCurrency(transaction.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _ledgerService.deleteTransaction(transaction.id!);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted')),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _editParty() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPartyScreen(party: widget.party),
      ),
    );
    if (result == true) _loadData();
  }

  void _exportPdf() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      await LedgerPdfService.generatePartyStatement(
        party: widget.party,
        transactions: _transactions,
        totalGive: _totalGive,
        totalTake: _totalTake,
        balance: _balance,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.party.name),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editParty,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBalanceCard(),
                _buildSummaryRow(),
                Expanded(child: _buildTransactionList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(),
        backgroundColor: AppTheme.secondaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Transaction',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isPositive = _balance >= 0;
    final balanceColor = widget.party.isDebtor
        ? (isPositive ? AppTheme.secondaryColor : AppTheme.errorColor)
        : (isPositive ? AppTheme.errorColor : AppTheme.secondaryColor);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Balance',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(_balance.abs()),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: balanceColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.party.isDebtor
                ? (isPositive ? 'They will pay you' : 'You have to pay')
                : (isPositive ? 'You have to give' : 'They will give you'),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
                'Total Given', _totalGive, AppTheme.errorColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryItem(
                'Total Taken', _totalTake, AppTheme.secondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style:
                  TextStyle(fontSize: 16, color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a transaction to track',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(LedgerTransaction transaction) {
    final isGive = transaction.isGive;
    final color = isGive ? AppTheme.errorColor : AppTheme.secondaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onLongPress: () => _showTransactionOptions(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isGive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGive ? 'You Gave' : 'You Took',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (transaction.remark != null &&
                        transaction.remark!.isNotEmpty)
                      Text(
                        transaction.remark!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      Formatters.formatDate(transaction.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.formatCurrency(transaction.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionOptions(LedgerTransaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Transaction'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddTransactionDialog(transaction: transaction);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Delete Transaction',
                  style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteTransaction(transaction);
              },
            ),
          ],
        ),
      ),
    );
  }
}
