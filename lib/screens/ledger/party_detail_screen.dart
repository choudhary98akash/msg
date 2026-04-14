import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/ledger_party_model.dart';
import '../../models/ledger_transaction_model.dart';
import '../../services/ledger_image_service.dart';
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
  final LedgerImageService _imageService = LedgerImageService();
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
    List<String> proofImages =
        List<String>.from(transaction?.proofImages ?? []);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !isSaving,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final canAddMore =
              proofImages.length < LedgerTransaction.maxProofImages;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
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
                    if (isSaving)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
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
                  enabled: !isSaving,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: isSaving
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
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
                  enabled: !isSaving,
                ),
                const SizedBox(height: 20),
                _buildProofSection(
                  proofImages: proofImages,
                  canAddMore: canAddMore,
                  isSaving: isSaving,
                  onAddFromCamera: () async {
                    if (!canAddMore) return;
                    try {
                      final path = await _imageService.pickFromCamera();
                      if (path != null) {
                        setModalState(() {
                          proofImages.add(path);
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to capture image: $e')),
                        );
                      }
                    }
                  },
                  onAddFromGallery: () async {
                    if (!canAddMore) return;
                    try {
                      final path = await _imageService.pickFromGallery();
                      if (path != null) {
                        setModalState(() {
                          proofImages.add(path);
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to select image: $e')),
                        );
                      }
                    }
                  },
                  onRemoveImage: (index) async {
                    final imagePath = proofImages[index];
                    setModalState(() {
                      proofImages.removeAt(index);
                    });
                    if (isEditing) {
                      await _imageService.deleteImage(imagePath);
                    }
                  },
                  onViewImage: (index) {
                    _showFullImageView(proofImages, index);
                  },
                  onMaxReached: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Maximum 4 proof images allowed'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final amount =
                                double.tryParse(amountController.text);
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please enter a valid amount')),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);

                            try {
                              final trans = LedgerTransaction(
                                id: transaction?.id,
                                partyId: widget.party.id!,
                                type: transactionType,
                                amount: amount,
                                date: selectedDate,
                                remark: remarkController.text.trim().isEmpty
                                    ? null
                                    : remarkController.text.trim(),
                                proofImages:
                                    proofImages.isEmpty ? null : proofImages,
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
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                              setModalState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEditing ? 'Update' : 'Add Transaction'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProofSection({
    required List<String> proofImages,
    required bool canAddMore,
    required bool isSaving,
    required VoidCallback onAddFromCamera,
    required VoidCallback onAddFromGallery,
    required Function(int) onRemoveImage,
    required Function(int) onViewImage,
    required VoidCallback onMaxReached,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Proof Images',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${proofImages.length}/4',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...proofImages.asMap().entries.map((entry) {
                return _buildImageThumbnail(
                  imagePath: entry.value,
                  index: entry.key,
                  onRemove: () => onRemoveImage(entry.key),
                  onTap: () => onViewImage(entry.key),
                );
              }),
              if (canAddMore) ...[
                _buildAddImageButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: isSaving ? null : onAddFromCamera,
                ),
                const SizedBox(width: 8),
                _buildAddImageButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: isSaving ? null : onAddFromGallery,
                ),
              ],
              if (!canAddMore && proofImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Center(
                    child: Text(
                      'Maximum reached',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail({
    required String imagePath,
    required int index,
    required VoidCallback onRemove,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                File(imagePath),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
          color: AppTheme.primaryColor.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImageView(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullImageViewScreen(
          images: images,
          initialIndex: initialIndex,
          onDelete: (index) async {
            final imagePath = images[index];
            await _imageService.deleteImage(imagePath);
            if (mounted) {
              Navigator.pop(context);
              _loadData();
            }
          },
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
              try {
                await _ledgerService.deleteTransaction(transaction.id!);

                if (transaction.proofImages != null &&
                    transaction.proofImages!.isNotEmpty) {
                  for (final imagePath in transaction.proofImages!) {
                    try {
                      await _imageService.deleteImage(imagePath);
                    } catch (e) {
                      await _imageService.markOrphan(imagePath);
                    }
                  }
                }

                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e')),
                  );
                }
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
    final hasImages =
        transaction.proofImages != null && transaction.proofImages!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onLongPress: () => _showTransactionOptions(transaction),
        onTap: hasImages
            ? () => _showFullImageView(transaction.proofImages!, 0)
            : null,
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
                    Row(
                      children: [
                        Text(
                          isGive ? 'You Gave' : 'You Took',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        if (hasImages) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 12,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${transaction.proofImages!.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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
            if (transaction.proofImages != null &&
                transaction.proofImages!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('View Proof Images'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFullImageView(transaction.proofImages!, 0);
                },
              ),
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

class _FullImageViewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final Function(int) onDelete;

  const _FullImageViewScreen({
    required this.images,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_FullImageViewScreen> createState() => _FullImageViewScreenState();
}

class _FullImageViewScreenState extends State<_FullImageViewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Image'),
                  content: const Text('Delete this proof image?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onDelete(_currentIndex);
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: AppTheme.errorColor)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(widget.images[index]),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
