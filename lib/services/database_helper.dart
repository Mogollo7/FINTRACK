import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fintrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  FutureOr<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        photoPath TEXT,
        isAnt INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<Expense> createExpense(Expense expense) async {
    final db = await database;
    final id = await db.insert('expenses', expense.toMap());
    return expense.copyWith(id: id);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

