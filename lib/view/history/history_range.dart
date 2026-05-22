/// Preset time windows for the History chart.
enum HistoryRange {
  hour(label: '1H', duration: Duration(hours: 1)),
  sixHours(label: '6H', duration: Duration(hours: 6)),
  day(label: '24H', duration: Duration(hours: 24));

  const HistoryRange({required this.label, required this.duration});

  final String label;
  final Duration duration;
}
