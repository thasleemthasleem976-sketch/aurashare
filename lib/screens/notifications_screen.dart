import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.incomingFile:
        return Icons.file_download;
      case NotificationType.connectionRequest:
        return Icons.link;
      case NotificationType.transferStarted:
        return Icons.sync;
      case NotificationType.transferCompleted:
        return Icons.check_circle_outline;
      case NotificationType.transferFailed:
        return Icons.error_outline;
      case NotificationType.transferCancelled:
        return Icons.cancel_outlined;
      case NotificationType.deviceConnected:
        return Icons.devices;
      case NotificationType.deviceDisconnected:
        return Icons.device_unknown;
      case NotificationType.securityAlert:
        return Icons.shield_outlined;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.incomingFile:
      case NotificationType.transferStarted:
        return AppColors.primary;
      case NotificationType.transferCompleted:
      case NotificationType.deviceConnected:
        return AppColors.success;
      case NotificationType.transferFailed:
      case NotificationType.securityAlert:
        return AppColors.error;
      case NotificationType.transferCancelled:
      case NotificationType.deviceDisconnected:
        return AppColors.warning;
      case NotificationType.connectionRequest:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Notifications',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Live event log of incoming files, connections, and transfer updates.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
                if (notifications.isNotEmpty)
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Mark Read'),
                        onPressed: () => notificationProvider.markAllAsRead(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        tooltip: 'Clear All',
                        onPressed: () => notificationProvider.clearAll(),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),

            if (notifications.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textSecondaryDark),
                    SizedBox(height: 16),
                    Text(
                      'No Notifications Yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'When devices connect or send files, notifications will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final iconColor = _getNotificationColor(notif.type);
                  final timeStr = DateFormat('MMM d, hh:mm a').format(notif.timestamp);

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notif.isRead ? AppColors.borderDark : AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getNotificationIcon(notif.type), color: iconColor, size: 20),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.message,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
