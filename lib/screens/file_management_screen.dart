import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/file_item_model.dart';
import '../../providers/file_management_provider.dart';
import '../../providers/device_provider.dart';
import '../../theme/app_colors.dart';

class FileManagementScreen extends StatelessWidget {
  const FileManagementScreen({super.key});

  IconData _getCategoryIcon(FileCategory cat) {
    switch (cat) {
      case FileCategory.document:
        return Icons.description_outlined;
      case FileCategory.image:
        return Icons.image_outlined;
      case FileCategory.video:
        return Icons.movie_outlined;
      case FileCategory.audio:
        return Icons.audiotrack_outlined;
      case FileCategory.archive:
        return Icons.folder_zip_outlined;
      case FileCategory.application:
        return Icons.android_outlined;
      case FileCategory.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getCategoryColor(FileCategory cat) {
    switch (cat) {
      case FileCategory.document:
        return const Color(0xFF3B82F6);
      case FileCategory.image:
        return const Color(0xFF10B981);
      case FileCategory.video:
        return const Color(0xFFF59E0B);
      case FileCategory.audio:
        return const Color(0xFF8B5CF6);
      case FileCategory.archive:
        return const Color(0xFFEC4899);
      case FileCategory.application:
        return const Color(0xFF06B6D4);
      case FileCategory.other:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileProvider = context.watch<FileManagementProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final stagedFiles = fileProvider.filteredFiles;

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
                      'File Management',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Browse local files, prepare transfer queues, and inspect file integrity.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Files'),
                  onPressed: fileProvider.isPicking
                      ? null
                      : () => fileProvider.pickFiles(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(context, fileProvider, null, 'All Files'),
                  _buildCategoryChip(context, fileProvider, FileCategory.document, 'Documents'),
                  _buildCategoryChip(context, fileProvider, FileCategory.image, 'Images'),
                  _buildCategoryChip(context, fileProvider, FileCategory.video, 'Videos'),
                  _buildCategoryChip(context, fileProvider, FileCategory.audio, 'Audio'),
                  _buildCategoryChip(context, fileProvider, FileCategory.archive, 'Archives'),
                  _buildCategoryChip(context, fileProvider, FileCategory.application, 'Apps'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Multi-File Selection Toolbar
            if (fileProvider.stagedFiles.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: fileProvider.selectedFiles.length == fileProvider.stagedFiles.length && fileProvider.stagedFiles.isNotEmpty,
                          onChanged: (val) {
                            if (val == true) {
                              fileProvider.selectAll();
                            } else {
                              fileProvider.deselectAll();
                            }
                          },
                        ),
                        Text(
                          '${fileProvider.selectedFiles.length} of ${fileProvider.stagedFiles.length} selected (${fileProvider.formattedSelectedSize})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => fileProvider.clearAll(),
                          child: const Text('Clear All', style: TextStyle(color: AppColors.error, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Send to Device'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: fileProvider.selectedFiles.isEmpty
                              ? null
                              : () {
                                  if (deviceProvider.connectedDevice == null) {
                                    context.go('/discovery');
                                  } else {
                                    context.go('/transfer');
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Files List or Empty State
            if (stagedFiles.isEmpty)
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.file_upload_outlined, size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Files Staged for Transfer',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select real local files from your device to prepare for direct offline transfer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse Device Storage'),
                      onPressed: () => fileProvider.pickFiles(),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stagedFiles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final file = stagedFiles[index];
                  final catColor = _getCategoryColor(file.category);

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: file.isSelected ? AppColors.primary : AppColors.borderDark,
                        width: file.isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: file.isSelected,
                            onChanged: (_) => fileProvider.toggleFileSelection(file.id),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_getCategoryIcon(file.category), color: catColor, size: 22),
                          ),
                        ],
                      ),
                      title: Text(
                        file.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Text(
                              file.formattedSize,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                file.category.name.toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: catColor),
                              ),
                            ),
                            if (file.checksumSha256 != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.shield, size: 12, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                file.checksumSha256!.substring(0, 8),
                                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondaryDark),
                              ),
                            ],
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.textSecondaryDark, size: 20),
                        onPressed: () => fileProvider.removeFile(file.id),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    FileManagementProvider provider,
    FileCategory? category,
    String label,
  ) {
    final isSelected = provider.selectedCategoryFilter == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setCategoryFilter(category),
        backgroundColor: AppColors.cardDark,
        selectedColor: AppColors.primary.withOpacity(0.2),
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
  }
}
