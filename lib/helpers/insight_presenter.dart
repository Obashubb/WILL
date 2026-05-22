import 'package:flutter/cupertino.dart';

import '../core/colors.dart';
import '../models/insight.dart';
import '../models/user_baseline.dart';

/// Pure-function presentation helpers for [Insight]. The view layer reads
/// from these so screens stay layout-only.
class InsightPresenter {
  InsightPresenter._();

  static ({Color color, IconData icon, String title}) heroSpec(
    InsightSeverity severity,
  ) {
    switch (severity) {
      case InsightSeverity.calm:
        return (
          color: WillColors.accent,
          icon: CupertinoIcons.checkmark_seal_fill,
          title: 'All clear',
        );
      case InsightSeverity.watch:
        return (
          color: WillColors.warning,
          icon: CupertinoIcons.eye_fill,
          title: 'Something to watch',
        );
      case InsightSeverity.act:
        return (
          color: WillColors.danger,
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          title: 'Time to act',
        );
    }
  }

  /// "Looking stressed · 74%" type subline. For calm the label is dropped.
  static String sublineFor(Insight insight) {
    final pct = (insight.confidence * 100).clamp(0, 100).toStringAsFixed(0);
    if (insight.severity == InsightSeverity.calm) {
      return '$pct% confident';
    }
    return '${insight.label.display} · $pct%';
  }

  /// Personalized "why" line. Falls back to the static narrative on the
  /// label when the user has no baseline or the delta is too small.
  static String whyFor(Insight insight, UserBaseline? baseline) {
    if (baseline == null) return insight.label.narrative;
    final b = baseline;
    final f = insight.features;
    switch (insight.label) {
      case InsightLabel.normal:
        return 'Your vitals are sitting close to your usual numbers.';
      case InsightLabel.stress:
        final delta = f.hrMean - b.restingHr;
        if (delta < 5) return insight.label.narrative;
        return 'Heart rate ${_signed(delta, 0)} above your resting ${b.restingHr.toStringAsFixed(0)}, with little movement.';
      case InsightLabel.dehydration:
        final delta = f.tempMax - b.baselineTemp;
        if (delta < 0.2) return insight.label.narrative;
        return 'Temperature ${_signed(delta, 1)} °C above your typical ${b.baselineTemp.toStringAsFixed(1)} while you’re still.';
      case InsightLabel.abnormalOxygen:
        final delta = b.baselineSpo2 - f.spo2Min;
        if (delta < 1) return insight.label.narrative;
        return 'Oxygen ${delta.toStringAsFixed(0)} below your usual ${b.baselineSpo2.toStringAsFixed(0)}%.';
    }
  }

  static String primaryActionFor(Insight insight) {
    final recs = insight.label.recommendations;
    return recs.isEmpty ? 'Keep going.' : recs.first;
  }

  /// Tint colour for each label, used by the prob-distribution bars and
  /// the timeline dot.
  static Color colorForLabel(InsightLabel label) {
    switch (label) {
      case InsightLabel.normal:
        return WillColors.accent;
      case InsightLabel.stress:
        return WillColors.warning;
      case InsightLabel.dehydration:
        return WillColors.action;
      case InsightLabel.abnormalOxygen:
        return WillColors.danger;
    }
  }

  static Color colorForSeverity(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.calm:
        return WillColors.accent;
      case InsightSeverity.watch:
        return WillColors.warning;
      case InsightSeverity.act:
        return WillColors.danger;
    }
  }

  static String _signed(double v, int fractionDigits) {
    final sign = v >= 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(fractionDigits)}';
  }
}
