import 'package:get_storage/get_storage.dart';

import '../models/app_user.dart';

class ProfileService {
  ProfileService._();

  static final GetStorage _box = GetStorage();

  static const String _userKey = 'app.user';
  static const String _seenDeviceSetupKey = 'device.seenSetup';
  static const String _pairedDeviceIdKey = 'device.pairedId';

  static AppUser? readUser() {
    final raw = _box.read<Map>(_userKey);
    if (raw == null) return null;
    return AppUser.fromJson(Map<String, dynamic>.from(raw));
  }

  static Future<void> writeUser(AppUser user) =>
      _box.write(_userKey, user.toJson());

  static Future<void> clearUser() => _box.remove(_userKey);

  static bool hasSeenDeviceSetup() =>
      _box.read<bool>(_seenDeviceSetupKey) ?? false;

  static Future<void> markDeviceSetupSeen() =>
      _box.write(_seenDeviceSetupKey, true);

  static String? pairedDeviceId() => _box.read<String?>(_pairedDeviceIdKey);

  static Future<void> setPairedDeviceId(String? id) {
    if (id == null) return _box.remove(_pairedDeviceIdKey);
    return _box.write(_pairedDeviceIdKey, id);
  }

  static Future<void> clearAll() async {
    await _box.remove(_userKey);
    await _box.remove(_seenDeviceSetupKey);
    await _box.remove(_pairedDeviceIdKey);
  }
}
