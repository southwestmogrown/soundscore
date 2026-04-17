import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'session.dart';

/// Repository for persisting and retrieving recording [Session]s using SQLite.
class SessionRepository {
  static const _dbName = 'soundscore_sessions.db';
  static const _tableName = 'sessions';
  static const _dbVersion = 1;

  Database? _db;

  /// Open (or create) the database. Safe to call multiple times.
  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        instrument_name TEXT NOT NULL,
        notes_json  TEXT    NOT NULL DEFAULT '',
        created_at  TEXT    NOT NULL
      )
    ''');
  }

  /// Save a new session and return it with its generated [id].
  Future<Session> insert(Session session) async {
    final db = await database;
    final id = await db.insert(_tableName, session.toMap());
    return session.copyWith(id: id);
  }

  /// Update an existing session (matched by [Session.id]).
  Future<void> update(Session session) async {
    assert(session.id != null, 'Cannot update a session without an id.');
    final db = await database;
    await db.update(
      _tableName,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Delete a session by [id].
  Future<void> delete(int id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Return all saved sessions, most recent first.
  Future<List<Session>> getAll() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );
    return rows.map(Session.fromMap).toList();
  }

  /// Return a single session by [id], or null if not found.
  Future<Session?> getById(int id) async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Session.fromMap(rows.first);
  }

  /// Close the database connection. Call when the app is shutting down.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
