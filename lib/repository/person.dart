import 'package:uuid/uuid.dart';
import '../database.dart';
import '../models/person.dart';
import '../../utils/birthday.dart';
import '../services/auto_backup.dart';

class PeopleRepository {
  final _uuid = const Uuid();

  Future<Person> addPerson({
    required String firstname,
    String? lastname,
    String? othername,
    String? phoneno,
    String? email,
    String? address,
    String? photoPath,
    Birthday? birthday,
    String? partner,
    String? intro,
    DateTime? metOn,
    String? metAt,
    DateTime? followUpDate,
  }) async {
    final db = await AppDatabase.instance.database;
    final person = Person(
      id: _uuid.v4(),
      firstname: firstname,
      lastname: lastname,
      othername: othername,
      phoneno: phoneno,
      email: email,
      address: address,
      photoPath: photoPath,
      birthday: birthday,
      partner: partner,
      intro: intro,
      metOn: metOn,
      metAt: metAt,
      followUpDate: followUpDate,
      createdAt: DateTime.now(),
    );
    await db.insert('people', person.toMap());
    AutoBackup.instance.markDirty();
    return person;
  }

  Future<List<Person>> getAllPeople() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('people', orderBy: 'created_at DESC');
    return rows.map(Person.fromMap).toList();
  }

  Future<Person?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'people',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Person.fromMap(rows.first);
  }

  Future<void> setFollowUp(String id, DateTime? date) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'people',
      {'follow_up_date': date?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    AutoBackup.instance.markDirty();
  }

  Future<void> updatePerson(Person person) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'people',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
    AutoBackup.instance.markDirty();
  }


  Future<void> deletePerson(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'people',
      where: 'id = ?',
      whereArgs: [id],
    );
    AutoBackup.instance.markDirty();
  }
}