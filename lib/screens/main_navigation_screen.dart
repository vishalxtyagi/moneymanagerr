import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/providers/auth_provider.dart';
import 'package:moneymanager/utils/context_util.dart';
import 'package:moneymanager/screens/add_transaction_screen.dart';
import 'package:moneymanager/screens/analytics_screen.dart';
import 'package:moneymanager/screens/calendar_view_screen.dart';
import 'package:moneymanager/screens/dashboard_screen.dart';
import 'package:moneymanager/screens/settings_screen.dart';
import 'package:moneymanager/widgets/common/logo.dart';
import 'package:moneymanager/router/app_router.dart';

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

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  bool _isAddTransactionOpen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void _onNavigationItemSelected(int index) {
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
    final isDesktop = context.isDesktop;

    return isDesktop
        ? _DesktopLayout(
            currentIndex: _currentIndex,
            onNavigationItemSelected: _onNavigationItemSelected,
            onToggleAddTransaction: _toggleAddTransaction,
            onCloseAddTransaction: _closeAddTransaction,
            isAddTransactionOpen: _isAddTransactionOpen,
          )
        : _MobileLayout(
            currentIndex: _currentIndex,
            onNavigationItemSelected: _onNavigationItemSelected,
            onToggleAddTransaction: _toggleAddTransaction,
            onCloseAddTransaction: _closeAddTransaction,
            isAddTransactionOpen: _isAddTransactionOpen,
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
  final VoidCallback onCloseAddTransaction;
  final bool isAddTransactionOpen;

  const _DesktopLayout({
    required this.currentIndex,
    required this.onNavigationItemSelected,
    required this.onToggleAddTransaction,
    required this.onCloseAddTransaction,
    required this.isAddTransactionOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(
            currentIndex: currentIndex,
            onNavigationItemSelected: onNavigationItemSelected,
            onAddTransactionPressed: onToggleAddTransaction,
            isAddTransactionOpen: isAddTransactionOpen,
          ),
          Expanded(
            child: Column(
              children: [
                _DesktopAppBar(
                  currentScreenData: _NavigationConfig.items[currentIndex],
                  onAddTransactionPressed: onToggleAddTransaction,
                ),
                Expanded(
                  child: RepaintBoundary(
                    child: IndexedStack(
                      index: currentIndex,
                      children: _NavigationConfig.screens,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isAddTransactionOpen)
            SizedBox(
              width: 400,
              child: AddTransactionScreen(
                key: const PageStorageKey('add_transaction_desktop'),
                onClose: onCloseAddTransaction,
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigationItemSelected;
  final VoidCallback onToggleAddTransaction;
  final VoidCallback onCloseAddTransaction;
  final bool isAddTransactionOpen;

  const _MobileLayout({
    required this.currentIndex,
    required this.onNavigationItemSelected,
    required this.onToggleAddTransaction,
    required this.onCloseAddTransaction,
    required this.isAddTransactionOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            child: _NavigationConfig.screens[currentIndex],
          ),
          if (isAddTransactionOpen) ...[
            GestureDetector(
              onTap: onCloseAddTransaction,
              child: const ColoredBox(color: Colors.black54),
            ),
            Positioned.fill(
              child: AddTransactionScreen(
                key: const PageStorageKey('add_transaction_mobile'),
                onClose: onCloseAddTransaction,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _MobileBottomNavigation(
        currentIndex: currentIndex,
        onNavigationItemSelected: onNavigationItemSelected,
      ),
      floatingActionButton: _MobileFAB(
        onPressed: onToggleAddTransaction,
        isOpen: isAddTransactionOpen,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigationItemSelected;
  final VoidCallback onAddTransactionPressed;
  final bool isAddTransactionOpen;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.onNavigationItemSelected,
    required this.onAddTransactionPressed,
    required this.isAddTransactionOpen,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: SizedBox(
        width: 280,
        child: Column(
          children: [
            const _LogoSection(),
            SizedBox(height: context.spacing(0.5)),
            _AddTransactionButton(
              onPressed: onAddTransactionPressed,
              isOpen: isAddTransactionOpen,
            ),
            _NavigationItems(
              currentIndex: currentIndex,
              onItemSelected: onNavigationItemSelected,
            ),
            const _UserInfo(),
          ],
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
              bottom: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border))),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.spacing()),
        child: const Row(
          children: [
            AppLogo(size: 80, type: LogoType.dark),
            Text(
              'Money Manager',
              style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTransactionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isOpen;

  const _AddTransactionButton({
    required this.onPressed,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing(),
        vertical: 4,
      ),
      child: _NavigationItemWidget(
        item: _NavigationItem(
            icon: Iconsax.add_copy,
            selectedIcon: Iconsax.add_copy,
            label: 'Add Transaction'),
        isSelected: isOpen,
        onTap: onPressed,
      ),
    );
  }
}

class _NavigationItems extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const _NavigationItems({
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _NavigationConfig.items.length,
        itemBuilder: (context, index) {
          final item = _NavigationConfig.items[index];
          final isSelected = currentIndex == index;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing(),
              vertical: 4,
            ),
            child: _NavigationItemWidget(
              item: item,
              isSelected: isSelected,
              onTap: () => onItemSelected(index),
            ),
          );
        },
      ),
    );
  }
}

class _NavigationItemWidget extends StatelessWidget {
  final _NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                item.label,
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  const _UserInfo();

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, (String?, String?)>(
      selector: (_, provider) => (
        provider.user?.displayName,
        provider.user?.email,
      ),
      builder: (context, userInfo, _) => DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.spacing()),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userInfo.$1 ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (userInfo.$2?.isNotEmpty == true)
                      Text(
                        userInfo.$2!,
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
    );
  }
}

class _DesktopAppBar extends StatelessWidget {
  final _NavigationItem currentScreenData;
  final VoidCallback onAddTransactionPressed;

  const _DesktopAppBar({
    required this.currentScreenData,
    required this.onAddTransactionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: SizedBox(
        height: 80,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacing(1.5)),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentScreenData.title,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: context.fontSize(24),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    currentScreenData.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigationItemSelected;

  const _MobileBottomNavigation({
    required this.currentIndex,
    required this.onNavigationItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onNavigationItemSelected,
      destinations: _NavigationConfig.items
          .map((item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ))
          .toList(),
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      height: 70,
      elevation: 8,
    );
  }
}

class _MobileFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isOpen;

  const _MobileFAB({
    required this.onPressed,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: isOpen ? AppColors.textSecondary : AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      child: Icon(isOpen ? Iconsax.close_circle : Iconsax.add_copy),
    );
  }
}
