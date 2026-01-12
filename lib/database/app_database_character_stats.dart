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
      return await db.update(
        'character_stats',
        stats.toMap(),
        where: 'date = ?',
        whereArgs: [dateStr],
      );
    } else {
      return await db.insert('character_stats', stats.toMap());
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
