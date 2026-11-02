class SettingsModel {
  final String deviceName;
  final String downloadPath;
  final bool autoAccept;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool isDarkMode;
  final int transferPort;
  final int discoveryPort;
  final bool requireVerification;
  final bool endToEndEncryption;
  final List<String> trustedDeviceIds;

  SettingsModel({
    this.deviceName = 'AuraShare Device',
    this.downloadPath = 'Downloads/AuraShare',
    this.autoAccept = false,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.isDarkMode = true,
    this.transferPort = 52346,
    this.discoveryPort = 52345,
    this.requireVerification = true,
    this.endToEndEncryption = true,
    this.trustedDeviceIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'downloadPath': downloadPath,
      'autoAccept': autoAccept,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'isDarkMode': isDarkMode,
      'transferPort': transferPort,
      'discoveryPort': discoveryPort,
      'requireVerification': requireVerification,
      'endToEndEncryption': endToEndEncryption,
      'trustedDeviceIds': trustedDeviceIds,
    };
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      deviceName: json['deviceName'] as String? ?? 'AuraShare Device',
      downloadPath: json['downloadPath'] as String? ?? 'Downloads/AuraShare',
      autoAccept: json['autoAccept'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      isDarkMode: json['isDarkMode'] as bool? ?? true,
      transferPort: json['transferPort'] as int? ?? 52346,
      discoveryPort: json['discoveryPort'] as int? ?? 52345,
      requireVerification: json['requireVerification'] as bool? ?? true,
      endToEndEncryption: json['endToEndEncryption'] as bool? ?? true,
      trustedDeviceIds: (json['trustedDeviceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  SettingsModel copyWith({
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
    List<String>? trustedDeviceIds,
  }) {
    return SettingsModel(
      deviceName: deviceName ?? this.deviceName,
      downloadPath: downloadPath ?? this.downloadPath,
      autoAccept: autoAccept ?? this.autoAccept,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      transferPort: transferPort ?? this.transferPort,
      discoveryPort: discoveryPort ?? this.discoveryPort,
      requireVerification: requireVerification ?? this.requireVerification,
      endToEndEncryption: endToEndEncryption ?? this.endToEndEncryption,
      trustedDeviceIds: trustedDeviceIds ?? this.trustedDeviceIds,
    );
  }
}
