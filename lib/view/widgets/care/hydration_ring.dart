import 'package:flutter/material.dart';

import '../../../controllers/care_controller.dart';
import '../../../core/colors.dart';

class HydrationRing extends StatelessWidget {
  const HydrationRing({super.key, required this.controller});

  final CareController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.hydrationProgress;
    final total = controller.hydrationTotalMl;
    final goal = controller.hydrationGoalMl.value;
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 124,
            height: 124,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 9,
              valueColor: AlwaysStoppedAnimation<Color>(
                WillColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          SizedBox(
            width: 124,
            height: 124,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutQuart,
              builder: (_, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 9,
                strokeCap: StrokeCap.round,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(WillColors.action),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: WillColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'of $goal ml',
                style: const TextStyle(
                  fontSize: 11,
                  color: WillColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
