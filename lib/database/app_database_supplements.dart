part of 'app_database.dart';

mixin SupplementCrud on AppDatabaseBase {
  // ===================
  // Supplements CRUD
  // ===================

  Future<int> insertSupplement(Supplement supplement) async {
    final db = await database;
    final id = await db.insert('supplements', supplement.toMap());
    Logger.info('Inserted supplement: $id', tag: AppDatabase._tag);
    
    await queueSync(
      tableName: 'supplements',
      rowId: id,
      operation: 'INSERT',
      data: supplement.toMap(),
    );
    
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
    final count = await db.update(
      'supplements',
      supplement.toMap(),
      where: 'id = ?',
      whereArgs: [supplement.id],
    );
    
    if (count > 0 && supplement.id != null) {
      await queueSync(
        tableName: 'supplements',
        rowId: supplement.id!,
        operation: 'UPDATE',
        data: supplement.toMap(),
      );
    }
    
    return count;
  }

  Future<int> deleteSupplement(int id) async {
    final db = await database;
    final count = await db.delete(
      'supplements',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'supplements',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }
}
