/// The user's per-person physiological baseline. Used to render insights
/// in terms the user actually feels, "HR +28 above resting" instead of
/// "HR 104 bpm".
///
/// Auto-learned from the first 24 h of calm data unless [isManual] is true,
/// in which case the user typed it in via the baseline sheet and we never
/// overwrite it.
class UserBaseline {
  const UserBaseline({
    required this.restingHr,
    required this.baselineSpo2,
    required this.baselineTemp,
    required this.learnedAt,
    required this.isManual,
  });

  /// Beats per minute at rest.
  final double restingHr;

  /// Typical blood-oxygen saturation, percent.
  final double baselineSpo2;

  /// Typical body temperature, °C.
  final double baselineTemp;

  /// When this baseline was committed (auto-learn) or entered (manual).
  final DateTime learnedAt;

  /// User typed these values, do not auto-overwrite.
  final bool isManual;

  UserBaseline copyWith({
    double? restingHr,
    double? baselineSpo2,
    double? baselineTemp,
    DateTime? learnedAt,
    bool? isManual,
  }) =>
      UserBaseline(
        restingHr: restingHr ?? this.restingHr,
        baselineSpo2: baselineSpo2 ?? this.baselineSpo2,
        baselineTemp: baselineTemp ?? this.baselineTemp,
        learnedAt: learnedAt ?? this.learnedAt,
        isManual: isManual ?? this.isManual,
      );

  Map<String, dynamic> toJson() => {
        'restingHr': restingHr,
        'baselineSpo2': baselineSpo2,
        'baselineTemp': baselineTemp,
        'learnedAt': learnedAt.millisecondsSinceEpoch,
        'isManual': isManual,
      };

  factory UserBaseline.fromJson(Map<String, dynamic> json) => UserBaseline(
        restingHr: (json['restingHr'] as num).toDouble(),
        baselineSpo2: (json['baselineSpo2'] as num).toDouble(),
        baselineTemp: (json['baselineTemp'] as num).toDouble(),
        learnedAt:
            DateTime.fromMillisecondsSinceEpoch(json['learnedAt'] as int),
        isManual: json['isManual'] as bool? ?? false,
      );
}
