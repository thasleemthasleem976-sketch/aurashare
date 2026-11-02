import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/transfer_provider.dart';
import '../../providers/file_management_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stat_summary_card.dart';
import '../../widgets/transfer_progress_card.dart';
import '../../models/transfer_session_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final transferProvider = context.watch<TransferProvider>();
    final fileProvider = context.watch<FileManagementProvider>();

    final user = authProvider.currentUser;
    final userName = user?.fullName ?? 'Aura User';
    final deviceName = user?.deviceName ?? 'Offline Node';

    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome & Status Banner
            _buildWelcomeHeader(userName, deviceName, deviceProvider),
            const SizedBox(height: 24),

            // Ongoing Transfer Card (if currently transferring or paused)
            if (transferProvider.activeSession != null) ...[
              const Text(
                'ACTIVE TRANSFER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              TransferProgressCard(
                session: transferProvider.activeSession!,
                onPause: () => transferProvider.pauseTransfer(),
                onResume: () => transferProvider.resumeTransfer(),
                onCancel: () => transferProvider.cancelTransfer(),
              ),
              const SizedBox(height: 24),
            ],

            // Quick Actions Bar
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context, fileProvider, deviceProvider),
            const SizedBox(height: 28),

            // 4 Stat Cards Grid
            const Text(
              'SHARING OVERVIEW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatsGrid(context, deviceProvider, transferProvider, isWide),
            const SizedBox(height: 28),

            // Security Status & Offline Mode Card
            _buildSecurityCard(context, deviceProvider),
            const SizedBox(height: 28),

            // Recent Transfers Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT TRANSFERS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/history'),
                  child: const Text('View All History', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentTransfersList(context, transferProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String userName, String deviceName, DeviceProvider deviceProvider) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircleAvatar(radius: 4, backgroundColor: AppColors.success),
                          SizedBox(width: 6),
                          Text(
                            'OFFLINE LAN ACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'IP: ${deviceProvider.localIp}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome, $userName 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Device: $deviceName • Direct offline peer-to-peer file transfer ready',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_tethering, color: AppColors.primary, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    FileManagementProvider fileProvider,
    DeviceProvider deviceProvider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final children = [
          Expanded(
            flex: isNarrow ? 0 : 1,
            child: _buildActionButton(
              icon: Icons.send_rounded,
              label: 'Send Files',
              subtitle: 'Pick files & tap nearby device',
              gradient: AppColors.primaryGradient,
              onTap: () async {
                await fileProvider.pickFiles();
                if (context.mounted) {
                  context.go('/transfer');
                }
              },
            ),
          ),
          SizedBox(width: isNarrow ? 0 : 12, height: isNarrow ? 10 : 0),
          Expanded(
            flex: isNarrow ? 0 : 1,
            child: _buildActionButton(
              icon: Icons.download_rounded,
              label: 'Receive Files',
              subtitle: 'Listen for incoming transfers',
              color: AppColors.surfaceDark,
              borderColor: AppColors.primary.withOpacity(0.4),
              onTap: () {
                deviceProvider.toggleScanning();
                context.go('/transfer');
              },
            ),
          ),
        ];

        return isNarrow
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
            : Row(children: children);
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    LinearGradient? gradient,
    Color? color,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    DeviceProvider deviceProvider,
    TransferProvider transferProvider,
    bool isWide,
  ) {
    final activeConnected = deviceProvider.connectedDevice != null ? '1 Connected' : '0 Connected';
    final nearbyCount = '${deviceProvider.devices.length} Nearby';

    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isWide ? 1.4 : 1.3,
      children: [
        StatSummaryCard(
          title: 'Connected Devices',
          value: deviceProvider.connectedDevice != null ? '1' : '${deviceProvider.devices.length}',
          subtitle: deviceProvider.connectedDevice != null ? activeConnected : nearbyCount,
          icon: Icons.devices,
          accentColor: AppColors.primary,
          onTap: () => context.go('/discovery'),
        ),
        StatSummaryCard(
          title: 'Files Sent',
          value: '${transferProvider.totalSentFilesCount}',
          subtitle: '${(transferProvider.totalSentBytes / (1024 * 1024)).toStringAsFixed(1)} MB Sent',
          icon: Icons.upload_file,
          accentColor: AppColors.accent,
          onTap: () => context.go('/history'),
        ),
        StatSummaryCard(
          title: 'Files Received',
          value: '${transferProvider.totalReceivedFilesCount}',
          subtitle: '${(transferProvider.totalReceivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB Received',
          icon: Icons.download_done,
          accentColor: AppColors.success,
          onTap: () => context.go('/history'),
        ),
        StatSummaryCard(
          title: 'Active Transfers',
          value: transferProvider.activeSession != null ? '1' : '0',
          subtitle: transferProvider.activeSession != null ? 'In Progress' : 'Idle',
          icon: Icons.sync,
          accentColor: AppColors.warning,
          onTap: () => context.go('/transfer'),
        ),
      ],
    );
  }

  Widget _buildSecurityCard(BuildContext context, DeviceProvider deviceProvider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user, color: AppColors.success, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'End-to-End Local Security Active',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                SizedBox(height: 3),
                Text(
                  'All transfers are direct socket streams. No cloud, zero external servers, SHA-256 integrity protected.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.3),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
            ),
            onPressed: () => context.go('/security'),
            child: const Text('Security Center', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransfersList(BuildContext context, TransferProvider transferProvider) {
    if (transferProvider.history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          children: const [
            Icon(Icons.history_toggle_off, size: 40, color: AppColors.textSecondaryDark),
            SizedBox(height: 12),
            Text(
              'No Transfer History Yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            SizedBox(height: 4),
            Text(
              'Files you send or receive will appear here with complete transfer details.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
            ),
          ],
        ),
      );
    }

    final recent = transferProvider.history.take(4).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final session = recent[index];
        final isSent = session.type == TransferType.sent;
        final statusColor = session.status == TransferStatus.completed
            ? AppColors.success
            : (session.status == TransferStatus.failed ? AppColors.error : AppColors.warning);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isSent ? AppColors.primary : AppColors.accent).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSent ? Icons.arrow_upward : Icons.arrow_downward,
                color: isSent ? AppColors.primary : AppColors.accent,
                size: 20,
              ),
            ),
            title: Text(
              session.files.isNotEmpty ? session.files.first.name : 'Unknown File',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${isSent ? "Sent to" : "Received from"} ${session.peerDeviceName} • ${session.formattedTotalSize}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.status.displayName,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}
