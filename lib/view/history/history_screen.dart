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
  heartRate('Heart rate', 'bpm', WillColors.danger),
  spo2('Oxygen', '%', WillColors.action),
  temperature('Temperature', '°C', WillColors.warning),
  motion('Activity', '', WillColors.accent);

  const _Metric(this.label, this.unit, this.color);
  final String label;
  final String unit;
  final Color color;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  _Metric _metric = _Metric.heartRate;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final wearable = Get.find<WearableService>();
    return Obx(() {
      // Rebuild whenever a new sample lands so the chart stays fresh.
      wearable.latestSample.value;
      final samples = SamplesRepository.readRecent();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('History'),
          const SizedBox(height: 12),
          _MetricPicker(
            value: _metric,
            onChanged: (m) => setState(() => _metric = m),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: samples.isEmpty
                ? const EmptyPlaceholder(
                    icon: Icons.show_chart,
                    title: 'No readings yet.',
                    subtitle: 'Trends will appear here as the band collects data.',
                  )
                : _TrendChart(samples: samples, metric: _metric),
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

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.samples, required this.metric});

  final List<HealthSample> samples;
  final _Metric metric;

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

  @override
  Widget build(BuildContext context) {
    final spots = samples
        .map((s) => FlSpot(
              s.timestamp.millisecondsSinceEpoch.toDouble(),
              _value(s),
            ))
        .toList();

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() * 0.15 + 1;

    final first = samples.first;
    final last = samples.last;
    final latestValue = _formatValue(last);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latestValue,
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
            '${DateFormat.jm().format(first.timestamp)} — ${DateFormat.jm().format(last.timestamp)} · ${samples.length} samples',
            style: const TextStyle(
              fontSize: 12,
              color: WillColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY - pad,
                maxY: maxY + pad,
                lineTouchData: const LineTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY - minY).abs() / 4)
                      .clamp(0.5, double.infinity),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: WillColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: metric.color,
                    barWidth: 2.4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: metric.color.withValues(alpha: 0.08),
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

  String _formatValue(HealthSample s) {
    switch (metric) {
      case _Metric.heartRate:
        return s.heartRate.toString();
      case _Metric.spo2:
        return s.spo2.toString();
      case _Metric.temperature:
        return s.temperature.toStringAsFixed(1);
      case _Metric.motion:
        return s.motion.toStringAsFixed(2);
    }
  }
}
