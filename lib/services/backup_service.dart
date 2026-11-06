import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../data/audio_storage.dart';
import '../database.dart';

class BackupService {
  static const _fileName = 'colaborer.db';

  Future<Map<String, String>> _remoteFiles(drive.DriveApi api) async {
    final result = <String, String>{};
    String? pageToken;
    do {
      final page = await api.files.list(
        spaces: 'appDataFolder',
        pageSize: 1000,
        pageToken: pageToken,
        $fields: 'nextPageToken, files(id, name)',
      );
      for (final f in page.files ?? <drive.File>[]) {
        if (f.name != null && f.id != null) result[f.name!] = f.id!;
      }
      pageToken = page.nextPageToken;
    } while (pageToken != null);
    return result;
  }

  Future<void> _upload(
    drive.DriveApi api,
    File file,
    String name,
    String? existingId,
  ) async {
    final media = drive.Media(file.openRead(), await file.length());
    if (existingId != null) {
      await api.files.update(drive.File(), existingId, uploadMedia: media);
    } else {
      final metadata = drive.File()
        ..name = name
        ..parents = ['appDataFolder'];
      await api.files.create(metadata, uploadMedia: media);
    }
  }

  Future<List<int>> _download(drive.DriveApi api, String id) async {
    final media = await api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  Future<void> backup(auth.AuthClient client) async {
    final api = drive.DriveApi(client);
    final remote = await _remoteFiles(api);

    final db = await AppDatabase.instance.database;
    await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    await _upload(api, File(db.path), _fileName, remote[_fileName]);

    final dir = await audioDirectory();
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (remote.containsKey(name)) continue;
      await _upload(api, entity, name, null);
    }
  }

  Future<bool> restore(auth.AuthClient client) async {
    final api = drive.DriveApi(client);
    final remote = await _remoteFiles(api);

    final dbId = remote[_fileName];
    if (dbId == null) return false;

    final dbBytes = await _download(api, dbId);
    if (dbBytes.isEmpty) return false;

    final dbPath = p.join(await getDatabasesPath(), _fileName);
    await AppDatabase.instance.close();
    await File(dbPath).writeAsBytes(dbBytes, flush: true);
    for (final suffix in ['-wal', '-shm']) {
      final side = File('$dbPath$suffix');
      if (await side.exists()) await side.delete();
    }
    await AppDatabase.instance.database;

    final dir = await audioDirectory();
    for (final entry in remote.entries) {
      if (entry.key == _fileName) continue;
      final local = File(p.join(dir.path, entry.key));
      if (await local.exists()) continue;
      final bytes = await _download(api, entry.value);
      await local.writeAsBytes(bytes, flush: true);
    }
    return true;
  }
}
