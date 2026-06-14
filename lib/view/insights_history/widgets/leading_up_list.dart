import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/colors.dart';
import '../../../core/router/routes.dart';
import '../../../helpers/insight_history_filter.dart';
import '../../../models/insight.dart';
import '../../../services/insights_repository.dart';
import 'timeline_row.dart';

class LeadingUpList extends StatelessWidget {
  const LeadingUpList({super.key, required this.pivot, this.limit = 5});

  final Insight pivot;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final earlier =
        insightsBefore(InsightsRepository.readRecent(), pivot, limit: limit);
    if (earlier.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          'This was the first saved insight of the run.',
          style: TextStyle(fontSize: 12, color: WillColors.textSecondary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 6),
          child: Text(
            'WHAT HAPPENED BEFORE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: WillColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        ...earlier.map(
          (i) => TimelineRow(
            insight: i,
            onTap: () => context.pushReplacement(
              WillRoutes.insightDetail,
              extra: i,
            ),
          ),
        ),
      ],
    );
  }
}
