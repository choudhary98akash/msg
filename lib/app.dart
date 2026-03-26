import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/customer/customer_list_screen.dart';
import 'screens/booking/booking_list_screen.dart';
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
    const BookingListScreen(),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon:
                    Icon(Icons.dashboard, color: AppTheme.primaryColor),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people, color: AppTheme.primaryColor),
                label: 'Customers',
              ),
              NavigationDestination(
                icon: const Icon(Icons.add_home_outlined),
                selectedIcon:
                    Icon(Icons.add_home, color: AppTheme.primaryColor),
                label: 'Booking',
              ),
              NavigationDestination(
                icon: const Icon(Icons.payment_outlined),
                selectedIcon: Icon(Icons.payment, color: AppTheme.primaryColor),
                label: 'Payments',
              ),
              NavigationDestination(
                icon: const Icon(Icons.description_outlined),
                selectedIcon:
                    Icon(Icons.description, color: AppTheme.primaryColor),
                label: 'Quotations',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
