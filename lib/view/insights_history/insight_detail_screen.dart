import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../models/insight.dart';
import '../../services/profile_service.dart';
import '../widgets/insights/feature_row.dart';
import '../widgets/insights/feedback_row.dart';
import '../widgets/insights/prob_bars.dart';
import '../widgets/insights/status_hero.dart';
import '../widgets/row_divider_label.dart';
import '../widgets/insights_history/leading_up_list.dart';

class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key, required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final baseline = ProfileService.readBaseline();
    return Scaffold(
      appBar: AppBar(title: const Text('Insight')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                DateFormat('EEE, d MMM · HH:mm').format(insight.timestamp),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: WillColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 10),
            StatusHero(insight: insight, baseline: baseline),
            const SizedBox(height: 14),
            FeedbackRow(insight: insight),
            const SizedBox(height: 22),
            const RowDividerLabel(label: 'Probability'),
            const SizedBox(height: 4),
            ProbBars(probs: insight.probs),
            const SizedBox(height: 22),
            const RowDividerLabel(label: 'What we saw'),
            FeatureRow(
              label: 'Heart rate',
              value: '${insight.features.hrMean.toStringAsFixed(0)} bpm',
            ),
            FeatureRow(
              label: 'Oxygen (min)',
              value: '${insight.features.spo2Min.toStringAsFixed(0)} %',
            ),
            FeatureRow(
              label: 'Temperature (max)',
              value:
                  '${insight.features.tempMax.toStringAsFixed(1)} °C',
            ),
            FeatureRow(
              label: 'Movement',
              value:
                  insight.features.motionVar < 0.05 ? 'Still' : 'Moving',
            ),
            const SizedBox(height: 22),
            LeadingUpList(pivot: insight),
          ],
        ),
      ),
    );
  }
}
