import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../services/inference_service.dart';

class SeverityChips extends StatelessWidget {
  const SeverityChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final InsightLabel? value;
  final ValueChanged<InsightLabel?> onChanged;

  static const _options = <(InsightLabel?, String, Color)>[
    (null, 'All', WillColors.textSecondary),
    (InsightLabel.normal, 'Calm', WillColors.accent),
    (InsightLabel.watch, 'Watch', WillColors.warning),
    (InsightLabel.alert, 'Alert', WillColors.danger),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final option = _options[i];
          final selected = option.$1 == value;
          final color = option.$3;
          return GestureDetector(
            onTap: () => onChanged(option.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutQuart,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              alignment: Alignment.center,
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
              child: Text(
                option.$2,
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
