import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/router/routes.dart';
import '../../services/sync_service.dart';
import '../../services/wearable_service.dart';
import '../auth/auth_controller.dart';
import '../care/care_controller.dart';
import '../home/home_controller.dart';
import '../home/home_shell.dart';
import '../widgets/section_title.dart';
import '../widgets/will_inkwell.dart';
import 'about_sheet.dart';
import 'demo_data_sheet.dart';
import 'hydration_goal_sheet.dart';
import 'wearable_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = Get.find<AuthController>();
    final wearable = Get.find<WearableService>();
    final sync = Get.find<SyncService>();
    final care = Get.find<CareController>();

    return Obx(() {
      final user = auth.user.value;
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          const SectionTitle('Profile'),
          const SizedBox(height: 12),
          if (user != null) ...[
            _IdentityCard(
              name: user.name,
              email: user.email,
              isGuest: user.isGuest,
            ),
            const SizedBox(height: 28),
          ],
          const _RowDivider(label: 'Device'),
          _SettingRow(
            icon: CupertinoIcons.bluetooth,
            label: 'Wearable',
            value: _wearableValue(wearable),
            hint: _wearableHint(wearable),
            onTap: () => _showSheet(context, const WearableSheet()),
          ),
          _SettingRow(
            icon: CupertinoIcons.cloud,
            label: 'Sync',
            value: _syncValue(sync, user?.isGuest ?? false),
            hint: _syncHint(sync, user?.isGuest ?? false),
            onTap: () async {
              await sync.flushNow();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    backgroundColor: WillColors.primary,
                    content: Text(
                      sync.lastError.value == null
                          ? 'Synced.'
                          : 'Sync failed. Will retry.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ));
              }
            },
          ),
          const SizedBox(height: 28),
          const _RowDivider(label: 'Care'),
          _SettingRow(
            icon: CupertinoIcons.bell,
            label: 'Reminders',
            value:
                '${care.medications.length} medication${care.medications.length == 1 ? '' : 's'}',
            hint: 'Open the Care tab to add, edit, or mark doses.',
            onTap: () => _goToTab(WillTab.care),
          ),
          _SettingRow(
            icon: CupertinoIcons.drop,
            label: 'Hydration goal',
            value: '${care.hydrationGoalMl.value} ml',
            hint: 'Tap to change your daily target.',
            onTap: () => _showSheet(context, const HydrationGoalSheet()),
          ),
          const SizedBox(height: 28),
          const _RowDivider(label: 'App'),
          _SettingRow(
            icon: CupertinoIcons.wand_stars,
            label: 'Demo data',
            hint: 'Seed sample data and switch scenarios.',
            onTap: () => _showSheet(context, const DemoDataSheet()),
          ),
          _SettingRow(
            icon: CupertinoIcons.info_circle,
            label: 'About',
            hint: 'Version, project, and credits.',
            onTap: () => _showSheet(context, const AboutSheet()),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: WillInkwell(
              onTap: () async {
                await auth.signOut();
                if (context.mounted) context.go(WillRoutes.welcome);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WillColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sign out',
                  style: TextStyle(
                    color: WillColors.danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WillColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => sheet,
    );
  }

  void _goToTab(WillTab tab) {
    Get.find<HomeController>().setTab(tab.index);
  }

  String _wearableValue(WearableService wearable) {
    final state = wearable.connectionState.value;
    switch (state) {
      case WearableConnectionState.connected:
        return wearable.deviceName.value.isEmpty
            ? 'Will Band'
            : wearable.deviceName.value;
      case WearableConnectionState.scanning:
        return 'Searching…';
      case WearableConnectionState.connecting:
        return 'Connecting…';
      case WearableConnectionState.disconnected:
        return 'Reconnecting…';
      case WearableConnectionState.error:
        return 'Tap to retry';
      case WearableConnectionState.idle:
        return 'Tap to pair';
    }
  }

  String _wearableHint(WearableService wearable) {
    final state = wearable.connectionState.value;
    if (state == WearableConnectionState.connected) {
      return wearable.mockMode.value ? 'Mock mode' : 'Live';
    }
    return wearable.lastError.value ?? '';
  }

  String _syncValue(SyncService sync, bool isGuest) {
    if (isGuest) return 'Local only';
    if (!sync.isOnline.value) return 'Offline';
    final last = sync.lastSyncedAt.value;
    if (last == null) return 'Pending';
    return 'Synced ${_relative(last)}';
  }

  String _syncHint(SyncService sync, bool isGuest) {
    if (isGuest) return 'Guest data stays on this phone.';
    return sync.lastError.value ?? 'Tap to sync now.';
  }

  String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return DateFormat.MMMd().format(t);
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.isGuest,
  });

  final String name;
  final String? email;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: WillColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: WillColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGuest ? 'Guest account' : (email ?? 'Signed in'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: WillColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: WillColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.value,
    this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WillInkwell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 20, color: WillColors.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: WillColors.textPrimary,
                    ),
                  ),
                  if (hint != null && hint!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: WillColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  value!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: WillColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: WillColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
