import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/utils/context_util.dart';
import 'package:moneymanager/screens/analytics_screen.dart';
import 'package:moneymanager/screens/calendar_view_screen.dart';
import 'package:moneymanager/screens/dashboard_screen.dart';
import 'package:moneymanager/screens/settings_screen.dart';
import 'package:moneymanager/widgets/common/logo.dart';
import 'package:moneymanager/widgets/transaction_drawer.dart';
import 'package:moneymanager/constants/router.dart';

final class _NavigationConfig {
  static const items = [
    _NavigationItem(
      icon: Iconsax.home_2_copy,
      selectedIcon: Iconsax.home_2,
      label: 'Dashboard',
      subtitle: 'Overview of your transactions',
    ),
    _NavigationItem(
      icon: Iconsax.chart_2_copy,
      selectedIcon: Iconsax.chart_21,
      label: 'Analytics',
    ),
    _NavigationItem(
      icon: Iconsax.calendar_2_copy,
      selectedIcon: Iconsax.calendar_2,
      label: 'Calendar',
    ),
    _NavigationItem(
      icon: Iconsax.setting_2_copy,
      selectedIcon: Iconsax.setting_2,
      label: 'Settings',
    ),
  ];

  static const screens = [
    DashboardScreen(key: PageStorageKey('dashboard')),
    AnalyticsScreen(key: PageStorageKey('analytics')),
    CalendarViewScreen(key: PageStorageKey('calendar')),
    SettingsScreen(key: PageStorageKey('settings')),
  ];
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavigationItemSelected(int index) {
    // Close the drawer if it's open
    if (_scaffoldKey.currentState?.isEndDrawerOpen == true) {
      _scaffoldKey.currentState?.closeEndDrawer();
    }

    if (index != _currentIndex) {
      // Navigate to the appropriate route
      switch (index) {
        case 0:
          GoRouter.of(context).go(AppRouter.dashboard);
          break;
        case 1:
          GoRouter.of(context).go(AppRouter.analytics);
          break;
        case 2:
          GoRouter.of(context).go(AppRouter.calendar);
          break;
        case 3:
          GoRouter.of(context).go(AppRouter.settings);
          break;
      }
    }
  }

  void _openTransactionDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _closeTransactionDrawer() {
    _scaffoldKey.currentState?.closeEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Scaffold(
      key: _scaffoldKey,
      body: isDesktop
          ? _DesktopLayout(
              currentIndex: _currentIndex,
              onNavigationItemSelected: _onNavigationItemSelected,
              onToggleAddTransaction: _openTransactionDrawer,
            )
          : _MobileLayout(
              currentIndex: _currentIndex,
              onNavigationItemSelected: _onNavigationItemSelected,
            ),
      endDrawer: TransactionDrawer(
        onClose: _closeTransactionDrawer,
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: _openTransactionDrawer,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onNavigationItemSelected,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              items: _NavigationConfig.items
                  .map((item) => BottomNavigationBarItem(
                        icon: Icon(item.icon),
                        activeIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ))
                  .toList(),
            )
          : null,
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String title;
  final String subtitle;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    String? title,
    String? subtitle,
  })  : title = title ?? label,
        subtitle = subtitle ?? 'Manage your finances efficiently';
}

class _DesktopLayout extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigationItemSelected;
  final VoidCallback onToggleAddTransaction;

  const _DesktopLayout({
    required this.currentIndex,
    required this.onNavigationItemSelected,
    required this.onToggleAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Side Navigation
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: const Row(
                  children: [
                    AppLogo(size: 32, type: LogoType.light),
                    SizedBox(width: 12),
                    Text(
                      'Money Manager',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _NavigationConfig.items.length,
                  itemBuilder: (context, index) {
                    final item = _NavigationConfig.items[index];
                    final isSelected = index == currentIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          color:
                              isSelected ? AppColors.primary : Colors.white70,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color:
                                isSelected ? AppColors.primary : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => onNavigationItemSelected(index),
                      ),
                    );
                  },
                ),
              ),

              // Add Transaction Button
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onToggleAddTransaction,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Transaction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Content
        Expanded(
          child: RepaintBoundary(
            child: IndexedStack(
              index: currentIndex,
              children: _NavigationConfig.screens,
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigationItemSelected;

  const _MobileLayout({
    required this.currentIndex,
    required this.onNavigationItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IndexedStack(
        index: currentIndex,
        children: _NavigationConfig.screens,
      ),
    );
  }
}
