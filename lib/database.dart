import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _open() async {
    final dbPath = join(await getDatabasesPath(), 'colaborer.db');
    return openDatabase(
      dbPath,
      version: 4,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE people (
            id TEXT PRIMARY KEY,
            firstname TEXT NOT NULL,
            lastname TEXT,
            othername TEXT,
            phoneno TEXT,
            email TEXT,
            address TEXT,
            photo_path TEXT,
            met_at TEXT,
            follow_up_date TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE interactions (
            id TEXT PRIMARY KEY,
            person_id TEXT NOT NULL REFERENCES people(id) ON DELETE CASCADE,
            note TEXT,
            audio_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE people ADD COLUMN phoneno TEXT');
          await db.execute('ALTER TABLE people ADD COLUMN email TEXT');
          await db.execute('ALTER TABLE people ADD COLUMN address TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE people ADD COLUMN photo_path TEXT');
        }
        if (oldVersion < 4) {
          await _createIndexes(db);
        }
      },
    );
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_interactions_person_created '
      'ON interactions(person_id, created_at)',
    );
  }
}