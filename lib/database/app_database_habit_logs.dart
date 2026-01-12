part of 'app_database.dart';

mixin HabitLogCrud on AppDatabaseBase {
  // =================
  // Habit Logs CRUD
  // =================

  Future<int> insertHabitLog(HabitLog log) async {
    final db = await database;
    final id = await db.insert('habit_logs', log.toMap());
    Logger.info('Inserted habit log: $id', tag: AppDatabase._tag);
    return id;
  }

  Future<List<HabitLog>> getHabitLogs({
    int? habitId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (habitId != null) {
      whereClause += 'habit_id = ?';
      whereArgs.add(habitId);
    }
    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date >= ?';
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }

    final maps = await db.query(
      'habit_logs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => HabitLog.fromMap(map)).toList();
  }

  Future<HabitLog?> getHabitLog(int id) async {
    final db = await database;
    final maps = await db.query(
      'habit_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return HabitLog.fromMap(maps.first);
  }

  Future<int> updateHabitLog(HabitLog log) async {
    final db = await database;
    return await db.update(
      'habit_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteHabitLog(int id) async {
    final db = await database;
    return await db.delete(
      'habit_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
