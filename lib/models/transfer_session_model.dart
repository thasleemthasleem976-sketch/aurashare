import 'file_item_model.dart';

enum TransferType {
  sent,
  received;

  String get displayName => this == TransferType.sent ? 'Sent' : 'Received';
}

enum TransferStatus {
  pending,
  requesting,
  transferring,
  paused,
  completed,
  cancelled,
  failed;

  String get displayName {
    switch (this) {
      case TransferStatus.pending:
        return 'Pending';
      case TransferStatus.requesting:
        return 'Waiting for Acceptance';
      case TransferStatus.transferring:
        return 'Transferring';
      case TransferStatus.paused:
        return 'Paused';
      case TransferStatus.completed:
        return 'Completed';
      case TransferStatus.cancelled:
        return 'Cancelled';
      case TransferStatus.failed:
        return 'Failed';
    }
  }
}

class TransferSessionModel {
  final String id;
  final TransferType type;
  final String peerDeviceId;
  final String peerDeviceName;
  final String peerIp;
  final List<FileItemModel> files;
  final int totalBytes;
  int transferredBytes;
  double progress; // 0.0 to 1.0
  double speedBytesPerSec;
  int etaSeconds;
  TransferStatus status;
  final DateTime startedAt;
  DateTime? completedAt;
  String? errorMessage;
  int currentFileIndex;

  TransferSessionModel({
    required this.id,
    required this.type,
    required this.peerDeviceId,
    required this.peerDeviceName,
    required this.peerIp,
    required this.files,
    required this.totalBytes,
    this.transferredBytes = 0,
    this.progress = 0.0,
    this.speedBytesPerSec = 0.0,
    this.etaSeconds = 0,
    this.status = TransferStatus.pending,
    required this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.currentFileIndex = 0,
  });

  String get formattedSpeed {
    if (speedBytesPerSec < 1024) return '${speedBytesPerSec.toStringAsFixed(0)} B/s';
    if (speedBytesPerSec < 1024 * 1024) return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  String get formattedEta {
    if (etaSeconds <= 0) return '0s';
    if (etaSeconds < 60) return '${etaSeconds}s';
    final minutes = etaSeconds ~/ 60;
    final seconds = etaSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  String get formattedTotalSize {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024) return '${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedTransferredSize {
    if (transferredBytes < 1024) return '$transferredBytes B';
    if (transferredBytes < 1024 * 1024) return '${(transferredBytes / 1024).toStringAsFixed(1)} KB';
    if (transferredBytes < 1024 * 1024 * 1024) return '${(transferredBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(transferredBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'peerDeviceId': peerDeviceId,
      'peerDeviceName': peerDeviceName,
      'peerIp': peerIp,
      'files': files.map((f) => f.toJson()).toList(),
      'totalBytes': totalBytes,
      'transferredBytes': transferredBytes,
      'progress': progress,
      'speedBytesPerSec': speedBytesPerSec,
      'etaSeconds': etaSeconds,
      'status': status.name,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'currentFileIndex': currentFileIndex,
    };
  }

  factory TransferSessionModel.fromJson(Map<String, dynamic> json) {
    return TransferSessionModel(
      id: json['id'] as String,
      type: TransferType.values.firstWhere((e) => e.name == json['type']),
      peerDeviceId: json['peerDeviceId'] as String? ?? 'unknown',
      peerDeviceName: json['peerDeviceName'] as String? ?? 'Nearby Device',
      peerIp: json['peerIp'] as String? ?? '',
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => FileItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalBytes: json['totalBytes'] as int? ?? 0,
      transferredBytes: json['transferredBytes'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      speedBytesPerSec: (json['speedBytesPerSec'] as num?)?.toDouble() ?? 0.0,
      etaSeconds: json['etaSeconds'] as int? ?? 0,
      status: TransferStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransferStatus.pending,
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      currentFileIndex: json['currentFileIndex'] as int? ?? 0,
    );
  }
}
