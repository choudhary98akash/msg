import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../payment/payment_list_screen.dart';
import '../quotation/quotation_list_screen.dart';
import '../ledger/ledger_dashboard.dart';
import '../payment/add_payment_screen.dart';
import '../quotation/quotation_form_screen.dart';
import '../ledger/add_party_screen.dart';

class FinanceWrapperScreen extends StatefulWidget {
  final bool inStandaloneMode;

  const FinanceWrapperScreen({
    super.key,
    this.inStandaloneMode = true,
  });

  @override
  FinanceWrapperScreenState createState() => FinanceWrapperScreenState();
}

class FinanceWrapperScreenState extends State<FinanceWrapperScreen> {
  int _selectedSegment = 0;

  List<Widget> get _screens => [
        const PaymentListScreen(inStandaloneMode: false),
        const QuotationListScreen(inStandaloneMode: false),
        const LedgerDashboard(inStandaloneMode: false),
      ];

  void switchToSubTab(int index) {
    if (index >= 0 && index < 3 && _selectedSegment != index) {
      setState(() {
        _selectedSegment = index;
      });
    }
  }

  void _navigateToAdd() {
    switch (_selectedSegment) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuotationFormScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPartyScreen()),
        );
        break;
    }
  }

  String get _buttonLabel {
    switch (_selectedSegment) {
      case 0:
        return 'Add Payment';
      case 1:
        return 'Create Quote';
      case 2:
        return 'Add Party';
      default:
        return 'Add';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Finance'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Payments')),
                    ButtonSegment(value: 1, label: Text('Quotes')),
                    ButtonSegment(value: 2, label: Text('Ledger')),
                  ],
                  selected: {_selectedSegment},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedSegment = selection.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primaryColor;
                      }
                      return Colors.grey.shade200;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.grey.shade700;
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedSegment,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).padding.bottom + 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _navigateToAdd,
            icon: const Icon(Icons.add),
            label: Text(_buttonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
