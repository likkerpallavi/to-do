import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:to_do/task.dart';

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
    final path = join(dbPath, 'todo.db');

    return await openDatabase(
      path,
      version: 2, // Bump the version here to 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Handle upgrades
    );
  }

  void _onCreate(Database db, int version) async {
    // Create the tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskName TEXT,
        taskDescription TEXT,
        taskDate TEXT,
        taskTime TEXT,
        color INTEGER,
        isCompleted INTEGER
      )
    ''');

    // Create the images table
    await db.execute('''
      CREATE TABLE images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image BLOB NOT NULL
      )
    ''');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // If upgrading from a version before 2, create the images table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image BLOB NOT NULL
        )
      ''');
    }
  }

  // Method to insert a task
  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Method to retrieve all tasks
  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // Method to save an image in the images table
  Future<int> insertImage(Uint8List imageBytes) async {
    final db = await database;
    return await db.insert('images', {'image': imageBytes});
  }

  // Method to retrieve the image from the images table as a File
  Future<File?> getImageAsFile() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('images', limit: 1);
    if (result.isNotEmpty) {
      Uint8List imageBytes = result.first['image'];
      return _saveBytesAsFile(imageBytes);
    }
    return null;
  }

  // Helper method to save Uint8List as a File in the temporary directory
  Future<File> _saveBytesAsFile(Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/background_image.png';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }
}
