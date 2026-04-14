import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/customers/customers_wrapper_screen.dart';
import 'screens/finance/finance_wrapper_screen.dart';

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
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final GlobalKey<CustomersWrapperScreenState> _customersKey = GlobalKey();
  final GlobalKey<FinanceWrapperScreenState> _financeKey = GlobalKey();

  late final List<Widget> _screens;

  MainNavigationState() {
    _screens = [
      const DashboardScreen(),
      CustomersWrapperScreen(key: _customersKey),
      FinanceWrapperScreen(key: _financeKey),
    ];
  }

  static MainNavigationState? of(BuildContext context) {
    final state = context.findAncestorStateOfType<MainNavigationState>();
    return state;
  }

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void switchToCustomersTab() {
    setState(() {
      _currentIndex = 1;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _customersKey.currentState?.switchToSubTab(0);
    });
  }

  void switchToBookingsTab() {
    setState(() {
      _currentIndex = 1;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _customersKey.currentState?.switchToSubTab(1);
    });
  }

  void switchToPaymentsTab() {
    setState(() {
      _currentIndex = 2;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _financeKey.currentState?.switchToSubTab(0);
    });
  }

  void switchToQuotationsTab() {
    setState(() {
      _currentIndex = 2;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _financeKey.currentState?.switchToSubTab(1);
    });
  }

  void switchToLedgerTab() {
    setState(() {
      _currentIndex = 2;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _financeKey.currentState?.switchToSubTab(2);
    });
  }

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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon:
                    Icon(Icons.dashboard, color: AppTheme.primaryColor),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people, color: AppTheme.primaryColor),
                label: 'Customers',
              ),
              NavigationDestination(
                icon: Icon(Icons.currency_rupee_outlined),
                selectedIcon:
                    Icon(Icons.currency_rupee, color: AppTheme.primaryColor),
                label: 'Finance',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
