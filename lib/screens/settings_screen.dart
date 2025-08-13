import 'package:flutter/material.dart';
import 'package:moneymanager/core/providers/auth_provider.dart';
import 'package:moneymanager/core/utils/notifier_utils.dart';
import 'package:moneymanager/screens/settings/category_manager_screen.dart';
import 'package:moneymanager/screens/settings/notification_manager_screen.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications Section
            _SettingsSection(
              title: 'Notifications',
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _notificationsEnabled,
                  builder: (context, enabled, _) => _NotificationTile(
                    enabled: enabled,
                    onChanged: (value) => _notificationsEnabled.value = value,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _notificationsEnabled,
                  builder: (context, enabled, _) => enabled
                      ? const _LowThresholdTile(threshold: _lowThresholdAmount)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Categories Section
            _SettingsSection(
              title: 'Categories',
              children: [
                _CategoryManagementTile(),
                const Divider(height: 1),
                ValueListenableBuilder<bool>(
                  valueListenable: _autoCategorize,
                  builder: (context, autoCategorize, _) => _AutoCategorizeTile(
                    enabled: autoCategorize,
                    onChanged: (value) => _autoCategorize.value = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Other sections...
            _SettingsSection(
              title: 'Account',
              children: [
                _ExportDataTile(),
                const Divider(height: 1),
                _SignOutTile(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widgets for optimized settings screen
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationManagerScreen(),
            ),
          ),
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CategoryManagerScreen(),
        ),
      ),
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
      title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
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
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
