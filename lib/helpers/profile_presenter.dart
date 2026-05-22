import '../helpers/relative_time.dart';
import '../services/sync_service.dart';
import '../services/wearable_service.dart';

/// Pure formatters for the rows on the Profile screen. Reading is the
/// only side effect; nothing here mutates state.
class ProfilePresenter {
  ProfilePresenter._();

  static String wearableValue(WearableService wearable) {
    switch (wearable.connectionState.value) {
      case WearableConnectionState.connected:
        final name = wearable.deviceName.value;
        return name.isEmpty ? 'Will Band' : name;
      case WearableConnectionState.scanning:
        return 'Searching…';
      case WearableConnectionState.connecting:
        return 'Connecting…';
      case WearableConnectionState.disconnected:
        return 'Reconnecting…';
      case WearableConnectionState.error:
        return 'Tap to retry';
      case WearableConnectionState.idle:
        return 'Tap to pair';
    }
  }

  static String wearableHint(WearableService wearable) {
    if (wearable.connectionState.value == WearableConnectionState.connected) {
      return wearable.mockMode.value ? 'Mock mode' : 'Live';
    }
    return wearable.lastError.value ?? '';
  }

  static String syncValue(SyncService sync, {required bool isGuest}) {
    if (isGuest) return 'Local only';
    if (!sync.isOnline.value) return 'Offline';
    final last = sync.lastSyncedAt.value;
    if (last == null) return 'Pending';
    return 'Synced ${relativeSyncTime(last)}';
  }

  static String syncHint(SyncService sync, {required bool isGuest}) {
    if (isGuest) return 'Guest data stays on this phone.';
    return sync.lastError.value ?? 'Tap to sync now.';
  }
}
