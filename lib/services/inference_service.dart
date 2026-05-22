import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../core/ble_constants.dart';
import '../models/health_sample.dart';
import '../models/insight.dart';
import 'notification_service.dart';
import 'wearable_service.dart';

/// Runs the on-device Random Forest over a 30-second rolling window of
/// samples and publishes the latest [Insight].
///
/// The model itself lives in `assets/ml/model.json` and is loaded once at
/// startup. Inference is a few microseconds of tree walking — cheap enough
/// to re-run on every new sample.
class InferenceService extends GetxService {
  static const String _modelAsset = 'assets/ml/model.json';
  static const Duration _windowLength = Duration(seconds: 30);
  static const int _minSamples = 5;

  final Rxn<Insight> latestInsight = Rxn<Insight>();
  final RxBool isReady = false.obs;

  late List<InsightLabel> _labels;
  late List<Map<String, dynamic>> _trees;
  final List<HealthSample> _window = [];
  StreamSubscription<HealthSample?>? _sub;

  static const double _alertConfidence = 0.7;
  static const Duration _alertCooldown = Duration(minutes: 5);
  final Map<InsightLabel, DateTime> _lastAlertAt = {};

  @override
  void onInit() {
    super.onInit();
    _loadModel();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _loadModel() async {
    try {
      final raw = await rootBundle.loadString(_modelAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _labels = (json['labels'] as List)
          .map((s) => InsightLabelExt.fromWire(s as String))
          .toList();
      _trees = (json['trees'] as List)
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList();
      isReady.value = true;
      _attach();
    } catch (e) {
      isReady.value = false;
    }
  }

  void _attach() {
    final wearable = Get.find<WearableService>();
    _sub = wearable.latestSample.stream.listen((sample) {
      if (sample == null) return;
      _ingest(sample);
    });
    final initial = wearable.latestSample.value;
    if (initial != null) _ingest(initial);
  }

  void _ingest(HealthSample sample) {
    _window.add(sample);
    final cutoff = DateTime.now().subtract(_windowLength);
    _window.removeWhere((s) => s.timestamp.isBefore(cutoff));
    if (_window.length < _minSamples) return;
    final insight = _predict();
    latestInsight.value = insight;
    _maybeAlert(insight);
  }

  void _maybeAlert(Insight insight) {
    if (!insight.isConcerning) return;
    if (insight.confidence < _alertConfidence) return;
    final last = _lastAlertAt[insight.label];
    if (last != null && DateTime.now().difference(last) < _alertCooldown) return;
    _lastAlertAt[insight.label] = DateTime.now();
    // Buzz the band on the wrist…
    final wearable = Get.find<WearableService>();
    wearable.sendCommand(WearableCommand.vibrate);
    // …and surface a system notification so the user sees it even if the
    // app is in the background.
    NotificationService.fireInsightAlert(
      title: insight.label.display,
      body: insight.label.narrative,
      tag: insight.label.index,
    );
  }

  Insight _predict() {
    final features = _extractFeatures(_window);
    final votes = List<double>.filled(_labels.length, 0);
    for (final tree in _trees) {
      final probs = _walk(tree, features.asVector());
      for (var i = 0; i < probs.length; i++) {
        votes[i] += probs[i];
      }
    }
    for (var i = 0; i < votes.length; i++) {
      votes[i] /= _trees.length;
    }

    var bestIndex = 0;
    for (var i = 1; i < votes.length; i++) {
      if (votes[i] > votes[bestIndex]) bestIndex = i;
    }

    return Insight(
      label: _labels[bestIndex],
      confidence: votes[bestIndex],
      probs: {
        for (var i = 0; i < _labels.length; i++) _labels[i]: votes[i],
      },
      features: features,
      timestamp: DateTime.now(),
    );
  }

  List<double> _walk(Map<String, dynamic> node, List<double> features) {
    var current = node;
    while (current['type'] == 'split') {
      final f = features[current['feature'] as int];
      final t = (current['threshold'] as num).toDouble();
      current = Map<String, dynamic>.from(
        (f <= t ? current['left'] : current['right']) as Map,
      );
    }
    final probs = (current['probs'] as List).cast<num>();
    return probs.map((p) => p.toDouble()).toList();
  }

  InsightFeatures _extractFeatures(List<HealthSample> window) {
    final n = window.length;
    final hr = window.map((s) => s.heartRate.toDouble()).toList();
    final spo2 = window.map((s) => s.spo2.toDouble()).toList();
    final temp = window.map((s) => s.temperature).toList();
    final motion = window.map((s) => s.motion).toList();

    final hrMean = hr.reduce((a, b) => a + b) / n;
    final spo2Min = spo2.reduce(min);
    final tempMax = temp.reduce(max);
    final motionMean = motion.reduce((a, b) => a + b) / n;
    final motionVar = motion
            .map((m) => (m - motionMean) * (m - motionMean))
            .reduce((a, b) => a + b) /
        n;

    final secondsSpan = window.last.timestamp
        .difference(window.first.timestamp)
        .inMilliseconds /
        1000;
    final hrSlope = secondsSpan <= 0
        ? 0.0
        : (window.last.heartRate - window.first.heartRate) / secondsSpan;

    return InsightFeatures(
      hrMean: hrMean,
      hrSlope: hrSlope,
      spo2Min: spo2Min,
      tempMax: tempMax,
      motionVar: motionVar,
      sampleCount: n,
    );
  }
}
