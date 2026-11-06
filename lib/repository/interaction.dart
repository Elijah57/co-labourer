import 'package:uuid/uuid.dart';
import '../database.dart';
import '../models/interaction.dart';

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

  Future<void> updateNote(String id, String note) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'interactions',
      {'note': note},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteInteraction(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('interactions', where: 'id = ?', whereArgs: [id]);
  }
}