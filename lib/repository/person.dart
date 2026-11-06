import 'package:uuid/uuid.dart';
import '../database.dart';
import '../models/person.dart';

class PeopleRepository {
  final _uuid = const Uuid();

  Future<Person> addPerson({
    required String firstname,
    String? lastname,
    String? othername,
    String? phoneno,
    String? email,
    String? address,
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
      metAt: metAt,
      followUpDate: followUpDate,
      createdAt: DateTime.now(),
    );
    await db.insert('people', person.toMap());
    return person;
  }

  Future<List<Person>> getAllPeople() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('people', orderBy: 'created_at DESC');
    return rows.map(Person.fromMap).toList();
  }

  Future<void> updatePerson(Person person) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'people',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }


  Future<void> deletePerson(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'people',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}