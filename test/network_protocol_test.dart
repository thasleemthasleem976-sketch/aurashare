import 'package:test/test.dart';
import '../lib/models/device_model.dart';
import '../lib/models/file_item_model.dart';
import '../lib/models/transfer_session_model.dart';

void main() {
  group('Network & Model Protocol Tests', () {
    test('DeviceModel serializes and deserializes correctly', () {
      final now = DateTime.now();
      final device = DeviceModel(
        id: 'dev_win_01',
        name: "Alex's PC",
        platform: DevicePlatform.windows,
        ipAddress: '192.168.1.55',
        port: 52346,
        lastSeen: now,
        isTrusted: true,
      );

      final json = device.toJson();
      expect(json['id'], equals('dev_win_01'));
      expect(json['platform'], equals('windows'));
      expect(json['isTrusted'], isTrue);

      final parsed = DeviceModel.fromJson(json);
      expect(parsed.name, equals("Alex's PC"));
      expect(parsed.platform, equals(DevicePlatform.windows));
      expect(parsed.ipAddress, equals('192.168.1.55'));
    });

    test('FileItemModel categories and size formatting are accurate', () {
      final docFile = FileItemModel(
        id: '1',
        name: 'Report.pdf',
        path: '/docs/Report.pdf',
        size: 5 * 1024 * 1024, // 5 MB
        extension: 'pdf',
        category: FileCategory.fromExtension('pdf'),
      );

      expect(docFile.category, equals(FileCategory.document));
      expect(docFile.formattedSize, equals('5.00 MB'));

      final videoFile = FileItemModel(
        id: '2',
        name: 'Presentation.mp4',
        path: '/videos/Presentation.mp4',
        size: 1500 * 1024 * 1024, // 1.46 GB
        extension: 'mp4',
        category: FileCategory.fromExtension('mp4'),
      );

      expect(videoFile.category, equals(FileCategory.video));
      expect(videoFile.formattedSize, equals('1.46 GB'));
    });

    test('TransferSessionModel speed and ETA calculations', () {
      final session = TransferSessionModel(
        id: 'session_001',
        type: TransferType.sent,
        peerDeviceId: 'peer_android',
        peerDeviceName: "Vishnu's Phone",
        peerIp: '192.168.1.72',
        files: [],
        totalBytes: 100 * 1024 * 1024, // 100 MB
        transferredBytes: 50 * 1024 * 1024, // 50 MB
        progress: 0.5,
        speedBytesPerSec: 10 * 1024 * 1024, // 10 MB/s
        etaSeconds: 5,
        startedAt: DateTime.now(),
      );

      expect(session.formattedSpeed, equals('10.00 MB/s'));
      expect(session.formattedEta, equals('5s'));
      expect(session.formattedTotalSize, equals('100.00 MB'));
      expect(session.formattedTransferredSize, equals('50.00 MB'));
    });
  });
}
