import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'backup_service.dart';
import 'drive_auth_service.dart';

class AutoBackup {
  static final AutoBackup instance = AutoBackup._();
  AutoBackup._();

  static const _enabledKey = 'auto_backup_enabled';
  static const _dirtyKey = 'backup_dirty';
  static const _lastKey = 'last_backup_ms';

  late SharedPreferences _prefs;
  Timer? _timer;
  bool _running = false;

  bool enabled = false;
  DateTime? lastBackup;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    enabled = _prefs.getBool(_enabledKey) ?? false;
    final ms = _prefs.getInt(_lastKey);
    lastBackup = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    if (enabled && (_prefs.getBool(_dirtyKey) ?? false)) _schedule();
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    await _prefs.setBool(_enabledKey, value);
    if (!value) _timer?.cancel();
  }

  void markDirty() {
    _prefs.setBool(_dirtyKey, true);
    if (enabled) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 30), _autoRun);
  }

  Future<void> _autoRun() async {
    try {
      final client = await DriveAuthService().trySilentClient();
      if (client == null) return;
      await run(client);
    } catch (e) {
      debugPrint('Auto backup failed: $e');
    }
  }

  Future<bool> run(auth.AuthClient client) async {
    if (_running) return false;
    _running = true;
    try {
      await _prefs.setBool(_dirtyKey, false);
      await BackupService().backup(client);
      lastBackup = DateTime.now();
      await _prefs.setInt(_lastKey, lastBackup!.millisecondsSinceEpoch);
      return true;
    } catch (e) {
      await _prefs.setBool(_dirtyKey, true);
      rethrow;
    } finally {
      _running = false;
    }
  }
}
