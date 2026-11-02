import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/encryption_service.dart';
import '../../theme/app_colors.dart';

class SecurityCenterScreen extends StatelessWidget {
  const SecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final user = authProvider.currentUser;
    final fingerprint = EncryptionService.generateDeviceFingerprint(
      user?.id ?? 'guest_device',
      deviceProvider.localIp,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Security & Trust Center',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Offline cryptography, local verification, and permission guard.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Device Fingerprint Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'DEVICE VERIFICATION FINGERPRINT',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1),
                      ),
                      Icon(Icons.fingerprint, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fingerprint,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Peers can compare this fingerprint on their screen to verify that the local socket connection is untampered.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Security Controls List
            const Text(
              'TRANSFER SECURITY POLICIES',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, letterSpacing: 1),
            ),
            const SizedBox(height: 12),

            _buildPolicyTile(
              icon: Icons.lock_outline,
              title: 'Require Explicit Transfer Acceptance',
              subtitle: 'Files cannot be saved unless manually confirmed by the receiver.',
              value: settingsProvider.settings.requireVerification,
              onChanged: (val) {
                settingsProvider.updateSettings(requireVerification: val);
              },
            ),
            const SizedBox(height: 10),

            _buildPolicyTile(
              icon: Icons.enhanced_encryption_outlined,
              title: 'AES Data Payload Obfuscation',
              subtitle: 'Local LAN packet payload encryption for offline privacy.',
              value: settingsProvider.settings.endToEndEncryption,
              onChanged: (val) {
                settingsProvider.updateSettings(endToEndEncryption: val);
              },
            ),
            const SizedBox(height: 10),

            _buildPolicyTile(
              icon: Icons.done_all,
              title: 'Auto-Accept from Trusted Devices',
              subtitle: 'Automatically receive files only from devices marked as trusted.',
              value: settingsProvider.settings.autoAccept,
              onChanged: (val) {
                settingsProvider.updateSettings(autoAccept: val);
              },
            ),
            const SizedBox(height: 28),

            // Trusted Devices Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TRUSTED PEER DEVICES',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, letterSpacing: 1),
                ),
                Text(
                  '${deviceProvider.trustedIds.length} Trusted',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (deviceProvider.trustedIds.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.star_border, size: 36, color: AppColors.textSecondaryDark),
                    SizedBox(height: 10),
                    Text(
                      'No Trusted Devices Yet',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Mark devices with the star icon in Device Discovery to grant trusted status.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deviceProvider.trustedIds.length,
                itemBuilder: (context, index) {
                  final id = deviceProvider.trustedIds[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.verified, color: AppColors.primary),
                      title: Text('Device ID: $id', style: const TextStyle(fontSize: 13, color: Colors.white)),
                      trailing: IconButton(
                        icon: const Icon(Icons.star, color: AppColors.warning),
                        tooltip: 'Revoke Trust',
                        onPressed: () => deviceProvider.toggleTrust(id),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 28),

            // Zero-Cloud Privacy Guarantee
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_off, color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Zero-Cloud Privacy Guarantee',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'AuraShare never uploads files, telemetry, or account credentials to external cloud services. All operations are confined to your physical local Wi-Fi, Ethernet, or mobile hotspot network.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
