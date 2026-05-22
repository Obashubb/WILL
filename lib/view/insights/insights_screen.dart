import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/colors.dart';
import '../../models/insight.dart';
import '../../services/inference_service.dart';
import '../widgets/empty_placeholder.dart';
import '../widgets/section_title.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final inference = Get.find<InferenceService>();
    return Obx(() {
      final insight = inference.latestInsight.value;
      if (insight == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SectionTitle('Insights'),
            Expanded(
              child: EmptyPlaceholder(
                icon: CupertinoIcons.sparkles,
                title: 'AI insights are warming up.',
                subtitle:
                    "Wear the band for about 30 seconds. We'll start showing you what we see.",
              ),
            ),
          ],
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          const SectionTitle('Insights'),
          const SizedBox(height: 8),
          _StatusHero(insight: insight),
          const SizedBox(height: 28),
          _RowDivider(label: 'What we see'),
          _FeatureRow(
            label: 'Heart rate',
            value: '${insight.features.hrMean.toStringAsFixed(0)} bpm',
            hint: _hrHint(insight.features.hrMean),
          ),
          _FeatureRow(
            label: 'HR trend',
            value:
                '${insight.features.hrSlope >= 0 ? '+' : ''}${insight.features.hrSlope.toStringAsFixed(2)} bpm/s',
            hint: _slopeHint(insight.features.hrSlope),
          ),
          _FeatureRow(
            label: 'Oxygen (min)',
            value: '${insight.features.spo2Min.toStringAsFixed(0)} %',
            hint: _spo2Hint(insight.features.spo2Min),
          ),
          _FeatureRow(
            label: 'Temperature (max)',
            value: '${insight.features.tempMax.toStringAsFixed(1)} °C',
            hint: _tempHint(insight.features.tempMax),
          ),
          _FeatureRow(
            label: 'Movement',
            value: insight.features.motionVar < 0.05 ? 'Still' : 'Moving',
            hint:
                'Variance ${insight.features.motionVar.toStringAsFixed(3)} over ${insight.features.sampleCount} samples',
          ),
          const SizedBox(height: 28),
          _RowDivider(label: 'What to do'),
          ...insight.label.recommendations
              .map((r) => _BulletRow(text: r)),
        ],
      );
    });
  }

  String _hrHint(double v) {
    if (v < 60) return 'Lower than typical resting range.';
    if (v <= 100) return 'Within typical resting range.';
    if (v <= 120) return 'Slightly elevated.';
    return 'Notably elevated.';
  }

  String _slopeHint(double v) {
    final abs = v.abs();
    if (abs < 0.3) return 'Stable.';
    if (abs < 1.0) return 'Gentle change.';
    if (abs < 2.0) return 'Climbing.';
    return 'Climbing fast.';
  }

  String _spo2Hint(double v) {
    if (v < 92) return 'Below typical range.';
    if (v < 95) return 'Low end of normal.';
    return 'Normal range.';
  }

  String _tempHint(double v) {
    if (v >= 37.5) return 'Elevated.';
    if (v >= 37.2) return 'Mildly warm.';
    return 'Within typical range.';
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.insight});

  final Insight insight;

  Color get _accent {
    switch (insight.label) {
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

  IconData get _icon {
    switch (insight.label) {
      case InsightLabel.normal:
        return CupertinoIcons.checkmark_seal;
      case InsightLabel.stress:
        return CupertinoIcons.heart;
      case InsightLabel.dehydration:
        return CupertinoIcons.drop;
      case InsightLabel.abnormalOxygen:
        return CupertinoIcons.exclamationmark_triangle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (insight.confidence * 100).clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, size: 22, color: _accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  insight.label.display,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: WillColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            insight.label.narrative,
            style: const TextStyle(
              fontSize: 14,
              color: WillColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                '${pct.toStringAsFixed(0)}% confidence',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: WillColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: insight.confidence.clamp(0, 1)),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutQuart,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: _accent.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        label.toUpperCase(),
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
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: WillColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 12,
                    color: WillColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: WillColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: WillColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: WillColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
