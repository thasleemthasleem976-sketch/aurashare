import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';

class OfflineCommunicationScreen extends StatelessWidget {
  const OfflineCommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

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
                  child: const Icon(Icons.wifi_off_outlined, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Offline Communication',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'LAN, Wi-Fi Direct, and Hotspot transmission configurations.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Interface Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          CircleAvatar(radius: 5, backgroundColor: AppColors.success),
                          SizedBox(width: 8),
                          Text(
                            'OFFLINE LOCAL INTERFACE ACTIVE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success, letterSpacing: 1),
                          ),
                        ],
                      ),
                      const Icon(Icons.router, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInterfaceRow('Bound Local IP', deviceProvider.localIp),
                  const Divider(height: 20),
                  _buildInterfaceRow('TCP Transfer Port', '${settingsProvider.settings.transferPort} (Incoming File Stream)'),
                  const Divider(height: 20),
                  _buildInterfaceRow('UDP Discovery Port', '${settingsProvider.settings.discoveryPort} (Multicast Beacons)'),
                  const Divider(height: 20),
                  _buildInterfaceRow('Subnet Broadcast', '255.255.255.255'),
                  const Divider(height: 20),
                  _buildInterfaceRow('Internet Dependency', 'None (0 bytes external traffic)'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Supported Technologies Accordion / Cards
            const Text(
              'SUPPORTED LOCAL TECHNOLOGIES',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, letterSpacing: 1),
            ),
            const SizedBox(height: 12),

            _buildTechCard(
              icon: Icons.wifi,
              title: 'Local Wi-Fi Network (LAN)',
              status: 'Ready & Listening',
              statusColor: AppColors.success,
              description: 'Connect both devices to the same standard Wi-Fi router. Internet connection is NOT required; the router routes packets directly between devices at full wireless speed.',
            ),
            const SizedBox(height: 12),

            _buildTechCard(
              icon: Icons.wifi_tethering,
              title: 'Portable Wi-Fi Hotspot',
              status: 'Supported',
              statusColor: AppColors.primary,
              description: 'Turn on Personal Hotspot on one phone or laptop. Connect the other device to the hotspot. AuraShare communicates directly without consuming any cellular mobile data.',
            ),
            const SizedBox(height: 12),

            _buildTechCard(
              icon: Icons.settings_ethernet,
              title: 'Wired Ethernet LAN',
              status: 'Ultra-Fast',
              statusColor: AppColors.accent,
              description: 'Connect computers via standard Ethernet cable or office LAN switch for gigabit transfer speeds with zero latency and complete air-gapped security.',
            ),
            const SizedBox(height: 28),

            // Diagnostic Tips
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Network Diagnostic & Troubleshooting Tips',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text('• If devices are on different subnets or AP isolation is enabled on guest Wi-Fi, use the "Direct IP" option in Device Discovery.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                  SizedBox(height: 6),
                  Text('• On Windows, ensure Windows Defender Firewall allows AuraShare on Private Networks.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                  SizedBox(height: 6),
                  Text('• On Android, grant Location/Nearby Devices permission which Android requires for Wi-Fi discovery.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterfaceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildTechCard({
    required IconData icon,
    required String title,
    required String status,
    required Color statusColor,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.4),
          ),
        ],
      ),
    );
  }
}
