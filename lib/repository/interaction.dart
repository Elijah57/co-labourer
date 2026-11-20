import 'package:uuid/uuid.dart';
import '../database.dart';
import '../models/interaction.dart';
import '../services/auto_backup.dart';

class InteractionsRepository {
  final _uuid = const Uuid();

  Future<Interaction> addInteraction({
    required String personId,
    String? note,
    String? audioPath,
  }) async {
    final db = await AppDatabase.instance.database;
    final interaction = Interaction(
      id: _uuid.v4(),
      personId: personId,
      note: note,
      audioPath: audioPath,
      createdAt: DateTime.now(),
    );
    await db.insert('interactions', interaction.toMap());
    AutoBackup.instance.markDirty();
    return interaction;
  }

  Future<List<Interaction>> getForPerson(String personId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'interactions',
      where: 'person_id = ?',
      whereArgs: [personId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Interaction.fromMap).toList();
  }

  /// Most recent conversation time for every person who has one.
  Future<Map<String, DateTime>> getLastByPerson() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      'SELECT person_id, MAX(created_at) AS last '
      'FROM interactions GROUP BY person_id',
    );
    final result = <String, DateTime>{};
    for (final row in rows) {
      final last = DateTime.tryParse(row['last'] as String? ?? '');
      if (last != null) result[row['person_id'] as String] = last;
    }
    return result;
  }

  Future<void> updateNote(String id, String note) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'interactions',
      {'note': note},
      where: 'id = ?',
      whereArgs: [id],
    );
    AutoBackup.instance.markDirty();
  }

  Future<void> deleteInteraction(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('interactions', where: 'id = ?', whereArgs: [id]);
    AutoBackup.instance.markDirty();
  }
}