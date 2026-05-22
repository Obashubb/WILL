import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/colors.dart';
import '../../../helpers/insight_presenter.dart';
import '../../../models/insight.dart';

class TimelineRow extends StatelessWidget {
  const TimelineRow({super.key, required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final color = InsightPresenter.colorForSeverity(insight.severity);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 56,
            child: Text(
              DateFormat.Hm().format(insight.timestamp),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: WillColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              insight.label.display,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: WillColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${(insight.confidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: WillColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
