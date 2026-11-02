import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/device_discovery_screen.dart';
import '../screens/file_management_screen.dart';
import '../screens/file_transfer_screen.dart';
import '../screens/transfer_history_screen.dart';
import '../screens/security_center_screen.dart';
import '../screens/offline_communication_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/developer_info_screen.dart';
import '../widgets/app_navigation_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppNavigationScaffold(
          currentRoute: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/discovery',
          builder: (context, state) => const DeviceDiscoveryScreen(),
        ),
        GoRoute(
          path: '/files',
          builder: (context, state) => const FileManagementScreen(),
        ),
        GoRoute(
          path: '/transfer',
          builder: (context, state) => const FileTransferScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const TransferHistoryScreen(),
        ),
        GoRoute(
          path: '/security',
          builder: (context, state) => const SecurityCenterScreen(),
        ),
        GoRoute(
          path: '/offline-comm',
          builder: (context, state) => const OfflineCommunicationScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/help',
          builder: (context, state) => const HelpSupportScreen(),
        ),
        GoRoute(
          path: '/developer',
          builder: (context, state) => const DeveloperInfoScreen(),
        ),
      ],
    ),
  ],
);
