part of 'app_database.dart';

mixin StreakCrud on AppDatabaseBase {
  // ==============
  // Streaks CRUD
  // ==============

  Future<int> insertStreak(Streak streak) async {
    final db = await database;
    final id = await db.insert('streaks', streak.toMap());
    Logger.info('Inserted streak: $id', tag: AppDatabase._tag);
    
    await queueSync(
      tableName: 'streaks',
      rowId: id,
      operation: 'INSERT',
      data: streak.toMap(),
    );
    
    return id;
  }

  Future<List<Streak>> getStreaks({
    int? userId,
    StreakType? type,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }
    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'streak_type = ?';
      whereArgs.add(type.name);
    }

    final maps = await db.query(
      'streaks',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'last_activity_date DESC',
    );

    return maps.map((map) => Streak.fromMap(map)).toList();
  }

  Future<Streak?> getStreak(int id) async {
    final db = await database;
    final maps = await db.query(
      'streaks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Streak.fromMap(maps.first);
  }

  Future<int> updateStreak(Streak streak) async {
    final db = await database;
    final count = await db.update(
      'streaks',
      streak.toMap(),
      where: 'id = ?',
      whereArgs: [streak.id],
    );
    
    if (count > 0 && streak.id != null) {
      await queueSync(
        tableName: 'streaks',
        rowId: streak.id!,
        operation: 'UPDATE',
        data: streak.toMap(),
      );
    }
    
    return count;
  }

  Future<int> deleteStreak(int id) async {
    final db = await database;
    final count = await db.delete(
      'streaks',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'streaks',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }
}
