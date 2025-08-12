import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';
import 'package:moneymanager/screens/add_transaction_screen.dart';
import 'package:moneymanager/screens/analytics_screen.dart';
import 'package:moneymanager/screens/calendar_view_screen.dart';
import 'package:moneymanager/screens/dashboard_screen.dart';
import 'package:moneymanager/screens/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  static const List<_NavItem> _navItems = [
    _NavItem(
        icon: Iconsax.home_2_copy, selectedIcon: Iconsax.home_2, label: 'Home'),
    _NavItem(
        icon: Iconsax.chart_2_copy,
        selectedIcon: Iconsax.chart_21,
        label: 'Analytics'),
    _NavItem(
        icon: Iconsax.add_copy,
        selectedIcon: Iconsax.add_copy,
        label: 'Add',
        hidden: true),
    _NavItem(
        icon: Iconsax.calendar_2_copy,
        selectedIcon: Iconsax.calendar_2,
        label: 'Calendar'),
    _NavItem(
        icon: Iconsax.setting_2_copy,
        selectedIcon: Iconsax.setting_2,
        label: 'Settings'),
  ];

  void _onDestinationSelected(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void initState() {
    super.initState();
    _screens = const [
      DashboardScreen(key: PageStorageKey('DashboardScreen')),
      AnalyticsScreen(key: PageStorageKey('AnalyticsScreen')),
      AddTransactionScreen(key: PageStorageKey('AddTransactionScreen')),
      CalendarViewScreen(key: PageStorageKey('CalendarViewScreen')),
      SettingsScreen(key: PageStorageKey('SettingsScreen')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil.of(context);
    final isMobile = responsive.isMobile;
    
    return Scaffold(
      body: Row(
        children: [
          if (!isMobile)
            _RailNavigation(
              currentIndex: _currentIndex,
              destinations: _navItems,
              onDestinationSelected: _onDestinationSelected,
            ),
          Expanded(
            child: RepaintBoundary(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? _BottomNavigation(
            currentIndex: _currentIndex,
            destinations: _navItems,
            onDestinationSelected: _onDestinationSelected,
          )
          : null,
      floatingActionButton: isMobile ? FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AddTransactionScreen(),
          ),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Iconsax.add_copy),
      ) : null,
      floatingActionButtonLocation:
          isMobile ? FloatingActionButtonLocation.centerDocked : null,
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> destinations;
  final Function(int) onDestinationSelected;

  const _BottomNavigation({
    required this.currentIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: const Color(0xFFFAFAFA),
          indicatorColor: Colors.transparent,
          destinations: destinations.map((item) {
            // Hide the item if hidden is true
            if (item.hidden) {
              return const NavigationDestination(
                enabled: false,
                icon: SizedBox.shrink(),
                label: '',
              );
            }
            return NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RailNavigation extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> destinations;
  final Function(int) onDestinationSelected;

  const _RailNavigation({
    required this.currentIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.white,
      destinations: destinations.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon),
          label: Text(item.label),
        );
      }).toList(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool hidden;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.hidden = false,
  });
}
