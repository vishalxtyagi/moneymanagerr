import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/providers/auth_provider.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';
import 'package:moneymanager/screens/add_transaction_screen.dart';
import 'package:moneymanager/screens/analytics_screen_optimized.dart';
import 'package:moneymanager/screens/calendar_view_screen.dart';
import 'package:moneymanager/screens/dashboard_screen.dart';
import 'package:moneymanager/screens/settings_screen.dart';
import 'package:moneymanager/widgets/common/logo.dart';

/// Optimized main navigation with IndexedStack for desktop and proper state management
class MainNavigationScreenOptimized extends StatefulWidget {
  const MainNavigationScreenOptimized({super.key});

  @override
  State<MainNavigationScreenOptimized> createState() => _MainNavigationScreenOptimizedState();
}

class _MainNavigationScreenOptimizedState extends State<MainNavigationScreenOptimized> {
  int _currentIndex = 0;
  bool _isAddTransactionOpen = false;
  
  // Pre-built screens with PageStorageKey for state preservation
  static final List<Widget> _screens = [
    const DashboardScreen(key: PageStorageKey('DashboardScreen')),
    const AnalyticsScreenOptimized(key: PageStorageKey('AnalyticsScreen')),
    const SizedBox.shrink(), // Placeholder for AddTransactionScreen
    const CalendarViewScreen(key: PageStorageKey('CalendarViewScreen')),
    const SettingsScreen(key: PageStorageKey('SettingsScreen')),
  ];

  // Pre-calculated screen titles
  static const List<String> _screenTitles = [
    'Dashboard',
    'Analytics',
    'Add Transaction',
    'Calendar',
    'Settings',
  ];

  void _onDestinationSelected(int index) {
    if (index != _currentIndex && index != 2) { // Skip add transaction index
      setState(() => _currentIndex = index);
    }
  }

  void _toggleAddTransaction() {
    setState(() => _isAddTransactionOpen = !_isAddTransactionOpen);
  }

  void _closeAddTransaction() {
    if (_isAddTransactionOpen) {
      setState(() => _isAddTransactionOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil.of(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content area
          Row(
            children: [
              // Desktop sidebar navigation
              if (responsive.isDesktop)
                _DesktopSidebar(
                  currentIndex: _currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  onAddTransactionPressed: _toggleAddTransaction,
                  isAddTransactionOpen: _isAddTransactionOpen,
                ),
              
              // Main content with IndexedStack for desktop
              Expanded(
                child: Column(
                  children: [
                    // Desktop app bar
                    if (responsive.isDesktop)
                      _DesktopAppBar(
                        currentScreenTitle: _screenTitles[_currentIndex],
                        onAddTransactionPressed: _toggleAddTransaction,
                        isAddTransactionOpen: _isAddTransactionOpen,
                      ),
                    
                    // Screen content - IndexedStack preserves state
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
              ),
            ],
          ),
          
          // Desktop Add Transaction Sidebar
          if (responsive.isDesktop && _isAddTransactionOpen)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: AddTransactionScreen(
                onClose: _closeAddTransaction,
              ),
            ),
          
          // Mobile overlay
          if (_isAddTransactionOpen && !responsive.isDesktop)
            GestureDetector(
              onTap: _closeAddTransaction,
              child: Container(
                color: Colors.black54,
              ),
            ),
        ],
      ),
      
      // Mobile bottom navigation
      bottomNavigationBar: responsive.isMobile ? _MobileBottomNavigation(
        currentIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ) : null,
          
      // Mobile floating action button
      floatingActionButton: responsive.isMobile ? _MobileFAB(
        onPressed: _toggleAddTransaction,
      ) : null,
      floatingActionButtonLocation:
          responsive.isMobile ? FloatingActionButtonLocation.centerDocked : null,
    );
  }
}

/// Optimized desktop sidebar with minimal rebuilds
class _DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final VoidCallback onAddTransactionPressed;
  final bool isAddTransactionOpen;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onAddTransactionPressed,
    required this.isAddTransactionOpen,
  });

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Iconsax.home_2, label: 'Dashboard'),
    _NavItem(icon: Iconsax.chart_21, label: 'Analytics'),
    _NavItem(icon: Iconsax.calendar_2, label: 'Calendar'),
    _NavItem(icon: Iconsax.setting_2, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil.of(context);
    
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Column(
        children: [
          // Logo section
          Container(
            height: 80,
            padding: EdgeInsets.all(responsive.spacing()),
            child: const Row(
              children: [
                AppLogo(size: 32),
                SizedBox(width: 12),
                Text(
                  'Money Manager',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Add Transaction Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.spacing()),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddTransactionPressed,
                icon: Icon(isAddTransactionOpen ? Iconsax.close_circle : Iconsax.add),
                label: Text(isAddTransactionOpen ? 'Close' : 'Add Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAddTransactionOpen ? Colors.grey : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(height: responsive.spacing()),
          
          // Navigation items
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = currentIndex == index;
                
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(),
                    vertical: 4,
                  ),
                  child: Material(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onDestinationSelected(index),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // User info at bottom
          Selector<AuthProvider, (String?, String?)>(
            selector: (_, provider) => (provider.user?.displayName, provider.user?.email),
            builder: (context, userInfo, _) => Container(
              padding: EdgeInsets.all(responsive.spacing()),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: Icon(Iconsax.user, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userInfo.$1 ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userInfo.$2 ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple navigation item model
class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

/// Desktop app bar with screen title
class _DesktopAppBar extends StatelessWidget {
  final String currentScreenTitle;
  final VoidCallback onAddTransactionPressed;
  final bool isAddTransactionOpen;

  const _DesktopAppBar({
    required this.currentScreenTitle,
    required this.onAddTransactionPressed,
    required this.isAddTransactionOpen,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil.of(context);
    
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(scale: 1.5)),
      child: Row(
        children: [
          Text(
            currentScreenTitle,
            style: TextStyle(
              fontSize: responsive.fontSize(24),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (!isAddTransactionOpen)
            ElevatedButton.icon(
              onPressed: onAddTransactionPressed,
              icon: const Icon(Iconsax.add),
              label: const Text('Add Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mobile bottom navigation
class _MobileBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const _MobileBottomNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Iconsax.home_2_copy),
            selectedIcon: Icon(Iconsax.home_2),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.chart_2_copy),
            selectedIcon: Icon(Iconsax.chart_21),
            label: 'Analytics',
          ),
          NavigationDestination(
            enabled: false,
            icon: SizedBox.shrink(),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.calendar_2_copy),
            selectedIcon: Icon(Iconsax.calendar_2),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.setting_2_copy),
            selectedIcon: Icon(Iconsax.setting_2),
            label: 'Settings',
          ),
        ],
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        height: 70,
      ),
    );
  }
}

/// Mobile floating action button
class _MobileFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const _MobileFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      child: const Icon(Iconsax.add),
    );
  }
}
