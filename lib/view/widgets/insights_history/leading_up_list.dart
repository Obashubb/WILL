import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../helpers/insight_history_filter.dart';
import '../../../models/insight.dart';
import '../../../services/insights_repository.dart';
import '../insights/timeline_row.dart';
import '../row_divider_label.dart';

class LeadingUpList extends StatelessWidget {
  const LeadingUpList({super.key, required this.pivot});

  final Insight pivot;

  @override
  Widget build(BuildContext context) {
    final earlier = insightsBefore(
      InsightsRepository.readRecent(),
      pivot,
      limit: 5,
    );
    if (earlier.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'This was the first recorded insight.',
          style: TextStyle(
            fontSize: 12,
            color: WillColors.textSecondary.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RowDividerLabel(label: 'What happened before'),
        ...earlier.map((i) => TimelineRow(insight: i)),
      ],
    );
  }
}
