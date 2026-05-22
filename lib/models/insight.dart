enum InsightLabel { normal, stress, dehydration, abnormalOxygen }

/// Three-tier user-facing severity derived from a raw [Insight]. The
/// underlying [InsightLabel] still drives narrative + recommendations;
/// severity drives colour, urgency framing, and alert delivery.
enum InsightSeverity { calm, watch, act }

class Insight {
  const Insight({
    required this.id,
    required this.label,
    required this.confidence,
    required this.probs,
    required this.features,
    required this.timestamp,
  });

  /// Stable id used for persistence + Firestore document name.
  final String id;
  final InsightLabel label;
  final double confidence;
  final Map<InsightLabel, double> probs;
  final InsightFeatures features;
  final DateTime timestamp;

  InsightSeverity get severity {
    if (label == InsightLabel.normal) {
      return confidence >= 0.6 ? InsightSeverity.calm : InsightSeverity.watch;
    }
    return confidence >= 0.7 ? InsightSeverity.act : InsightSeverity.watch;
  }

  bool get isConcerning => severity != InsightSeverity.calm;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': InsightLabelExt(label).wire,
        'confidence': confidence,
        'probs': {
          for (final e in probs.entries) InsightLabelExt(e.key).wire: e.value,
        },
        'features': {
          'hrMean': features.hrMean,
          'hrSlope': features.hrSlope,
          'spo2Min': features.spo2Min,
          'tempMax': features.tempMax,
          'motionVar': features.motionVar,
          'sampleCount': features.sampleCount,
        },
        'ts': timestamp.millisecondsSinceEpoch,
        'severity': severity.name,
      };

  factory Insight.fromJson(Map<String, dynamic> json) {
    final f = Map<String, dynamic>.from(json['features'] as Map);
    final p = Map<String, dynamic>.from(json['probs'] as Map);
    return Insight(
      id: json['id'] as String,
      label: InsightLabelExt.fromWire(json['label'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      probs: {
        for (final e in p.entries)
          InsightLabelExt.fromWire(e.key): (e.value as num).toDouble(),
      },
      features: InsightFeatures(
        hrMean: (f['hrMean'] as num).toDouble(),
        hrSlope: (f['hrSlope'] as num).toDouble(),
        spo2Min: (f['spo2Min'] as num).toDouble(),
        tempMax: (f['tempMax'] as num).toDouble(),
        motionVar: (f['motionVar'] as num).toDouble(),
        sampleCount: f['sampleCount'] as int,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
    );
  }
}

enum InsightFeedbackStatus { helpful, wrong }

class InsightFeedback {
  const InsightFeedback({
    required this.insightId,
    required this.status,
    required this.actedAt,
  });

  final String insightId;
  final InsightFeedbackStatus status;
  final DateTime actedAt;

  Map<String, dynamic> toJson() => {
        'insightId': insightId,
        'status': status.name,
        'actedAt': actedAt.millisecondsSinceEpoch,
      };

  factory InsightFeedback.fromJson(Map<String, dynamic> json) =>
      InsightFeedback(
        insightId: json['insightId'] as String,
        status: InsightFeedbackStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => InsightFeedbackStatus.helpful,
        ),
        actedAt: DateTime.fromMillisecondsSinceEpoch(json['actedAt'] as int),
      );
}

class InsightFeatures {
  const InsightFeatures({
    required this.hrMean,
    required this.hrSlope,
    required this.spo2Min,
    required this.tempMax,
    required this.motionVar,
    required this.sampleCount,
  });

  final double hrMean;
  final double hrSlope;
  final double spo2Min;
  final double tempMax;
  final double motionVar;
  final int sampleCount;

  List<double> asVector() => [hrMean, hrSlope, spo2Min, tempMax, motionVar];
}

extension InsightLabelExt on InsightLabel {
  static const _wireNames = {
    InsightLabel.normal: 'normal',
    InsightLabel.stress: 'stress',
    InsightLabel.dehydration: 'dehydration',
    InsightLabel.abnormalOxygen: 'abnormal_oxygen',
  };

  String get wire => _wireNames[this]!;

  static InsightLabel fromWire(String s) {
    return _wireNames.entries
        .firstWhere(
          (e) => e.value == s,
          orElse: () => const MapEntry(InsightLabel.normal, 'normal'),
        )
        .key;
  }

  /// Short, user-facing label.
  String get display {
    switch (this) {
      case InsightLabel.normal:
        return 'All clear';
      case InsightLabel.stress:
        return 'Looking stressed';
      case InsightLabel.dehydration:
        return 'Hydration check';
      case InsightLabel.abnormalOxygen:
        return 'Low oxygen';
    }
  }

  /// Plain-English explanation shown under the headline.
  String get narrative {
    switch (this) {
      case InsightLabel.normal:
        return 'Your vitals are within healthy ranges. Keep doing what you’re doing.';
      case InsightLabel.stress:
        return 'Your heart rate climbed without much movement. Could be stress or pain, try sitting calmly and breathing slowly.';
      case InsightLabel.dehydration:
        return 'Your temperature is slightly elevated while you’re still. Drink some water.';
      case InsightLabel.abnormalOxygen:
        return 'Your blood oxygen dipped below normal. If it stays low, contact a healthcare professional.';
    }
  }

  List<String> get recommendations {
    switch (this) {
      case InsightLabel.normal:
        return const [
          'Keep your usual rhythm.',
          'Stay hydrated, small sips throughout the day.',
        ];
      case InsightLabel.stress:
        return const [
          'Sit down and take five slow breaths.',
          'Check if you’re in pain. If yes, treat it early.',
          'Limit caffeine for the next hour.',
        ];
      case InsightLabel.dehydration:
        return const [
          'Drink 250 ml of water now.',
          'Avoid intense activity until temperature settles.',
        ];
      case InsightLabel.abnormalOxygen:
        return const [
          'Sit upright and breathe slowly.',
          'If oxygen stays under 92% for more than a few minutes, get medical attention.',
        ];
    }
  }
}
