import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../models/insight.dart';
import '../../services/inference_service.dart';
import '../../services/insights_repository.dart';
import '../../services/profile_service.dart';
import '../widgets/empty_placeholder.dart';
import '../widgets/row_divider_label.dart';
import '../widgets/section_title.dart';
import '../widgets/insights/advisory_footer.dart';
import '../widgets/insights/expandable_details.dart';
import '../widgets/insights/feedback_row.dart';
import '../widgets/insights/status_hero.dart';
import '../widgets/insights/timeline_row.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with AutomaticKeepAliveClientMixin {
  bool _detailsOpen = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final inference = Get.find<InferenceService>();
    return Obx(() {
      final insight = inference.latestInsight.value;
      final baseline = ProfileService.readBaseline();
      if (insight == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SectionTitle('Insights'),
            Expanded(
              child: EmptyPlaceholder(
                icon: CupertinoIcons.sparkles,
                title: 'AI insights are warming up.',
                subtitle:
                    "Wear the band for about 30 seconds. We'll start showing you what we see.",
              ),
            ),
          ],
        );
      }
      final timeline = _todaysTimeline();
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          const SectionTitle('Insights'),
          const SizedBox(height: 8),
          StatusHero(insight: insight, baseline: baseline),
          const SizedBox(height: 10),
          FeedbackRow(insight: insight),
          const SizedBox(height: 18),
          ExpandableDetails(
            insight: insight,
            isOpen: _detailsOpen,
            onToggle: () => setState(() => _detailsOpen = !_detailsOpen),
          ),
          if (timeline.isNotEmpty) ...[
            const SizedBox(height: 22),
            const RowDividerLabel(label: 'Today'),
            ...timeline.take(5).map((i) => TimelineRow(insight: i)),
          ],
          const SizedBox(height: 18),
          const AdvisoryFooter(),
        ],
      );
    });
  }

  List<Insight> _todaysTimeline() {
    final today = DateTime.now();
    return InsightsRepository.readRecent()
        .where((i) =>
            i.timestamp.year == today.year &&
            i.timestamp.month == today.month &&
            i.timestamp.day == today.day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
