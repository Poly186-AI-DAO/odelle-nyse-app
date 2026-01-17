part of 'app_database.dart';

mixin CharacterStatsCrud on AppDatabaseBase {
  // ====================
  // Character Stats CRUD
  // ====================

  Future<int> upsertCharacterStats(CharacterStats stats) async {
    final db = await database;
    final dateStr = stats.date.toIso8601String().split('T')[0];

    // Check if stats exist for this date
    final existing = await db.query(
      'character_stats',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (existing.isNotEmpty) {
      final count = await db.update(
        'character_stats',
        stats.toMap(),
        where: 'date = ?',
        whereArgs: [dateStr],
      );
      
      // We don't have a reliable single int ID for stats (composite key on date)
      // but we can use a hash or just 0 if we handle it specially on the backend.
      // For now, let's assume we can map it.
      // Actually, sync_queue expects row_id.
      // We need to fetch the rowID or rethink this for non-integer PKs.
      // Character stats has an 'id' integer PK? Let's check schema.
      // If schema has auto-increment ID, we should use it.
      
      // Querying ID to queue sync
      final idResult = await db.query('character_stats', columns: ['id'], where: 'date = ?', whereArgs: [dateStr]);
      if (idResult.isNotEmpty) {
        final id = idResult.first['id'] as int;
        await queueSync(tableName: 'character_stats', rowId: id, operation: 'UPDATE', data: stats.toMap());
      }
      
      return count;
    } else {
      final id = await db.insert('character_stats', stats.toMap());
      await queueSync(tableName: 'character_stats', rowId: id, operation: 'INSERT', data: stats.toMap());
      return id;
    }
  }

  Future<CharacterStats?> getCharacterStats(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];

    final maps = await db.query(
      'character_stats',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (maps.isEmpty) return null;
    return CharacterStats.fromMap(maps.first);
  }

  Future<CharacterStats> getTodayStats() async {
    final existing = await getCharacterStats(DateTime.now());
    return existing ?? CharacterStats.today();
  }
}
