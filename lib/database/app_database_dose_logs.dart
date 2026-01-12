part of 'app_database.dart';

mixin DoseLogCrud on AppDatabaseBase {
  // =================
  // Dose Logs CRUD
  // =================

  Future<int> insertDoseLog(DoseLog log) async {
    final db = await database;
    final id = await db.insert('dose_logs', log.toMap());
    Logger.info('Inserted dose log: $id', tag: AppDatabase._tag);
    return id;
  }

  Future<List<DoseLog>> getDoseLogs({
    int limit = 50,
    int offset = 0,
    int? supplementId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (supplementId != null) {
      whereClause += 'supplement_id = ?';
      whereArgs.add(supplementId);
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
      'dose_logs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => DoseLog.fromMap(map)).toList();
  }

  Future<DoseLog?> getDoseLog(int id) async {
    final db = await database;
    final maps = await db.query(
      'dose_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return DoseLog.fromMap(maps.first);
  }

  Future<int> updateDoseLog(DoseLog log) async {
    final db = await database;
    return await db.update(
      'dose_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteDoseLog(int id) async {
    final db = await database;
    return await db.delete(
      'dose_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
