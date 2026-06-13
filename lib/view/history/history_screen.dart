import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../models/health_sample.dart';
import '../../services/samples_repository.dart';
import '../../services/wearable_service.dart';
import '../widgets/empty_placeholder.dart';
import '../widgets/section_title.dart';

enum _Metric {
  heartRate(
    'Heart rate',
    'bpm',
    Color(0xFF14B8A6), // muted teal
    axisMin: 40,
    axisMax: 160,
    normalLow: 75,
    normalHigh: 100,
  ),
  spo2(
    'Oxygen',
    '%',
    Color(0xFF5B8DEF), // slate blue
    axisMin: 80,
    axisMax: 100,
    normalLow: 92,
    normalHigh: 100,
  ),
  temperature(
    'Temperature',
    '°C',
    Color(0xFFE0A458), // warm amber
    axisMin: 35,
    axisMax: 41,
    normalLow: 36.1,
    normalHigh: 37.2,
  ),
  motion(
    'Activity',
    '',
    Color(0xFF7BA05B), // sage green
    axisMin: 0,
    axisMax: 1,
    normalLow: 0,
    normalHigh: 0.6,
  ),
  stepcount(
    'Steps',
    '',
    Color(0xFF9B7BD4), // soft violet
    axisMin: 0,
    axisMax: 10000,
    normalLow: 0,
    normalHigh: 10000,
  );

  const _Metric(
    this.label,
    this.unit,
    this.color, {
    required this.axisMin,
    required this.axisMax,
    required this.normalLow,
    required this.normalHigh,
  });

  final String label;
  final String unit;
  final Color color;

  /// The fixed bottom and top of the Y-axis for this metric. Keeping these
  /// constant means normal fluctuations look small and real spikes look big,
  /// instead of the chart auto-zooming and making tiny wobbles look dramatic.
  final double axisMin;
  final double axisMax;

  /// The healthy range for this metric. We shade this band behind the line
  /// so the user can instantly see whether they're inside normal limits.
  final double normalLow;
  final double normalHigh;
}

enum _Window {
  day('Day', Duration(days: 1)),
  week('Week', Duration(days: 7)),
  month('Month', Duration(days: 30));

  const _Window(this.label, this.span);
  final String label;
  final Duration span;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  _Metric _metric = _Metric.heartRate;
  _Window _window = _Window.day; // default to Day view

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final wearable = Get.find<WearableService>();
    return Obx(() {
      wearable.latestSample.value; // rebuild when a new sample lands

      // Filter to only samples inside the selected window.
      final cutoff = DateTime.now().subtract(_window.span);
      final samples = SamplesRepository.readRecent()
          .where((s) => s.timestamp.isAfter(cutoff))
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SectionTitle('History'),
          const SizedBox(height: 12),
          _MetricPicker(
            value: _metric,
            onChanged: (m) => setState(() => _metric = m),
          ),
          const SizedBox(height: 12),
          _WindowPicker(
            value: _window,
            onChanged: (w) => setState(() => _window = w),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 400,
            child: samples.isEmpty
                ? const EmptyPlaceholder(
                    icon: Icons.show_chart,
                    title: 'No readings yet.',
                    subtitle:
                        'Trends will appear here as the band collects data.',
                  )
                : _metric == _Metric.stepcount
                ? _StepsBarChart(samples: samples, metric: _metric)
                : _TrendChart(
                    samples: samples,
                    metric: _metric,
                    window: _window,
                  ),
          ),
        ],
      );
    });
  }
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
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

class _WindowPicker extends StatelessWidget {
  const _WindowPicker({required this.value, required this.onChanged});

  final _Window value;
  final ValueChanged<_Window> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _Window.values.map((w) {
          final selected = w == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(w),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutQuart,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? WillColors.textPrimary.withValues(alpha: 0.06)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? WillColors.textPrimary.withValues(alpha: 0.2)
                        : WillColors.border.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  w.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? WillColors.textPrimary
                        : WillColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.samples,
    required this.metric,
    required this.window,
  });

  final List<HealthSample> samples;
  final _Metric metric;
  final _Window window;

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
      case _Metric.stepcount:
        return s.stepcount.toDouble();
    }
  }

  String _formatY(double y) {
    switch (metric) {
      case _Metric.heartRate:
      case _Metric.spo2:
        return y.toInt().toString();
      case _Metric.temperature:
        return y.toStringAsFixed(1);
      case _Metric.motion:
        return y.toStringAsFixed(1);
      case _Metric.stepcount:
        return y.toInt().toString();
    }
  }

  /// Formats an X-axis (time) label depending on the window.
  /// Day shows the hour (e.g. "14:00"); Week and Month show the date.
  String _formatX(double msSinceEpoch) {
    final t = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch.toInt());
    switch (window) {
      case _Window.day:
        return DateFormat.Hm().format(t); // 14:30
      case _Window.week:
      case _Window.month:
        return DateFormat.MMMd().format(t); // Jun 3
    }
  }

  List<FlSpot> _aggregateSpots(List<HealthSample> samples) {
    if (samples.isEmpty) return [];

    // Choose bucket size based on the window.
    final bucketDuration = window == _Window.day
        ? const Duration(hours: 1)
        : const Duration(days: 1);

    // Group samples into buckets keyed by the bucket's start time.
    final buckets = <int, List<double>>{};
    for (final s in samples) {
      final ms = s.timestamp.millisecondsSinceEpoch;
      final bucketMs =
          (ms ~/ bucketDuration.inMilliseconds) * bucketDuration.inMilliseconds;
      buckets.putIfAbsent(bucketMs, () => []).add(_value(s));
    }

    // Average each bucket and build one spot per bucket.
    final spots = buckets.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return FlSpot(e.key.toDouble(), avg);
    }).toList()..sort((a, b) => a.x.compareTo(b.x));

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...samples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Aggregate into time buckets so each window summarises differently:
    // Day = hourly buckets, Week/Month = daily buckets.
    final spots = _aggregateSpots(sorted);

    // Fixed X range: the full selected window, from cutoff to now.
    final now = DateTime.now();
    final start = now.subtract(window.span);
    final minX = start.millisecondsSinceEpoch.toDouble();
    final maxX = now.millisecondsSinceEpoch.toDouble();

    // Fixed Y range from the metric's clinical bounds.
    final minY = metric.axisMin;
    final maxY = metric.axisMax;

    final last = sorted.last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big current value
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatY(_value(last)),
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
          // Normal-range caption so the user knows what the band means
          Text(
            'Normal: ${_formatY(metric.normalLow)}–${_formatY(metric.normalHigh)} ${metric.unit}',
            style: const TextStyle(
              fontSize: 12,
              color: WillColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,

                // The shaded normal-range band behind the line.
                rangeAnnotations: RangeAnnotations(
                  // The shaded normal-range band (horizontal).
                  horizontalRangeAnnotations: [
                    HorizontalRangeAnnotation(
                      y1: metric.normalLow,
                      y2: metric.normalHigh,
                      color: metric.color.withValues(alpha: 0.08),
                    ),
                  ],
                  // A thin vertical band marking "now" at the right edge.
                  // We make it a hair wide so it reads as a line.
                  verticalRangeAnnotations: [
                    VerticalRangeAnnotation(
                      x1: maxX - ((maxX - minX) * 0.002),
                      x2: maxX,
                      color: WillColors.textSecondary.withValues(alpha: 0.35),
                    ),
                  ],
                ),

                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touched) => touched.map((s) {
                      return LineTooltipItem(
                        '${_formatY(s.y)} ${metric.unit}\n${_formatX(s.x)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  // 4 horizontal grid bands across the fixed range.
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: WillColors.border.withValues(alpha: 0.8),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),

                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  // LEFT — value labels at each grid band
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (value, meta) {
                        // Don't draw a label right at the very top/bottom edge,
                        // where it can collide or render a misaligned number.
                        if (value <= meta.min || value >= meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _formatY(value),
                          style: const TextStyle(
                            color: WillColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  // BOTTOM — time labels at 4 points across the window
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: (maxX - minX) / 4,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 6,
                          child: Text(
                            _formatX(value),
                            style: const TextStyle(
                              color: WillColors.textSecondary,
                              fontSize: 9,
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
                    curveSmoothness: 0.3,
                    color: metric.color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      // Vertical gradient: metric colour at the top of the
                      // fill, fading to fully transparent at the bottom.
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          metric.color.withValues(alpha: 0.25),
                          metric.color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One day's step total, for the bar chart.
class _DailySteps {
  final DateTime day;
  final int steps;
  const _DailySteps(this.day, this.steps);
}

/// Computes true per-day step counts for the last 7 days.
///
/// The band reports a continuously climbing total (it has no clock, so it
/// never resets itself). The phone, which DOES know the date, computes each
/// day's steps as: (that day's ending total) − (previous day's ending total).
/// This gives the steps actually taken on each calendar day.
List<_DailySteps> _bucketStepsByDay(List<HealthSample> samples) {
  if (samples.isEmpty) return [];

  // For each calendar day, find the ending (highest) cumulative total.
  final endOfDayTotal = <DateTime, int>{};
  for (final s in samples) {
    final day = DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
    final current = endOfDayTotal[day] ?? 0;
    if (s.stepcount > current) endOfDayTotal[day] = s.stepcount;
  }

  // Build the last 7 days as deltas from the previous day's ending total.
  final result = <_DailySteps>[];
  final today = DateTime.now();
  int? previousTotal;

  for (var i = 6; i >= 0; i--) {
    final day = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: i));
    final total = endOfDayTotal[day];

    if (total == null) {
      // No data that day — zero steps.
      result.add(_DailySteps(day, 0));
    } else {
      // Steps that day = today's total minus where we ended yesterday.
      final daySteps = previousTotal == null ? total : (total - previousTotal);
      result.add(_DailySteps(day, daySteps < 0 ? 0 : daySteps));
      previousTotal = total;
    }
  }

  return result;
}

class _StepsBarChart extends StatelessWidget {
  const _StepsBarChart({required this.samples, required this.metric});

  final List<HealthSample> samples;
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final daily = _bucketStepsByDay(samples);
    final todaySteps = daily.isNotEmpty ? daily.last.steps : 0;

    // The tallest bar sets the chart height; pad a little above it.
    final maxSteps = daily.fold<int>(0, (m, d) => d.steps > m ? d.steps : m);
    final maxY = (maxSteps * 1.2).clamp(100, double.infinity).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big "today" number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$todaySteps',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: WillColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'steps today',
                  style: TextStyle(
                    fontSize: 14,
                    color: WillColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Last 7 days',
            style: TextStyle(fontSize: 12, color: WillColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.toInt()} steps',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: WillColors.border.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: WillColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= daily.length) {
                          return const SizedBox.shrink();
                        }
                        // Show weekday initial (M, T, W...).
                        final d = daily[i].day;
                        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[d.weekday - 1],
                            style: const TextStyle(
                              color: WillColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < daily.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: daily[i].steps.toDouble(),
                          color: metric.color,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
