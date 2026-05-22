import 'package:flutter/cupertino.dart';

import '../../../core/colors.dart';
import '../will_inkwell.dart';

class DoseChip extends StatelessWidget {
  const DoseChip({
    super.key,
    required this.time,
    required this.taken,
    required this.onTap,
  });

  final String time;
  final bool taken;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = taken ? WillColors.accent : WillColors.textSecondary;
    return WillInkwell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              taken
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.clock,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
