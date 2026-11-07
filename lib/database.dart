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
      version: 7,
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
            birthday TEXT,
            partner TEXT,
            intro TEXT,
            met_on TEXT,
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
        await _createJournal(db);
        await _createProfile(db);
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
          await db.execute('ALTER TABLE people ADD COLUMN birthday TEXT');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE people ADD COLUMN partner TEXT');
          await db.execute('ALTER TABLE people ADD COLUMN intro TEXT');
          await db.execute('ALTER TABLE people ADD COLUMN met_on TEXT');
        }
        if (oldVersion < 6) {
          await _createJournal(db);
        }
        if (oldVersion < 7) {
          await _createProfile(db);
        }
      },
    );
  }

  Future<void> _createJournal(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_entries (
        id TEXT PRIMARY KEY,
        note TEXT,
        audio_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_journal_created '
      'ON journal_entries(created_at)',
    );
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_interactions_person_created '
      'ON interactions(person_id, created_at)',
    );
  }

  Future<void> _createProfile(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        about TEXT
      )
    ''');
  }
}