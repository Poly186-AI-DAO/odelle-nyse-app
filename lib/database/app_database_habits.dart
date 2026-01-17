part of 'app_database.dart';

mixin HabitCrud on AppDatabaseBase {
  // =================
  // Habits CRUD
  // =================

  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    final id = await db.insert('habits', habit.toMap());
    Logger.info('Inserted habit: $id', tag: AppDatabase._tag);
    
    await queueSync(
      tableName: 'habits',
      rowId: id,
      operation: 'INSERT',
      data: habit.toMap(),
    );
    
    return id;
  }

  Future<List<Habit>> getHabits({
    int? userId,
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }
    if (activeOnly) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_active = 1 AND is_archived = 0';
    }

    final maps = await db.query(
      'habits',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'sort_order ASC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<Habit?> getHabit(int id) async {
    final db = await database;
    final maps = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    final count = await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
    
    if (count > 0 && habit.id != null) {
      await queueSync(
        tableName: 'habits',
        rowId: habit.id!,
        operation: 'UPDATE',
        data: habit.toMap(),
      );
    }
    
    return count;
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    final count = await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'habits',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }
}
