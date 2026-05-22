import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../helpers/insight_presenter.dart';
import '../../../models/insight.dart';

class SeverityChips extends StatelessWidget {
  const SeverityChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// `null` means "All".
  final InsightSeverity? value;
  final ValueChanged<InsightSeverity?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <(InsightSeverity?, String)>[
      (null, 'All'),
      (InsightSeverity.calm, 'Calm'),
      (InsightSeverity.watch, 'Watch'),
      (InsightSeverity.act, 'Act'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (sev, label) = options[i];
          final selected = sev == value;
          final color = sev == null
              ? WillColors.primary
              : InsightPresenter.colorForSeverity(sev);
          return GestureDetector(
            onTap: () => onChanged(sev),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutQuart,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.12)
                    : WillColors.surface,
                border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.4)
                      : WillColors.border.withValues(alpha: 0.6),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : WillColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
