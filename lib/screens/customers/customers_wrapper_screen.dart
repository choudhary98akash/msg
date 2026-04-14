import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../customer/customer_list_screen.dart';
import '../booking/booking_list_screen.dart';
import '../customer/add_customer_screen.dart';
import '../booking/booking_form_screen.dart';

class CustomersWrapperScreen extends StatefulWidget {
  final bool inStandaloneMode;

  const CustomersWrapperScreen({
    super.key,
    this.inStandaloneMode = true,
  });

  @override
  CustomersWrapperScreenState createState() => CustomersWrapperScreenState();
}

class CustomersWrapperScreenState extends State<CustomersWrapperScreen> {
  int _selectedSegment = 0;

  List<Widget> get _screens => [
        const CustomerListScreen(inStandaloneMode: false),
        const BookingListScreen(inStandaloneMode: false),
      ];

  void switchToSubTab(int index) {
    if (index >= 0 && index < 2 && _selectedSegment != index) {
      setState(() {
        _selectedSegment = index;
      });
    }
  }

  void _navigateToAdd() {
    if (_selectedSegment == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BookingFormScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Customers'),
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
                    ButtonSegment(value: 0, label: Text('Customers')),
                    ButtonSegment(value: 1, label: Text('Bookings')),
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
            label: Text(_selectedSegment == 0 ? 'Add Customer' : 'Add Booking'),
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
