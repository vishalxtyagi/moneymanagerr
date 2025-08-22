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
      title: 'Dashboard',
      subtitle: 'Overview of your transactions',
    ),
    _NavigationItem(
      icon: Iconsax.chart_2_copy,
      selectedIcon: Iconsax.chart_21,
      label: 'Analytics',
      title: 'Analytics',
      subtitle: 'Insights and financial trends',
    ),
    _NavigationItem(
      icon: Iconsax.calendar_2_copy,
      selectedIcon: Iconsax.calendar_2,
      label: 'Calendar',
      title: 'Calendar',
      subtitle: 'View transactions by date',
    ),
    _NavigationItem(
      icon: Iconsax.setting_2_copy,
      selectedIcon: Iconsax.setting_2,
      label: 'Settings',
      title: 'Settings',
      subtitle: 'Configure your preferences',
    ),
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
            color: Colors.white,
            border: Border(
              right: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Logo Section
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    AppLogo(size: 80, type: LogoType.dark),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Money Manager',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Personal Finance Tracker',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Navigation Items
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _NavigationConfig.items.length,
                    itemBuilder: (context, index) {
                      final item = _NavigationConfig.items[index];
                      final isSelected = index == currentIndex;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          hoverColor: AppColors.primaryVariant.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () => onNavigationItemSelected(index),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Add Transaction Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onToggleAddTransaction,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Transaction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
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
              children: _NavigationConfig.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                // Create screens with title and subtitle parameters
                switch (index) {
                  case 0:
                    return DashboardScreen(
                      key: const PageStorageKey('dashboard'),
                      title: item.title,
                      subtitle: item.subtitle,
                    );
                  case 1:
                    return AnalyticsScreen(
                      key: const PageStorageKey('analytics'),
                      title: item.title,
                      subtitle: item.subtitle,
                    );
                  case 2:
                    return CalendarViewScreen(
                      key: const PageStorageKey('calendar'),
                      title: item.title,
                      subtitle: item.subtitle,
                    );
                  case 3:
                    return SettingsScreen(
                      key: const PageStorageKey('settings'),
                      title: item.title,
                      subtitle: item.subtitle,
                    );
                  default:
                    return const SizedBox();
                }
              }).toList(),
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
        children: _NavigationConfig.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          // Create screens with title parameters
          switch (index) {
            case 0:
              return DashboardScreen(
                key: const PageStorageKey('dashboard'),
                title: item.title,
              );
            case 1:
              return AnalyticsScreen(
                key: const PageStorageKey('analytics'),
                title: item.title,
              );
            case 2:
              return CalendarViewScreen(
                key: const PageStorageKey('calendar'),
                title: item.title,
              );
            case 3:
              return SettingsScreen(
                key: const PageStorageKey('settings'),
                title: item.title,
              );
            default:
              return const SizedBox();
          }
        }).toList(),
      ),
    );
  }
}
