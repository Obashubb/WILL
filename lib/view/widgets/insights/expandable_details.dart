import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../core/colors.dart';
import '../../../models/insight.dart';
import '../will_inkwell.dart';
import 'feature_row.dart';
import 'prob_bars.dart';

class ExpandableDetails extends StatelessWidget {
  const ExpandableDetails({
    super.key,
    required this.insight,
    required this.isOpen,
    required this.onToggle,
  });

  final Insight insight;
  final bool isOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WillInkwell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                const Text(
                  'DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: WillColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Icon(
                  isOpen
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 14,
                  color: WillColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutQuart,
          child: isOpen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Updated ${DateFormat.Hm().format(insight.timestamp)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: WillColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ProbBars(probs: insight.probs),
                    const SizedBox(height: 14),
                    FeatureRow(
                      label: 'Heart rate',
                      value:
                          '${insight.features.hrMean.toStringAsFixed(0)} bpm',
                    ),
                    FeatureRow(
                      label: 'Oxygen (min)',
                      value:
                          '${insight.features.spo2Min.toStringAsFixed(0)} %',
                    ),
                    FeatureRow(
                      label: 'Temperature (max)',
                      value:
                          '${insight.features.tempMax.toStringAsFixed(1)} °C',
                    ),
                    FeatureRow(
                      label: 'Movement',
                      value: insight.features.motionVar < 0.05
                          ? 'Still'
                          : 'Moving',
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
