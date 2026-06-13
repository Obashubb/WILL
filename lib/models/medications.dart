class Medications {
  final String id;
  final String name;
  final String dose;
  final int hour;
  final int minute;
  final DateTime? lastTakenDate;

  Medications({
    required this.id,
    required this.name,
    required this.dose,
    required this.hour,
    required this.minute,
    this.lastTakenDate,
  });

  bool get takenToday {
    final lastTaken = lastTakenDate;
    if (lastTaken == null) return false;
    final now = DateTime.now();
    return lastTaken.year == now.year &&
        lastTaken.month == now.month &&
        lastTaken.day == now.day;
  }

  Medications copyWith({DateTime? lastTakenDate}) {
    return Medications(
      id: id,
      name: name,
      dose: dose,
      hour: hour,
      minute: minute,
      lastTakenDate: lastTakenDate ?? this.lastTakenDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dose': dose,
    'hour': hour,
    'minute': minute,
    'lastTakenDate': lastTakenDate?.toIso8601String(),
  };

  factory Medications.fromJson(Map<String, dynamic> json) => Medications(
    id: json['id'],
    name: json['name'],
    dose: json['dose'],
    hour: json['hour'],
    minute: json['minute'],
    lastTakenDate: json['lastTakenDate'] != null
        ? DateTime.parse(json['lastTakenDate'])
        : null,
  );
}
