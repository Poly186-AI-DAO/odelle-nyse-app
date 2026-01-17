part of 'app_database.dart';

mixin MantraCrud on AppDatabaseBase {
  // =============
  // Mantras CRUD
  // =============

  Future<int> insertMantra(Mantra mantra) async {
    final db = await database;
    final id = await db.insert('mantras', mantra.toMap());
    
    await queueSync(
      tableName: 'mantras',
      rowId: id,
      operation: 'INSERT',
      data: mantra.toMap(),
    );
    
    return id;
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
    final count = await db.update(
      'mantras',
      mantra.toMap(),
      where: 'id = ?',
      whereArgs: [mantra.id],
    );
    
    if (count > 0 && mantra.id != null) {
      await queueSync(
        tableName: 'mantras',
        rowId: mantra.id!,
        operation: 'UPDATE',
        data: mantra.toMap(),
      );
    }
    
    return count;
  }

  Future<int> deleteMantra(int id) async {
    final db = await database;
    final count = await db.delete(
      'mantras',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'mantras',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }
}
