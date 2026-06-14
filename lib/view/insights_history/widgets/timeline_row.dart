import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../core/colors.dart';
import '../../../models/insight.dart';
import '../../../services/inference_service.dart';
import '../../widgets/will_inkwell.dart';

class TimelineRow extends StatelessWidget {
  const TimelineRow({super.key, required this.insight, this.onTap});

  final Insight insight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(insight.severity);
    final title = _titleFor(insight);
    return WillInkwell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: WillColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WillColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                DateFormat.Hm().format(insight.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: WillColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: WillColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 12,
              color: WillColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(InsightLabel s) {
    switch (s) {
      case InsightLabel.normal:
        return WillColors.accent;
      case InsightLabel.watch:
        return WillColors.warning;
      case InsightLabel.alert:
        return WillColors.danger;
    }
  }

  String _titleFor(Insight i) {
    final cond = _conditionLabel(i.condition);
    if (cond.isNotEmpty) return cond;
    switch (i.severity) {
      case InsightLabel.normal:
        return 'Vitals looking calm';
      case InsightLabel.watch:
        return 'Worth watching';
      case InsightLabel.alert:
        return 'Vitals need attention';
    }
  }

  String _conditionLabel(ConditionLabel c) {
    switch (c) {
      case ConditionLabel.none:
        return '';
      case ConditionLabel.stress:
        return 'Looking stressed';
      case ConditionLabel.dehydration:
        return 'Hydration check';
      case ConditionLabel.overexertion:
        return 'Slow down a moment';
    }
  }
}
