import 'package:flutter/material.dart';

import '../../../controllers/care_controller.dart';
import '../../../core/colors.dart';
import 'hydration_button.dart';
import 'hydration_ring.dart';

class HydrationBlock extends StatelessWidget {
  const HydrationBlock({super.key, required this.controller});

  final CareController controller;

  @override
  Widget build(BuildContext context) {
    final entryCount = controller.hydrationToday.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HydrationRing(controller: controller),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hydration',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: WillColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    HydrationButton(
                      label: '+250 ml',
                      onTap: () => controller.addHydration(250),
                    ),
                    const SizedBox(width: 8),
                    HydrationButton(
                      label: '+500 ml',
                      onTap: () => controller.addHydration(500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  entryCount == 0
                      ? 'No water logged yet today.'
                      : '$entryCount entry${entryCount == 1 ? '' : ' (s)'} today',
                  style: const TextStyle(
                    fontSize: 12,
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
