import 'package:uuid/uuid.dart';
import '../database.dart';
import '../models/journal_entry.dart';
import '../services/auto_backup.dart';

class JournalRepository {
  final _uuid = const Uuid();

  Future<JournalEntry> add({String? note, String? audioPath}) async {
    final db = await AppDatabase.instance.database;
    final entry = JournalEntry(
      id: _uuid.v4(),
      note: note,
      audioPath: audioPath,
      createdAt: DateTime.now(),
    );
    await db.insert('journal_entries', entry.toMap());
    AutoBackup.instance.markDirty();
    return entry;
  }

  Future<List<JournalEntry>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('journal_entries', orderBy: 'created_at DESC');
    return rows.map(JournalEntry.fromMap).toList();
  }

  Future<void> updateNote(String id, String note) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'journal_entries',
      {'note': note},
      where: 'id = ?',
      whereArgs: [id],
    );
    AutoBackup.instance.markDirty();
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    AutoBackup.instance.markDirty();
  }
}
