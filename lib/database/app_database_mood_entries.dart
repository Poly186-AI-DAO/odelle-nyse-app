part of 'app_database.dart';

mixin MoodEntryCrud on AppDatabaseBase {
  // ==================
  // Mood Entries CRUD
  // ==================

  Future<int> insertMoodEntry(MoodEntry entry) async {
    final db = await database;
    final id = await db.insert('mood_entries', entry.toMap());
    Logger.info('Inserted mood entry: $id', tag: AppDatabase._tag);
    
    await queueSync(
      tableName: 'mood_entries',
      rowId: id,
      operation: 'INSERT',
      data: entry.toMap(),
    );
    
    return id;
  }

  Future<List<MoodEntry>> getMoodEntries({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
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
      'mood_entries',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => MoodEntry.fromMap(map)).toList();
  }

  Future<MoodEntry?> getMoodEntry(int id) async {
    final db = await database;
    final maps = await db.query(
      'mood_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MoodEntry.fromMap(maps.first);
  }

  Future<int> updateMoodEntry(MoodEntry entry) async {
    final db = await database;
    final count = await db.update(
      'mood_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    
    if (count > 0 && entry.id != null) {
      await queueSync(
        tableName: 'mood_entries',
        rowId: entry.id!,
        operation: 'UPDATE',
        data: entry.toMap(),
      );
    }
    
    return count;
  }

  Future<int> deleteMoodEntry(int id) async {
    final db = await database;
    final count = await db.delete(
      'mood_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'mood_entries',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }
}
