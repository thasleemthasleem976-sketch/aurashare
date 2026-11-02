import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import 'local_storage_service.dart';

class NotificationService {
  final LocalStorageService _storage;
  final _streamController = StreamController<NotificationModel>.broadcast();

  NotificationService(this._storage);

  Stream<NotificationModel> get stream => _streamController.stream;

  Future<NotificationModel> notify({
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? metadata,
  }) async {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      metadata: metadata,
    );

    await _storage.saveNotification(notification);
    _streamController.add(notification);
    return notification;
  }

  void dispose() {
    _streamController.close();
  }
}
