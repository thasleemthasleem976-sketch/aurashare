import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'local_storage_service.dart';
import 'encryption_service.dart';

class AuthService {
  final LocalStorageService _storage;
  UserModel? _currentUser;

  AuthService(this._storage);

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<UserModel?> checkCurrentSession() async {
    final email = await _storage.getCurrentUserEmail();
    if (email != null) {
      _currentUser = await _storage.getUserByEmail(email);
    }
    return _currentUser;
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String deviceName,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedName.isEmpty) {
      throw Exception('Full Name is required');
    }
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      throw Exception('Please enter a valid email address');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    final existing = await _storage.getUserByEmail(trimmedEmail);
    if (existing != null) {
      throw Exception('An account with this email already exists on this device');
    }

    final newUser = UserModel(
      id: const Uuid().v4(),
      fullName: trimmedName,
      email: trimmedEmail,
      passwordHash: EncryptionService.hashPassword(password),
      deviceName: deviceName.trim().isEmpty ? 'AuraDevice' : deviceName.trim(),
      avatar: 'avatar_${(trimmedName.length % 5) + 1}',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    await _storage.saveUser(newUser);
    await _storage.setCurrentUserEmail(newUser.email);
    _currentUser = newUser;
    return newUser;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw Exception('Email and Password are required');
    }

    final user = await _storage.getUserByEmail(trimmedEmail);
    if (user == null) {
      throw Exception('No account found for this email. Please register first.');
    }

    final hashed = EncryptionService.hashPassword(password);
    if (user.passwordHash != hashed) {
      throw Exception('Invalid password. Please check your credentials.');
    }

    final updated = user.copyWith(lastLogin: DateTime.now());
    await _storage.saveUser(updated);
    await _storage.setCurrentUserEmail(updated.email);
    _currentUser = updated;
    return updated;
  }

  Future<void> updateProfile({
    String? fullName,
    String? deviceName,
    String? avatar,
  }) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(
      fullName: fullName,
      deviceName: deviceName,
      avatar: avatar,
    );
    await _storage.saveUser(updated);
    _currentUser = updated;
  }

  Future<void> logout() async {
    await _storage.setCurrentUserEmail(null);
    _currentUser = null;
  }
}
