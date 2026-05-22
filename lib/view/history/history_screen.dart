import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/chart_math.dart';
import '../../services/samples_repository.dart';
import '../../services/wearable_service.dart';
import '../widgets/empty_placeholder.dart';
import '../widgets/section_title.dart';
import 'history_metric.dart';
import 'history_range.dart';
import '../widgets/history/metric_picker.dart';
import '../widgets/history/range_picker.dart';
import '../widgets/history/trend_chart.dart';

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
  HistoryMetric _metric = HistoryMetric.heartRate;
  HistoryRange _range = HistoryRange.hour;

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
          MetricPicker(
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
                        child: RangePicker(
                          value: _range,
                          onChanged: (r) => setState(() => _range = r),
                        ),
                      ),
                      const Expanded(
                        child: EmptyPlaceholder(
                          icon: Icons.show_chart,
                          title: 'Not enough data yet.',
                          subtitle:
                              'Wear the band for about a minute, trends will appear here.',
                        ),
                      ),
                    ],
                  )
                : TrendChart(
                    samples: downsample(raw, _targetPoints),
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
