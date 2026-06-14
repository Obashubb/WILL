class UserBaseline {
  const UserBaseline({
    required this.restingHr,
    required this.restingSpo2,
    required this.restingTemp,
    required this.capturedAt,
  });

  final int restingHr;
  final int restingSpo2;
  final double restingTemp;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() => {
        'restingHr': restingHr,
        'restingSpo2': restingSpo2,
        'restingTemp': restingTemp,
        'capturedAt': capturedAt.millisecondsSinceEpoch,
      };

  factory UserBaseline.fromJson(Map<String, dynamic> json) => UserBaseline(
        restingHr: (json['restingHr'] as num?)?.toInt() ?? 72,
        restingSpo2: (json['restingSpo2'] as num?)?.toInt() ?? 97,
        restingTemp: (json['restingTemp'] as num?)?.toDouble() ?? 36.7,
        capturedAt: json['capturedAt'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['capturedAt'] as int)
            : DateTime.now(),
      );

  UserBaseline copyWith({
    int? restingHr,
    int? restingSpo2,
    double? restingTemp,
    DateTime? capturedAt,
  }) =>
      UserBaseline(
        restingHr: restingHr ?? this.restingHr,
        restingSpo2: restingSpo2 ?? this.restingSpo2,
        restingTemp: restingTemp ?? this.restingTemp,
        capturedAt: capturedAt ?? this.capturedAt,
      );
}
