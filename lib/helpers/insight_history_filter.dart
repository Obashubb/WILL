import '../models/insight.dart';

/// Preset windows for the Insights history screen.
enum InsightDateRange {
  today(label: 'Today'),
  thisWeek(label: 'This week'),
  all(label: 'All');

  const InsightDateRange({required this.label});
  final String label;
}

/// Returns the subset of [all] that matches the given filters. Pure
/// function, no Flutter import, no side effects.
List<Insight> filterInsights(
  List<Insight> all, {
  InsightSeverity? severity,
  required InsightDateRange range,
}) {
  final cutoff = _cutoffFor(range);
  return all.where((i) {
    if (cutoff != null && i.timestamp.isBefore(cutoff)) return false;
    if (severity != null && i.severity != severity) return false;
    return true;
  }).toList();
}

/// Groups [insights] by calendar day (local time). The map's keys are
/// midnight of each day; values are sorted reverse-chronological.
Map<DateTime, List<Insight>> groupByDay(List<Insight> insights) {
  final byDay = <DateTime, List<Insight>>{};
  for (final i in insights) {
    final local = i.timestamp.toLocal();
    final key = DateTime(local.year, local.month, local.day);
    byDay.putIfAbsent(key, () => []).add(i);
  }
  for (final list in byDay.values) {
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  return byDay;
}

/// Returns up to [limit] insights from [all] that fired before [pivot],
/// sorted reverse-chronological (most recent first).
List<Insight> insightsBefore(
  List<Insight> all,
  Insight pivot, {
  int limit = 5,
}) {
  final earlier = all
      .where((i) => i.timestamp.isBefore(pivot.timestamp))
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return earlier.take(limit).toList();
}

DateTime? _cutoffFor(InsightDateRange range) {
  final now = DateTime.now();
  switch (range) {
    case InsightDateRange.today:
      return DateTime(now.year, now.month, now.day);
    case InsightDateRange.thisWeek:
      // Cut off at midnight 7 days ago (rolling week, not calendar week).
      return DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
    case InsightDateRange.all:
      return null;
  }
}
