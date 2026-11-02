import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _deviceNameController = TextEditingController();
  final _downloadPathController = TextEditingController();
  final _transferPortController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _deviceNameController.text = settings.deviceName;
    _downloadPathController.text = settings.downloadPath;
    _transferPortController.text = '${settings.transferPort}';
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _downloadPathController.dispose();
    _transferPortController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final settingsProvider = context.read<SettingsProvider>();
    final authProvider = context.read<AuthProvider>();

    final devName = _deviceNameController.text.trim();
    final path = _downloadPathController.text.trim();
    final port = int.tryParse(_transferPortController.text.trim()) ?? 52346;

    await settingsProvider.updateSettings(
      deviceName: devName,
      downloadPath: path,
      transferPort: port,
    );

    if (devName.isNotEmpty) {
      await authProvider.updateProfile(deviceName: devName);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved locally!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;

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
                      'Settings',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Configure device identity, transfer policies, and network ports.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Changes'),
                  onPressed: _saveSettings,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Device Identity
            _buildSectionHeader('DEVICE IDENTITY'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _deviceNameController,
                    decoration: const InputDecoration(
                      labelText: 'Device Name (Visible to peers)',
                      prefixIcon: Icon(Icons.devices),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _downloadPathController,
                    decoration: const InputDecoration(
                      labelText: 'Save Directory for Incoming Files',
                      prefixIcon: Icon(Icons.folder_special),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Transfer & Security Preferences
            _buildSectionHeader('TRANSFER & SECURITY PREFERENCES'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.shield_outlined, color: AppColors.primary),
                    title: const Text('Require Confirmation for Every Transfer', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    subtitle: const Text('Never auto-accept files from unverified peers', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                    value: settings.requireVerification,
                    onChanged: (val) => settingsProvider.updateSettings(requireVerification: val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.auto_awesome, color: AppColors.accent),
                    title: const Text('Auto-Accept from Trusted Devices', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    subtitle: const Text('Bypass manual prompt for starred trusted peers', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                    value: settings.autoAccept,
                    onChanged: (val) => settingsProvider.updateSettings(autoAccept: val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.lock, color: AppColors.success),
                    title: const Text('Local AES Data Obfuscation', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    subtitle: const Text('Encrypt socket stream chunks across local network', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                    value: settings.endToEndEncryption,
                    onChanged: (val) => settingsProvider.updateSettings(endToEndEncryption: val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Notification Preferences
            _buildSectionHeader('NOTIFICATIONS & ALERTS'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                    title: const Text('In-App Notification Alerts', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    subtitle: const Text('Receive alerts for incoming requests and completed transfers', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                    value: settings.notificationsEnabled,
                    onChanged: (val) => settingsProvider.updateSettings(notificationsEnabled: val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_outlined, color: AppColors.primary),
                    title: const Text('Transfer Sound Effects', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    subtitle: const Text('Play chime when file transmission finishes', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                    value: settings.soundEnabled,
                    onChanged: (val) => settingsProvider.updateSettings(soundEnabled: val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Advanced Network Port Configurations
            _buildSectionHeader('ADVANCED OFFLINE PORTS'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _transferPortController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'TCP File Transfer Server Port',
                      prefixIcon: Icon(Icons.settings_input_composite),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Default is 52346 for TCP file streaming and 52345 for UDP broadcast discovery. Change only if your network administrator has blocked these specific ports.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, letterSpacing: 1),
      ),
    );
  }
}
