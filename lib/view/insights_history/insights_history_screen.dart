import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/router/routes.dart';
import '../../helpers/insight_history_filter.dart';
import '../../models/insight.dart';
import '../../services/inference_service.dart';
import '../../services/insights_repository.dart';
import '../widgets/empty_placeholder.dart';
import 'widgets/date_range_chips.dart';
import 'widgets/severity_chips.dart';
import 'widgets/timeline_row.dart';

/// Retrospective view: every saved insight, grouped by day, filterable by
/// severity and date range. Lives at `/insights-history` and is reached
/// from the Profile screen.
class InsightsHistoryScreen extends StatefulWidget {
  const InsightsHistoryScreen({super.key});

  @override
  State<InsightsHistoryScreen> createState() => _InsightsHistoryScreenState();
}

class _InsightsHistoryScreenState extends State<InsightsHistoryScreen> {
  InsightLabel? _severity;
  InsightDateRange _range = InsightDateRange.thisWeek;
  late List<Insight> _all;

  @override
  void initState() {
    super.initState();
    _all = InsightsRepository.readRecent();
  }

  void _refresh() {
    setState(() => _all = InsightsRepository.readRecent());
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        filterInsights(_all, severity: _severity, range: _range);
    final grouped = groupByDay(filtered);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WillColors.background,
        elevation: 0,
        title: const Text(
          'Insights history',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: WillColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: WillColors.textPrimary),
      ),
      backgroundColor: WillColors.background,
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: WillColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  SeverityChips(
                    value: _severity,
                    onChanged: (v) => setState(() => _severity = v),
                  ),
                  const SizedBox(height: 10),
                  DateRangeChips(
                    value: _range,
                    onChanged: (v) => setState(() => _range = v),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            if (grouped.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyPlaceholder(
                  icon: CupertinoIcons.sparkles,
                  title: 'Nothing in this window.',
                  subtitle:
                      'Try widening the date range, or wait for new readings.',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: grouped.length,
                  (context, index) {
                    final day = grouped.keys.elementAt(index);
                    final rows = grouped[day]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                          child: Text(
                            _dayLabel(day).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: WillColors.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        ...rows.map(
                          (i) => TimelineRow(
                            insight: i,
                            onTap: () => context.push(
                              WillRoutes.insightDetail,
                              extra: i,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _dayLabel(DateTime day) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (sameDay(day, today)) return 'Today';
    if (sameDay(day, yesterday)) return 'Yesterday';
    return DateFormat('EEE · d MMM').format(day);
  }
}
