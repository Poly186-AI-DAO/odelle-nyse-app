part of 'app_database.dart';

mixin WorkoutLogCrud on AppDatabaseBase {
  // =================
  // Workout Logs CRUD
  // =================

  Future<int> insertWorkoutLog(WorkoutLog log) async {
    final db = await database;
    final id = await db.insert('workout_logs', log.toMap());
    Logger.info('Inserted workout log: $id', tag: AppDatabase._tag);
    
    await queueSync(
      tableName: 'workout_logs',
      rowId: id,
      operation: 'INSERT',
      data: log.toMap(),
    );
    
    return id;
  }

  Future<List<WorkoutLog>> getWorkoutLogs({
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
      whereClause += 'start_time >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      // Using start_time for range check on workouts
      whereClause += 'start_time <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'workout_logs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => WorkoutLog.fromMap(map)).toList();
  }

  Future<WorkoutLog?> getWorkoutLog(int id) async {
    final db = await database;
    final maps = await db.query(
      'workout_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return WorkoutLog.fromMap(maps.first);
  }

  Future<int> updateWorkoutLog(WorkoutLog log) async {
    final db = await database;
    final count = await db.update(
      'workout_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
    
    if (count > 0 && log.id != null) {
      await queueSync(
        tableName: 'workout_logs',
        rowId: log.id!,
        operation: 'UPDATE',
        data: log.toMap(),
      );
    }
    
    return count;
  }

  Future<int> deleteWorkoutLog(int id) async {
    final db = await database;
    final count = await db.delete(
      'workout_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'workout_logs',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }
}
