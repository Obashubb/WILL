import 'package:flutter/cupertino.dart';

import '../widgets/empty_placeholder.dart';
import '../widgets/section_title.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionTitle('Care'),
        Expanded(
          child: EmptyPlaceholder(
            icon: CupertinoIcons.heart,
            title: 'Hydration and medication, in one place.',
            subtitle: 'Track water intake and stay on top of your meds.',
          ),
        ),
      ],
    );
  }
}
