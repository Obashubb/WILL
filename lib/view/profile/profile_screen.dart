import 'package:flutter/cupertino.dart';

import '../widgets/empty_placeholder.dart';
import '../widgets/section_title.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionTitle('Profile'),
        Expanded(
          child: EmptyPlaceholder(
            icon: CupertinoIcons.person,
            title: 'Your profile and device.',
            subtitle: 'Account, settings, and your connected band live here.',
          ),
        ),
      ],
    );
  }
}
