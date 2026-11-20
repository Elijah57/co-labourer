import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database.dart';
import '../models/tag.dart';
import '../services/auto_backup.dart';

class TagsRepository {
  final _uuid = const Uuid();

  Future<List<Tag>> getAllTags() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('tags', orderBy: 'name COLLATE NOCASE');
    return rows.map(Tag.fromMap).toList();
  }

  /// Returns the existing tag with this name (case-insensitive) or creates it.
  Future<Tag> getOrCreate(String name) async {
    final trimmed = name.trim();
    final db = await AppDatabase.instance.database;
    final existing = await db.query(
      'tags',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (existing.isNotEmpty) return Tag.fromMap(existing.first);

    final tag = Tag(id: _uuid.v4(), name: trimmed, createdAt: DateTime.now());
    await db.insert('tags', tag.toMap());
    AutoBackup.instance.markDirty();
    return tag;
  }

  Future<List<Tag>> getForPerson(String personId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      'SELECT t.* FROM tags t '
      'JOIN person_tags pt ON pt.tag_id = t.id '
      'WHERE pt.person_id = ? '
      'ORDER BY t.name COLLATE NOCASE',
      [personId],
    );
    return rows.map(Tag.fromMap).toList();
  }

  /// Tag IDs for every person that has at least one tag.
  Future<Map<String, Set<String>>> getTagIdsByPerson() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('person_tags');
    final result = <String, Set<String>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row['person_id'] as String, () => <String>{})
          .add(row['tag_id'] as String);
    }
    return result;
  }

  Future<void> setPersonTags(String personId, Set<String> tagIds) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        'person_tags',
        where: 'person_id = ?',
        whereArgs: [personId],
      );
      for (final tagId in tagIds) {
        await txn.insert(
          'person_tags',
          {'person_id': personId, 'tag_id': tagId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
    AutoBackup.instance.markDirty();
  }

  /// Deletes the tag and removes it from everyone who has it.
  Future<void> deleteTag(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
    AutoBackup.instance.markDirty();
  }
}
