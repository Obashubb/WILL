import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../will_inkwell.dart';

class NoBandBanner extends StatelessWidget {
  const NoBandBanner({super.key, required this.onPair});

  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WillColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.bluetooth,
            size: 18,
            color: WillColors.textSecondary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No band paired. Pair one to see live readings.',
              style: TextStyle(
                fontSize: 13,
                color: WillColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
          WillInkwell(
            onTap: onPair,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: WillColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Pair',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
