import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/file_item_model.dart';
import '../services/encryption_service.dart';

class FileManagementProvider extends ChangeNotifier {
  final List<FileItemModel> _stagedFiles = [];
  FileCategory? _selectedCategoryFilter;
  bool _isPicking = false;

  List<FileItemModel> get stagedFiles => _stagedFiles;
  FileCategory? get selectedCategoryFilter => _selectedCategoryFilter;
  bool get isPicking => _isPicking;

  List<FileItemModel> get filteredFiles {
    if (_selectedCategoryFilter == null) return _stagedFiles;
    return _stagedFiles.where((f) => f.category == _selectedCategoryFilter).toList();
  }

  List<FileItemModel> get selectedFiles => _stagedFiles.where((f) => f.isSelected).toList();

  int get totalSelectedBytes => selectedFiles.fold<int>(0, (sum, f) => sum + f.size);

  String get formattedSelectedSize {
    final size = totalSelectedBytes;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void setCategoryFilter(FileCategory? category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  Future<void> pickFiles({FileType type = FileType.any}) async {
    _isPicking = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: type,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var platformFile in result.files) {
          final filePath = platformFile.path ?? '';
          final fileName = platformFile.name;
          final fileSize = platformFile.size;
          final ext = platformFile.extension ?? fileName.split('.').last;
          final category = FileCategory.fromExtension(ext);

          String? checksum;
          Uint8List? preview;

          if (platformFile.bytes != null) {
            preview = platformFile.bytes;
            checksum = EncryptionService.calculateChecksum(platformFile.bytes!);
          } else if (filePath.isNotEmpty && !kIsWeb) {
            try {
              final file = File(filePath);
              if (await file.exists() && fileSize < 50 * 1024 * 1024) {
                // Compute checksum for files under 50MB quickly
                final bytes = await file.readAsBytes();
                checksum = EncryptionService.calculateChecksum(bytes);
              }
            } catch (_) {}
          }

          // Avoid duplicates
          final existing = _stagedFiles.indexWhere((f) => f.name == fileName && f.size == fileSize);
          if (existing == -1) {
            _stagedFiles.add(FileItemModel(
              id: const Uuid().v4(),
              name: fileName,
              path: filePath,
              size: fileSize,
              extension: ext,
              category: category,
              checksumSha256: checksum,
              previewBytes: preview,
              lastModified: DateTime.now(),
              isSelected: true,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('[FileManagementProvider] pickFiles error: $e');
    } finally {
      _isPicking = false;
      notifyListeners();
    }
  }

  void toggleFileSelection(String id) {
    final idx = _stagedFiles.indexWhere((f) => f.id == id);
    if (idx >= 0) {
      _stagedFiles[idx].isSelected = !_stagedFiles[idx].isSelected;
      notifyListeners();
    }
  }

  void selectAll() {
    for (var f in _stagedFiles) {
      f.isSelected = true;
    }
    notifyListeners();
  }

  void deselectAll() {
    for (var f in _stagedFiles) {
      f.isSelected = false;
    }
    notifyListeners();
  }

  void removeFile(String id) {
    _stagedFiles.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  void clearAll() {
    _stagedFiles.clear();
    notifyListeners();
  }
}
