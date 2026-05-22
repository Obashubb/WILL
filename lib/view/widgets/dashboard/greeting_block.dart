import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../services/wearable_service.dart';
import 'connection_pill.dart';

class GreetingBlock extends StatelessWidget {
  const GreetingBlock({
    super.key,
    required this.greeting,
    required this.firstName,
    required this.state,
  });

  final String greeting;
  final String firstName;
  final WearableConnectionState state;

  @override
  Widget build(BuildContext context) {
    final headline =
        firstName.isEmpty ? '$greeting.' : '$greeting, $firstName.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConnectionPill(state: state),
        const SizedBox(height: 18),
        Text(
          headline,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.05,
            color: WillColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutQuart,
          switchOutCurve: Curves.easeOutQuart,
          child: Text(
            _subtitleFor(state),
            key: ValueKey(state),
            style: const TextStyle(
              fontSize: 14,
              color: WillColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _subtitleFor(WearableConnectionState s) {
    switch (s) {
      case WearableConnectionState.connected:
        return 'Your band is reading your vitals.';
      case WearableConnectionState.scanning:
        return 'Looking for your band…';
      case WearableConnectionState.connecting:
        return 'Connecting to your band…';
      case WearableConnectionState.disconnected:
        return 'Reconnecting to your band…';
      case WearableConnectionState.error:
        return 'Tap the band icon in Profile to retry.';
      case WearableConnectionState.idle:
        return 'No band paired yet.';
    }
  }
}
