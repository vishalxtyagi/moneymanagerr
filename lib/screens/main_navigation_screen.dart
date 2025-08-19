import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/providers/auth_provider.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';
import 'package:moneymanager/screens/add_transaction_screen.dart';
import 'package:moneymanager/screens/analytics_screen.dart';
import 'package:moneymanager/screens/calendar_view_screen.dart';
import 'package:moneymanager/screens/dashboard_screen.dart';
import 'package:moneymanager/screens/settings_screen.dart';
import 'package:moneymanager/widgets/common/logo.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isAddTransactionOpen = false;
  
  // Cache responsive state to avoid repeated calculations
  late bool _isMobile;
  late bool _isDesktop;
  
  // Pre-built screens with PageStorageKey for state preservation
  static final List<Widget> _screens = [
    const DashboardScreen(key: PageStorageKey('DashboardScreen')),
    const AnalyticsScreen(key: PageStorageKey('AnalyticsScreen')),
    const SizedBox.shrink(), // Placeholder for AddTransactionScreen
    const CalendarViewScreen(key: PageStorageKey('CalendarViewScreen')),
    const SettingsScreen(key: PageStorageKey('SettingsScreen')),
  ];

  // Simplified navigation items - removed unnecessary abstraction
  static const List<NavigationDestination> _mobileNavItems = [
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
  ];
  
  // Pre-calculated screen titles to avoid switch statement in build
  static const List<String> _screenTitles = [
    'Dashboard',
    'Analytics',
    'Add Transaction',
    'Calendar',
    'Settings',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache responsive state once to avoid repeated calculations
    final responsive = ResponsiveUtil.of(context);
    _isMobile = responsive.isMobile;
    _isDesktop = responsive.isDesktop;
  }

  void _onDestinationSelected(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _toggleAddTransaction() {
    setState(() {
      _isAddTransactionOpen = !_isAddTransactionOpen;
    });
  }

  void _closeAddTransaction() {
    if (_isAddTransactionOpen) {
      setState(() {
        _isAddTransactionOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content area
          Row(
            children: [
              // Desktop sidebar navigation
              if (!_isMobile)
                _DesktopSidebar(
                  currentIndex: _currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  onAddTransactionPressed: _toggleAddTransaction,
                  isAddTransactionOpen: _isAddTransactionOpen,
                ),
              
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // Desktop app bar
                    if (_isDesktop)
                      _DesktopAppBar(
                        currentScreenTitle: _currentIndex < _screenTitles.length 
                            ? _screenTitles[_currentIndex] 
                            : 'Money Manager',
                        onAddTransactionPressed: _toggleAddTransaction,
                        isAddTransactionOpen: _isAddTransactionOpen,
                      ),
                    
                    // Screen content
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
          
          // Desktop Add Transaction Sidebar - simple conditional display
          if (_isDesktop && _isAddTransactionOpen)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: AddTransactionScreen(
                onClose: _closeAddTransaction,
              ),
            ),
          
          // Mobile overlay for sidebar
          if (_isAddTransactionOpen && !_isDesktop)
            GestureDetector(
              onTap: _closeAddTransaction,
              child: Container(
                color: Colors.black54, // More efficient than withOpacity
              ),
            ),
        ],
      ),
      
      // Mobile bottom navigation
      bottomNavigationBar: _isMobile ? _MobileBottomNavigation(
        currentIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ) : null,
          
      // Mobile floating action button
      floatingActionButton: _isMobile ? const _MobileFAB() : null,
      floatingActionButtonLocation:
          _isMobile ? FloatingActionButtonLocation.centerDocked : null,
    );
  }
}

// Stateless widget for mobile bottom navigation - prevents rebuilds
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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: const Color(0xFFFAFAFA),
          indicatorColor: AppColors.primary.withOpacity(0.1),
          destinations: _MainNavigationScreenState._mobileNavItems,
        ),
      ),
    );
  }
}

// Stateless widget for mobile FAB - prevents rebuilds
class _MobileFAB extends StatelessWidget {
  const _MobileFAB();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AddTransactionScreen(),
        ),
      ),
      backgroundColor: AppColors.primary,
      child: const Icon(Iconsax.add_copy, color: Colors.white),
    );
  }
}

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

  // Pre-computed sidebar navigation items for better performance
  static const List<_SidebarNavItem> _sidebarItems = [
    _SidebarNavItem(
      icon: Iconsax.home_2_copy,
      selectedIcon: Iconsax.home_2,
      label: 'Home',
      index: 0,
    ),
    _SidebarNavItem(
      icon: Iconsax.chart_2_copy,
      selectedIcon: Iconsax.chart_21,
      label: 'Analytics',
      index: 1,
    ),
    _SidebarNavItem(
      icon: Iconsax.calendar_2_copy,
      selectedIcon: Iconsax.calendar_2,
      label: 'Calendar',
      index: 3,
    ),
    _SidebarNavItem(
      icon: Iconsax.setting_2_copy,
      selectedIcon: Iconsax.setting_2,
      label: 'Settings',
      index: 4,
    ),
  ];

  // Pre-computed colors for better performance
  static final Color _selectedBgColor = AppColors.primary.withOpacity(0.1);
  static final Color _unselectedIconColor = Colors.grey.shade600;
  static final Color _unselectedTextColor = Colors.grey.shade700;
  static final Color _borderColor = Colors.grey.shade200;
  static final Color _shadowColor = Colors.black.withOpacity(0.05);
  static final Color _buttonBackgroundColor = Colors.grey.shade600;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Brand area
          const _BrandHeader(),
          
          const Divider(height: 1),
          
          // Quick Add Transaction Button
          _AddTransactionButton(
            onPressed: onAddTransactionPressed,
            isOpen: isAddTransactionOpen,
          ),
          
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sidebarItems.length,
              itemBuilder: (context, index) => _SidebarNavigationItem(
                item: _sidebarItems[index],
                isSelected: _sidebarItems[index].index == currentIndex,
                onTap: () => onDestinationSelected(_sidebarItems[index].index),
              ),
            ),
          ),
          
          // Bottom area
          const _UserProfile(),
        ],
      ),
    );
  }
}

// Stateless widget for brand header
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const AppLogo(size: 24)
          ),
          const SizedBox(width: 12),
          const Text(
            'Money Manager',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Stateless widget for add transaction button
class _AddTransactionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isOpen;

  const _AddTransactionButton({
    required this.onPressed,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            isOpen ? Iconsax.close_square : Iconsax.add_square,
            size: 20,
          ),
          label: Text(
            isOpen ? 'Close' : 'Add Transaction',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isOpen 
                ? _DesktopSidebar._buttonBackgroundColor 
                : AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// Stateless widget for sidebar navigation item
class _SidebarNavigationItem extends StatelessWidget {
  final _SidebarNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavigationItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _DesktopSidebar._selectedBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected ? AppColors.primary : _DesktopSidebar._unselectedIconColor,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : _DesktopSidebar._unselectedTextColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Stateless widget for user profile
class _UserProfile extends StatelessWidget {
  const _UserProfile();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1),
        Selector<AuthProvider, (String?, String?)>(
          selector: (_, provider) => (provider.user?.displayName, provider.user?.photoURL),
          builder: (context, user, _) => Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  child: user.$2 != null ?
                  ClipOval(
                    child: Image.network(
                      user.$2!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ) :
                  Icon(
                    Iconsax.user,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logged in as:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                          user.$1 ?? 'User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Optimized sidebar navigation item data class
class _SidebarNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;

  const _SidebarNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.index,
  });
}

class _DesktopAppBar extends StatelessWidget {
  final String currentScreenTitle;
  final VoidCallback onAddTransactionPressed;
  final bool isAddTransactionOpen;

  const _DesktopAppBar({
    required this.currentScreenTitle,
    required this.onAddTransactionPressed,
    required this.isAddTransactionOpen,
  });

  // Pre-computed colors for better performance
  static final Color _borderColor = Colors.grey.shade200;
  static final Color _iconColor = Colors.grey.shade600;
  static final Color _subtitleColor = Colors.grey.shade600;
  static final Color _buttonForegroundColor = Colors.grey.shade700;
  static final Color _buttonBorderColor = Colors.grey.shade400;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Current screen title
          Expanded(
            child: _ScreenTitleSection(title: currentScreenTitle),
          ),
          
          // Quick actions
          _QuickActionsSection(
            onAddTransactionPressed: onAddTransactionPressed,
            isAddTransactionOpen: isAddTransactionOpen,
          ),
        ],
      ),
    );
  }
}

// Stateless widget for screen title section
class _ScreenTitleSection extends StatelessWidget {
  final String title;

  const _ScreenTitleSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Manage your finances efficiently',
          style: TextStyle(
            fontSize: 14,
            color: _DesktopAppBar._subtitleColor,
          ),
        ),
      ],
    );
  }
}

// Stateless widget for quick actions section
class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onAddTransactionPressed;
  final bool isAddTransactionOpen;

  const _QuickActionsSection({
    required this.onAddTransactionPressed,
    required this.isAddTransactionOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search button
        IconButton(
          onPressed: () {
            // Implement global search
          },
          icon: Icon(Iconsax.search_normal, color: _DesktopAppBar._iconColor),
          tooltip: 'Search transactions',
        ),
        
        const SizedBox(width: 8),
        
        // Notifications
        IconButton(
          onPressed: () {
            // Implement notifications
          },
          icon: Icon(Iconsax.notification, color: _DesktopAppBar._iconColor),
          tooltip: 'Notifications',
        ),
        
        const SizedBox(width: 16),
        
        // Add transaction button (alternative)
        OutlinedButton.icon(
          onPressed: onAddTransactionPressed,
          icon: Icon(
            isAddTransactionOpen ? Iconsax.close_square : Iconsax.add_square,
            size: 18,
          ),
          label: Text(
            isAddTransactionOpen ? 'Close' : 'Quick Add',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: isAddTransactionOpen 
                ? _DesktopAppBar._buttonForegroundColor 
                : AppColors.primary,
            side: BorderSide(
              color: isAddTransactionOpen 
                  ? _DesktopAppBar._buttonBorderColor 
                  : AppColors.primary,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}