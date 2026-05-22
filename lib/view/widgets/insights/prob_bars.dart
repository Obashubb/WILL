import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../helpers/insight_presenter.dart';
import '../../../models/insight.dart';

class ProbBars extends StatelessWidget {
  const ProbBars({super.key, required this.probs});

  final Map<InsightLabel, double> probs;

  @override
  Widget build(BuildContext context) {
    final entries = InsightLabel.values
        .map((l) => MapEntry(l, probs[l] ?? 0.0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      e.key.display,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: WillColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: e.value.clamp(0, 1),
                        minHeight: 4,
                        backgroundColor: InsightPresenter.colorForLabel(e.key)
                            .withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          InsightPresenter.colorForLabel(e.key),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${(e.value * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: WillColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
