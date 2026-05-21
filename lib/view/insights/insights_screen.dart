import 'package:flutter/cupertino.dart';

import '../widgets/empty_placeholder.dart';
import '../widgets/section_title.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionTitle('Insights'),
        Expanded(
          child: EmptyPlaceholder(
            icon: CupertinoIcons.sparkles,
            title: 'AI insights are warming up.',
            subtitle:
                "Once enough readings are in, you'll see patterns and gentle recommendations here.",
          ),
        ),
      ],
    );
  }
}
