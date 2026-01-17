part of 'app_database.dart';

mixin ProtocolEntryCrud on AppDatabaseBase {
  // ====================
  // Protocol Entry CRUD
  // ====================

  Future<int> insertProtocolEntry(ProtocolEntry entry) async {
    final db = await database;
    final id = await db.insert('protocol_entries', entry.toMap());
    Logger.info('Inserted protocol entry: ${entry.type.displayName}',
        tag: AppDatabase._tag);
        
    await queueSync(
      tableName: 'protocol_entries',
      rowId: id,
      operation: 'INSERT',
      data: entry.toMap(),
    );
    
    return id;
  }

  Future<List<ProtocolEntry>> getProtocolEntries({
    int limit = 50,
    int offset = 0,
    ProtocolType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (type != null) {
      whereClause += 'type = ?';
      whereArgs.add(type.name);
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
      'protocol_entries',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => ProtocolEntry.fromMap(map)).toList();
  }

  @override
  Future<List<ProtocolEntry>> getTodayProtocolEntries() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getProtocolEntries(startDate: startOfDay, endDate: endOfDay);
  }

  Future<int> deleteProtocolEntry(int id) async {
    final db = await database;
    final count = await db.delete(
      'protocol_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'protocol_entries',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }
}
