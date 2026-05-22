import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../helpers/chart_math.dart';
import '../../models/health_sample.dart';

/// Which metric the History chart is currently rendering. Each option
/// carries its label, unit, accent colour, minimum chart range, a value
/// extractor, and the number formatter the chart uses for its axis and
/// headline.
enum HistoryMetric {
  heartRate(
    label: 'Heart rate',
    unit: 'bpm',
    color: WillColors.danger,
    minRange: 15,
  ),
  spo2(
    label: 'Oxygen',
    unit: '%',
    color: WillColors.action,
    minRange: 4,
  ),
  temperature(
    label: 'Temperature',
    unit: '°C',
    color: WillColors.warning,
    minRange: 0.5,
  ),
  motion(
    label: 'Activity',
    unit: '',
    color: WillColors.accent,
    minRange: 0.2,
  );

  const HistoryMetric({
    required this.label,
    required this.unit,
    required this.color,
    required this.minRange,
  });

  final String label;
  final String unit;
  final Color color;

  /// Smallest acceptable chart range. Prevents the chart from zooming so
  /// far in that random sensor noise looks like a trend.
  final double minRange;

  double valueOf(HealthSample sample) {
    switch (this) {
      case HistoryMetric.heartRate:
        return sample.heartRate.toDouble();
      case HistoryMetric.spo2:
        return sample.spo2.toDouble();
      case HistoryMetric.temperature:
        return sample.temperature;
      case HistoryMetric.motion:
        return sample.motion;
    }
  }

  NumberFormatter get formatter {
    switch (this) {
      case HistoryMetric.temperature:
        return formatOneDecimal;
      case HistoryMetric.motion:
        return formatTwoDecimal;
      default:
        return formatInt;
    }
  }
}
