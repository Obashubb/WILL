import 'package:flutter/cupertino.dart';

import '../widgets/empty_placeholder.dart';
import '../widgets/section_title.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionTitle('History'),
        Expanded(
          child: EmptyPlaceholder(
            icon: CupertinoIcons.chart_bar,
            title: 'Your readings, over time.',
            subtitle: 'Trends will appear here as the band collects data.',
          ),
        ),
      ],
    );
  }
}
