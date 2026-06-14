import '../services/inference_service.dart';
import 'health_sample.dart';

class Insight {
  const Insight({
    required this.id,
    required this.timestamp,
    required this.severity,
    required this.condition,
    required this.sample,
    this.helpful,
  });

  final String id;
  final DateTime timestamp;
  final InsightLabel severity;
  final ConditionLabel condition;
  final HealthSample sample;
  final bool? helpful;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'severity': severity.name,
        'condition': condition.name,
        'sample': sample.toJson(),
        'helpful': helpful,
      };

  factory Insight.fromJson(Map<String, dynamic> json) {
    final ts = json['timestamp'] is int
        ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
        : DateTime.now();
    final severity = InsightLabel.values.firstWhere(
      (e) => e.name == json['severity'],
      orElse: () => InsightLabel.normal,
    );
    final condition = ConditionLabel.values.firstWhere(
      (e) => e.name == json['condition'],
      orElse: () => ConditionLabel.none,
    );
    final rawSample = json['sample'];
    final sample = rawSample is Map
        ? HealthSample.fromJson(Map<String, dynamic>.from(rawSample))
        : HealthSample(
            heartRate: 0,
            spo2: 0,
            temperature: 0,
            motion: 0,
            timestamp: ts,
          );
    return Insight(
      id: (json['id'] as String?) ?? buildId(ts, severity, condition),
      timestamp: ts,
      severity: severity,
      condition: condition,
      sample: sample,
      helpful: json['helpful'] as bool?,
    );
  }

  Insight copyWith({bool? helpful}) => Insight(
        id: id,
        timestamp: timestamp,
        severity: severity,
        condition: condition,
        sample: sample,
        helpful: helpful ?? this.helpful,
      );

  static String buildId(DateTime t, InsightLabel s, ConditionLabel c) =>
      '${t.millisecondsSinceEpoch}-${s.name}-${c.name}';
}
