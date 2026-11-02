import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/file_management_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/radar_scan_animation.dart';
import '../../widgets/device_card.dart';

class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '52346');

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _showDirectConnectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: Row(
          children: const [
            Icon(Icons.settings_ethernet, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text('Connect by Direct IP', style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the local IP address of another device running AuraShare on your Wi-Fi or Hotspot.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Target IPv4 Address',
                hintText: 'e.g. 192.168.1.15',
                prefixIcon: Icon(Icons.computer),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Port',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              final ip = _ipController.text.trim();
              final port = int.tryParse(_portController.text.trim()) ?? 52346;
              if (ip.isNotEmpty) {
                Navigator.pop(ctx);
                final devProv = context.read<DeviceProvider>();
                final dev = await devProv.probeManualIp(ip, port: port);
                if (dev == null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not reach AuraShare node at $ip:$port'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Probe & Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final fileProvider = context.watch<FileManagementProvider>();
    final devices = deviceProvider.devices;

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
                  children: [
                    const Text(
                      'Nearby Device Discovery',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan local network via UDP beacons for live AuraShare nodes.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_link, size: 18),
                  label: const Text('Direct IP'),
                  onPressed: _showDirectConnectDialog,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Radar Scanner Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: deviceProvider.isScanning ? AppColors.primary.withOpacity(0.6) : AppColors.borderDark,
                ),
              ),
              child: Row(
                children: [
                  RadarScanAnimation(
                    isScanning: deviceProvider.isScanning,
                    size: 140,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: deviceProvider.isScanning
                                    ? AppColors.primary.withOpacity(0.2)
                                    : AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: deviceProvider.isScanning ? AppColors.primary : AppColors.borderDark,
                                ),
                              ),
                              child: Text(
                                deviceProvider.isScanning ? 'RADAR ACTIVE' : 'RADAR PAUSED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: deviceProvider.isScanning ? AppColors.primary : AppColors.textSecondaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Port: 52345 UDP',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          deviceProvider.isScanning
                            ? 'Broadcasting discovery beacons and listening for responses...'
                            : 'Radar is idle. Click below to scan your local network.',
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(deviceProvider.isScanning ? Icons.stop : Icons.play_arrow, size: 18),
                              label: Text(deviceProvider.isScanning ? 'Stop Scanning' : 'Scan Nearby Devices'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: deviceProvider.isScanning ? AppColors.cardDark : AppColors.primary,
                                foregroundColor: deviceProvider.isScanning ? Colors.white : Colors.white,
                                side: deviceProvider.isScanning ? const BorderSide(color: AppColors.borderDark) : null,
                              ),
                              onPressed: () => deviceProvider.toggleScanning(),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: AppColors.textSecondaryDark),
                              tooltip: 'Refresh Device List',
                              onPressed: () => deviceProvider.refresh(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Discovered Devices Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'AVAILABLE DEVICES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${devices.length}',
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (deviceProvider.connectedDevice != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Connected to: ${deviceProvider.connectedDevice!.name}',
                          style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Device List
            if (devices.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    Icon(
                      deviceProvider.isScanning ? Icons.radar : Icons.devices_outlined,
                      size: 48,
                      color: AppColors.textSecondaryDark.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      deviceProvider.isScanning
                          ? 'Searching for AuraShare devices on local network...'
                          : 'No nearby devices currently visible',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ensure both devices are connected to the same Wi-Fi router, local LAN, or phone Wi-Fi hotspot with AuraShare open.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                    const SizedBox(height: 20),
                    if (!deviceProvider.isScanning)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.radar, size: 18),
                        label: const Text('Start Radar Scan'),
                        onPressed: () => deviceProvider.toggleScanning(),
                      ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final dev = devices[index];
                  final isConnected = deviceProvider.connectedDevice?.id == dev.id;

                  return DeviceCard(
                    device: dev,
                    isConnected: isConnected,
                    onConnect: () => deviceProvider.connectToDevice(dev),
                    onDisconnect: () => deviceProvider.disconnect(),
                    onToggleTrust: () => deviceProvider.toggleTrust(dev.id),
                    onSelect: () {
                      deviceProvider.connectToDevice(dev);
                      if (fileProvider.selectedFiles.isNotEmpty) {
                        context.go('/transfer');
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
