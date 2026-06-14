import '../services/inference_service.dart';
import 'health_sample.dart';

/// A persisted snapshot of one inference event. The Insights History screen
/// reads a list of these; the live Insights tab continues to read the
/// in-memory `currentInsight` directly off `WearableService`.
class Insight {
  const Insight({
    required this.id,
    required this.timestamp,
    required this.severity,
    required this.condition,
    required this.sample,
    this.helpful,
  });

  /// Stable id, used by the detail screen's `extra` payload + list keys.
  /// Built from millisecondsSinceEpoch + severity.name + condition.name so
  /// it's deterministic and human-debuggable.
  final String id;

  final DateTime timestamp;
  final InsightLabel severity;
  final ConditionLabel condition;

  /// The vitals snapshot at the moment of classification. Detail screen
  /// renders HR / SpO₂ / temp / motion from this.
  final HealthSample sample;

  /// User feedback on whether the insight was useful. `null` means not
  /// rated yet, `true` = thumbs up, `false` = thumbs down.
  final bool? helpful;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'severity': severity.name,
        'condition': condition.name,
        'sample': sample.toJson(),
        'helpful': helpful,
      };

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
        id: json['id'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        severity: InsightLabel.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => InsightLabel.normal,
        ),
        condition: ConditionLabel.values.firstWhere(
          (e) => e.name == json['condition'],
          orElse: () => ConditionLabel.none,
        ),
        sample:
            HealthSample.fromJson(Map<String, dynamic>.from(json['sample'])),
        helpful: json['helpful'] as bool?,
      );

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
