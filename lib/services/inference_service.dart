import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/health_sample.dart';

enum InsightLabel { normal, watch, alert }

enum ConditionLabel { none, stress, dehydration, overexertion }

/// The full result of one classification: severity + likely condition.
class InsightResult {
  final InsightLabel severity;
  final ConditionLabel condition;
  const InsightResult(this.severity, this.condition);
}

class InferenceService extends GetxService {
  List<Map<String, dynamic>> _trees = [];
  bool _ready = false;

  Future<InferenceService> init() async {
    final jsonStr = await rootBundle.loadString('assets/ml/model.json');
    final model = json.decode(jsonStr) as Map<String, dynamic>;
    _trees = List<Map<String, dynamic>>.from(model['trees']);
    _ready = true;
    return this;
  }

  /// Classifies a sample into severity + condition using the multi-output forest.
  InsightResult classify(HealthSample sample) {
    if (!_ready) {
      return const InsightResult(InsightLabel.normal, ConditionLabel.none);
    }

    final features = [
      sample.heartRate.toDouble(),
      sample.spo2.toDouble(),
      sample.temperature,
      sample.motion,
      sample.perfusionIndex,
      sample.hrv.toDouble(),
    ];

    // Tally votes for each output across all trees.
    final severityVotes = List<int>.filled(3, 0); // Normal, Watch, Alert
    final conditionVotes = List<int>.filled(
      4,
      0,
    ); // None, Stress, Dehydr, Overex

    for (final tree in _trees) {
      final result = _walkTree(tree, features);
      severityVotes[result[0]]++;
      conditionVotes[result[1]]++;
    }

    final severityIndex = _argmax(severityVotes);
    final conditionIndex = _argmax(conditionVotes);

    return InsightResult(
      InsightLabel.values[severityIndex],
      ConditionLabel.values[conditionIndex],
    );
  }

  /// Walks one tree and returns [severityClass, conditionClass] at the leaf.
  List<int> _walkTree(Map<String, dynamic> tree, List<double> features) {
    final childrenLeft = List<int>.from(tree['children_left']);
    final childrenRight = List<int>.from(tree['children_right']);
    final featureIndex = List<int>.from(tree['feature']);
    final threshold = List<double>.from(
      (tree['threshold'] as List).map((e) => (e as num).toDouble()),
    );
    final value = tree['value'] as List;

    int node = 0;
    while (childrenLeft[node] != -1) {
      final f = featureIndex[node];
      if (features[f] <= threshold[node]) {
        node = childrenLeft[node];
      } else {
        node = childrenRight[node];
      }
    }

    // value[node] is [output][class] — output 0 = severity, output 1 = condition.
    final leaf = value[node] as List;
    final severityCounts = List<num>.from(leaf[0] as List);
    final conditionCounts = List<num>.from(leaf[1] as List);

    return [_argmax(severityCounts), _argmax(conditionCounts)];
  }

  int _argmax(List<num> counts) {
    var maxI = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] > counts[maxI]) maxI = i;
    }
    return maxI;
  }

  String messageFor(InsightLabel label) {
    switch (label) {
      case InsightLabel.normal:
        return 'Your vitals look stable. Keep hydrated and stay rested.';
      case InsightLabel.watch:
        return 'Some readings need attention. Rest, drink water, and monitor closely.';
      case InsightLabel.alert:
        return 'Your vitals are concerning. Please contact your doctor or go to a clinic immediately.';
    }
  }

  /// Plain-English description of the detected condition.
  String conditionMessage(ConditionLabel c) {
    switch (c) {
      case ConditionLabel.none:
        return 'No specific condition detected.';
      case ConditionLabel.stress:
        return 'This looks like stress — your heart rate is raised while oxygen stays normal. Try to rest and breathe slowly.';
      case ConditionLabel.dehydration:
        return 'This looks like dehydration — raised heart rate with slightly low oxygen. Drink water and rest.';
      case ConditionLabel.overexertion:
        return 'This looks like overexertion — high activity with a rising heart rate. Slow down and take a break.';
    }
  }
}
