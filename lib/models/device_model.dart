enum DevicePlatform {
  android,
  windows,
  linux,
  macos,
  ios,
  web,
  unknown;

  static DevicePlatform fromString(String val) {
    switch (val.toLowerCase()) {
      case 'android':
        return DevicePlatform.android;
      case 'windows':
        return DevicePlatform.windows;
      case 'linux':
        return DevicePlatform.linux;
      case 'macos':
        return DevicePlatform.macos;
      case 'ios':
        return DevicePlatform.ios;
      case 'web':
        return DevicePlatform.web;
      default:
        return DevicePlatform.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case DevicePlatform.android:
        return 'Android';
      case DevicePlatform.windows:
        return 'Windows';
      case DevicePlatform.linux:
        return 'Linux';
      case DevicePlatform.macos:
        return 'macOS';
      case DevicePlatform.ios:
        return 'iOS';
      case DevicePlatform.web:
        return 'Web';
      case DevicePlatform.unknown:
        return 'Unknown';
    }
  }
}

enum DeviceConnectionStatus {
  available,
  connecting,
  connected,
  busy,
  disconnected,
}

class DeviceModel {
  final String id;
  final String name;
  final DevicePlatform platform;
  final String ipAddress;
  final int port;
  final DateTime lastSeen;
  final bool isTrusted;
  final DeviceConnectionStatus status;
  final String? avatar;
  final String? userEmail;

  DeviceModel({
    required this.id,
    required this.name,
    required this.platform,
    required this.ipAddress,
    this.port = 52346,
    required this.lastSeen,
    this.isTrusted = false,
    this.status = DeviceConnectionStatus.available,
    this.avatar,
    this.userEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform.name,
      'ipAddress': ipAddress,
      'port': port,
      'lastSeen': lastSeen.toIso8601String(),
      'isTrusted': isTrusted,
      'status': status.name,
      'avatar': avatar,
      'userEmail': userEmail,
    };
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      platform: DevicePlatform.fromString(json['platform'] as String? ?? 'unknown'),
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int? ?? 52346,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      isTrusted: json['isTrusted'] as bool? ?? false,
      status: DeviceConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeviceConnectionStatus.available,
      ),
      avatar: json['avatar'] as String?,
      userEmail: json['userEmail'] as String?,
    );
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    DevicePlatform? platform,
    String? ipAddress,
    int? port,
    DateTime? lastSeen,
    bool? isTrusted,
    DeviceConnectionStatus? status,
    String? avatar,
    String? userEmail,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      lastSeen: lastSeen ?? this.lastSeen,
      isTrusted: isTrusted ?? this.isTrusted,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
