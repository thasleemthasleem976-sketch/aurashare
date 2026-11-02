import 'dart:async';
import 'package:flutter/material.dart';
import '../models/file_item_model.dart';
import '../models/transfer_session_model.dart';
import '../services/socket_transfer_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class TransferProvider extends ChangeNotifier {
  final SocketTransferService _transferService;
  final LocalStorageService _storage;
  final NotificationService _notificationService;

  TransferSessionModel? _activeSession;
  TransferSessionModel? _pendingIncomingSession;
  void Function(bool accept)? _pendingIncomingResponseCallback;

  List<TransferSessionModel> _history = [];
  bool _isLoadingHistory = true;

  TransferProvider(
    this._transferService,
    this._storage,
    this._notificationService,
  ) {
    _init();
  }

  TransferSessionModel? get activeSession => _activeSession;
  TransferSessionModel? get pendingIncomingSession => _pendingIncomingSession;
  List<TransferSessionModel> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;

  int get totalSentBytes => _history
      .where((s) => s.type == TransferType.sent && s.status == TransferStatus.completed)
      .fold<int>(0, (sum, s) => sum + s.totalBytes);

  int get totalReceivedBytes => _history
      .where((s) => s.type == TransferType.received && s.status == TransferStatus.completed)
      .fold<int>(0, (sum, s) => sum + s.totalBytes);

  int get totalSentFilesCount => _history
      .where((s) => s.type == TransferType.sent && s.status == TransferStatus.completed)
      .fold<int>(0, (sum, s) => sum + s.files.length);

  int get totalReceivedFilesCount => _history
      .where((s) => s.type == TransferType.received && s.status == TransferStatus.completed)
      .fold<int>(0, (sum, s) => sum + s.files.length);

  Future<void> _init() async {
    _isLoadingHistory = true;
    notifyListeners();
    _history = await _storage.getTransferHistory();
    _isLoadingHistory = false;
    notifyListeners();
  }

  /// Receiver: incoming transfer request hook called by SocketTransferService
  void handleIncomingTransfer(
    TransferSessionModel session,
    void Function(bool accept) respond,
  ) {
    _pendingIncomingSession = session;
    _pendingIncomingResponseCallback = respond;

    _notificationService.notify(
      title: 'Incoming File Request',
      message: '${session.peerDeviceName} wants to send ${session.files.length} file(s) (${session.formattedTotalSize})',
      type: NotificationType.incomingFile,
      metadata: {'sessionId': session.id},
    );

    notifyListeners();
  }

  void acceptIncomingTransfer() {
    if (_pendingIncomingResponseCallback != null && _pendingIncomingSession != null) {
      _activeSession = _pendingIncomingSession;
      _pendingIncomingResponseCallback!(true);
      _pendingIncomingSession = null;
      _pendingIncomingResponseCallback = null;

      _notificationService.notify(
        title: 'Transfer Started',
        message: 'Receiving files from ${_activeSession!.peerDeviceName}...',
        type: NotificationType.transferStarted,
      );

      notifyListeners();
    }
  }

  void rejectIncomingTransfer() {
    if (_pendingIncomingResponseCallback != null) {
      _pendingIncomingResponseCallback!(false);
      _pendingIncomingSession = null;
      _pendingIncomingResponseCallback = null;
      notifyListeners();
    }
  }

  /// Sender: send list of files to peer
  Future<TransferSessionModel> startSend({
    required String peerIp,
    required int peerPort,
    required String peerDeviceId,
    required String peerDeviceName,
    required List<FileItemModel> files,
  }) async {
    final session = await _transferService.sendFiles(
      peerIp: peerIp,
      peerPort: peerPort,
      peerDeviceId: peerDeviceId,
      peerDeviceName: peerDeviceName,
      files: files,
    );
    _activeSession = session;

    _notificationService.notify(
      title: 'Transfer Request Sent',
      message: 'Sending ${files.length} file(s) to $peerDeviceName...',
      type: NotificationType.transferStarted,
    );

    notifyListeners();
    return session;
  }

  void updateProgress(TransferSessionModel session) {
    _activeSession = session;
    notifyListeners();
  }

  Future<void> onTransferCompleted(TransferSessionModel session) async {
    _activeSession = null;
    await _storage.saveTransferRecord(session);
    _history = await _storage.getTransferHistory();

    _notificationService.notify(
      title: 'Transfer Completed',
      message: 'Successfully transferred ${session.files.length} file(s) (${session.formattedTotalSize})',
      type: NotificationType.transferCompleted,
    );

    notifyListeners();
  }

  Future<void> onTransferError(TransferSessionModel session, String error) async {
    _activeSession = null;
    await _storage.saveTransferRecord(session);
    _history = await _storage.getTransferHistory();

    _notificationService.notify(
      title: 'Transfer Failed',
      message: error,
      type: NotificationType.transferFailed,
    );

    notifyListeners();
  }

  void pauseTransfer() {
    if (_activeSession != null) {
      _transferService.pauseTransfer(_activeSession!.id);
      notifyListeners();
    }
  }

  void resumeTransfer() {
    if (_activeSession != null) {
      _transferService.resumeTransfer(_activeSession!.id);
      notifyListeners();
    }
  }

  void cancelTransfer() {
    if (_activeSession != null) {
      _transferService.cancelTransfer(_activeSession!.id);
      _activeSession = null;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    await _storage.clearHistory();
    _history.clear();
    notifyListeners();
  }
}
