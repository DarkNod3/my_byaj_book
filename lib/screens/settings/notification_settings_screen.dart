import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_byaj_book/utils/permission_handler.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';

class NotificationSettingsScreen extends StatefulWidget {
  static const routeName = '/notification-settings';

  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isNotificationPermissionGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    // Check notification permission status
    final notificationStatus = await Permission.notification.status;
    
    setState(() {
      _isNotificationPermissionGranted = notificationStatus.isGranted;
      _isLoading = false;
    });
  }

  Future<void> _requestNotificationPermission() async {
    final permissionUtils = PermissionUtils();
    final granted = await permissionUtils.requestNotificationPermission(context);
    
    setState(() {
      _isNotificationPermissionGranted = granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          const AppHeader(
            title: 'Notification Settings',
            showBackButton: true,
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notification Permissions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPermissionItem(
                                title: 'Allow Notifications',
                                description: 'Enable notifications for payment reminders, due dates and other alerts',
                                isGranted: _isNotificationPermissionGranted,
                                onTap: _requestNotificationPermission,
                              ),
                              const Divider(height: 32),
                              const Text(
                                'Notification Types',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildNotificationTypeItem(
                                title: 'Payment Reminders',
                                description: 'For upcoming payments of loans, cards, and bills',
                                icon: Icons.payment,
                                color: Colors.green,
                                isEnabled: _isNotificationPermissionGranted,
                              ),
                              const SizedBox(height: 16),
                              _buildNotificationTypeItem(
                                title: 'Due Date Alerts',
                                description: 'For contact due dates and reminders',
                                icon: Icons.event,
                                color: Colors.orange,
                                isEnabled: _isNotificationPermissionGranted,
                              ),
                              const SizedBox(height: 16),
                              _buildNotificationTypeItem(
                                title: 'System Alerts',
                                description: 'Important app updates and announcements',
                                icon: Icons.info,
                                color: Colors.blue,
                                isEnabled: _isNotificationPermissionGranted,
                              ),
                              if (!_isNotificationPermissionGranted) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.amber.shade800,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'You need to enable notification permission to receive important reminders and alerts',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notification Schedule',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Important reminders are shown multiple times per day:',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildScheduleItem(
                                time: '9:00 AM',
                                label: 'Morning Reminder',
                                isEnabled: _isNotificationPermissionGranted,
                              ),
                              const SizedBox(height: 8),
                              _buildScheduleItem(
                                time: '12:00 PM',
                                label: 'Afternoon Reminder',
                                isEnabled: _isNotificationPermissionGranted,
                              ),
                              const SizedBox(height: 8),
                              _buildScheduleItem(
                                time: '5:00 PM',
                                label: 'Evening Reminder',
                                isEnabled: _isNotificationPermissionGranted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: isGranted,
        activeColor: AppTheme.primaryColor,
        onChanged: (value) {
          if (!isGranted) {
            onTap();
          } else {
            // If already granted, open settings
            openAppSettings();
          }
        },
      ),
      onTap: onTap,
    );
  }

  Widget _buildNotificationTypeItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isEnabled,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.check_circle,
          color: isEnabled ? Colors.green : Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildScheduleItem({
    required String time,
    required String label,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? () {
        // Toggle the schedule when tapped if notifications are enabled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label notifications will be sent at $time'),
            duration: const Duration(seconds: 2),
          ),
        );
      } : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEnabled
                    ? AppTheme.primaryColor.withOpacity(0.5)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isEnabled ? AppTheme.primaryColor : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isEnabled ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Icon(
            isEnabled ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: isEnabled ? Colors.green : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
} 