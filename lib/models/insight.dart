enum InsightLabel { normal, stress, dehydration, abnormalOxygen }

class Insight {
  const Insight({
    required this.label,
    required this.confidence,
    required this.probs,
    required this.features,
    required this.timestamp,
  });

  final InsightLabel label;
  final double confidence;
  final Map<InsightLabel, double> probs;
  final InsightFeatures features;
  final DateTime timestamp;

  bool get isConcerning => label != InsightLabel.normal && confidence >= 0.5;
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
        return 'Your heart rate climbed without much movement. Could be stress or pain — try sitting calmly and breathing slowly.';
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
          'Stay hydrated — small sips throughout the day.',
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
