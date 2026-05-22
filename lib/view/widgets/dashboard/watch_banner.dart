import 'package:flutter/cupertino.dart';

import '../../../core/colors.dart';
import '../../../models/insight.dart';

class WatchBanner extends StatelessWidget {
  const WatchBanner({super.key, required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: WillColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WillColors.warning.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.eye_fill,
            size: 18,
            color: WillColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Something to watch, ${insight.label.display.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: WillColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Open Insights for the details.',
                  style: TextStyle(
                    fontSize: 11,
                    color: WillColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
