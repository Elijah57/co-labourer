import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLock {
  static final AppLock instance = AppLock._();
  AppLock._();

  static const _key = 'app_lock_enabled';

  final _auth = LocalAuthentication();
  late SharedPreferences _prefs;
  bool enabled = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    enabled = _prefs.getBool(_key) ?? false;
  }

  Future<bool> authenticate() async {
    try {
      if (!await _auth.isDeviceSupported()) return true;
      return await _auth.authenticate(localizedReason: 'Unlock Co-laborer');
    } catch (e) {
      debugPrint('Unlock failed: $e');
      return false;
    }
  }

  Future<bool> setEnabled(bool value) async {
    if (value) {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await authenticate()) return false;
    }
    enabled = value;
    await _prefs.setBool(_key, value);
    return true;
  }
}
