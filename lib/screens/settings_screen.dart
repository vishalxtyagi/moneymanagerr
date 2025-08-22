import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/providers/auth_provider.dart';
import 'package:moneymanager/constants/router.dart';
import 'package:moneymanager/utils/context_util.dart';
import 'package:moneymanager/utils/notifier_utils.dart';
import 'package:moneymanager/widgets/common/button.dart';
import 'package:moneymanager/widgets/common/card.dart';
import 'package:moneymanager/widgets/header/section_header.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  final String? title;
  final String? subtitle;

  const SettingsScreen({
    super.key,
    this.title,
    this.subtitle,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Use CachedValueNotifiers for efficient rebuilds
  late final CachedValueNotifier<bool> _notificationsEnabled;
  late final CachedValueNotifier<bool> _autoCategorize;

  // Constants to avoid repeated computations
  static const double _lowThresholdAmount = 100.0;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = CachedValueNotifier(true);
    _autoCategorize = CachedValueNotifier(true);
  }

  @override
  void dispose() {
    _notificationsEnabled.dispose();
    _autoCategorize.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for keep alive
    return Scaffold(
      appBar: context.isMobile
          ? AppBar(
              title: Text(
                widget.title ?? 'Settings',
              ),
            )
          : null,
      body: Column(
        children: [
          // Custom App Bar (only for desktop)
          if (context.isDesktop)
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title ?? 'Settings',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          widget.subtitle ?? 'Configure your preferences',
                          style: const TextStyle(
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
            ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notifications Section
                  const AppSectionHeader(title: 'Notifications'),
                  AppCard(
                    child: Column(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _notificationsEnabled,
                          builder: (context, enabled, _) => _NotificationTile(
                            enabled: enabled,
                            onChanged: (value) =>
                                _notificationsEnabled.value = value,
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: _notificationsEnabled,
                          builder: (context, enabled, _) => enabled
                              ? const _LowThresholdTile(
                                  threshold: _lowThresholdAmount)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Categories Section
                  const AppSectionHeader(title: 'Categories'),
                  AppCard(
                    child: Column(
                      children: [
                        _CategoryManagementTile(),
                        const Divider(height: 1),
                        ValueListenableBuilder<bool>(
                          valueListenable: _autoCategorize,
                          builder: (context, autoCategorize, _) =>
                              _AutoCategorizeTile(
                            enabled: autoCategorize,
                            onChanged: (value) => _autoCategorize.value = value,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Other sections...
                  const AppSectionHeader(title: 'Account'),
                  AppCard(
                    child: Column(
                      children: [
                        _ExportDataTile(),
                        const Divider(height: 1),
                        _SignOutTile(),
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

// Helper widgets for optimized settings screen
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications),
      title: const Text('Push Notifications'),
      subtitle: const Text('Receive alerts for transactions'),
      trailing: Switch(
        value: enabled,
        onChanged: onChanged,
      ),
    );
  }
}

class _LowThresholdTile extends StatelessWidget {
  const _LowThresholdTile({required this.threshold});

  final double threshold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.warning),
          title: const Text('Low Threshold Alert'),
          subtitle: Text(
            'Alert when balance goes below ₹${threshold.toStringAsFixed(0)}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Implement notification manager with named routes
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Notification settings coming soon!')),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryManagementTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.category),
      title: const Text('Manage Categories'),
      subtitle: const Text('Add, edit, or remove transaction categories'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRouter.categoryManager),
    );
  }
}

class _AutoCategorizeTile extends StatelessWidget {
  const _AutoCategorizeTile({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.auto_awesome),
      title: const Text('Auto-categorize Transactions'),
      subtitle: const Text('Automatically categorize based on merchant names'),
      trailing: Switch(
        value: enabled,
        onChanged: onChanged,
      ),
    );
  }
}

class _ExportDataTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.download),
      title: const Text('Export Data'),
      subtitle: const Text('Export transactions as CSV'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export feature coming soon!')),
        );
      },
    );
  }
}

class _SignOutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('Sign Out',
          style: TextStyle(overflow: TextOverflow.ellipsis, color: Colors.red)),
      onTap: () async {
        final authProvider = context.read<AuthProvider>();
        final confirmed = await _showSignOutDialog(context);
        if (confirmed) {
          await authProvider.signOut();
        }
      },
    );
  }

  Future<bool> _showSignOutDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: 'Cancel',
                    type: ButtonType.outlined,
                    size: ButtonSize.sm,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    text: 'Sign Out',
                    type: ButtonType.error,
                    size: ButtonSize.sm,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ) ??
        false;
  }
}
