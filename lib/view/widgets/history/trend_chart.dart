import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/colors.dart';
import '../../../helpers/chart_math.dart';
import '../../../helpers/relative_time.dart';
import '../../../models/health_sample.dart';
import '../../../services/wearable_service.dart';
import '../../history/history_metric.dart';
import '../../history/history_range.dart';
import 'pulse_dot.dart';
import 'range_picker.dart';
import 'y_axis_sidebar.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.samples,
    required this.rawSamples,
    required this.metric,
    required this.range,
    required this.onRangeChanged,
  });

  /// Downsampled, drives the smooth curve.
  final List<HealthSample> samples;

  /// Raw, unsmoothed samples drive the displayed headline value and the
  /// min / max in the subtitle so the numbers always reflect what the band
  /// actually saw, not the bucket average.
  final List<HealthSample> rawSamples;

  final HistoryMetric metric;
  final HistoryRange range;
  final ValueChanged<HistoryRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final spots = samples
        .map((s) => FlSpot(
              s.timestamp.millisecondsSinceEpoch.toDouble(),
              metric.valueOf(s),
            ))
        .toList();

    final smoothedValues = spots.map((s) => s.y).toList();
    final curveMin = smoothedValues.reduce((a, b) => a < b ? a : b);
    final curveMax = smoothedValues.reduce((a, b) => a > b ? a : b);
    final window = yWindow(curveMin, curveMax, metric.minRange);
    final minY = window.minY;
    final maxY = window.maxY;

    final rawValues = rawSamples.map(metric.valueOf).toList();
    final rawMin = rawValues.reduce((a, b) => a < b ? a : b);
    final rawMax = rawValues.reduce((a, b) => a > b ? a : b);
    final headline = metric.formatter(metric.valueOf(rawSamples.last));

    final yInterval = ((maxY - minY) / 4).abs().clamp(0.01, double.infinity);
    final xMin = spots.first.x;
    final xMax = spots.last.x;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    headline,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: WillColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      metric.unit,
                      style: const TextStyle(
                        fontSize: 14,
                        color: WillColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Updated ${relativeTime(rawSamples.last.timestamp)} · '
                'min ${metric.formatter(rawMin)} · '
                'max ${metric.formatter(rawMax)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: WillColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              RangePicker(value: range, onChanged: onRangeChanged),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 5, 0, 29),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: YAxisSidebar(
                    minY: minY,
                    maxY: maxY,
                    interval: yInterval,
                    format: metric.formatter,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const bottomAxis = 22.0;
                      final plotHeight = constraints.maxHeight - bottomAxis;
                      final lastValue = metric.valueOf(rawSamples.last);
                      final normalized =
                          ((lastValue - minY) / (maxY - minY)).clamp(0.0, 1.0);
                      const dotSize = 10.0;
                      final dotTop =
                          (1 - normalized) * plotHeight - dotSize / 2;
                      final active = Get.find<WearableService>()
                              .connectionState
                              .value ==
                          WearableConnectionState.connected;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: LineChart(
                              LineChartData(
                                minX: xMin,
                                maxX: xMax,
                                minY: minY,
                                maxY: maxY,
                                lineTouchData:
                                    const LineTouchData(enabled: false),
                                clipData: const FlClipData.all(),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: yInterval,
                                  getDrawingHorizontalLine: (_) => FlLine(
                                    color: WillColors.border
                                        .withValues(alpha: 0.4),
                                    strokeWidth: 1,
                                    dashArray: const [4, 6],
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: bottomAxis,
                                      interval: (xMax - xMin) / 2,
                                      getTitlesWidget: (value, meta) {
                                        final dt = DateTime
                                            .fromMillisecondsSinceEpoch(
                                          value.toInt(),
                                        );
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Text(
                                            DateFormat.Hm().format(dt),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color:
                                                  WillColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    curveSmoothness: 0.45,
                                    preventCurveOverShooting: true,
                                    color: metric.color,
                                    barWidth: 2.4,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          metric.color
                                              .withValues(alpha: 0.18),
                                          metric.color
                                              .withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: dotTop,
                            child: PulseDot(
                              color: metric.color,
                              active: active,
                              size: dotSize,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.10,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
