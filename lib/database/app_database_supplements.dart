part of 'app_database.dart';

mixin SupplementCrud on AppDatabaseBase {
  // ===================
  // Supplements CRUD
  // ===================

  Future<int> insertSupplement(Supplement supplement) async {
    final db = await database;
    final id = await db.insert('supplements', supplement.toMap());
    Logger.info('Inserted supplement: $id', tag: AppDatabase._tag);
    return id;
  }

  Future<List<Supplement>> getSupplements({
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'supplements',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Supplement.fromMap(map)).toList();
  }

  Future<List<Supplement>> getActiveSupplements() async {
    return getSupplements();
  }

  Future<Supplement?> getSupplement(int id) async {
    final db = await database;
    final maps = await db.query(
      'supplements',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Supplement.fromMap(maps.first);
  }

  Future<int> updateSupplement(Supplement supplement) async {
    final db = await database;
    return await db.update(
      'supplements',
      supplement.toMap(),
      where: 'id = ?',
      whereArgs: [supplement.id],
    );
  }

  Future<int> deleteSupplement(int id) async {
    final db = await database;
    return await db.delete(
      'supplements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
