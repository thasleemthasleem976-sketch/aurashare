class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String deviceName;
  final String avatar;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.deviceName,
    required this.avatar,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'passwordHash': passwordHash,
      'deviceName': deviceName,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      deviceName: json['deviceName'] as String? ?? 'AuraDevice',
      avatar: json['avatar'] as String? ?? 'device_laptop',
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? passwordHash,
    String? deviceName,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      deviceName: deviceName ?? this.deviceName,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
