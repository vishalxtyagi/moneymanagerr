import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/styles.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _dailyReminder = true;
  bool _budgetAlert = true;
  bool _expenseAlert = true;
  bool _weeklyReport = false;
  bool _monthlyReport = true;
  
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0);
  double _budgetThreshold = 80.0;
  double _expenseThreshold = 100.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Daily Notifications'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Daily Expense Reminder'),
                    subtitle: const Text('Remind me to log my daily expenses'),
                    value: _dailyReminder,
                    onChanged: (value) {
                      setState(() {
                        _dailyReminder = value;
                      });
                    },
                  ),
                  if (_dailyReminder) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Reminder Time'),
                      subtitle: Text(_reminderTime.format(context)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectReminderTime,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            _buildSectionHeader('Budget Alerts'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Budget Threshold Alert'),
                    subtitle: Text('Alert when spending reaches ${_budgetThreshold.toInt()}% of budget'),
                    value: _budgetAlert,
                    onChanged: (value) {
                      setState(() {
                        _budgetAlert = value;
                      });
                    },
                  ),
                  if (_budgetAlert) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Budget Alert Threshold'),
                      subtitle: Text('${_budgetThreshold.toInt()}% of daily budget'),
                      trailing: SizedBox(
                        width: 100,
                        child: Slider(
                          value: _budgetThreshold,
                          min: 50,
                          max: 100,
                          divisions: 10,
                          label: '${_budgetThreshold.toInt()}%',
                          onChanged: (value) {
                            setState(() {
                              _budgetThreshold = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            _buildSectionHeader('Expense Alerts'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Large Expense Alert'),
                    subtitle: Text('Alert for expenses above ₹${_expenseThreshold.toInt()}'),
                    value: _expenseAlert,
                    onChanged: (value) {
                      setState(() {
                        _expenseAlert = value;
                      });
                    },
                  ),
                  if (_expenseAlert) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Expense Alert Threshold'),
                      subtitle: Text('₹${_expenseThreshold.toInt()}'),
                      trailing: SizedBox(
                        width: 100,
                        child: Slider(
                          value: _expenseThreshold,
                          min: 50,
                          max: 1000,
                          divisions: 19,
                          label: '₹${_expenseThreshold.toInt()}',
                          onChanged: (value) {
                            setState(() {
                              _expenseThreshold = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            _buildSectionHeader('Reports'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Weekly Summary'),
                    subtitle: const Text('Get weekly expense summary'),
                    value: _weeklyReport,
                    onChanged: (value) {
                      setState(() {
                        _weeklyReport = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Monthly Report'),
                    subtitle: const Text('Get monthly spending analysis'),
                    value: _monthlyReport,
                    onChanged: (value) {
                      setState(() {
                        _monthlyReport = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  void _saveSettings() {
    // TODO: Implement save settings functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved successfully'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }
}
