import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../models/health_sample.dart';
import '../../services/wearable_service.dart';
import '../auth/auth_controller.dart';
import '../widgets/will_inkwell.dart';
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
      final sample = wearable.latestSample.value;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _GreetingBlock(
            greeting: greeting,
            firstName: firstName,
            state: state,
          ),
          const SizedBox(height: 28),
          _SectionLabel(
            title: 'Live health overview',
            trailing: sample == null
                ? 'Waiting for data'
                : 'Updated ${DateFormat.Hm().format(sample.timestamp)}',
          ),
          const SizedBox(height: 14),
          if (state == WearableConnectionState.idle) ...[
            _NoBandBanner(onPair: () => wearable.startPairing()),
            const SizedBox(height: 14),
          ],
          _MetricsGrid(sample: sample),
        ],
      );
    });
  }
}

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({
    required this.greeting,
    required this.firstName,
    required this.state,
  });

  final String greeting;
  final String firstName;
  final WearableConnectionState state;

  @override
  Widget build(BuildContext context) {
    final headline =
        firstName.isEmpty ? '$greeting.' : '$greeting, $firstName.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConnectionPill(state: state),
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutQuart,
          switchOutCurve: Curves.easeOutQuart,
          child: Text(
            _subtitleFor(state),
            key: ValueKey(state),
            style: const TextStyle(
              fontSize: 14,
              color: WillColors.textSecondary,
            ),
          ),
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
        return 'Reconnecting to your band…';
      case WearableConnectionState.error:
        return 'Tap the band icon in Profile to retry.';
      case WearableConnectionState.idle:
        return 'No band paired yet.';
    }
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.state});

  final WearableConnectionState state;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(state);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutQuart,
      switchOutCurve: Curves.easeOutQuart,
      child: Container(
        key: ValueKey(state),
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
              decoration:
                  BoxDecoration(color: spec.color, shape: BoxShape.circle),
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
          style: const TextStyle(
            fontSize: 11,
            color: WillColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _NoBandBanner extends StatelessWidget {
  const _NoBandBanner({required this.onPair});

  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WillColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.bluetooth,
            size: 18,
            color: WillColors.textSecondary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No band paired. Pair one to see live readings.',
              style: TextStyle(
                fontSize: 13,
                color: WillColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
          WillInkwell(
            onTap: onPair,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: WillColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Pair',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.sample});

  final HealthSample? sample;

  @override
  Widget build(BuildContext context) {
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
          value: sample?.heartRate.toDouble(),
          unit: 'bpm',
          icon: CupertinoIcons.heart_fill,
          accent: WillColors.danger,
        ),
        MetricCard(
          label: 'Oxygen',
          value: sample?.spo2.toDouble(),
          unit: '%',
          icon: CupertinoIcons.drop_fill,
          accent: WillColors.action,
        ),
        MetricCard(
          label: 'Temperature',
          value: sample?.temperature,
          format: (v) => v.toStringAsFixed(1),
          unit: '°C',
          icon: CupertinoIcons.thermometer,
          accent: WillColors.warning,
        ),
        MetricCard(
          label: 'Activity',
          value: sample == null ? null : _scoreFor(sample!.motion),
          format: (_) => sample == null ? '--' : _motionLabel(sample!.motion),
          unit: '',
          icon: CupertinoIcons.flame_fill,
          accent: WillColors.accent,
        ),
      ],
    );
  }

  double _scoreFor(double m) {
    // Just a numeric trigger for the animation; the format string is what
    // the user actually sees.
    return m * 10;
  }

  String _motionLabel(double m) {
    if (m < 0.1) return 'Rest';
    if (m < 0.3) return 'Low';
    if (m < 0.6) return 'Active';
    return 'High';
  }
}
