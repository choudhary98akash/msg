import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/customer/customer_list_screen.dart';
import 'screens/booking/booking_form_screen.dart';
import 'screens/payment/payment_list_screen.dart';
import 'screens/quotation/quotation_list_screen.dart';

class MsGroupPropertiesApp extends StatelessWidget {
  const MsGroupPropertiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M.S. Group Properties',
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CustomerListScreen(),
    const BookingFormScreen(),
    const PaymentListScreen(),
    const QuotationListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index != 2) {
            setState(() => _currentIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_home_outlined),
            selectedIcon: Icon(Icons.add_home),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: 'Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Quotations',
          ),
        ],
      ),
    );
  }
}
