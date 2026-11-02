import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../theme/app_colors.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final bool isConnected;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onToggleTrust;
  final VoidCallback? onSelect;

  const DeviceCard({
    super.key,
    required this.device,
    required this.isConnected,
    required this.onConnect,
    required this.onDisconnect,
    required this.onToggleTrust,
    this.onSelect,
  });

  IconData _getPlatformIcon(DevicePlatform platform) {
    switch (platform) {
      case DevicePlatform.android:
        return Icons.phone_android;
      case DevicePlatform.windows:
        return Icons.laptop_windows;
      case DevicePlatform.linux:
        return Icons.computer;
      case DevicePlatform.macos:
        return Icons.laptop_mac;
      case DevicePlatform.ios:
        return Icons.phone_iphone;
      case DevicePlatform.web:
        return Icons.language;
      case DevicePlatform.unknown:
        return Icons.devices_other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? AppColors.primary : AppColors.borderDark,
          width: isConnected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onSelect,
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isConnected
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isConnected ? AppColors.primary : AppColors.borderDark,
                ),
              ),
              child: Icon(
                _getPlatformIcon(device.platform),
                color: isConnected ? AppColors.primary : AppColors.textSecondaryDark,
                size: 24,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.success : AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardDark, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                device.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (device.isTrusted)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.verified_user, color: AppColors.primary, size: 16),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  device.platform.displayName,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                device.ipAddress,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                device.isTrusted ? Icons.star : Icons.star_border,
                color: device.isTrusted ? AppColors.warning : AppColors.textSecondaryDark,
                size: 20,
              ),
              tooltip: device.isTrusted ? 'Trusted Device' : 'Mark as Trusted',
              onPressed: onToggleTrust,
            ),
            const SizedBox(width: 4),
            isConnected
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: onDisconnect,
                    child: const Text('Disconnect', style: TextStyle(fontSize: 12)),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.send, size: 14),
                    label: const Text('Send', style: TextStyle(fontSize: 12)),
                    onPressed: onConnect,
                  ),
          ],
        ),
      ),
    );
  }
}
