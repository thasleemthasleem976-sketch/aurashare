import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transfer_provider.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _deviceNameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController.text = user?.fullName ?? '';
    _deviceNameController.text = user?.deviceName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    await auth.updateProfile(
      fullName: _nameController.text.trim(),
      deviceName: _deviceNameController.text.trim(),
    );
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final transferProvider = context.watch<TransferProvider>();
    final user = authProvider.currentUser;

    final initial = (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : 'A';
    final memberSince = user != null ? DateFormat('MMMM yyyy').format(user.createdAt) : '2026';

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
                      'User Profile',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Local identity displayed to nearby discoverable peers.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: Icon(_isEditing ? Icons.check : Icons.edit, size: 18),
                  label: Text(_isEditing ? 'Save Profile' : 'Edit Profile'),
                  onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      initial,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _isEditing
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Full Name'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _deviceNameController,
                                decoration: const InputDecoration(labelText: 'Device Name'),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Aura User',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'offline@aurashare.local',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Node: ${user?.deviceName ?? "Device"}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceDark,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Offline Member Since $memberSince',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                                    ),
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

            // Lifetime Statistics
            const Text(
              'LIFETIME SHARING STATISTICS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, letterSpacing: 1),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  _buildStatRow('Total Files Sent', '${transferProvider.totalSentFilesCount} files', Icons.upload),
                  const Divider(height: 24),
                  _buildStatRow('Total Data Sent', '${(transferProvider.totalSentBytes / (1024 * 1024)).toStringAsFixed(1)} MB', Icons.file_upload_outlined),
                  const Divider(height: 24),
                  _buildStatRow('Total Files Received', '${transferProvider.totalReceivedFilesCount} files', Icons.download),
                  const Divider(height: 24),
                  _buildStatRow('Total Data Received', '${(transferProvider.totalReceivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB', Icons.file_download_outlined),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Account Security info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: AppColors.success, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Local Vault Storage',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Credentials and transfer sessions are stored strictly on this device inside encrypted local storage.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
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

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
