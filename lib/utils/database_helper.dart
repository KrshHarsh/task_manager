import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'task_manager.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'todo',
        blockedByTaskId TEXT,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'sortOrder ASC, createdAt DESC');
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    // Clear blockedByTaskId references to the deleted task
    await db.update(
      'tasks',
      {'blockedByTaskId': null},
      where: 'blockedByTaskId = ?',
      whereArgs: [id],
    );
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSortOrders(List<Task> tasks) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < tasks.length; i++) {
      batch.update(
        'tasks',
        {'sortOrder': i},
        where: 'id = ?',
        whereArgs: [tasks[i].id],
      );
    }
    await batch.commit(noResult: true);
  }
}
