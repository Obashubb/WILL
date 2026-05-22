import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/colors.dart';
import '../../services/wearable_service.dart';
import '../widgets/will_inkwell.dart';
import '../widgets/will_primary_button.dart';

class WearableSheet extends StatelessWidget {
  const WearableSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final wearable = Get.find<WearableService>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Obx(() {
          final state = wearable.connectionState.value;
          final busy = state == WearableConnectionState.scanning ||
              state == WearableConnectionState.connecting;
          final connected = state == WearableConnectionState.connected;
          return Column(
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
              const SizedBox(height: 16),
              const Text(
                'Wearable',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: WillColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _StatusRow(state: state, name: wearable.deviceName.value),
              if (wearable.lastError.value != null) ...[
                const SizedBox(height: 8),
                Text(
                  wearable.lastError.value!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: WillColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              _MockToggle(
                value: wearable.mockMode.value,
                onChanged: busy
                    ? null
                    : (v) => wearable.mockMode.value = v,
              ),
              const SizedBox(height: 18),
              if (connected)
                WillPrimaryButton(
                  label: 'Disconnect',
                  onPressed: () async {
                    await wearable.stop();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                )
              else
                WillPrimaryButton(
                  label: busy
                      ? 'Searching…'
                      : (state == WearableConnectionState.error
                          ? 'Try again'
                          : 'Pair device'),
                  isLoading: busy,
                  onPressed: busy
                      ? null
                      : () async {
                          await wearable.startPairing();
                          if (wearable.connectionState.value ==
                                  WearableConnectionState.connected &&
                              context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.state, required this.name});

  final WearableConnectionState state;
  final String name;

  ({Color color, String label}) get _spec {
    switch (state) {
      case WearableConnectionState.connected:
        return (color: WillColors.accent, label: 'Connected');
      case WearableConnectionState.scanning:
        return (color: WillColors.warning, label: 'Scanning');
      case WearableConnectionState.connecting:
        return (color: WillColors.warning, label: 'Connecting');
      case WearableConnectionState.disconnected:
        return (color: WillColors.warning, label: 'Reconnecting');
      case WearableConnectionState.error:
        return (color: WillColors.danger, label: 'Offline');
      case WearableConnectionState.idle:
        return (color: WillColors.textSecondary, label: 'Not paired');
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WillColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(CupertinoIcons.bluetooth, color: spec.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Will Band' : name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: WillColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  spec.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: spec.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: spec.color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _MockToggle extends StatelessWidget {
  const _MockToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return WillInkwell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: WillColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WillColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mock mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: WillColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Use synthetic data instead of a real band.',
                    style: TextStyle(
                      fontSize: 12,
                      color: WillColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
