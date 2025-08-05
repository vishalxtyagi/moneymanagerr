import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:moneymanager/constants/app_colors.dart';
import 'package:moneymanager/screens/add_transaction_screen.dart';
import 'package:moneymanager/screens/analytics_screen.dart';
import 'package:moneymanager/screens/calendar_view_screen.dart';
import 'package:moneymanager/screens/dashboard_screen.dart';
import 'package:moneymanager/screens/settings_screen.dart';
import 'package:moneymanager/utils/responsive_helper.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    SizedBox.shrink(),
    CalendarViewScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    if (isDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation Rail
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              if (index == 2) {
                _navigateToAddTransaction();
              } else {
                setState(() => _currentIndex = index);
              }
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            elevation: 1,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Iconsax.home_2_copy),
                selectedIcon: Icon(Iconsax.home_2, color: AppColors.primary),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Iconsax.chart_2_copy),
                selectedIcon: Icon(Iconsax.chart_21, color: AppColors.primary),
                label: Text('Analytics'),
              ),
              NavigationRailDestination(
                icon: Icon(Iconsax.add_copy),
                selectedIcon: Icon(Iconsax.add, color: AppColors.primary),
                label: Text('Add'),
              ),
              NavigationRailDestination(
                icon: Icon(Iconsax.calendar_2_copy),
                selectedIcon: Icon(Iconsax.calendar_2, color: AppColors.primary),
                label: Text('Calendar'),
              ),
              NavigationRailDestination(
                icon: Icon(Iconsax.setting_2_copy),
                selectedIcon: Icon(Iconsax.setting_2, color: AppColors.primary),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          
          // Main Content
          Expanded(
            child: _screens[_currentIndex == 2 ? 0 : _currentIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        backgroundColor: AppColors.primary,
        elevation: 8,
        child: const Icon(Iconsax.add_copy, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: Material(
        elevation: 8,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: const Color(0xFFFAFAFA),
            indicatorColor: Colors.transparent,
            height: 70,
            destinations: const [
              NavigationDestination(
                icon: Icon(Iconsax.home_2_copy),
                selectedIcon: Icon(Iconsax.home_2, color: AppColors.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Iconsax.chart_2_copy),
                selectedIcon: Icon(Iconsax.chart_21, color: AppColors.primary),
                label: 'Analytics',
              ),
              NavigationDestination(
                enabled: false,
                icon: SizedBox.shrink(),
                label: '',
              ),
              NavigationDestination(
                icon: Icon(Iconsax.calendar_2_copy),
                selectedIcon: Icon(Iconsax.calendar_2, color: AppColors.primary),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Iconsax.setting_2_copy),
                selectedIcon: Icon(Iconsax.setting_2, color: AppColors.primary),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );
  }
}