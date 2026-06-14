import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../helpers/insight_history_filter.dart';

/// Single-select range picker spanning the available width (Today / This week
/// / All). Visual style matches the History screen's window picker.
class DateRangeChips extends StatelessWidget {
  const DateRangeChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final InsightDateRange value;
  final ValueChanged<InsightDateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: InsightDateRange.values.map((range) {
          final selected = range == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutQuart,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? WillColors.textPrimary.withValues(alpha: 0.06)
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? WillColors.textPrimary.withValues(alpha: 0.2)
                        : WillColors.border.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  range.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? WillColors.textPrimary
                        : WillColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
