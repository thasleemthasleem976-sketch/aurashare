import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/transfer_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/file_management_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/transfer_progress_card.dart';
import '../../models/transfer_session_model.dart';

class FileTransferScreen extends StatelessWidget {
  const FileTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transferProvider = context.watch<TransferProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final fileProvider = context.watch<FileManagementProvider>();
    final activeSession = transferProvider.activeSession;

    final targetDevice = deviceProvider.connectedDevice;
    final selectedFiles = fileProvider.selectedFiles;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'File Transmission Hub',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time streaming over local offline socket connection.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 24),

            // Active Transfer View
            if (activeSession != null) ...[
              TransferProgressCard(
                session: activeSession,
                onPause: () => transferProvider.pauseTransfer(),
                onResume: () => transferProvider.resumeTransfer(),
                onCancel: () => transferProvider.cancelTransfer(),
              ),
              const SizedBox(height: 24),

              // Files in current transfer
              const Text(
                'TRANSFER QUEUE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeSession.files.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final file = activeSession.files[index];
                  final isCurrent = index == activeSession.currentFileIndex;
                  final isDone = index < activeSession.currentFileIndex ||
                      activeSession.status == TransferStatus.completed;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent ? AppColors.primary : AppColors.borderDark,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle
                              : (isCurrent ? Icons.sync : Icons.hourglass_empty),
                          color: isDone
                              ? AppColors.success
                              : (isCurrent ? AppColors.primary : AppColors.textSecondaryDark),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                file.formattedSize,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isDone
                              ? 'Finished'
                              : (isCurrent ? 'Transferring' : 'Queued'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDone
                                ? AppColors.success
                                : (isCurrent ? AppColors.primary : AppColors.textSecondaryDark),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              // Ready to Transfer Staging Box
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ready to Transfer',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: targetDevice != null
                                ? AppColors.success.withOpacity(0.15)
                                : AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            targetDevice != null ? 'PEER CONNECTED' : 'NO PEER SELECTED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: targetDevice != null ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Target Device Status Row
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.borderDark),
                      ),
                      tileColor: AppColors.surfaceDark,
                      leading: const Icon(Icons.devices, color: AppColors.primary),
                      title: Text(
                        targetDevice?.name ?? 'No Target Device Connected',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        targetDevice != null
                            ? '${targetDevice.platform.displayName} • ${targetDevice.ipAddress}:${targetDevice.port}'
                            : 'Select a nearby device to send files',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                      ),
                      trailing: TextButton(
                        onPressed: () => context.go('/discovery'),
                        child: Text(
                          targetDevice != null ? 'Change Peer' : 'Discover',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selected Files Summary Row
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.borderDark),
                      ),
                      tileColor: AppColors.surfaceDark,
                      leading: const Icon(Icons.folder_copy_outlined, color: AppColors.accent),
                      title: Text(
                        '${selectedFiles.length} file(s) staged for transfer',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        selectedFiles.isNotEmpty
                            ? 'Total Payload: ${fileProvider.formattedSelectedSize}'
                            : 'Browse local files to build a transfer queue',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                      ),
                      trailing: TextButton(
                        onPressed: () => context.go('/files'),
                        child: Text(
                          selectedFiles.isNotEmpty ? 'Edit Files' : 'Select Files',
                          style: const TextStyle(color: AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Start Transfer Action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Initiate Direct Transfer Request'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: (targetDevice != null && selectedFiles.isNotEmpty)
                            ? () async {
                                await transferProvider.startSend(
                                  peerIp: targetDevice.ipAddress,
                                  peerPort: targetDevice.port,
                                  peerDeviceId: targetDevice.id,
                                  peerDeviceName: targetDevice.name,
                                  files: selectedFiles,
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Listening Mode Pill
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cell_tower, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Incoming Transfer Listener Active',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'This device is listening on TCP port 52346. Any nearby AuraShare peer can send files with your authorization.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
