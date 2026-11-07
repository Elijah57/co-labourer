import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/profile.dart';
import '../services/auto_backup.dart';

class ProfileRepository {
  Future<Profile?> get() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'profile',
      where: 'id = ?',
      whereArgs: ['me'],
      limit: 1,
    );
    return rows.isEmpty ? null : Profile.fromMap(rows.first);
  }

  Future<void> save(Profile profile) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AutoBackup.instance.markDirty();
  }
}