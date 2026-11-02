import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import '../lib/services/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    test('Password hashing produces consistent SHA-256 digests', () {
      final hash1 = EncryptionService.hashPassword('MySecurePassword123');
      final hash2 = EncryptionService.hashPassword('MySecurePassword123');
      final hash3 = EncryptionService.hashPassword('DifferentPassword');

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
      expect(hash1.length, equals(64)); // SHA-256 hex string length
    });

    test('File checksum verification matches data content', () {
      final sampleData = utf8.encode('AuraShare secure offline file transfer payload');
      final checksum = EncryptionService.calculateChecksum(sampleData);

      expect(checksum.length, equals(64));
      expect(EncryptionService.verifyFileIntegrity(sampleData, checksum), isTrue);

      final corruptedData = utf8.encode('AuraShare corrupted file payload');
      expect(EncryptionService.verifyFileIntegrity(corruptedData, checksum), isFalse);
    });

    test('Device fingerprint generation is deterministic', () {
      final fp1 = EncryptionService.generateDeviceFingerprint('dev_123', '192.168.1.10');
      final fp2 = EncryptionService.generateDeviceFingerprint('dev_123', '192.168.1.10');
      final fp3 = EncryptionService.generateDeviceFingerprint('dev_456', '192.168.1.10');

      expect(fp1, equals(fp2));
      expect(fp1, isNot(equals(fp3)));
      expect(fp1, matches(RegExp(r'^[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$')));
    });

    test('Payload encryption & decryption is symmetric', () {
      final original = utf8.encode('Sensitive offline packet chunk payload');
      const key = 'AuraSecretKey2026';

      final encrypted = EncryptionService.encryptPayload(original, key);
      expect(encrypted, isNot(equals(original)));

      final decrypted = EncryptionService.decryptPayload(encrypted, key);
      expect(utf8.decode(decrypted), equals('Sensitive offline packet chunk payload'));
    });
  });
}
