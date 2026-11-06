import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../database.dart';

class BackupService {
  static const _fileName = 'colaborer.db';

  Future<void> backup(auth.AuthClient client) async {
    final db = await AppDatabase.instance.database;
    await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');

    final file = File(db.path);
    final media = drive.Media(file.openRead(), await file.length());
    final api = drive.DriveApi(client);

    final existing = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName'",
      $fields: 'files(id)',
    );

    final files = existing.files;
    if (files != null && files.isNotEmpty) {
      await api.files.update(drive.File(), files.first.id!, uploadMedia: media);
    } else {
      final metadata = drive.File()
        ..name = _fileName
        ..parents = ['appDataFolder'];
      await api.files.create(metadata, uploadMedia: media);
    }
  }

  Future<bool> restore(auth.AuthClient client) async {
    final api = drive.DriveApi(client);

    final existing = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName'",
      $fields: 'files(id)',
    );
    final files = existing.files;
    if (files == null || files.isEmpty) return false;

    final media = await api.files.get(
      files.first.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    if (bytes.isEmpty) return false;

    final dbPath = join(await getDatabasesPath(), _fileName);
    await AppDatabase.instance.close();
    await File(dbPath).writeAsBytes(bytes, flush: true);

    for (final suffix in ['-wal', '-shm']) {
      final sideFile = File('$dbPath$suffix');
      if (await sideFile.exists()) await sideFile.delete();
    }

    await AppDatabase.instance.database;
    return true;
  }
}
