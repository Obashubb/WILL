import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../core/colors.dart';
import '../../core/router/routes.dart';
import '../../services/profile_service.dart';
import '../../services/wearable_service.dart';
import '../profile/wearable_sheet.dart';
import '../widgets/will_inkwell.dart';
import '../widgets/will_primary_button.dart';

class DeviceSetupScreen extends StatelessWidget {
  const DeviceSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wearable = Get.find<WearableService>();

    Future<void> openSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: WillColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const WearableSheet(),
      );
      if (wearable.connectionState.value == WearableConnectionState.connected) {
        await ProfileService.markDeviceSetupSeen();
        if (context.mounted) context.go(WillRoutes.home);
      }
    }

    Future<void> skip() async {
      await ProfileService.markDeviceSetupSeen();
      if (context.mounted) context.go(WillRoutes.home);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Obx(() {
            final state = wearable.connectionState.value;
            final busy = state == WearableConnectionState.scanning ||
                state == WearableConnectionState.connecting;
            return Column(
              children: [
                const Spacer(flex: 2),
                _BandIllustration(active: busy)
                    .animate()
                    .fadeIn(duration: 280.ms),
                const SizedBox(height: 36),
                const Text(
                  'Connect your Will band.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: WillColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Pair the wristband so the app can see your heart rate, oxygen, temperature, and activity in real time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: WillColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                WillPrimaryButton(
                  label: busy ? 'Searching for your band' : 'Pair device',
                  isLoading: busy,
                  onPressed: busy ? null : openSheet,
                ),
                const SizedBox(height: 14),
                WillInkwell(
                  onTap: busy ? null : skip,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "I'll set this up later",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: WillColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _BandIllustration extends StatelessWidget {
  const _BandIllustration({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            ...List.generate(3, (i) {
              return Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: WillColors.accent.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
              )
                  .animate(
                    onPlay: (c) => c.repeat(),
                    delay: (i * 500).ms,
                  )
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.4, 1.4),
                    duration: 1500.ms,
                    curve: Curves.easeOutQuart,
                  )
                  .fadeOut(duration: 1500.ms, curve: Curves.easeOutQuart);
            }),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: WillColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: WillColors.border),
            ),
            child: const Icon(
              CupertinoIcons.bluetooth,
              size: 48,
              color: WillColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
