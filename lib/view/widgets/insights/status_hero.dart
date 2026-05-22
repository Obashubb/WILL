import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../helpers/insight_presenter.dart';
import '../../../models/insight.dart';
import '../../../models/user_baseline.dart';
import 'hero_icon.dart';
import 'primary_action.dart';

class StatusHero extends StatelessWidget {
  const StatusHero({
    super.key,
    required this.insight,
    required this.baseline,
  });

  final Insight insight;
  final UserBaseline? baseline;

  @override
  Widget build(BuildContext context) {
    final spec = InsightPresenter.heroSpec(insight.severity);
    final subline = InsightPresenter.sublineFor(insight);
    final why = InsightPresenter.whyFor(insight, baseline);
    final isAct = insight.severity == InsightSeverity.act;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HeroIcon(color: spec.color, icon: spec.icon, pulse: isAct),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: WillColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subline,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: spec.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            why,
            style: const TextStyle(
              fontSize: 14,
              color: WillColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (insight.severity != InsightSeverity.calm) ...[
            const SizedBox(height: 16),
            PrimaryAction(
              text: InsightPresenter.primaryActionFor(insight),
              color: spec.color,
            ),
          ],
        ],
      ),
    );
  }
}
