import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/transfer_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/file_management_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/transfer_progress_card.dart';
import '../../models/transfer_session_model.dart';
import '../../models/device_model.dart';

class FileTransferScreen extends StatelessWidget {
  const FileTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transferProvider = context.watch<TransferProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final fileProvider = context.watch<FileManagementProvider>();
    final activeSession = transferProvider.activeSession;

    final selectedFiles = fileProvider.selectedFiles;
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
                  children: const [
                    Text(
                      'Send & Transfer Hub',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choose files and select a nearby device to stream directly without separate connection setup.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Transfer View (if running)
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
              const SizedBox(height: 28),
            ],

            // Step 1: Choose Files Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
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
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            alignment: Alignment.center,
                            child: const Text('1', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Choose Files to Transfer',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Browse Files'),
                        onPressed: () => fileProvider.pickFiles(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (selectedFiles.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.folder_open, size: 36, color: AppColors.textSecondaryDark),
                          SizedBox(height: 8),
                          Text(
                            'No files selected yet. Click "Browse Files" to choose files.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedFiles.length} file(s) selected • Total: ${fileProvider.formattedSelectedSize}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedFiles.map((f) {
                            return Chip(
                              backgroundColor: AppColors.surfaceDark,
                              avatar: const Icon(Icons.insert_drive_file, size: 16, color: AppColors.primary),
                              label: Text('${f.name} (${f.formattedSize})', style: const TextStyle(fontSize: 12, color: Colors.white)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => fileProvider.removeFile(f.id),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step 2: Choose Nearby Device (Scanning Live)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
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
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            alignment: Alignment.center,
                            child: const Text('2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Select Nearby Device (Auto-Scanning)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Rescan'),
                        onPressed: () => deviceProvider.refresh(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap any detected device below to connect and transfer instantly.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                  ),
                  const SizedBox(height: 16),

                  if (devices.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.radar, size: 36, color: AppColors.primary),
                          SizedBox(height: 10),
                          Text(
                            'Scanning for nearby receivers on Wi-Fi...',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Make sure AuraShare is open on the receiver device and on the same Wi-Fi or hotspot.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final dev = devices[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              child: Icon(
                                dev.platform == DevicePlatform.android ? Icons.phone_android : Icons.laptop,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              dev.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${dev.platform.displayName} • ${dev.ipAddress}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                            ),
                            trailing: ElevatedButton.icon(
                              icon: const Icon(Icons.send_rounded, size: 16),
                              label: const Text('Send'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: () async {
                                if (selectedFiles.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please choose at least one file to send!'),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                  await fileProvider.pickFiles();
                                  return;
                                }

                                await transferProvider.startSend(
                                  peerIp: dev.ipAddress,
                                  peerPort: dev.port,
                                  peerDeviceId: dev.id,
                                  peerDeviceName: dev.name,
                                  files: selectedFiles,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
