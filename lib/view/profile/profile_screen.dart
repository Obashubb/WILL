import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/care_controller.dart';
import '../../controllers/home_controller.dart';
import '../../core/colors.dart';
import '../../core/router/routes.dart';
import '../../helpers/profile_presenter.dart';
import '../../services/insights_repository.dart';
import '../../services/profile_service.dart';
import '../../services/sync_service.dart';
import '../../services/wearable_service.dart';
import '../home/home_shell.dart';
import '../widgets/row_divider_label.dart';
import '../widgets/section_title.dart';
import 'about_sheet.dart';
import 'baseline_sheet.dart';
import 'demo_data_sheet.dart';
import 'hydration_goal_sheet.dart';
import 'wearable_sheet.dart';
import '../widgets/profile/identity_card.dart';
import '../widgets/profile/setting_row.dart';
import '../widgets/profile/sign_out_button.dart';

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
      final isGuest = user?.isGuest ?? false;
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          const SectionTitle('Profile'),
          const SizedBox(height: 12),
          if (user != null) ...[
            IdentityCard(
              name: user.name,
              email: user.email,
              isGuest: user.isGuest,
            ),
            const SizedBox(height: 28),
          ],
          const RowDividerLabel(label: 'Device'),
          SettingRow(
            icon: CupertinoIcons.bluetooth,
            label: 'Wearable',
            value: ProfilePresenter.wearableValue(wearable),
            hint: ProfilePresenter.wearableHint(wearable),
            onTap: () => _showSheet(context, const WearableSheet()),
          ),
          SettingRow(
            icon: CupertinoIcons.cloud,
            label: 'Sync',
            value: ProfilePresenter.syncValue(sync, isGuest: isGuest),
            hint: ProfilePresenter.syncHint(sync, isGuest: isGuest),
            onTap: () async {
              await sync.flushNow();
              if (context.mounted) _showSyncSnack(context, sync);
            },
          ),
          const SizedBox(height: 28),
          const RowDividerLabel(label: 'Care'),
          SettingRow(
            icon: CupertinoIcons.bell,
            label: 'Reminders',
            value:
                '${care.medications.length} medication${care.medications.length == 1 ? '' : 's'}',
            hint: 'Open the Care tab to add, edit, or mark doses.',
            onTap: () => _goToTab(WillTab.care),
          ),
          SettingRow(
            icon: CupertinoIcons.drop,
            label: 'Hydration goal',
            value: '${care.hydrationGoalMl.value} ml',
            hint: 'Tap to change your daily target.',
            onTap: () => _showSheet(context, const HydrationGoalSheet()),
          ),
          SettingRow(
            icon: CupertinoIcons.heart_circle,
            label: 'Resting baseline',
            value: _baselineValue(),
            hint: 'Insights compare against your usual numbers.',
            onTap: () => _showSheet(context, const BaselineSheet()),
          ),
          SettingRow(
            icon: CupertinoIcons.sparkles,
            label: 'Insights history',
            value: _insightsCountValue(),
            hint: 'Tap to review past flags and trends.',
            onTap: () => context.push(WillRoutes.insightsHistory),
          ),
          const SizedBox(height: 28),
          const RowDividerLabel(label: 'App'),
          SettingRow(
            icon: CupertinoIcons.wand_stars,
            label: 'Demo data',
            hint: 'Seed sample data and switch scenarios.',
            onTap: () => _showSheet(context, const DemoDataSheet()),
          ),
          SettingRow(
            icon: CupertinoIcons.info_circle,
            label: 'About',
            hint: 'Version, project, and credits.',
            onTap: () => _showSheet(context, const AboutSheet()),
          ),
          const SizedBox(height: 28),
          SignOutButton(
            onTap: () async {
              await auth.signOut();
              if (context.mounted) context.go(WillRoutes.welcome);
            },
          ),
        ],
      );
    });
  }

  String _baselineValue() {
    final b = ProfileService.readBaseline();
    if (b == null) return 'Auto-learning';
    return '${b.restingHr.toStringAsFixed(0)} bpm';
  }

  String _insightsCountValue() {
    final n = InsightsRepository.readRecent().length;
    if (n == 0) return 'None yet';
    return '$n saved';
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

  void _showSyncSnack(BuildContext context, SyncService sync) {
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
}
