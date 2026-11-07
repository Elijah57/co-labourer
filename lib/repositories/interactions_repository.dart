import 'dart:io';
import '../database.dart';

class InteractionsRepository {
  Future<void> removeOrphanAudio() async {
    final db = await AppDatabase.instance.database;

    final List<String> referenced = await db.rawQuery('''
      SELECT audio_path FROM interactions
      WHERE audio_path IS NOT NULL AND audio_path != ''
      UNION
      SELECT audio_path FROM journal_entries
      WHERE audio_path IS NOT NULL AND audio_path != ''
    ''') as List<String>;

    final referencedSet = {...referenced};

    final allRows = await db.rawQuery('SELECT audio_path FROM interactions');
    for (final row in allRows) {
      final path = row['audio_path'] as String?;
      if (path != null && !referencedSet.contains(path)) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }

    final journalRows = await db.rawQuery('SELECT audio_path FROM journal_entries');
    for (final row in journalRows) {
      final path = row['audio_path'] as String?;
      if (path != null && !referencedSet.contains(path)) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
  }
}