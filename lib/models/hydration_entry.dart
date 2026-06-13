class HydrationEntry {
  final int amountMl;
  final DateTime timestamp;

  HydrationEntry({required this.amountMl, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'amountMl': amountMl,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HydrationEntry.fromJson(Map<String, dynamic> json) => HydrationEntry(
    amountMl: json['amountMl'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}
