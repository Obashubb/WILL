import 'package:flutter/cupertino.dart';

import '../../../core/colors.dart';
import '../../../services/wearable_service.dart';

class ConnectionPill extends StatelessWidget {
  const ConnectionPill({super.key, required this.state});

  final WearableConnectionState state;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(state);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutQuart,
      switchOutCurve: Curves.easeOutQuart,
      child: Container(
        key: ValueKey(state),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: spec.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: spec.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: spec.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.bluetooth, color: spec.color, size: 14),
            const SizedBox(width: 6),
            Text(
              spec.label,
              style: TextStyle(
                color: spec.color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({Color color, String label}) _specFor(WearableConnectionState s) {
    switch (s) {
      case WearableConnectionState.connected:
        return (color: WillColors.accent, label: 'Connected');
      case WearableConnectionState.scanning:
      case WearableConnectionState.connecting:
        return (color: WillColors.warning, label: 'Connecting');
      case WearableConnectionState.disconnected:
        return (color: WillColors.warning, label: 'Reconnecting');
      case WearableConnectionState.error:
        return (color: WillColors.danger, label: 'Offline');
      case WearableConnectionState.idle:
        return (color: WillColors.textSecondary, label: 'No band');
    }
  }
}
