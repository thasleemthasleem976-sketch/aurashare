import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'theme/app_theme.dart';
import 'routes/app_router.dart';

import 'services/local_storage_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/network_discovery_service.dart';
import 'services/socket_transfer_service.dart';

import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/device_provider.dart';
import 'providers/file_management_provider.dart';
import 'providers/transfer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Local Storage (Offline DB)
  final storageService = LocalStorageService();
  await storageService.init();

  // 2. Initialize Core Services
  final authService = AuthService(storageService);
  final notificationService = NotificationService(storageService);
  final settings = await storageService.getSettings();

  final localDeviceId = 'aura_dev_${const Uuid().v4().substring(0, 8)}';

  // 3. Network Discovery Service (UDP Beacons)
  final discoveryService = NetworkDiscoveryService(
    discoveryPort: settings.discoveryPort,
    transferPort: settings.transferPort,
    localDeviceId: localDeviceId,
    getLocalDeviceName: () => authService.currentUser?.deviceName ?? settings.deviceName,
    getLocalUserEmail: () => authService.currentUser?.email ?? 'offline@aurashare.local',
  );
  await discoveryService.init();

  // Late-reference holder for TransferProvider to bind with SocketTransferService callbacks
  TransferProvider? transferProviderRef;

  // 4. Socket Transfer Service (TCP Streaming Server)
  final transferService = SocketTransferService(
    port: settings.transferPort,
    localDeviceId: localDeviceId,
    localDeviceName: authService.currentUser?.deviceName ?? settings.deviceName,
    onIncomingTransfer: (session, respond) {
      if (settings.autoAccept && settings.trustedDeviceIds.contains(session.peerDeviceId)) {
        respond(true);
      } else {
        transferProviderRef?.handleIncomingTransfer(session, respond);
      }
    },
    onTransferProgress: (session) {
      transferProviderRef?.updateProgress(session);
    },
    onTransferComplete: (session) {
      transferProviderRef?.onTransferCompleted(session);
    },
    onTransferError: (session, error) {
      transferProviderRef?.onTransferError(session, error);
    },
  );

  // Start background TCP socket server if not running on Web
  if (!kIsWeb) {
    transferService.startServer();
  }

  runApp(
    AuraShareRoot(
      storageService: storageService,
      authService: authService,
      notificationService: notificationService,
      discoveryService: discoveryService,
      transferService: transferService,
      onTransferProviderCreated: (provider) {
        transferProviderRef = provider;
      },
    ),
  );
}

class AuraShareRoot extends StatelessWidget {
  final LocalStorageService storageService;
  final AuthService authService;
  final NotificationService notificationService;
  final NetworkDiscoveryService discoveryService;
  final SocketTransferService transferService;
  final ValueChanged<TransferProvider> onTransferProviderCreated;

  const AuraShareRoot({
    super.key,
    required this.storageService,
    required this.authService,
    required this.notificationService,
    required this.discoveryService,
    required this.transferService,
    required this.onTransferProviderCreated,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storageService),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(notificationService, storageService),
        ),
        ChangeNotifierProvider<DeviceProvider>(
          create: (_) => DeviceProvider(discoveryService, storageService),
        ),
        ChangeNotifierProvider<FileManagementProvider>(
          create: (_) => FileManagementProvider(),
        ),
        ChangeNotifierProvider<TransferProvider>(
          create: (_) {
            final provider = TransferProvider(transferService, storageService, notificationService);
            onTransferProviderCreated(provider);
            return provider;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp.router(
            title: 'AuraShare',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
