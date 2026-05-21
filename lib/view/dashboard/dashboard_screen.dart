import 'package:flutter/cupertino.dart';

import '../../core/colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  final String userName = 'Ada';
  final bool isConnected = true;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        _GreetingBlock(userName: userName, isConnected: isConnected),
        const SizedBox(height: 32),
        const _SectionLabel(
          title: 'Live Health Overview',
          trailing: 'Last updated 16:13',
        ),
      ],
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.userName, required this.isConnected});

  final String userName;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConnectionPill(isConnected: isConnected),
        const SizedBox(height: 18),
        Text(
          'Good morning, $userName.',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.05,
            color: WillColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your band is reading your vitals.',
          style: TextStyle(
            fontSize: 14,
            color: WillColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? WillColors.accent : WillColors.danger;
    final label = isConnected ? 'Connected' : 'Offline';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Icon(CupertinoIcons.bluetooth, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: WillColors.textPrimary,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 11,
            color: WillColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
