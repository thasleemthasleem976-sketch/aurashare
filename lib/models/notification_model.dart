enum NotificationType {
  incomingFile,
  connectionRequest,
  transferStarted,
  transferCompleted,
  transferFailed,
  transferCancelled,
  deviceConnected,
  deviceDisconnected,
  securityAlert;

  String get defaultTitle {
    switch (this) {
      case NotificationType.incomingFile:
        return 'Incoming File Request';
      case NotificationType.connectionRequest:
        return 'Connection Request';
      case NotificationType.transferStarted:
        return 'File Transfer Started';
      case NotificationType.transferCompleted:
        return 'Transfer Completed Successfully';
      case NotificationType.transferFailed:
        return 'Transfer Failed';
      case NotificationType.transferCancelled:
        return 'Transfer Cancelled';
      case NotificationType.deviceConnected:
        return 'Device Connected';
      case NotificationType.deviceDisconnected:
        return 'Device Disconnected';
      case NotificationType.securityAlert:
        return 'Security Notice';
    }
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.securityAlert,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
