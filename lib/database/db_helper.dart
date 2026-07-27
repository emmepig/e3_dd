import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/point_layer.dart';
import '../models/point_marker.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._internal();

  factory DBHelper() => instance;

  DBHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, 'e3trace.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE layers(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon INTEGER NOT NULL,
        visible INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE points(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        layer_id TEXT NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        nome TEXT,
        dimensione INTEGER,
        accessibilita INTEGER,
        note TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Aggiornamento automatico di updated_at per layers
    await db.execute('''
    CREATE TRIGGER layers_updated_at
    AFTER UPDATE ON layers
    FOR EACH ROW
    BEGIN
      UPDATE layers
      SET updated_at = CURRENT_TIMESTAMP
      WHERE id = OLD.id;
    END;
  ''');

    // Aggiornamento automatico di updated_at per points
    await db.execute('''
    CREATE TRIGGER points_updated_at
    AFTER UPDATE ON points
    FOR EACH ROW
    BEGIN
      UPDATE points
      SET updated_at = CURRENT_TIMESTAMP
      WHERE id = OLD.id;
    END;
  ''');
  }

  Future<void> insertLayer(PointLayer layer) async {
    final db = await database;

    await db.insert(
      'layers',
      layer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLayer(PointLayer layer) async {
    final db = await database;

    await db.update(
      'layers',
      layer.toMap(),
      where: 'id = ?',
      whereArgs: [layer.id],
    );
  }

  Future<void> deleteLayer(String id) async {
    final db = await database;

    await db.delete('layers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PointLayer>> getLayers() async {
    final db = await database;

    final result = await db.query('layers');

    return result.map((e) => PointLayer.fromMap(e)).toList();
  }

  Future<int> insertPoint(PointMarker point) async {
    final db = await database;

    return await db.insert('points', point.toMap());
  }

  Future<void> updatePoint(PointMarker point) async {
    final db = await database;

    await db.update(
      'points',
      point.toMap(),
      where: 'id = ?',
      whereArgs: [point.id],
    );
  }

  Future<void> deletePoint(int id) async {
    final db = await database;

    await db.delete('points', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PointMarker>> getPoints() async {
    final db = await database;

    final result = await db.query('points');

    return result.map((e) => PointMarker.fromMap(e)).toList();
  }

  Future<void> clearAll() async {
    final db = await database;

    await db.delete('points');
    await db.delete('layers');
  }
}
