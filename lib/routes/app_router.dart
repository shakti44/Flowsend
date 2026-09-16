import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/discovered_device.dart';
import '../models/selected_file.dart';
import '../models/transfer_session.dart';
import '../features/home/home_screen.dart';
import '../features/file_selection/file_selection_screen.dart';
import '../features/device_discovery/device_discovery_screen.dart';
import '../features/device_discovery/transfer_session_screen.dart';
import '../features/device_connection/device_connection_screen.dart';
import '../features/transfer/active_transfer_screen.dart';
import '../features/transfer/multi_device_transfer_screen.dart';
import '../features/transfer/smart_transfer_check_screen.dart';
import '../features/interrupted/connection_interrupted_screen.dart';
import '../features/complete/transfer_complete_screen.dart';
import '../features/receive/receive_screen.dart';
import '../features/history/transfer_history_screen.dart';
import '../features/devices/trusted_devices_screen.dart';
import '../features/settings/settings_screen.dart';

/// Named route path constants — use these throughout the app.
abstract final class AppRoutes {
  static const home = '/';
  static const selectFiles = '/select-files';
  static const chooseDevice = '/choose-device';
  static const transferSession = '/transfer-session';
  static const deviceConnection = '/device-connection';
  static const activeTransfer = '/active-transfer';
  static const multiDeviceTransfer = '/multi-device-transfer';
  static const smartTransferCheck = '/smart-transfer-check';
  static const connectionInterrupted = '/connection-interrupted';
  static const transferComplete = '/transfer-complete';
  static const receive = '/receive';
  static const history = '/history';
  static const devices = '/devices';
  static const settings = '/settings';
}

/// Application router — main navigation shell with bottom tabs.
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: [
    // Root shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) => _RootShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.history,
          name: 'history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TransferHistoryScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.devices,
          name: 'devices',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TrustedDevicesScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),

    // Transfer flow — full-page routes outside shell
    GoRoute(
      path: AppRoutes.selectFiles,
      name: 'select-files',
      builder: (context, state) => const FileSelectionScreen(),
    ),

    GoRoute(
      path: AppRoutes.chooseDevice,
      name: 'choose-device',
      builder: (context, state) {
        final files = state.extra as List<SelectedFile>? ?? [];
        return DeviceDiscoveryScreen(selectedFiles: files);
      },
    ),

    GoRoute(
      path: AppRoutes.transferSession,
      name: 'transfer-session',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return TransferSessionScreen(
          files: (extra['files'] as List<SelectedFile>?) ?? const [],
          mode: extra['mode'] as TransferSessionMode,
        );
      },
    ),

    GoRoute(
      path: AppRoutes.deviceConnection,
      name: 'device-connection',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return DeviceConnectionScreen(
          files: (extra['files'] as List<SelectedFile>?) ?? [],
          device: extra['device'] as DiscoveredDevice,
        );
      },
    ),

    GoRoute(
      path: AppRoutes.activeTransfer,
      name: 'active-transfer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ActiveTransferScreen(
          files: (extra['files'] as List<SelectedFile>?) ?? [],
          device: extra['device'] as DiscoveredDevice,
        );
      },
    ),

    GoRoute(
      path: AppRoutes.multiDeviceTransfer,
      name: 'multi-device-transfer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MultiDeviceTransferScreen(
          files: (extra['files'] as List<SelectedFile>?) ?? const [],
          devices: (extra['devices'] as List<DiscoveredDevice>?) ?? const [],
          filesByDevice: (extra['filesByDevice'] as Map<String, List<SelectedFile>>?),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.smartTransferCheck,
      name: 'smart-transfer-check',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return SmartTransferCheckScreen(
          files: (extra['files'] as List<SelectedFile>?) ?? const [],
          devices: (extra['devices'] as List<DiscoveredDevice>?) ?? const [],
        );
      },
    ),

    GoRoute(
      path: AppRoutes.connectionInterrupted,
      name: 'connection-interrupted',
      builder: (context, state) {
        final session = state.extra as TransferSession;
        return ConnectionInterruptedScreen(session: session);
      },
    ),

    GoRoute(
      path: AppRoutes.transferComplete,
      name: 'transfer-complete',
      builder: (context, state) {
        final session = state.extra as TransferSession;
        return TransferCompleteScreen(session: session);
      },
    ),

    GoRoute(
      path: AppRoutes.receive,
      name: 'receive',
      builder: (context, state) => const ReceiveScreen(),
    ),
  ],
);

/// Root shell — wraps Home/History/Devices/Settings tabs with the bottom nav bar.
class _RootShell extends StatefulWidget {
  const _RootShell({required this.child});
  final Widget child;

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  static const _tabs = [
    AppRoutes.home,
    AppRoutes.history,
    AppRoutes.devices,
    AppRoutes.settings,
  ];

  int _currentIndex = 0;

  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _FlowSendBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

class _FlowSendBottomNav extends StatelessWidget {
  const _FlowSendBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    _NavTab(icon: Icons.swap_horiz, label: 'Home'),
    _NavTab(icon: Icons.sync_alt, label: 'Transfers'),
    _NavTab(icon: Icons.radar, label: 'Devices'),
    _NavTab(icon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xD90A0E17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 84,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final isSelected = i == currentIndex;
              final tab = _tabs[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 68,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                      ? const Color(0x4D262A34)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                      ? const Border(top: BorderSide(color: Color(0xFFA5E7FF), width: 2))
                      : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        size: 24,
                        color: isSelected
                          ? const Color(0xFFA5E7FF)
                          : const Color(0xFFC2C6D8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFA5E7FF)
                              : const Color(0xFFC2C6D8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
