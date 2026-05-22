import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../models/health_sample.dart';
import '../../services/samples_repository.dart';
import '../../services/wearable_service.dart';
import '../widgets/empty_placeholder.dart';
import '../widgets/section_title.dart';

enum _Metric {
  heartRate('Heart rate', 'bpm', WillColors.danger, 15),
  spo2('Oxygen', '%', WillColors.action, 4),
  temperature('Temperature', '°C', WillColors.warning, 0.5),
  motion('Activity', '', WillColors.accent, 0.2);

  const _Metric(this.label, this.unit, this.color, this.minRange);

  final String label;
  final String unit;
  final Color color;

  /// Smallest acceptable chart range. Prevents the chart from zooming in
  /// so far that random sensor noise looks like a giant trend.
  final double minRange;
}

enum _Range {
  hour('1H', Duration(hours: 1)),
  sixHours('6H', Duration(hours: 6)),
  day('24H', Duration(hours: 24));

  const _Range(this.label, this.duration);

  final String label;
  final Duration duration;
}

/// Target number of visible data points in the chart. Anything more gets
/// downsampled by bucket-averaging so the curve stays readable.
const int _targetPoints = 30;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  _Metric _metric = _Metric.heartRate;
  _Range _range = _Range.hour;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final wearable = Get.find<WearableService>();
    return Obx(() {
      // Rebuild whenever a new sample lands so the chart stays fresh.
      wearable.latestSample.value;
      final all = SamplesRepository.readRecent();
      final cutoff = DateTime.now().subtract(_range.duration);
      final raw = all
          .where((s) => !s.timestamp.isBefore(cutoff))
          .toList(growable: false);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('History'),
          const SizedBox(height: 12),
          _MetricPicker(
            value: _metric,
            onChanged: (m) => setState(() => _metric = m),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: raw.length < 2
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _RangePicker(
                          value: _range,
                          onChanged: (r) => setState(() => _range = r),
                        ),
                      ),
                      const Expanded(
                        child: EmptyPlaceholder(
                          icon: Icons.show_chart,
                          title: 'Not enough data yet.',
                          subtitle:
                              'Wear the band for about a minute — trends will appear here.',
                        ),
                      ),
                    ],
                  )
                : _TrendChart(
                    samples: _downsample(raw, _targetPoints),
                    rawSamples: raw,
                    metric: _metric,
                    range: _range,
                    onRangeChanged: (r) => setState(() => _range = r),
                  ),
          ),
        ],
      );
    });
  }
}

/// Bucket-averages [samples] down to roughly [target] points. The shape of
/// the curve is preserved; high-frequency noise disappears.
List<HealthSample> _downsample(List<HealthSample> samples, int target) {
  if (samples.length <= target) return samples;
  final bucketSize = samples.length / target;
  final out = <HealthSample>[];
  for (var i = 0; i < target; i++) {
    final start = (i * bucketSize).floor();
    final end =
        ((i + 1) * bucketSize).floor().clamp(start + 1, samples.length);
    final bucket = samples.sublist(start, end);

    var hrSum = 0;
    var spo2Sum = 0;
    var tempSum = 0.0;
    var motionSum = 0.0;
    for (final s in bucket) {
      hrSum += s.heartRate;
      spo2Sum += s.spo2;
      tempSum += s.temperature;
      motionSum += s.motion;
    }
    final n = bucket.length;
    out.add(HealthSample(
      heartRate: (hrSum / n).round(),
      spo2: (spo2Sum / n).round(),
      temperature: double.parse((tempSum / n).toStringAsFixed(2)),
      motion: double.parse((motionSum / n).toStringAsFixed(3)),
      timestamp: bucket[n ~/ 2].timestamp,
    ));
  }
  return out;
}

class _MetricPicker extends StatelessWidget {
  const _MetricPicker({required this.value, required this.onChanged});

  final _Metric value;
  final ValueChanged<_Metric> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _Metric.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final m = _Metric.values[i];
          final selected = m == value;
          return GestureDetector(
            onTap: () => onChanged(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutQuart,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? m.color.withValues(alpha: 0.12)
                    : WillColors.surface,
                border: Border.all(
                  color: selected
                      ? m.color.withValues(alpha: 0.4)
                      : WillColors.border.withValues(alpha: 0.6),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                m.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? m.color : WillColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RangePicker extends StatelessWidget {
  const _RangePicker({required this.value, required this.onChanged});

  final _Range value;
  final ValueChanged<_Range> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _Range.values.map((r) {
          final selected = r == value;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutQuart,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? WillColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  r.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : WillColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.samples,
    required this.rawSamples,
    required this.metric,
    required this.range,
    required this.onRangeChanged,
  });

  /// Downsampled — drives the smooth curve.
  final List<HealthSample> samples;

  /// Raw, unsmoothed samples — drives the displayed headline value and the
  /// min / max in the subtitle, so the numbers always reflect what the band
  /// actually saw, not the bucket average.
  final List<HealthSample> rawSamples;

  final _Metric metric;
  final _Range range;
  final ValueChanged<_Range> onRangeChanged;

  double _value(HealthSample s) {
    switch (metric) {
      case _Metric.heartRate:
        return s.heartRate.toDouble();
      case _Metric.spo2:
        return s.spo2.toDouble();
      case _Metric.temperature:
        return s.temperature;
      case _Metric.motion:
        return s.motion;
    }
  }

  String _formatY(double v) {
    switch (metric) {
      case _Metric.temperature:
        return v.toStringAsFixed(1);
      case _Metric.motion:
        return v.toStringAsFixed(2);
      default:
        return v.toStringAsFixed(0);
    }
  }

  /// Computes a Y window where the data occupies the middle 50% of the
  /// chart (25% breathing room above + below). Falls back to the metric's
  /// minimum range when the data is too flat to set a meaningful scale.
  ({double minY, double maxY}) _yWindow(double dataMin, double dataMax) {
    final dataRange = (dataMax - dataMin).abs();
    final center = (dataMin + dataMax) / 2;
    // chartRange = 2 × dataRange  → data fills middle 50%.
    var chartRange = dataRange * 2;
    if (chartRange < metric.minRange) chartRange = metric.minRange;
    final half = chartRange / 2;
    return (minY: center - half, maxY: center + half);
  }

  @override
  Widget build(BuildContext context) {
    final spots = samples
        .map((s) => FlSpot(
              s.timestamp.millisecondsSinceEpoch.toDouble(),
              _value(s),
            ))
        .toList();

    // Chart Y bounds normalize to the *downsampled* curve so the drawn line
    // sits in the middle 50% of the canvas.
    final smoothedValues = spots.map((s) => s.y).toList();
    final curveMin = smoothedValues.reduce((a, b) => a < b ? a : b);
    final curveMax = smoothedValues.reduce((a, b) => a > b ? a : b);
    final window = _yWindow(curveMin, curveMax);
    final minY = window.minY;
    final maxY = window.maxY;

    // Headline and subtitle pull from the *raw* samples so the displayed
    // numbers are exact, not bucket averages.
    final rawValues = rawSamples.map(_value).toList();
    final rawMin = rawValues.reduce((a, b) => a < b ? a : b);
    final rawMax = rawValues.reduce((a, b) => a > b ? a : b);
    final headline = _formatY(_value(rawSamples.last));

    final yInterval = ((maxY - minY) / 4).abs().clamp(0.01, double.infinity);
    final xMin = spots.first.x;
    final xMax = spots.last.x;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data-point text + range picker share the same outer padding.
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
                '${samples.length} of ${rawSamples.length} points · '
                'min ${_formatY(rawMin)} · '
                'max ${_formatY(rawMax)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: WillColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _RangePicker(value: range, onChanged: onRangeChanged),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Sidebar Y labels on the left, chart taking the rest of the width,
        // and a 10%-of-screen right gutter.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 5, 0, 29),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _YAxisSidebar(
                    minY: minY,
                    maxY: maxY,
                    interval: yInterval,
                    format: _formatY,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // bottomTitles reserve 22 pt — subtract so the pulse
                      // dot lines up with the plotted curve, not the axis.
                      const bottomAxis = 22.0;
                      final plotHeight = constraints.maxHeight - bottomAxis;
                      final lastValue = _value(rawSamples.last);
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
                                          metric.color.withValues(alpha: 0.0),
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
                            child: _PulseDot(
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

class _YAxisSidebar extends StatelessWidget {
  const _YAxisSidebar({
    required this.minY,
    required this.maxY,
    required this.interval,
    required this.format,
  });

  final double minY;
  final double maxY;
  final double interval;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    // bottomTitles inside the chart reserve 22 pt; subtract so labels
    // align with the plotted band, not the axis strip.
    const bottomAxisReserve = 22.0;
    const labelHeight = 14.0;

    // Step from maxY downward by interval, skipping the values that fall
    // within 40 % of an interval from either edge (same rule the old
    // leftTitles used).
    final values = <double>[];
    final edgeGuard = interval * 0.4;
    for (var v = maxY; v >= minY - 0.001; v -= interval) {
      if ((v - minY).abs() < edgeGuard || (v - maxY).abs() < edgeGuard) {
        continue;
      }
      values.add(v);
    }

    return Container(
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plotHeight = constraints.maxHeight - bottomAxisReserve;
          return SizedBox(
            width: 32,
            child: Stack(
              children: [
                for (final v in values)
                  Positioned(
                    right: 0,
                    left: 0,
                    top: (1 - (v - minY) / (maxY - minY)) * plotHeight -
                        labelHeight / 2,
                    child: Text(
                      format(v),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10,
                        color: WillColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({
    required this.color,
    required this.active,
    this.size = 10,
  });

  final Color color;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
    );

    if (!active) return dot;

    return SizedBox(
      width: size * 4,
      height: size * 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(2, (i) {
            return Container(
              width: size * 4,
              height: size * 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(),
                  delay: (i * 750).ms,
                )
                .scale(
                  begin: const Offset(0.25, 0.25),
                  end: const Offset(1, 1),
                  duration: 1500.ms,
                  curve: Curves.easeOutQuart,
                )
                .fadeOut(
                  duration: 1500.ms,
                  curve: Curves.easeOutQuart,
                );
          }),
          dot,
        ],
      ),
    );
  }
}
