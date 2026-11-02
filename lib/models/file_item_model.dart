import 'dart:typed_data';

enum FileCategory {
  document,
  image,
  video,
  audio,
  archive,
  application,
  other;

  static FileCategory fromExtension(String ext) {
    final clean = ext.toLowerCase().replaceAll('.', '');
    if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt', 'xls', 'xlsx', 'ppt', 'pptx', 'csv', 'md'].contains(clean)) {
      return FileCategory.document;
    } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'heic'].contains(clean)) {
      return FileCategory.image;
    } else if (['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', '3gp'].contains(clean)) {
      return FileCategory.video;
    } else if (['mp3', 'wav', 'ogg', 'm4a', 'flac', 'aac', 'wma'].contains(clean)) {
      return FileCategory.audio;
    } else if (['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].contains(clean)) {
      return FileCategory.archive;
    } else if (['apk', 'exe', 'msi', 'dmg', 'deb', 'rpm'].contains(clean)) {
      return FileCategory.application;
    }
    return FileCategory.other;
  }
}

class FileItemModel {
  final String id;
  final String name;
  final String path;
  final int size; // size in bytes
  final String extension;
  final FileCategory category;
  final String? checksumSha256;
  final Uint8List? previewBytes;
  final DateTime? lastModified;
  bool isSelected;

  FileItemModel({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.extension,
    required this.category,
    this.checksumSha256,
    this.previewBytes,
    this.lastModified,
    this.isSelected = false,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'size': size,
      'extension': extension,
      'category': category.name,
      'checksumSha256': checksumSha256,
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory FileItemModel.fromJson(Map<String, dynamic> json) {
    final ext = json['extension'] as String? ?? '';
    return FileItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      extension: ext,
      category: FileCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => FileCategory.fromExtension(ext),
      ),
      checksumSha256: json['checksumSha256'] as String?,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }

  FileItemModel copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    String? extension,
    FileCategory? category,
    String? checksumSha256,
    Uint8List? previewBytes,
    DateTime? lastModified,
    bool? isSelected,
  }) {
    return FileItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      extension: extension ?? this.extension,
      category: category ?? this.category,
      checksumSha256: checksumSha256 ?? this.checksumSha256,
      previewBytes: previewBytes ?? this.previewBytes,
      lastModified: lastModified ?? this.lastModified,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
