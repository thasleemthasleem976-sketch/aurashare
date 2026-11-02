import 'package:flutter/material.dart';
import '../models/settings_model.dart';
import '../services/local_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  SettingsModel _settings = SettingsModel();
  bool _isLoading = true;

  SettingsProvider(this._storage) {
    _init();
  }

  SettingsModel get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    _settings = await _storage.getSettings();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSettings({
    String? deviceName,
    String? downloadPath,
    bool? autoAccept,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? isDarkMode,
    int? transferPort,
    int? discoveryPort,
    bool? requireVerification,
    bool? endToEndEncryption,
  }) async {
    _settings = _settings.copyWith(
      deviceName: deviceName,
      downloadPath: downloadPath,
      autoAccept: autoAccept,
      notificationsEnabled: notificationsEnabled,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      isDarkMode: isDarkMode,
      transferPort: transferPort,
      discoveryPort: discoveryPort,
      requireVerification: requireVerification,
      endToEndEncryption: endToEndEncryption,
    );
    await _storage.saveSettings(_settings);
    notifyListeners();
  }
}
