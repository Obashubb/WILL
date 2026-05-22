import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../history/history_metric.dart';

class MetricPicker extends StatelessWidget {
  const MetricPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final HistoryMetric value;
  final ValueChanged<HistoryMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: HistoryMetric.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final m = HistoryMetric.values[i];
          final selected = m == value;
          return GestureDetector(
            onTap: () => onChanged(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutQuart,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? m.color.withValues(alpha: 0.12)
                    : WillColors.surface,
                border: Border.all(
                  color: selected
                      ? m.color.withValues(alpha: 0.4)
                      : WillColors.border.withValues(alpha: 0.6),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                m.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? m.color : WillColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
