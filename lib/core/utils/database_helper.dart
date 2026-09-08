import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter_mvvm_riverpod/core/constants/database_constants.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_database_schema.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Heroes table
    await db.execute(HeroTable.createTableQuery);
    await GroupExpenseDatabaseSchema.createAndSeed(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await GroupExpenseDatabaseSchema.createAndSeed(db);
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
