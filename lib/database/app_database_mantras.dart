part of 'app_database.dart';

mixin MantraCrud on AppDatabaseBase {
  // =============
  // Mantras CRUD
  // =============

  Future<int> insertMantra(Mantra mantra) async {
    final db = await database;
    return await db.insert('mantras', mantra.toMap());
  }

  Future<List<Mantra>> getMantras({bool activeOnly = true}) async {
    final db = await database;
    final maps = await db.query(
      'mantras',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Mantra.fromMap(map)).toList();
  }

  Future<Mantra?> getRandomMantra() async {
    final db = await database;
    final maps = await db.rawQuery(
        'SELECT * FROM mantras WHERE is_active = 1 ORDER BY RANDOM() LIMIT 1');
    if (maps.isEmpty) return null;
    return Mantra.fromMap(maps.first);
  }

  Future<int> updateMantra(Mantra mantra) async {
    final db = await database;
    return await db.update(
      'mantras',
      mantra.toMap(),
      where: 'id = ?',
      whereArgs: [mantra.id],
    );
  }

  Future<int> deleteMantra(int id) async {
    final db = await database;
    return await db.delete(
      'mantras',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
