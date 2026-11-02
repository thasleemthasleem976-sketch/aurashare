import 'package:flutter/material.dart';
import '../models/transfer_session_model.dart';
import '../theme/app_colors.dart';

class TransferProgressCard extends StatelessWidget {
  final TransferSessionModel session;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const TransferProgressCard({
    super.key,
    required this.session,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isPaused = session.status == TransferStatus.paused;
    final isSent = session.type == TransferType.sent;
    final currentFileName = session.files.isNotEmpty &&
            session.currentFileIndex < session.files.length
        ? session.files[session.currentFileIndex].name
        : 'Preparing files...';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSent
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.accent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSent ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isSent ? AppColors.primary : AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSent
                            ? 'Sending to ${session.peerDeviceName}'
                            : 'Receiving from ${session.peerDeviceName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'File ${session.currentFileIndex + 1} of ${session.files.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaused
                      ? AppColors.warning.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPaused ? AppColors.warning : AppColors.primary,
                  ),
                ),
                child: Text(
                  session.status.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPaused ? AppColors.warning : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // File Name
          Text(
            currentFileName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaused ? AppColors.warning : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Stats Row: Progress %, Transferred Size, Speed, ETA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(session.progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              Text(
                '${session.formattedTransferredSize} / ${session.formattedTotalSize}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              Text(
                session.formattedSpeed,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'ETA: ${session.formattedEta}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          // Controls: Pause, Resume, Cancel
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: onCancel,
              ),
              const SizedBox(width: 12),
              isPaused
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: onResume,
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.pause, size: 16),
                      label: const Text('Pause'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: onPause,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
