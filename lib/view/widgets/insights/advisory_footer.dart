import 'package:flutter/cupertino.dart';

import '../../../core/colors.dart';

class AdvisoryFooter extends StatelessWidget {
  const AdvisoryFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WillColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WillColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.info_circle,
              size: 14,
              color: WillColors.textSecondary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Will's predictions are advisory and built from a research prototype model. They are not a medical diagnosis. Talk to a healthcare professional for clinical decisions.",
                style: TextStyle(
                  fontSize: 11,
                  color: WillColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
