import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';
import '../models/transfer_session_model.dart';
import '../models/notification_model.dart';

class LocalStorageService {
  static const String _keyUsers = 'aurashare_users';
  static const String _keyCurrentUser = 'aurashare_current_user_email';
  static const String _keySettings = 'aurashare_settings';
  static const String _keyHistory = 'aurashare_transfer_history';
  static const String _keyNotifications = 'aurashare_notifications';
  static const String _keyTrustedDevices = 'aurashare_trusted_devices';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Users & Auth ---

  Future<List<UserModel>> getUsers() async {
    await init();
    final raw = _prefs?.getString(_keyUsers);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw) as List;
      return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveUser(UserModel user) async {
    await init();
    final users = await getUsers();
    final index = users.indexWhere((u) => u.email.toLowerCase() == user.email.toLowerCase());
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }
    await _prefs?.setString(_keyUsers, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final users = await getUsers();
    try {
      return users.firstWhere((u) => u.email.toLowerCase() == email.trim().toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<void> setCurrentUserEmail(String? email) async {
    await init();
    if (email == null) {
      await _prefs?.remove(_keyCurrentUser);
    } else {
      await _prefs?.setString(_keyCurrentUser, email);
    }
  }

  Future<String?> getCurrentUserEmail() async {
    await init();
    return _prefs?.getString(_keyCurrentUser);
  }

  // --- Settings ---

  Future<SettingsModel> getSettings() async {
    await init();
    final raw = _prefs?.getString(_keySettings);
    if (raw == null || raw.isEmpty) return SettingsModel();
    try {
      return SettingsModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return SettingsModel();
    }
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await init();
    await _prefs?.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  // --- Transfer History ---

  Future<List<TransferSessionModel>> getTransferHistory() async {
    await init();
    final raw = _prefs?.getString(_keyHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw) as List;
      return list.map((e) => TransferSessionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransferRecord(TransferSessionModel session) async {
    await init();
    final list = await getTransferHistory();
    final existingIndex = list.indexWhere((s) => s.id == session.id);
    if (existingIndex >= 0) {
      list[existingIndex] = session;
    } else {
      list.insert(0, session);
    }
    // Keep last 100 records
    final trimmed = list.take(100).toList();
    await _prefs?.setString(_keyHistory, jsonEncode(trimmed.map((s) => s.toJson()).toList()));
  }

  Future<void> clearHistory() async {
    await init();
    await _prefs?.remove(_keyHistory);
  }

  // --- Notifications ---

  Future<List<NotificationModel>> getNotifications() async {
    await init();
    final raw = _prefs?.getString(_keyNotifications);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw) as List;
      return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotification(NotificationModel notification) async {
    await init();
    final list = await getNotifications();
    list.insert(0, notification);
    final trimmed = list.take(50).toList();
    await _prefs?.setString(_keyNotifications, jsonEncode(trimmed.map((n) => n.toJson()).toList()));
  }

  Future<void> markAllNotificationsRead() async {
    await init();
    final list = await getNotifications();
    for (var n in list) {
      n.isRead = true;
    }
    await _prefs?.setString(_keyNotifications, jsonEncode(list.map((n) => n.toJson()).toList()));
  }

  Future<void> clearNotifications() async {
    await init();
    await _prefs?.remove(_keyNotifications);
  }

  // --- Trusted Devices ---

  Future<List<String>> getTrustedDeviceIds() async {
    await init();
    return _prefs?.getStringList(_keyTrustedDevices) ?? [];
  }

  Future<void> addTrustedDevice(String deviceId) async {
    await init();
    final list = await getTrustedDeviceIds();
    if (!list.contains(deviceId)) {
      list.add(deviceId);
      await _prefs?.setStringList(_keyTrustedDevices, list);
    }
  }

  Future<void> removeTrustedDevice(String deviceId) async {
    await init();
    final list = await getTrustedDeviceIds();
    list.remove(deviceId);
    await _prefs?.setStringList(_keyTrustedDevices, list);
  }
}
