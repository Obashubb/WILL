class HydrationEntry {
  const HydrationEntry({
    required this.id,
    required this.amountMl,
    required this.timestamp,
  });

  final String id;
  final int amountMl;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amountMl': amountMl,
        'ts': timestamp.millisecondsSinceEpoch,
      };

  factory HydrationEntry.fromJson(Map<String, dynamic> json) => HydrationEntry(
        id: json['id'] as String,
        amountMl: json['amountMl'] as int,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      );
}
