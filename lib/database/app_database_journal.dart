part of 'app_database.dart';

mixin JournalEntryCrud on AppDatabaseBase {
  // ===================
  // Journal Entry CRUD
  // ===================

  Future<int> insertJournalEntry(JournalEntry entry) async {
    final db = await database;
    final id = await db.insert('journal_entries', entry.toMap());
    Logger.info('Inserted journal entry: $id', tag: AppDatabase._tag);
    
    await queueSync(
      tableName: 'journal_entries',
      rowId: id,
      operation: 'INSERT',
      data: entry.toMap(),
    );
    
    return id;
  }

  Future<List<JournalEntry>> getJournalEntries({
    int limit = 50,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'journal_entries',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  Future<JournalEntry?> getJournalEntry(int id) async {
    final db = await database;
    final maps = await db.query(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return JournalEntry.fromMap(maps.first);
  }

  Future<int> updateJournalEntry(JournalEntry entry) async {
    final db = await database;
    final count = await db.update(
      'journal_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    
    if (count > 0 && entry.id != null) {
      await queueSync(
        tableName: 'journal_entries',
        rowId: entry.id!,
        operation: 'UPDATE',
        data: entry.toMap(),
      );
    }
    
    return count;
  }

  Future<int> deleteJournalEntry(int id) async {
    final db = await database;
    final count = await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'journal_entries',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }
}
