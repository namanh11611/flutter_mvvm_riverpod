import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter_mvvm_riverpod/core/utils/database_helper.dart';

part 'database_provider.g.dart';

@riverpod
Future<Database> database(Ref ref) async {
  final db = await DatabaseHelper.instance.database;
  
  ref.onDispose(() async {
    await DatabaseHelper.instance.close();
  });
  
  return db;
}
