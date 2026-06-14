import '../models/insight.dart';
import '../services/inference_service.dart';

enum InsightDateRange {
  today('Today'),
  thisWeek('This week'),
  all('All');

  const InsightDateRange(this.label);
  final String label;
}

List<Insight> filterInsights(
  List<Insight> all, {
  InsightLabel? severity,
  required InsightDateRange range,
}) {
  final now = DateTime.now();
  bool inRange(DateTime t) {
    switch (range) {
      case InsightDateRange.today:
        return t.year == now.year && t.month == now.month && t.day == now.day;
      case InsightDateRange.thisWeek:
        return now.difference(t).inDays < 7;
      case InsightDateRange.all:
        return true;
    }
  }

  return all
      .where((i) => inRange(i.timestamp))
      .where((i) => severity == null ? true : i.severity == severity)
      .toList();
}

Map<DateTime, List<Insight>> groupByDay(List<Insight> insights) {
  final out = <DateTime, List<Insight>>{};
  for (final i in insights) {
    final day = DateTime(i.timestamp.year, i.timestamp.month, i.timestamp.day);
    out.putIfAbsent(day, () => []).add(i);
  }
  final sortedKeys = out.keys.toList()..sort((a, b) => b.compareTo(a));
  return {for (final k in sortedKeys) k: out[k]!};
}

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
