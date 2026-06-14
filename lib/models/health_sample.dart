class HealthSample {
  const HealthSample({
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.motion,
    this.stepcount = 0, // NEW — defaults to 0 so old data still loads
    this.perfusionIndex = 0,
    this.hrv = 0,
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

  final int stepcount;

  final double perfusionIndex;
  final int hrv;

  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'hr': heartRate,
    'spo2': spo2,
    'temp': temperature,
    'motion': motion,
    'stepcount': stepcount,
    'perfusionIndex': perfusionIndex,
    'hrv': hrv,
    'ts': timestamp.millisecondsSinceEpoch,
  };

  factory HealthSample.fromJson(Map<String, dynamic> json) => HealthSample(
    heartRate: (json['hr'] as num?)?.toInt() ?? 0,
    spo2: (json['spo2'] as num?)?.toInt() ?? 0,
    temperature: (json['temp'] as num?)?.toDouble() ?? 0,
    motion: (json['motion'] as num?)?.toDouble() ?? 0,
    stepcount: (json['stepcount'] as num?)?.toInt() ?? 0,
    perfusionIndex: (json['perfusionIndex'] as num?)?.toDouble() ?? 0,
    hrv: (json['hrv'] as num?)?.toInt() ?? 0,
    timestamp: json['ts'] is int
        ? DateTime.fromMillisecondsSinceEpoch(json['ts'] as int)
        : DateTime.now(),
  );
}
