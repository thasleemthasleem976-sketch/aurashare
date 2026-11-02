import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/local_storage_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;
  final LocalStorageService _storage;

  StreamSubscription? _sub;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  NotificationProvider(this._notificationService, this._storage) {
    _init();
  }

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    _notifications = await _storage.getNotifications();
    _isLoading = false;
    notifyListeners();

    _sub = _notificationService.stream.listen((notification) {
      _notifications.insert(0, notification);
      notifyListeners();
    });
  }

  Future<void> markAllAsRead() async {
    await _storage.markAllNotificationsRead();
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _storage.clearNotifications();
    _notifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
