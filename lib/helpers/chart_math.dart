import '../models/health_sample.dart';

/// Bucket-averages [samples] down to roughly [target] points. Preserves the
/// shape of the curve while removing high-frequency noise.
List<HealthSample> downsample(List<HealthSample> samples, int target) {
  if (samples.length <= target) return samples;
  final bucketSize = samples.length / target;
  final out = <HealthSample>[];
  for (var i = 0; i < target; i++) {
    final start = (i * bucketSize).floor();
    final end =
        ((i + 1) * bucketSize).floor().clamp(start + 1, samples.length);
    final bucket = samples.sublist(start, end);

    var hrSum = 0;
    var spo2Sum = 0;
    var tempSum = 0.0;
    var motionSum = 0.0;
    for (final s in bucket) {
      hrSum += s.heartRate;
      spo2Sum += s.spo2;
      tempSum += s.temperature;
      motionSum += s.motion;
    }
    final n = bucket.length;
    out.add(HealthSample(
      heartRate: (hrSum / n).round(),
      spo2: (spo2Sum / n).round(),
      temperature: double.parse((tempSum / n).toStringAsFixed(2)),
      motion: double.parse((motionSum / n).toStringAsFixed(3)),
      timestamp: bucket[n ~/ 2].timestamp,
    ));
  }
  return out;
}

/// Computes a Y window where the data occupies the middle 50 % of the
/// chart (25 % breathing room top and bottom). Expands to [minRange] when
/// data is too flat for a meaningful auto-scale.
({double minY, double maxY}) yWindow(
  double dataMin,
  double dataMax,
  double minRange,
) {
  final dataRange = (dataMax - dataMin).abs();
  final center = (dataMin + dataMax) / 2;
  var chartRange = dataRange * 2;
  if (chartRange < minRange) chartRange = minRange;
  final half = chartRange / 2;
  return (minY: center - half, maxY: center + half);
}

/// One-decimal for temperatures, two-decimal for motion, zero-decimal for
/// everything else (heart rate, oxygen). The chart's metric chooses which
/// formatter it wants.
typedef NumberFormatter = String Function(double value);

String formatInt(double v) => v.toStringAsFixed(0);
String formatOneDecimal(double v) => v.toStringAsFixed(1);
String formatTwoDecimal(double v) => v.toStringAsFixed(2);
