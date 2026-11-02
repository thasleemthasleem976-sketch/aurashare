import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/transfer_provider.dart';
import '../../models/transfer_session_model.dart';
import '../../theme/app_colors.dart';

class TransferHistoryScreen extends StatefulWidget {
  const TransferHistoryScreen({super.key});

  @override
  State<TransferHistoryScreen> createState() => _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends State<TransferHistoryScreen> {
  String _filter = 'All'; // 'All', 'Sent', 'Received', 'Completed', 'Failed'

  @override
  Widget build(BuildContext context) {
    final transferProvider = context.watch<TransferProvider>();
    final allHistory = transferProvider.history;

    final filtered = allHistory.where((s) {
      if (_filter == 'Sent') return s.type == TransferType.sent;
      if (_filter == 'Received') return s.type == TransferType.received;
      if (_filter == 'Completed') return s.status == TransferStatus.completed;
      if (_filter == 'Failed') return s.status == TransferStatus.failed;
      return true;
    }).toList();

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
                      'Transfer History',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Locally stored records of all files sent and received offline.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
                if (allHistory.isNotEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.cardDark,
                          title: const Text('Clear History?'),
                          content: const Text('Are you sure you want to remove all offline transfer records?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () {
                                Navigator.pop(ctx);
                                transferProvider.clearHistory();
                              },
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Sent', 'Received', 'Completed', 'Failed'].map((filterName) {
                  final isSelected = _filter == filterName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filterName),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filter = filterName),
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      backgroundColor: AppColors.cardDark,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.borderDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // History List
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.history_toggle_off, size: 48, color: AppColors.textSecondaryDark),
                    const SizedBox(height: 16),
                    Text(
                      'No $_filter Transfer Records',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Transfer records will automatically persist here without internet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final session = filtered[index];
                  final isSent = session.type == TransferType.sent;
                  final timeFormatted = DateFormat('MMM d, yyyy • hh:mm a').format(session.startedAt);

                  Color statusColor;
                  switch (session.status) {
                    case TransferStatus.completed:
                      statusColor = AppColors.success;
                      break;
                    case TransferStatus.failed:
                      statusColor = AppColors.error;
                      break;
                    case TransferStatus.paused:
                      statusColor = AppColors.warning;
                      break;
                    case TransferStatus.cancelled:
                      statusColor = AppColors.offline;
                      break;
                    default:
                      statusColor = AppColors.primary;
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
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
                                    color: (isSent ? AppColors.primary : AppColors.accent).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isSent ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: isSent ? AppColors.primary : AppColors.accent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${isSent ? "Sent to" : "Received from"} ${session.peerDeviceName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                    ),
                                    Text(
                                      timeFormatted,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                session.status.displayName,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${session.files.length} file(s) • ${session.formattedTotalSize}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                            ),
                            Text(
                              'IP: ${session.peerIp}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                        if (session.files.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            session.files.map((f) => f.name).join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
