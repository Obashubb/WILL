import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/colors.dart';
import '../../helpers/relative_time.dart';
import '../../models/health_sample.dart';
import '../../services/wearable_service.dart';
import '../auth/auth_controller.dart';
import '../profile/wearable_sheet.dart';
import '../widgets/will_inkwell.dart';
import '../widgets/will_primary_button.dart';
import 'metric_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = Get.find<AuthController>();
    final wearable = Get.find<WearableService>();

    return Obx(() {
      final firstName = auth.user.value?.firstName ?? '';
      final greeting = _greeting(DateTime.now());
      final state = wearable.connectionState.value;
      final sample = wearable.displaySample.value;
      final lastSeen = wearable.lastSampleAt.value;
      final showEmpty =
          state == WearableConnectionState.idle && sample == null;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _GreetingBlock(
            greeting: greeting,
            firstName: firstName,
            state: state,
            onTapPill: () => _openWearableSheet(context),
          ),
          const SizedBox(height: 28),
          if (showEmpty)
            _NoBandCard(onPair: () => _openWearableSheet(context))
          else ...[
            _SectionLabel(
              title: 'Live health overview',
              trailing: lastSeen != null
                  ? RelativeTime.short(lastSeen)
                  : 'Waiting for data',
            ),
            const SizedBox(height: 14),
            _MetricsGrid(sample: sample),
          ],
        ],
      );
    });
  }

  void _openWearableSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WillColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const WearableSheet(),
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({
    required this.greeting,
    required this.firstName,
    required this.state,
    required this.onTapPill,
  });

  final String greeting;
  final String firstName;
  final WearableConnectionState state;
  final VoidCallback onTapPill;

  @override
  Widget build(BuildContext context) {
    final headline = firstName.isEmpty
        ? '$greeting.'
        : '$greeting, $firstName.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WillInkwell(onTap: onTapPill, child: _ConnectionPill(state: state)),
        const SizedBox(height: 18),
        Text(
          headline,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.05,
            color: WillColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _subtitleFor(state),
          style: const TextStyle(fontSize: 14, color: WillColors.textSecondary),
        ),
      ],
    );
  }

  String _subtitleFor(WearableConnectionState s) {
    switch (s) {
      case WearableConnectionState.connected:
        return 'Your band is reading your vitals.';
      case WearableConnectionState.scanning:
        return 'Looking for your band…';
      case WearableConnectionState.connecting:
        return 'Connecting to your band…';
      case WearableConnectionState.disconnected:
        return 'Trying to reconnect…';
      case WearableConnectionState.error:
        return 'Tap the band pill above to fix it.';
      case WearableConnectionState.idle:
        return 'Tap the band pill above to pair your wristband.';
    }
  }
}

class _NoBandCard extends StatelessWidget {
  const _NoBandCard({required this.onPair});

  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WillColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WillColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.bluetooth,
              size: 32,
              color: WillColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No band connected',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: WillColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pair your Will Band to see your live vitals here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: WillColors.textSecondary),
          ),
          const SizedBox(height: 18),
          WillPrimaryButton(label: 'Pair device', onPressed: onPair),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.state});

  final WearableConnectionState state;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: spec.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: spec.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Icon(CupertinoIcons.bluetooth, color: spec.color, size: 14),
          const SizedBox(width: 6),
          Text(
            spec.label,
            style: TextStyle(
              color: spec.color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  ({Color color, String label}) _specFor(WearableConnectionState s) {
    switch (s) {
      case WearableConnectionState.connected:
        return (color: WillColors.accent, label: 'Connected');
      case WearableConnectionState.scanning:
      case WearableConnectionState.connecting:
        return (color: WillColors.warning, label: 'Connecting');
      case WearableConnectionState.disconnected:
        return (color: WillColors.warning, label: 'Reconnecting');
      case WearableConnectionState.error:
        return (color: WillColors.danger, label: 'Offline');
      case WearableConnectionState.idle:
        return (color: WillColors.textSecondary, label: 'No band');
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: WillColors.textPrimary,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(fontSize: 11, color: WillColors.textSecondary),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.sample});

  final HealthSample? sample;

  @override
  Widget build(BuildContext context) {
    final hr = sample?.heartRate.toString() ?? '--';
    final spo2 = sample?.spo2.toString() ?? '--';
    final temp = sample?.temperature.toStringAsFixed(1) ?? '--';
    final motion = sample == null ? '--' : _motionLabel(sample!.motion);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        MetricCard(
          label: 'Heart rate',
          value: hr,
          unit: 'bpm',
          icon: CupertinoIcons.heart_fill,
          accent: WillColors.danger,
        ),
        MetricCard(
          label: 'Oxygen',
          value: spo2,
          unit: '%',
          icon: CupertinoIcons.drop_fill,
          accent: WillColors.action,
        ),
        MetricCard(
          label: 'Temperature',
          value: temp,
          unit: '°C',
          icon: CupertinoIcons.thermometer,
          accent: WillColors.warning,
        ),
        MetricCard(
          label: 'Activity',
          value: motion,
          unit: '',
          icon: CupertinoIcons.flame_fill,
          accent: WillColors.accent,
        ),
        MetricCard(
          label: 'Steps',
          value: sample?.stepcount.toString() ?? '--',
          unit: '',
          icon: CupertinoIcons.location_solid, // or a footprint-style icon
          accent: const Color(0xFF9B7BD4), // violet to match History
        ),
      ],
    );
  }

  String _motionLabel(double m) {
    if (m < 0.1) return 'Rest';
    if (m < 0.3) return 'Low';
    if (m < 0.6) return 'Active';
    return 'High';
  }
}
