import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../helpers/insight_history_filter.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: InsightDateRange.values.map((r) {
          final selected = r == value;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutQuart,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? WillColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  r.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : WillColors.textSecondary,
                    letterSpacing: 0.3,
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
