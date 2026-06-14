import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../models/insight.dart';
import '../../models/user_baseline.dart';
import '../../services/inference_service.dart';
import '../../services/insights_repository.dart';
import '../../services/profile_service.dart';
import 'widgets/leading_up_list.dart';

/// Per-insight retrospective: severity hero, captured vitals, baseline
/// comparison if available, feedback, and a 5-up timeline of what happened
/// in the run-up. Loaded via `state.extra`.
class InsightDetailScreen extends StatefulWidget {
  const InsightDetailScreen({super.key, required this.insight});

  final Insight insight;

  @override
  State<InsightDetailScreen> createState() => _InsightDetailScreenState();
}

class _InsightDetailScreenState extends State<InsightDetailScreen> {
  late Insight _insight = widget.insight;
  late final UserBaseline? _baseline = ProfileService.readBaseline();

  Future<void> _rate(bool helpful) async {
    await InsightsRepository.rate(_insight.id, helpful);
    if (mounted) setState(() => _insight = _insight.copyWith(helpful: helpful));
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(_insight.severity);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WillColors.background,
        elevation: 0,
        title: const Text(
          'Insight',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: WillColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: WillColors.textPrimary),
      ),
      backgroundColor: WillColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              DateFormat('EEE, d MMM · HH:mm').format(_insight.timestamp),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: WillColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SeverityHero(insight: _insight, color: color),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _FeedbackRow(helpful: _insight.helpful, onRate: _rate),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(label: 'WHAT WE SAW'),
          _FeatureRow(
            label: 'Heart rate',
            value: '${_insight.sample.heartRate} bpm',
            baselineDelta: _baseline == null
                ? null
                : _insight.sample.heartRate - _baseline.restingHr,
            baselineUnit: 'bpm',
          ),
          _FeatureRow(
            label: 'Oxygen',
            value: '${_insight.sample.spo2}%',
            baselineDelta: _baseline == null
                ? null
                : _insight.sample.spo2 - _baseline.restingSpo2,
            baselineUnit: '%',
            inverted: true,
          ),
          _FeatureRow(
            label: 'Temperature',
            value: '${_insight.sample.temperature.toStringAsFixed(1)} °C',
            baselineDelta: _baseline == null
                ? null
                : double.parse(
                    (_insight.sample.temperature - _baseline.restingTemp)
                        .toStringAsFixed(1),
                  ),
            baselineUnit: '°C',
          ),
          _FeatureRow(
            label: 'Movement',
            value: _insight.sample.motion < 0.05 ? 'Still' : 'Moving',
          ),
          const SizedBox(height: 22),
          LeadingUpList(pivot: _insight),
        ],
      ),
    );
  }

  Color _severityColor(InsightLabel s) {
    switch (s) {
      case InsightLabel.normal:
        return WillColors.accent;
      case InsightLabel.watch:
        return WillColors.warning;
      case InsightLabel.alert:
        return WillColors.danger;
    }
  }
}

class _SeverityHero extends StatelessWidget {
  const _SeverityHero({required this.insight, required this.color});

  final Insight insight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final title = _titleFor(insight);
    final body = _bodyFor(insight);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: WillColors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(Insight i) {
    switch (i.condition) {
      case ConditionLabel.stress:
        return 'Looking stressed';
      case ConditionLabel.dehydration:
        return 'Hydration check';
      case ConditionLabel.overexertion:
        return 'Slow down a moment';
      case ConditionLabel.none:
        switch (i.severity) {
          case InsightLabel.normal:
            return 'Vitals looking calm';
          case InsightLabel.watch:
            return 'Worth watching';
          case InsightLabel.alert:
            return 'Vitals need attention';
        }
    }
  }

  String _bodyFor(Insight i) {
    switch (i.severity) {
      case InsightLabel.normal:
        return "Everything is within your normal range. We saved this entry so you can see when things stayed calm.";
      case InsightLabel.watch:
        return "Some vitals drifted from your baseline. Worth a moment of rest and hydration.";
      case InsightLabel.alert:
        return "Vitals were outside the comfortable range. If this happens often, mention it to your care team.";
    }
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.helpful, required this.onRate});

  final bool? helpful;
  final ValueChanged<bool> onRate;

  @override
  Widget build(BuildContext context) {
    if (helpful != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: WillColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WillColors.border.withValues(alpha: 0.6)),
        ),
        child: Text(
          'Thanks for the feedback.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: WillColors.textSecondary,
          ),
        ),
      );
    }
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Was this helpful?',
            style: TextStyle(
              fontSize: 13,
              color: WillColors.textPrimary,
            ),
          ),
        ),
        _FeedbackButton(
          icon: CupertinoIcons.hand_thumbsup,
          onTap: () => onRate(true),
        ),
        const SizedBox(width: 8),
        _FeedbackButton(
          icon: CupertinoIcons.hand_thumbsdown,
          onTap: () => onRate(false),
        ),
      ],
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: WillColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WillColors.border.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, size: 16, color: WillColors.textPrimary),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: WillColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.value,
    this.baselineDelta,
    this.baselineUnit,
    this.inverted = false,
  });

  final String label;
  final String value;

  /// `null` when no baseline is set. Otherwise current - resting; positive
  /// values are "above baseline" (or below, when [inverted] is true, since
  /// SpO₂ going down is the concerning direction).
  final num? baselineDelta;
  final String? baselineUnit;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final hint = _hint();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: WillColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WillColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: WillColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: WillColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (hint != null)
              Text(
                hint,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _hintColor(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _hintColor() {
    final d = baselineDelta;
    if (d == null) return WillColors.textSecondary;
    final magnitude = d is int ? d.abs() : (d as double).abs();
    final concerning = inverted ? d < 0 : d > 0;
    if (magnitude == 0) return WillColors.textSecondary;
    return concerning ? WillColors.warning : WillColors.accent;
  }

  String? _hint() {
    final d = baselineDelta;
    if (d == null) return null;
    final unit = baselineUnit ?? '';
    if (d is int) {
      if (d == 0) return 'at your baseline';
      final sign = d > 0 ? '+' : '−';
      return '$sign${d.abs()} $unit';
    }
    final value = (d as double);
    if (value == 0) return 'at your baseline';
    final sign = value > 0 ? '+' : '−';
    return '$sign${value.abs().toStringAsFixed(1)} $unit';
  }
}
