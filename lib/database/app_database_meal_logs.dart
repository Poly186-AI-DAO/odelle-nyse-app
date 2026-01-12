part of 'app_database.dart';

mixin MealLogCrud on AppDatabaseBase {
  // =================
  // Meal Logs CRUD
  // =================

  Future<int> insertMealLog(MealLog log) async {
    final db = await database;
    final id = await db.insert('meal_logs', log.toMap());
    Logger.info('Inserted meal log: $id', tag: AppDatabase._tag);
    return id;
  }

  Future<List<MealLog>> getMealLogs({
    int limit = 50,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'meal_logs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => MealLog.fromMap(map)).toList();
  }

  Future<MealLog?> getMealLog(int id) async {
    final db = await database;
    final maps = await db.query(
      'meal_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MealLog.fromMap(maps.first);
  }

  Future<int> updateMealLog(MealLog log) async {
    final db = await database;
    return await db.update(
      'meal_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteMealLog(int id) async {
    final db = await database;
    return await db.delete(
      'meal_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
