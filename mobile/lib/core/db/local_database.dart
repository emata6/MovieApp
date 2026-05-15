import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static const _dbName = 'movie_app.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cached_movies (
        imdbId TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        year TEXT,
        poster TEXT,
        genre TEXT,
        director TEXT,
        actors TEXT,
        plot TEXT,
        imdbRating TEXT,
        runtime TEXT,
        rated TEXT,
        fetchedAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE favorites (
        imdbId TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        year TEXT,
        poster TEXT,
        addedAt TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        pendingDelete INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> upsertMovie(Map<String, dynamic> movie) async {
    final db = await database;
    await db.insert('cached_movies', movie,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getMovie(String imdbId) async {
    final db = await database;
    final rows = await db.query('cached_movies',
        where: 'imdbId = ?', whereArgs: [imdbId]);
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<List<Map<String, dynamic>>> getAllMovies() async {
    final db = await database;
    final rows = await db.query('cached_movies', orderBy: 'fetchedAt DESC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await database;
    final rows = await db.query('favorites', where: 'pendingDelete = 0');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> upsertFavorite(Map<String, dynamic> fav) async {
    final db = await database;
    await db.insert('favorites', fav,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markFavoriteDeleted(String imdbId) async {
    final db = await database;
    final rows =
        await db.query('favorites', where: 'imdbId = ?', whereArgs: [imdbId]);
    if (rows.isEmpty) return;
    if ((rows.first['synced'] as int) == 0) {
      await db.delete('favorites', where: 'imdbId = ?', whereArgs: [imdbId]);
    } else {
      await db.update('favorites', {'pendingDelete': 1},
          where: 'imdbId = ?', whereArgs: [imdbId]);
    }
  }

  Future<void> deleteFavorite(String imdbId) async {
    final db = await database;
    await db.delete('favorites', where: 'imdbId = ?', whereArgs: [imdbId]);
  }

  Future<void> markFavoriteSynced(String imdbId) async {
    final db = await database;
    await db.update('favorites', {'synced': 1, 'pendingDelete': 0},
        where: 'imdbId = ?', whereArgs: [imdbId]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedFavorites() async {
    final db = await database;
    final rows = await db.query('favorites',
        where: 'synced = 0 AND pendingDelete = 0');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getPendingDeleteFavorites() async {
    final db = await database;
    final rows =
        await db.query('favorites', where: 'pendingDelete = 1');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> replaceFavorites(List<Map<String, dynamic>> favorites) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('favorites');
      for (final fav in favorites) {
        await txn.insert('favorites', fav,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
