import 'package:flutter/cupertino.dart';

import '../../../core/colors.dart';
import '../../../models/health_sample.dart';
import '../../dashboard/metric_card.dart';

class MetricsGrid extends StatelessWidget {
  const MetricsGrid({super.key, required this.sample});

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

  /// Numeric trigger for the animation; the format string is what the
  /// user actually sees.
  double _scoreFor(double m) => m * 10;

  String _motionLabel(double m) {
    if (m < 0.1) return 'Rest';
    if (m < 0.3) return 'Low';
    if (m < 0.6) return 'Active';
    return 'High';
  }
}
