import 'package:flutter/cupertino.dart';

import '../../core/colors.dart';

class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: WillColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Will',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1,
                color: WillColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'AI-based wearable monitoring for sickle cell patients.',
              style: TextStyle(
                fontSize: 14,
                color: WillColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            _Row(label: 'Version', value: '1.0.0'),
            _Row(label: 'Build', value: '1'),
            _Row(label: 'Bundle id', value: 'com.blessing.will'),
            _Row(label: 'Firebase project', value: 'will-wristband'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WillColors.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: WillColors.border.withValues(alpha: 0.6)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 18,
                    color: WillColors.warning,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Final-year project prototype. Not a medical device, do not use for clinical decisions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: WillColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Built with Flutter. Random Forest inference runs on-device. Vitals stream over BLE from an ESP32-C3 wristband.',
              style: TextStyle(
                fontSize: 12,
                color: WillColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: WillColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: WillColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
