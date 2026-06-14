import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import '../../core/ble_constants.dart';
import '../../core/colors.dart';
import '../../helpers/relative_time.dart';
import '../../models/health_sample.dart';
import '../../services/wearable_service.dart';
import '../widgets/will_inkwell.dart';
import '../widgets/will_primary_button.dart';

/// Single source of truth for everything band-related. Opens from the Profile
/// row, the dashboard pill, and the onboarding screen so the user always
/// lands in the same place to manage the wearable.
class WearableSheet extends StatelessWidget {
  const WearableSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final wearable = Get.find<WearableService>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Obx(() {
            final state = wearable.connectionState.value;
            final sample = wearable.displaySample.value;
            final lastSeen = wearable.lastSampleAt.value;
            final adapter = wearable.adapterState.value;
            final mock = wearable.mockMode.value;
            final needsSettings = wearable.needsAppSettings.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Handle(),
                const _SheetHeader(),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    children: [
                      _ConnectionCard(
                        state: state,
                        sample: sample,
                        lastSeen: lastSeen,
                        deviceName: wearable.deviceName.value,
                        mock: mock,
                      ),
                      const SizedBox(height: 18),
                      _DemoToggle(
                        enabled: mock,
                        onChanged: wearable.setMockMode,
                      ),
                      const SizedBox(height: 22),
                      _ListArea(
                        wearable: wearable,
                        needsSettings: needsSettings,
                        adapter: adapter,
                        mock: mock,
                      ),
                    ],
                  ),
                ),
                _Footer(wearable: wearable, mock: mock),
                const SizedBox(height: 12),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 6),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: WillColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Will Band',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: WillColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              CupertinoIcons.xmark,
              size: 18,
              color: WillColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.state,
    required this.sample,
    required this.lastSeen,
    required this.deviceName,
    required this.mock,
  });

  final WearableConnectionState state;
  final HealthSample? sample;
  final DateTime? lastSeen;
  final String deviceName;
  final bool mock;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(state);
    final title = mock
        ? 'Demo band'
        : (deviceName.isNotEmpty ? deviceName : 'Will Band');
    final lastSeenText = lastSeen != null
        ? 'Updated ${RelativeTime.short(lastSeen!)}'
        : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WillColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: spec.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: WillColors.textPrimary,
                  ),
                ),
              ),
              if (lastSeenText != null)
                Text(
                  lastSeenText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: WillColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            spec.subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: spec.color,
            ),
          ),
          if (sample != null && state == WearableConnectionState.connected) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniStat(
                  label: 'HR',
                  value: '${sample!.heartRate}',
                  unit: 'bpm',
                ),
                const SizedBox(width: 18),
                _MiniStat(label: 'SpO₂', value: '${sample!.spo2}', unit: '%'),
                const SizedBox(width: 18),
                _MiniStat(
                  label: 'Temp',
                  value: sample!.temperature.toStringAsFixed(1),
                  unit: '°C',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  _CardSpec _spec(WearableConnectionState s) {
    switch (s) {
      case WearableConnectionState.connected:
        return _CardSpec(WillColors.accent, 'Connected · streaming vitals');
      case WearableConnectionState.scanning:
        return _CardSpec(WillColors.warning, 'Scanning for nearby devices…');
      case WearableConnectionState.connecting:
        return _CardSpec(WillColors.warning, 'Connecting…');
      case WearableConnectionState.disconnected:
        return _CardSpec(
          WillColors.warning,
          'Lost connection. Trying to reconnect…',
        );
      case WearableConnectionState.error:
        return _CardSpec(WillColors.danger, 'Something went wrong');
      case WearableConnectionState.idle:
        return _CardSpec(
          WillColors.textSecondary,
          'No band paired yet. Scan to find yours.',
        );
    }
  }
}

class _CardSpec {
  const _CardSpec(this.color, this.subtitle);
  final Color color;
  final String subtitle;
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: WillColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: WillColors.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: WillColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DemoToggle extends StatelessWidget {
  const _DemoToggle({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WillColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: WillColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Stream realistic mock vitals without a band.',
                  style: TextStyle(
                    fontSize: 11,
                    color: WillColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: enabled,
            onChanged: onChanged,
            activeTrackColor: WillColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ListArea extends StatelessWidget {
  const _ListArea({
    required this.wearable,
    required this.needsSettings,
    required this.adapter,
    required this.mock,
  });

  final WearableService wearable;
  final bool needsSettings;
  final BluetoothAdapterState? adapter;
  final bool mock;

  @override
  Widget build(BuildContext context) {
    if (mock) {
      return const _InlineNote(
        title: 'Demo mode is on.',
        body: 'Turn it off to scan for your real Will Band.',
      );
    }
    if (needsSettings) {
      return _PermissionDeniedCard(
        onOpenSettings: wearable.openPermissionSettings,
      );
    }
    if (adapter != null && adapter != BluetoothAdapterState.on) {
      return const _BluetoothOffCard();
    }
    return _NearbyList(wearable: wearable);
  }
}

class _NearbyList extends StatelessWidget {
  const _NearbyList({required this.wearable});

  final WearableService wearable;

  @override
  Widget build(BuildContext context) {
    final scanning =
        wearable.connectionState.value == WearableConnectionState.scanning;
    final devices = wearable.discoveredDevices;
    if (devices.isEmpty && !scanning) {
      return const _InlineNote(
        title: 'No devices yet.',
        body: 'Tap "Scan for bands" below to look for nearby devices.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Nearby devices',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: WillColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(),
            if (scanning)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    WillColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...devices.map(
          (r) => _NearbyDeviceRow(
            result: r,
            onPair: () => wearable.connectTo(r.device),
          ),
        ),
        if (devices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Looking for devices…',
              style: TextStyle(
                fontSize: 12,
                color: WillColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _NearbyDeviceRow extends StatelessWidget {
  const _NearbyDeviceRow({required this.result, required this.onPair});

  final ScanResult result;
  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    final name = result.device.advName.isNotEmpty
        ? result.device.advName
        : (result.advertisementData.advName.isNotEmpty
            ? result.advertisementData.advName
            : 'Unknown device');
    final isWill = name.toLowerCase().contains('will');
    return WillInkwell(
      onTap: onPair,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: WillColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WillColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (isWill ? WillColors.accent : WillColors.textSecondary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isWill ? CupertinoIcons.heart_fill : CupertinoIcons.bluetooth,
                size: 14,
                color: isWill ? WillColors.accent : WillColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: WillColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isWill) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: WillColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Will Band',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: WillColors.accent,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${result.rssi} dBm · ${result.device.remoteId.str.substring(0, 5).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: WillColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: WillColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedCard extends StatelessWidget {
  const _PermissionDeniedCard({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WillColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.lock_shield, size: 16, color: WillColors.warning),
              SizedBox(width: 8),
              Text(
                'Bluetooth access is blocked',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: WillColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Will needs Bluetooth to find your band. Open Settings to enable it.",
            style: TextStyle(fontSize: 12, color: WillColors.textSecondary),
          ),
          const SizedBox(height: 12),
          WillPrimaryButton(
            label: 'Open Settings',
            onPressed: onOpenSettings,
          ),
        ],
      ),
    );
  }
}

class _BluetoothOffCard extends StatelessWidget {
  const _BluetoothOffCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WillColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(
            CupertinoIcons.bluetooth,
            size: 18,
            color: WillColors.warning,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bluetooth is off',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: WillColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Turn it on and we'll start looking right away.",
                  style: TextStyle(
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

class _InlineNote extends StatelessWidget {
  const _InlineNote({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WillColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WillColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: WillColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: const TextStyle(
              fontSize: 12,
              color: WillColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.wearable, required this.mock});

  final WearableService wearable;
  final bool mock;

  @override
  Widget build(BuildContext context) {
    final state = wearable.connectionState.value;
    final connected = state == WearableConnectionState.connected;
    final scanning = state == WearableConnectionState.scanning;
    final connecting = state == WearableConnectionState.connecting;
    final buttonLabel = mock
        ? (connected ? 'Stop demo' : 'Start demo')
        : connected
            ? 'Disconnect'
            : scanning
                ? 'Stop scanning'
                : connecting
                    ? 'Cancel'
                    : 'Scan for bands';
    Future<void> onTap() async {
      if (connected || scanning || connecting) {
        await wearable.stop();
      } else {
        await wearable.startPairing();
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WillPrimaryButton(
            label: buttonLabel,
            isLoading: connecting,
            onPressed: onTap,
          ),
          if (connected && !mock) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final ok = await wearable.sendCommand(WearableCommand.vibrate);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      backgroundColor: ok
                          ? WillColors.primary
                          : WillColors.danger,
                      content: Text(
                        ok ? 'Buzz sent to your band.' : 'Could not send buzz.',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
              },
              child: const Text(
                'Buzz the band',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WillColors.action,
                ),
              ),
            ),
          ],
          if (wearable.lastError.value != null && !connected && !scanning) ...[
            const SizedBox(height: 10),
            Text(
              wearable.lastError.value!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: WillColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
