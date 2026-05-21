class HealthSample {
  const HealthSample({
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.motion,
    required this.timestamp,
  });

  /// Beats per minute.
  final int heartRate;

  /// Blood oxygen saturation, percent (0-100).
  final int spo2;

  /// Body temperature in degrees Celsius.
  final double temperature;

  /// Motion magnitude, normalized 0-1 (rough indication of activity).
  final double motion;

  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'hr': heartRate,
        'spo2': spo2,
        'temp': temperature,
        'motion': motion,
        'ts': timestamp.millisecondsSinceEpoch,
      };

  factory HealthSample.fromJson(Map<String, dynamic> json) => HealthSample(
        heartRate: json['hr'] as int,
        spo2: json['spo2'] as int,
        temperature: (json['temp'] as num).toDouble(),
        motion: (json['motion'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      );
}
