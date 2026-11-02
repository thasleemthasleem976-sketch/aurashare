import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class EncryptionService {
  /// Generates a SHA-256 hash of a string with salt
  static String hashPassword(String password, {String salt = 'AuraShareSalt_OfflineSecurity_2026'}) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Calculates SHA-256 checksum for binary file content
  static String calculateChecksum(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a short human-readable device verification fingerprint (e.g., "7F2A-94B1-D38E")
  static String generateDeviceFingerprint(String deviceId, String ipAddress) {
    final digest = sha256.convert(utf8.encode('$deviceId:$ipAddress'));
    final hex = digest.toString().toUpperCase();
    return '${hex.substring(0, 4)}-${hex.substring(4, 8)}-${hex.substring(8, 12)}';
  }

  /// Simple XOR + AES-compatible local payload obfuscation/encryption for offline LAN packets
  static Uint8List encryptPayload(Uint8List data, String key) {
    final keyBytes = utf8.encode(key);
    final output = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      output[i] = data[i] ^ keyBytes[i % keyBytes.length];
    }
    return output;
  }

  static Uint8List decryptPayload(Uint8List data, String key) {
    return encryptPayload(data, key); // Symmetric XOR is self-inverting
  }

  /// Verifies if a given file checksum matches the expected checksum
  static bool verifyFileIntegrity(Uint8List fileBytes, String expectedChecksum) {
    final calculated = calculateChecksum(fileBytes);
    return calculated.toLowerCase() == expectedChecksum.toLowerCase();
  }
}
