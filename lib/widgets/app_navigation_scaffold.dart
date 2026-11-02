import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/transfer_provider.dart';
import 'incoming_transfer_dialog.dart';

class NavigationItem {
  final String title;
  final IconData icon;
  final String route;
  final bool isSecondary;

  const NavigationItem({
    required this.title,
    required this.icon,
    required this.route,
    this.isSecondary = false,
  });
}

class AppNavigationScaffold extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const AppNavigationScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  static const List<NavigationItem> primaryNavItems = [
    NavigationItem(title: 'Dashboard', icon: Icons.dashboard_outlined, route: '/dashboard'),
    NavigationItem(title: 'Send & Receive', icon: Icons.swap_horiz, route: '/transfer'),
    NavigationItem(title: 'File Management', icon: Icons.folder_open, route: '/files'),
    NavigationItem(title: 'Device Radar', icon: Icons.radar, route: '/discovery'),
    NavigationItem(title: 'Transfer History', icon: Icons.history, route: '/history'),
  ];

  static const List<NavigationItem> secondaryNavItems = [
    NavigationItem(title: 'Security Center', icon: Icons.shield_outlined, route: '/security', isSecondary: true),
    NavigationItem(title: 'Offline Communication', icon: Icons.wifi_off_outlined, route: '/offline-comm', isSecondary: true),
    NavigationItem(title: 'Notifications', icon: Icons.notifications_none, route: '/notifications', isSecondary: true),
    NavigationItem(title: 'Settings', icon: Icons.settings_outlined, route: '/settings', isSecondary: true),
    NavigationItem(title: 'Profile', icon: Icons.person_outline, route: '/profile', isSecondary: true),
    NavigationItem(title: 'Help & Support', icon: Icons.help_outline, route: '/help', isSecondary: true),
    NavigationItem(title: 'Developer Information', icon: Icons.code, route: '/developer', isSecondary: true),
  ];

  @override
  Widget build(BuildContext context) {
    final transferProvider = context.watch<TransferProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final authProvider = context.watch<AuthProvider>();

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Stack(
      children: [
        Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  leading: Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.share, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AuraShare',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  actions: [
                    // Offline LAN badge
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(radius: 4, backgroundColor: AppColors.success),
                          const SizedBox(width: 5),
                          Text(
                            deviceProvider.localIp,
                            style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Notifications Bell
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_none),
                          if (notificationProvider.unreadCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                child: Text(
                                  '${notificationProvider.unreadCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () => context.go('/notifications'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
          drawer: isDesktop ? null : _buildDrawer(context, authProvider, notificationProvider),
          body: Row(
            children: [
              if (isDesktop) _buildDesktopSidebar(context, authProvider, notificationProvider, deviceProvider),
              Expanded(
                child: child,
              ),
            ],
          ),
          bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(context),
        ),

        // Global Overlay for Incoming Transfer Request
        if (transferProvider.pendingIncomingSession != null)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.65),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: IncomingTransferDialog(
                    session: transferProvider.pendingIncomingSession!,
                    onAccept: () => transferProvider.acceptIncomingTransfer(),
                    onReject: () => transferProvider.rejectIncomingTransfer(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    AuthProvider authProvider,
    NotificationProvider notificationProvider,
    DeviceProvider deviceProvider,
  ) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(right: BorderSide(color: AppColors.borderDark)),
      ),
      child: Column(
        children: [
          // AuraShare Header / Brand
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'AuraShare',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Secure Offline Transfer',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Offline LAN Status Pill
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 4, backgroundColor: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Local LAN Node',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
                      ),
                      Text(
                        '${deviceProvider.localIp}:52346',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.offline_bolt, color: AppColors.primary, size: 16),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(indent: 16, endIndent: 16),

          // Primary Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'MAIN OPERATIONS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, letterSpacing: 1),
                  ),
                ),
                ...primaryNavItems.map((item) => _buildNavItem(context, item)),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'SECURITY & PREFERENCES',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, letterSpacing: 1),
                  ),
                ),
                ...secondaryNavItems.map((item) {
                  final badgeCount = item.route == '/notifications' ? notificationProvider.unreadCount : null;
                  return _buildNavItem(context, item, badgeCount: badgeCount);
                }),
              ],
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // User Footer & Logout
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    authProvider.currentUser?.fullName.isNotEmpty == true
                        ? authProvider.currentUser!.fullName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.currentUser?.fullName ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authProvider.currentUser?.deviceName ?? 'Offline Device',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
                  tooltip: 'Logout',
                  onPressed: () async {
                    await authProvider.logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavigationItem item, {int? badgeCount}) {
    final isSelected = currentRoute == item.route;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withOpacity(0.12),
        leading: Icon(
          item.icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
          size: 20,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
        trailing: badgeCount != null && badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
        onTap: () => context.go(item.route),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    AuthProvider authProvider,
    NotificationProvider notificationProvider,
  ) {
    return Drawer(
      backgroundColor: AppColors.surfaceDark,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                authProvider.currentUser?.fullName.isNotEmpty == true
                    ? authProvider.currentUser!.fullName[0].toUpperCase()
                    : 'A',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ),
            accountName: Text(authProvider.currentUser?.fullName ?? 'AuraShare User'),
            accountEmail: Text(authProvider.currentUser?.email ?? 'offline@aurashare.local'),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...primaryNavItems.map((item) => _buildDrawerTile(context, item)),
                const Divider(),
                ...secondaryNavItems.map((item) {
                  final badgeCount = item.route == '/notifications' ? notificationProvider.unreadCount : null;
                  return _buildDrawerTile(context, item, badgeCount: badgeCount);
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text('Logout', style: TextStyle(color: AppColors.error)),
                  onTap: () async {
                    Navigator.pop(context);
                    await authProvider.logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(BuildContext context, NavigationItem item, {int? badgeCount}) {
    final isSelected = currentRoute == item.route;
    return ListTile(
      leading: Icon(item.icon, color: isSelected ? AppColors.primary : null),
      title: Text(item.title, style: TextStyle(color: isSelected ? AppColors.primary : null)),
      trailing: badgeCount != null && badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        context.go(item.route);
      },
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    int getIndex() {
      switch (currentRoute) {
        case '/dashboard':
          return 0;
        case '/discovery':
          return 1;
        case '/files':
          return 2;
        case '/transfer':
          return 3;
        case '/history':
          return 4;
        default:
          return 0;
      }
    }

    return NavigationBar(
      selectedIndex: getIndex(),
      backgroundColor: AppColors.surfaceDark,
      indicatorColor: AppColors.primary.withOpacity(0.2),
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/dashboard');
            break;
          case 1:
            context.go('/discovery');
            break;
          case 2:
            context.go('/files');
            break;
          case 3:
            context.go('/transfer');
            break;
          case 4:
            context.go('/history');
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: AppColors.primary), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.radar), selectedIcon: Icon(Icons.radar, color: AppColors.primary), label: 'Radar'),
        NavigationDestination(icon: Icon(Icons.folder_open), selectedIcon: Icon(Icons.folder, color: AppColors.primary), label: 'Files'),
        NavigationDestination(icon: Icon(Icons.swap_horiz), selectedIcon: Icon(Icons.swap_horiz, color: AppColors.primary), label: 'Transfer'),
        NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history, color: AppColors.primary), label: 'History'),
      ],
    );
  }
}
