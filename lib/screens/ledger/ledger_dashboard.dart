import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../config/theme.dart';
import '../../models/ledger_party_model.dart';
import '../../models/ledger_transaction_model.dart';
import '../../services/ledger_service.dart';
import '../../utils/formatters.dart';
import 'add_party_screen.dart';
import 'party_detail_screen.dart';

class LedgerDashboard extends StatefulWidget {
  const LedgerDashboard({super.key});

  @override
  State<LedgerDashboard> createState() => _LedgerDashboardState();
}

class _LedgerDashboardState extends State<LedgerDashboard> {
  final LedgerService _ledgerService = LedgerService();
  LedgerSummary? _summary;
  List<LedgerPartyWithBalance> _parties = [];
  bool _isLoading = true;
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _ledgerService.getSummary();
      final parties = await _loadParties();
      setState(() {
        _summary = summary;
        _parties = parties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ledger: $e')),
        );
      }
    }
  }

  Future<List<LedgerPartyWithBalance>> _loadParties() async {
    if (_searchQuery.isNotEmpty) {
      return await _ledgerService.searchPartiesWithBalance(_searchQuery);
    }
    if (_filterType == 'debtor') {
      return await _ledgerService
          .getPartiesWithBalanceByType(LedgerParty.typeDebtor);
    }
    if (_filterType == 'creditor') {
      return await _ledgerService
          .getPartiesWithBalanceByType(LedgerParty.typeCreditor);
    }
    return await _ledgerService.getAllPartiesWithBalance();
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _loadData();
  }

  void _onFilterChange(String filter) {
    setState(() => _filterType = filter);
    _loadData();
  }

  void _navigateToAddParty() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPartyScreen()),
    );
    if (result == true) _loadData();
  }

  void _navigateToPartyDetail(LedgerParty party) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PartyDetailScreen(party: party)),
    );
    if (result == true) _loadData();
  }

  void _deleteParty(LedgerParty party) async {
    final hasTransactions =
        await _ledgerService.partyHasTransactions(party.id!);

    if (!mounted) return;

    if (hasTransactions) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: const Text(
              'This party has transactions. Delete all transactions first?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _ledgerService.deleteParty(party.id!);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Party deleted')),
                  );
                }
              },
              child: const Text('Delete All',
                  style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Party'),
          content: Text('Are you sure you want to delete "${party.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _ledgerService.deleteParty(party.id!);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Party deleted')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ledger'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCards(),
                _buildSearchBar(),
                _buildFilterChips(),
                Expanded(child: _buildPartyList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddParty,
        icon: const Icon(Icons.add),
        label: const Text('Add Party'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_summary == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'You Will Get',
              _summary!.totalYouWillGet,
              AppTheme.secondaryColor,
              Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'You Will Give',
              _summary!.totalYouWillGive,
              AppTheme.errorColor,
              Icons.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search parties...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _onSearch(''),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _onSearch,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Debtors', 'debtor'),
          const SizedBox(width: 8),
          _buildFilterChip('Creditors', 'creditor'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChange(value),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildPartyList() {
    if (_parties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No parties found' : 'No parties yet',
              style:
                  TextStyle(fontSize: 16, color: AppTheme.textSecondaryColor),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Add a party to start tracking',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _parties.length,
      itemBuilder: (context, index) {
        final item = _parties[index];
        return _buildPartyCard(item);
      },
    );
  }

  Widget _buildPartyCard(LedgerPartyWithBalance item) {
    final party = item.party;
    final balance = item.currentBalance;
    final isPositive = balance >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _deleteParty(party),
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(12)),
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () => _navigateToPartyDetail(party),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: party.isDebtor
                        ? AppTheme.secondaryColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                    child: Text(
                      party.name[0].toUpperCase(),
                      style: TextStyle(
                        color: party.isDebtor
                            ? AppTheme.secondaryColor
                            : AppTheme.errorColor,
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
                          party.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (party.phone != null && party.phone!.isNotEmpty)
                          Text(
                            party.phone!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCurrency(balance.abs()),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? AppTheme.secondaryColor
                              : AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        party.isDebtor
                            ? (isPositive ? 'Will get' : 'To pay')
                            : (isPositive ? 'To give' : 'Will get'),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
