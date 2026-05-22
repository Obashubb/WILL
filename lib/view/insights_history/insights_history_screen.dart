import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/routes.dart';
import '../../helpers/insight_history_filter.dart';
import '../../models/insight.dart';
import '../../services/insights_repository.dart';
import '../widgets/insights/timeline_row.dart';
import '../widgets/empty_placeholder.dart';
import '../widgets/row_divider_label.dart';
import '../widgets/will_inkwell.dart';
import '../widgets/insights_history/date_range_chips.dart';
import '../widgets/insights_history/severity_chips.dart';

class InsightsHistoryScreen extends StatefulWidget {
  const InsightsHistoryScreen({super.key});

  @override
  State<InsightsHistoryScreen> createState() => _InsightsHistoryScreenState();
}

class _InsightsHistoryScreenState extends State<InsightsHistoryScreen> {
  InsightSeverity? _severity;
  InsightDateRange _range = InsightDateRange.thisWeek;

  @override
  Widget build(BuildContext context) {
    final all = InsightsRepository.readRecent();
    final filtered = filterInsights(all, severity: _severity, range: _range);
    final grouped = groupByDay(filtered);
    final days = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Insights history')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            SeverityChips(
              value: _severity,
              onChanged: (s) => setState(() => _severity = s),
            ),
            const SizedBox(height: 10),
            DateRangeChips(
              value: _range,
              onChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyPlaceholder(
                      icon: Icons.history,
                      title: 'Nothing here yet.',
                      subtitle:
                          'Try a wider date range or wear the band longer to build up history.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: days.length,
                      itemBuilder: (context, i) {
                        final day = days[i];
                        final items = grouped[day]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (i > 0) const SizedBox(height: 14),
                            RowDividerLabel(label: _formatDayHeader(day)),
                            ...items.map(
                              (insight) => WillInkwell(
                                onTap: () => context.push(
                                  WillRoutes.insightDetail,
                                  extra: insight,
                                ),
                                child: TimelineRow(insight: insight),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDayHeader(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(day);
  }
}
