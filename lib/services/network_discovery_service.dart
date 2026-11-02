import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/device_model.dart';

class NetworkDiscoveryService {
  final int discoveryPort;
  final int transferPort;
  final String localDeviceId;
  final String Function() getLocalDeviceName;
  final String Function() getLocalUserEmail;

  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _listenSocket;
  Timer? _beaconTimer;
  Timer? _pruneTimer;

  final Map<String, DeviceModel> _discoveredDevices = {};
  final _devicesStreamController = StreamController<List<DeviceModel>>.broadcast();

  bool _isScanning = false;
  String _localIp = '127.0.0.1';

  NetworkDiscoveryService({
    this.discoveryPort = 52345,
    this.transferPort = 52346,
    required this.localDeviceId,
    required this.getLocalDeviceName,
    required this.getLocalUserEmail,
  });

  Stream<List<DeviceModel>> get devicesStream => _devicesStreamController.stream;
  List<DeviceModel> get currentDevices => _discoveredDevices.values.toList();
  bool get isScanning => _isScanning;
  String get localIp => _localIp;
  bool get isSupported => !kIsWeb;

  Future<void> init() async {
    if (kIsWeb) return;
    await _detectLocalIp();
  }

  Future<void> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.isNotEmpty) {
            _localIp = addr.address;
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[NetworkDiscovery] Error detecting local IP: $e');
    }
  }

  Future<void> startDiscovery() async {
    if (kIsWeb) {
      debugPrint('[NetworkDiscovery] Discovery is disabled on Web due to browser sandbox');
      return;
    }

    if (_isScanning) return;
    _isScanning = true;

    await _detectLocalIp();

    try {
      // 1. Setup Listener Socket
      _listenSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
        reusePort: !Platform.isWindows, // reusePort not supported on Windows
      );
      _listenSocket?.broadcastEnabled = true;

      _listenSocket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _listenSocket?.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram);
          }
        }
      });

      // 2. Setup Broadcast Socket
      _broadcastSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      _broadcastSocket?.broadcastEnabled = true;

      // 3. Send immediate beacon & start periodic beacon
      _sendBeacon();
      _beaconTimer = Timer.periodic(const Duration(seconds: 3), (_) => _sendBeacon());

      // 4. Periodically prune inactive devices (stale after 12s)
      _pruneTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pruneStaleDevices());
    } catch (e) {
      debugPrint('[NetworkDiscovery] Start discovery failed: $e');
      _isScanning = false;
    }
  }

  void _sendBeacon() {
    if (_broadcastSocket == null || !_isScanning) return;

    try {
      final payload = jsonEncode({
        'aura_protocol': 'aurashare_v1',
        'type': 'AURASHARE_BEACON',
        'id': localDeviceId,
        'name': getLocalDeviceName(),
        'platform': _getCurrentPlatformString(),
        'ip': _localIp,
        'port': transferPort,
        'email': getLocalUserEmail(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      final bytes = utf8.encode(payload);
      _broadcastSocket?.send(
        bytes,
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );
    } catch (e) {
      debugPrint('[NetworkDiscovery] Error sending beacon: $e');
    }
  }

  void _handleIncomingPacket(Datagram datagram) {
    try {
      final msg = utf8.decode(datagram.data);
      final json = jsonDecode(msg) as Map<String, dynamic>;

      if (json['aura_protocol'] != 'aurashare_v1') return;

      final senderId = json['id'] as String?;
      if (senderId == null || senderId == localDeviceId) {
        // Ignore self packet
        return;
      }

      final senderIp = datagram.address.address;
      final senderPort = json['port'] as int? ?? transferPort;
      final senderName = json['name'] as String? ?? 'Nearby Device';
      final platformStr = json['platform'] as String? ?? 'unknown';

      final device = DeviceModel(
        id: senderId,
        name: senderName,
        platform: DevicePlatform.fromString(platformStr),
        ipAddress: senderIp,
        port: senderPort,
        lastSeen: DateTime.now(),
        status: DeviceConnectionStatus.available,
        userEmail: json['email'] as String?,
      );

      _discoveredDevices[senderId] = device;
      _devicesStreamController.add(currentDevices);
    } catch (e) {
      debugPrint('[NetworkDiscovery] Packet parse error: $e');
    }
  }

  void _pruneStaleDevices() {
    final now = DateTime.now();
    final toRemove = <String>[];
    _discoveredDevices.forEach((id, device) {
      if (now.difference(device.lastSeen).inSeconds > 12) {
        toRemove.add(id);
      }
    });

    if (toRemove.isNotEmpty) {
      for (var id in toRemove) {
        _discoveredDevices.remove(id);
      }
      _devicesStreamController.add(currentDevices);
    }
  }

  /// Direct manual IP probe / connect
  Future<DeviceModel?> probeDirectIp(String ip, {int port = 52346}) async {
    if (kIsWeb) return null;
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 2));
      // Send handshake ping
      final ping = jsonEncode({
        'action': 'PING',
        'id': localDeviceId,
        'name': getLocalDeviceName(),
        'platform': _getCurrentPlatformString(),
      });
      socket.write('$ping\n');
      await socket.flush();

      // Read response
      final completer = Completer<DeviceModel?>();
      socket.listen((data) {
        try {
          final res = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
          final dev = DeviceModel(
            id: res['id'] as String? ?? ip,
            name: res['name'] as String? ?? 'Direct Host ($ip)',
            platform: DevicePlatform.fromString(res['platform'] as String? ?? 'unknown'),
            ipAddress: ip,
            port: port,
            lastSeen: DateTime.now(),
            status: DeviceConnectionStatus.available,
          );
          _discoveredDevices[dev.id] = dev;
          _devicesStreamController.add(currentDevices);
          if (!completer.isCompleted) completer.complete(dev);
        } catch (_) {
          if (!completer.isCompleted) completer.complete(null);
        }
      }, onError: (_) {
        if (!completer.isCompleted) completer.complete(null);
      });

      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('[NetworkDiscovery] Direct IP probe failed: $e');
      return null;
    }
  }

  Future<void> stopDiscovery() async {
    _isScanning = false;
    _beaconTimer?.cancel();
    _pruneTimer?.cancel();
    _listenSocket?.close();
    _broadcastSocket?.close();
    _listenSocket = null;
    _broadcastSocket = null;
    _discoveredDevices.clear();
    _devicesStreamController.add([]);
  }

  String _getCurrentPlatformString() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  void dispose() {
    stopDiscovery();
    _devicesStreamController.close();
  }
}
