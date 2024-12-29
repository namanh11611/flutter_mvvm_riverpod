import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../constants/database_constants.dart';
import '../../common/local/database_provider.dart';
import '../model/hero.dart';

part 'hero_list_repository.g.dart';

@riverpod
Future<HeroListRepository> heroListRepository(Ref ref) async {
  final db = await ref.watch(databaseProvider.future);
  return HeroListRepository(db);
}

class HeroListRepository {
  final Database database;

  HeroListRepository(this.database);

  Future<List<Hero>> getHeroes() async {
    // TODO: remove this delay
    await Future.delayed(Duration(seconds: 1));
    final maps = await database.query(HeroTable.tableName);
    return maps.map(Hero.fromJson).toList();
  }

  Future<Hero?> getHero(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      HeroTable.tableName,
      where: '${HeroTable.columnId} = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Hero.fromJson(maps[0]);
  }

  Future<void> insertHero(Hero hero) async {
    await database.insert(
      HeroTable.tableName,
      hero.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateHero(Hero hero) async {
    final map = hero.toJson()..remove(HeroTable.columnId);
    map[HeroTable.columnLastUpdated] = DateTime.now().millisecondsSinceEpoch;

    await database.update(
      HeroTable.tableName,
      map,
      where: '${HeroTable.columnId} = ?',
      whereArgs: [hero.id],
    );
  }

  Future<void> deleteHero(String id) async {
    await database.delete(
      HeroTable.tableName,
      where: '${HeroTable.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleFavorite(String id) async {
    final hero = await getHero(id);
    if (hero != null) {
      await updateHero(hero.copyWith(isFavorite: !hero.isFavorite));
    }
  }
}
