class HeroTable {
  HeroTable._();

  static const String tableName = 'heroes';

  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnDescription = 'description';
  static const String columnImageUrl = 'imageUrl';
  static const String columnIsFavorite = 'isFavorite';
  static const String columnPower = 'power';
  static const String columnLastUpdated = 'lastUpdated';

  static const String createTableQuery = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnName TEXT NOT NULL,
      $columnDescription TEXT NOT NULL,
      $columnImageUrl TEXT NOT NULL,
      $columnIsFavorite INTEGER NOT NULL DEFAULT 0,
      $columnPower INTEGER NOT NULL DEFAULT 0,
      $columnLastUpdated INTEGER
    )
  ''';
}
