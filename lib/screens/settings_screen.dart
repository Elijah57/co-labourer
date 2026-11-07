import 'package:flutter/material.dart';
import '../repository/person.dart';
import '../services/app_lock.dart';
import '../services/auto_backup.dart';
import '../services/backup_service.dart';
import '../services/drive_auth_service.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  String _lastBackupLabel() {
    final t = AutoBackup.instance.lastBackup;
    if (t == null) return 'No backup yet';
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return 'Last backup: ${t.day}/${t.month} $hh:$mm';
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _backup() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final client = await DriveAuthService().signIn();
      final ran = await AutoBackup.instance.run(client);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ran ? 'Backup complete' : 'A backup is already running'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _confirm(
      'Restore from Drive?',
      'This replaces everything on this phone with your last backup.',
      'Restore',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      final client = await DriveAuthService().signIn();
      final found = await BackupService().restore(client);
      if (found) {
        await NotificationService.instance.rescheduleAll(
          await PeopleRepository().getAllPeople(),
        );
      }
      messenger.showSnackBar(
        SnackBar(content: Text(found ? 'Restore complete' : 'No backup found')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleAutoBackup(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final auto = AutoBackup.instance;

    if (!value) {
      await auto.setEnabled(false);
      if (mounted) setState(() {});
      return;
    }

    try {
      await DriveAuthService().signIn();
      await auto.setEnabled(true);
      auto.markDirty();
      messenger.showSnackBar(const SnackBar(content: Text('Auto backup on')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not enable: $e')));
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleLock(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await AppLock.instance.setEnabled(value);
    if (!mounted) return;
    setState(() {});
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not change app lock. Make sure your phone has a screen lock set up.',
          ),
        ),
      );
    }
  }

  Future<void> _export() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _confirm(
      'Export your data?',
      'The CSV file is not encrypted. Anyone you send it to can read every name, number and note.',
      'Export',
    );
    if (!ok || !mounted) return;

    if (AppLock.instance.enabled && !await AppLock.instance.authenticate()) {
      return;
    }

    setState(() => _busy = true);
    try {
      await ExportService().share();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: scheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        children: [
          _section('Backup'),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Back up now'),
            subtitle: Text(_lastBackupLabel()),
            enabled: !_busy,
            onTap: _backup,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.sync),
            title: const Text('Auto backup'),
            subtitle: const Text('Saves to Drive shortly after every change'),
            value: AutoBackup.instance.enabled,
            onChanged: _busy ? null : _toggleAutoBackup,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Restore from Drive'),
            subtitle: const Text('Replaces everything on this phone'),
            enabled: !_busy,
            onTap: _restore,
          ),
          _section('Security'),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('App lock'),
            subtitle: const Text('Ask for your fingerprint or PIN'),
            value: AppLock.instance.enabled,
            onChanged: _busy ? null : _toggleLock,
          ),
          _section('Your data'),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export people to CSV'),
            subtitle: const Text('A spreadsheet of people and conversations'),
            enabled: !_busy,
            onTap: _export,
          ),
        ],
      ),
    );
  }
}