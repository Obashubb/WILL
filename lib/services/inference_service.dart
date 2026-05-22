import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../core/ble_constants.dart';
import '../models/health_sample.dart';
import '../models/insight.dart';
import '../models/user_baseline.dart';
import 'insights_repository.dart';
import 'notification_service.dart';
import 'profile_service.dart';
import 'wearable_service.dart';

/// Runs the on-device Random Forest over a 30-second rolling window of
/// samples and publishes the latest [Insight].
///
/// Side effects on each new insight:
///  * `latestInsight` Rx is updated (drives the Insights tab live).
///  * Watch + Act insights are persisted via [InsightsRepository] for the
///    history timeline and queued for Firestore upload.
///  * Act insights trigger band vibrate + system notification, debounced
///    to one alert per label every 5 minutes.
///
/// In parallel, a [BaselineCalibrator] watches "calm" samples and commits
/// an auto-learned [UserBaseline] to [ProfileService] after 24 h. Manual
/// baselines (typed in by the user) are never overwritten.
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

  static const Duration _alertCooldown = Duration(minutes: 5);
  static const Duration _persistHeartbeat = Duration(minutes: 5);

  final Map<InsightLabel, DateTime> _lastAlertAt = {};

  /// Track the last insight we wrote to [InsightsRepository] so we can
  /// persist only on transitions (label / severity change) or via the
  /// heartbeat below. Prevents 30 calm entries per minute filling the log.
  Insight? _lastPersisted;
  DateTime? _lastPersistedAt;

  final _BaselineCalibrator _calibrator = _BaselineCalibrator();

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
    _calibrator.consider(sample, insight);
    _persistIfChangedOrHeartbeat(insight);
    _maybeAlert(insight);
  }

  /// Persist when the label or severity differs from the last persisted
  /// insight, OR when [_persistHeartbeat] has elapsed since the last
  /// write. Stops the log filling with 30 calm copies per minute while
  /// still leaving long calm stretches visible as periodic markers.
  void _persistIfChangedOrHeartbeat(Insight insight) {
    final last = _lastPersisted;
    final lastAt = _lastPersistedAt;
    final changed = last == null ||
        last.label != insight.label ||
        last.severity != insight.severity;
    final heartbeat =
        lastAt == null || DateTime.now().difference(lastAt) >= _persistHeartbeat;
    if (!changed && !heartbeat) return;
    _lastPersisted = insight;
    _lastPersistedAt = DateTime.now();
    InsightsRepository.appendRecent(insight);
    InsightsRepository.enqueuePending(insight);
  }

  /// Clear in-memory persister state. Called from AuthController on
  /// sign-out so a fresh account starts with a clean slate.
  void resetPersisterState() {
    _lastPersisted = null;
    _lastPersistedAt = null;
    _lastAlertAt.clear();
  }

  void _maybeAlert(Insight insight) {
    // Only Act severity fires the band buzz + system notification. Watch
    // is signalled visually in-app only.
    if (insight.severity != InsightSeverity.act) return;
    final last = _lastAlertAt[insight.label];
    if (last != null && DateTime.now().difference(last) < _alertCooldown) {
      return;
    }
    _lastAlertAt[insight.label] = DateTime.now();
    final wearable = Get.find<WearableService>();
    wearable.sendCommand(WearableCommand.vibrate);
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

    final ts = DateTime.now();
    return Insight(
      id: 'ins_${ts.microsecondsSinceEpoch}',
      label: _labels[bestIndex],
      confidence: votes[bestIndex],
      probs: {
        for (var i = 0; i < _labels.length; i++) _labels[i]: votes[i],
      },
      features: features,
      timestamp: ts,
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

/// Watches calm, still samples and quietly averages them into a per-user
/// baseline. Commits to [ProfileService] once we have 1000 calm samples or
/// 24 h has elapsed since calibration started.
///
/// Manual baselines (typed in by the user) are honoured forever, the
/// calibrator checks `isManual` before writing.
class _BaselineCalibrator {
  static const int _minSamples = 1000;
  static const Duration _maxDuration = Duration(hours: 24);
  static const double _stillVarianceCeiling = 0.05;

  DateTime? _startedAt;
  int _count = 0;
  double _hrSum = 0;
  double _spo2Sum = 0;
  double _tempSum = 0;
  bool _committed = false;

  void consider(HealthSample sample, Insight insight) {
    final existing = ProfileService.readBaseline();
    if (existing?.isManual == true) return; // Never overwrite manual.
    if (_committed && existing != null) return;

    final isCalm = insight.severity == InsightSeverity.calm &&
        insight.features.motionVar < _stillVarianceCeiling;
    if (!isCalm) return;

    _startedAt ??= DateTime.now();
    _hrSum += sample.heartRate;
    _spo2Sum += sample.spo2;
    _tempSum += sample.temperature;
    _count += 1;

    final elapsed = DateTime.now().difference(_startedAt!);
    if (_count >= _minSamples || elapsed >= _maxDuration) {
      _commit();
    }
  }

  void _commit() {
    if (_count == 0) return;
    final baseline = UserBaseline(
      restingHr: _hrSum / _count,
      baselineSpo2: _spo2Sum / _count,
      baselineTemp: _tempSum / _count,
      learnedAt: DateTime.now(),
      isManual: false,
    );
    ProfileService.writeBaseline(baseline);
    _committed = true;
  }
}
