import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_item_model.dart';
import '../models/transfer_session_model.dart';
import 'encryption_service.dart';

typedef IncomingTransferCallback = void Function(
  TransferSessionModel session,
  void Function(bool accept) respond,
);

class SocketTransferService {
  final int port;
  final String localDeviceId;
  final String localDeviceName;
  final IncomingTransferCallback onIncomingTransfer;
  final void Function(TransferSessionModel session) onTransferProgress;
  final void Function(TransferSessionModel session) onTransferComplete;
  final void Function(TransferSessionModel session, String error) onTransferError;

  ServerSocket? _serverSocket;
  bool _isRunning = false;

  // Active sessions tracking
  final Map<String, TransferSessionModel> _activeSessions = {};
  final Map<String, Socket> _activeSockets = {};
  final Map<String, bool> _pausedSessions = {};
  final Map<String, bool> _cancelledSessions = {};

  SocketTransferService({
    this.port = 52346,
    required this.localDeviceId,
    required this.localDeviceName,
    required this.onIncomingTransfer,
    required this.onTransferProgress,
    required this.onTransferComplete,
    required this.onTransferError,
  });

  bool get isRunning => _isRunning;

  Future<void> startServer() async {
    if (kIsWeb || _isRunning) return;

    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _isRunning = true;
      debugPrint('[SocketTransfer] Server listening on port $port');

      _serverSocket?.listen((socket) {
        _handleIncomingConnection(socket);
      }, onError: (e) {
        debugPrint('[SocketTransfer] Server socket error: $e');
      });
    } catch (e) {
      debugPrint('[SocketTransfer] Failed to bind server socket: $e');
    }
  }

  void _handleIncomingConnection(Socket socket) {
    StringBuffer buffer = StringBuffer();
    bool isInTransferMode = false;
    TransferSessionModel? currentSession;
    IOSink? currentFileWriter;
    File? currentOutputFile;
    int receivedBytesForCurrentFile = 0;
    int expectedFileSize = 0;
    String expectedChecksum = '';

    socket.listen((data) async {
      if (!isInTransferMode) {
        buffer.write(utf8.decode(data, allowMalformed: true));
        final content = buffer.toString();

        if (content.contains('\n')) {
          final lines = content.split('\n');
          for (var i = 0; i < lines.length - 1; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;

            try {
              final json = jsonDecode(line) as Map<String, dynamic>;
              final action = json['action'] as String?;

              if (action == 'PING') {
                final pong = jsonEncode({
                  'status': 'PONG',
                  'id': localDeviceId,
                  'name': localDeviceName,
                });
                socket.write('$pong\n');
                await socket.flush();
                socket.close();
                return;
              }

              if (action == 'TRANSFER_REQUEST') {
                final sessionId = json['sessionId'] as String;
                final senderName = json['senderName'] as String? ?? 'Nearby Device';
                final senderId = json['senderId'] as String? ?? 'unknown';
                final filesRaw = json['files'] as List<dynamic>? ?? [];

                final files = filesRaw.map((f) {
                  return FileItemModel(
                    id: f['id'] as String,
                    name: f['name'] as String,
                    path: '',
                    size: f['size'] as int,
                    extension: (f['name'] as String).split('.').last,
                    category: FileCategory.fromExtension((f['name'] as String).split('.').last),
                    checksumSha256: f['checksum'] as String?,
                  );
                }).toList();

                final totalBytes = files.fold<int>(0, (sum, f) => sum + f.size);

                currentSession = TransferSessionModel(
                  id: sessionId,
                  type: TransferType.received,
                  peerDeviceId: senderId,
                  peerDeviceName: senderName,
                  peerIp: socket.remoteAddress.address,
                  files: files,
                  totalBytes: totalBytes,
                  status: TransferStatus.requesting,
                  startedAt: DateTime.now(),
                );

                _activeSessions[sessionId] = currentSession!;
                _activeSockets[sessionId] = socket;

                onIncomingTransfer(currentSession!, (accept) async {
                  if (accept) {
                    currentSession!.status = TransferStatus.transferring;
                    final acceptMsg = jsonEncode({
                      'action': 'TRANSFER_RESPONSE',
                      'sessionId': sessionId,
                      'accepted': true,
                    });
                    socket.write('$acceptMsg\n');
                    await socket.flush();
                    isInTransferMode = true;
                    _receiveFiles(socket, currentSession!);
                  } else {
                    currentSession!.status = TransferStatus.cancelled;
                    final rejectMsg = jsonEncode({
                      'action': 'TRANSFER_RESPONSE',
                      'sessionId': sessionId,
                      'accepted': false,
                    });
                    socket.write('$rejectMsg\n');
                    await socket.flush();
                    socket.close();
                    _activeSessions.remove(sessionId);
                    _activeSockets.remove(sessionId);
                  }
                });
              }
            } catch (e) {
              debugPrint('[SocketTransfer] JSON error handling incoming line: $e');
            }
          }
          buffer = StringBuffer(lines.last);
        }
      }
    }, onError: (e) {
      if (currentSession != null) {
        currentSession!.status = TransferStatus.failed;
        currentSession!.errorMessage = e.toString();
        onTransferError(currentSession!, e.toString());
      }
    }, onDone: () {
      currentFileWriter?.close();
    });
  }

  Future<void> _receiveFiles(Socket socket, TransferSessionModel session) async {
    final saveDir = await _getSaveDirectory();
    int currentFileIdx = 0;
    int transferredOverall = 0;
    DateTime lastTime = DateTime.now();
    int bytesSinceLast = 0;

    for (var file in session.files) {
      if (_cancelledSessions[session.id] == true) {
        session.status = TransferStatus.cancelled;
        onTransferProgress(session);
        return;
      }

      session.currentFileIndex = currentFileIdx;
      final targetFile = File('${saveDir.path}/${file.name}');
      final sink = targetFile.openWrite();
      int fileBytesReceived = 0;

      final fileCompleter = Completer<void>();

      late StreamSubscription sub;
      sub = socket.listen((chunk) {
        if (_cancelledSessions[session.id] == true) {
          sub.cancel();
          sink.close();
          targetFile.delete().ignore();
          fileCompleter.complete();
          return;
        }

        sink.add(chunk);
        fileBytesReceived += chunk.length;
        transferredOverall += chunk.length;
        bytesSinceLast += chunk.length;

        final now = DateTime.now();
        final ms = now.difference(lastTime).inMilliseconds;
        if (ms >= 500) {
          final speed = (bytesSinceLast / (ms / 1000.0));
          session.transferredBytes = transferredOverall;
          session.progress = (transferredOverall / session.totalBytes).clamp(0.0, 1.0);
          session.speedBytesPerSec = speed;
          final remainingBytes = session.totalBytes - transferredOverall;
          session.etaSeconds = speed > 0 ? (remainingBytes / speed).ceil() : 0;
          onTransferProgress(session);
          bytesSinceLast = 0;
          lastTime = now;
        }

        if (fileBytesReceived >= file.size) {
          sub.pause();
          sink.flush().then((_) {
            sink.close().then((_) {
              fileCompleter.complete();
            });
          });
        }
      });

      await fileCompleter.future;
      currentFileIdx++;
    }

    session.status = TransferStatus.completed;
    session.completedAt = DateTime.now();
    session.progress = 1.0;
    session.transferredBytes = session.totalBytes;
    onTransferComplete(session);
    _cleanupSession(session.id);
  }

  /// SENDER: Send files to peer device
  Future<TransferSessionModel> sendFiles({
    required String peerIp,
    required int peerPort,
    required String peerDeviceId,
    required String peerDeviceName,
    required List<FileItemModel> files,
  }) async {
    final sessionId = 'aura_${DateTime.now().millisecondsSinceEpoch}';
    final totalBytes = files.fold<int>(0, (sum, f) => sum + f.size);

    final session = TransferSessionModel(
      id: sessionId,
      type: TransferType.sent,
      peerDeviceId: peerDeviceId,
      peerDeviceName: peerDeviceName,
      peerIp: peerIp,
      files: files,
      totalBytes: totalBytes,
      status: TransferStatus.requesting,
      startedAt: DateTime.now(),
    );

    _activeSessions[sessionId] = session;
    _pausedSessions[sessionId] = false;
    _cancelledSessions[sessionId] = false;

    if (kIsWeb) {
      session.status = TransferStatus.failed;
      session.errorMessage = 'Socket file transfer is not supported in Web browsers.';
      onTransferError(session, session.errorMessage!);
      return session;
    }

    try {
      final socket = await Socket.connect(peerIp, peerPort, timeout: const Duration(seconds: 5));
      _activeSockets[sessionId] = socket;

      // 1. Send Handshake Request
      final requestPayload = jsonEncode({
        'action': 'TRANSFER_REQUEST',
        'sessionId': sessionId,
        'senderId': localDeviceId,
        'senderName': localDeviceName,
        'files': files.map((f) => {
          'id': f.id,
          'name': f.name,
          'size': f.size,
          'checksum': f.checksumSha256,
        }).toList(),
      });

      socket.write('$requestPayload\n');
      await socket.flush();

      // 2. Wait for receiver's response
      final completer = Completer<bool>();
      late StreamSubscription responseSub;

      StringBuffer respBuffer = StringBuffer();
      responseSub = socket.listen((data) {
        respBuffer.write(utf8.decode(data, allowMalformed: true));
        final str = respBuffer.toString();
        if (str.contains('\n')) {
          for (var line in str.split('\n')) {
            final t = line.trim();
            if (t.isEmpty) continue;
            try {
              final json = jsonDecode(t) as Map<String, dynamic>;
              if (json['action'] == 'TRANSFER_RESPONSE' && json['sessionId'] == sessionId) {
                final accepted = json['accepted'] as bool? ?? false;
                responseSub.cancel();
                completer.complete(accepted);
                break;
              }
            } catch (_) {}
          }
        }
      }, onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      });

      final accepted = await completer.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () => false,
      );

      if (!accepted) {
        session.status = TransferStatus.cancelled;
        session.errorMessage = 'Transfer request rejected or timed out by receiver.';
        onTransferError(session, session.errorMessage!);
        _cleanupSession(sessionId);
        return session;
      }

      // 3. Begin File Transmission
      session.status = TransferStatus.transferring;
      onTransferProgress(session);

      int transferredOverall = 0;
      DateTime lastTime = DateTime.now();
      int bytesSinceLast = 0;

      for (int i = 0; i < files.length; i++) {
        final fileItem = files[i];
        session.currentFileIndex = i;

        if (_cancelledSessions[sessionId] == true) {
          session.status = TransferStatus.cancelled;
          onTransferProgress(session);
          _cleanupSession(sessionId);
          return session;
        }

        // Stream file content
        final localFile = File(fileItem.path);
        if (!await localFile.exists()) {
          // If file object is in memory or missing, generate test stream or report error
          session.errorMessage = 'File not found at path: ${fileItem.path}';
          session.status = TransferStatus.failed;
          onTransferError(session, session.errorMessage!);
          _cleanupSession(sessionId);
          return session;
        }

        final fileStream = localFile.openRead();
        await for (final chunk in fileStream) {
          while (_pausedSessions[sessionId] == true) {
            await Future.delayed(const Duration(milliseconds: 200));
            if (_cancelledSessions[sessionId] == true) break;
          }

          if (_cancelledSessions[sessionId] == true) {
            break;
          }

          socket.add(chunk);
          await socket.flush();

          transferredOverall += chunk.length;
          bytesSinceLast += chunk.length;

          final now = DateTime.now();
          final ms = now.difference(lastTime).inMilliseconds;
          if (ms >= 400) {
            final speed = (bytesSinceLast / (ms / 1000.0));
            session.transferredBytes = transferredOverall;
            session.progress = (transferredOverall / totalBytes).clamp(0.0, 1.0);
            session.speedBytesPerSec = speed;
            final remainingBytes = totalBytes - transferredOverall;
            session.etaSeconds = speed > 0 ? (remainingBytes / speed).ceil() : 0;
            onTransferProgress(session);
            bytesSinceLast = 0;
            lastTime = now;
          }
        }
      }

      session.status = TransferStatus.completed;
      session.completedAt = DateTime.now();
      session.progress = 1.0;
      session.transferredBytes = totalBytes;
      onTransferComplete(session);
      _cleanupSession(sessionId);
    } catch (e) {
      session.status = TransferStatus.failed;
      session.errorMessage = e.toString();
      onTransferError(session, e.toString());
      _cleanupSession(sessionId);
    }

    return session;
  }

  void pauseTransfer(String sessionId) {
    if (_activeSessions.containsKey(sessionId)) {
      _pausedSessions[sessionId] = true;
      final session = _activeSessions[sessionId]!;
      session.status = TransferStatus.paused;
      session.speedBytesPerSec = 0;
      onTransferProgress(session);
    }
  }

  void resumeTransfer(String sessionId) {
    if (_activeSessions.containsKey(sessionId)) {
      _pausedSessions[sessionId] = false;
      final session = _activeSessions[sessionId]!;
      session.status = TransferStatus.transferring;
      onTransferProgress(session);
    }
  }

  void cancelTransfer(String sessionId) {
    _cancelledSessions[sessionId] = true;
    if (_activeSessions.containsKey(sessionId)) {
      final session = _activeSessions[sessionId]!;
      session.status = TransferStatus.cancelled;
      onTransferProgress(session);
      _cleanupSession(sessionId);
    }
  }

  Future<Directory> _getSaveDirectory() async {
    Directory baseDir;
    try {
      baseDir = (await getDownloadsDirectory()) ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir = Directory.current;
    }
    final target = Directory('${baseDir.path}/AuraShare');
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target;
  }

  void _cleanupSession(String sessionId) {
    try {
      _activeSockets[sessionId]?.close();
    } catch (_) {}
    _activeSockets.remove(sessionId);
    _pausedSessions.remove(sessionId);
    _cancelledSessions.remove(sessionId);
  }

  Future<void> stopServer() async {
    _isRunning = false;
    for (var s in _activeSockets.values) {
      try {
        s.close();
      } catch (_) {}
    }
    _activeSockets.clear();
    await _serverSocket?.close();
    _serverSocket = null;
  }
}
