part of 'app_database.dart';

mixin BillCrud on AppDatabaseBase {
  // ===================
  // Bills CRUD (Wealth Pillar)
  // ===================

  Future<int> insertBill(Bill bill) async {
    final db = await database;
    final id = await db.insert('bills', bill.toMap());
    Logger.info('Inserted bill: $id', tag: AppDatabase._tag);
    
    await queueSync(
      tableName: 'bills',
      rowId: id,
      operation: 'INSERT',
      data: bill.toMap(),
    );
    
    return id;
  }

  Future<List<Bill>> getBills({
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'bills',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'next_due_date ASC, name ASC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Bill.fromMap(map)).toList();
  }

  Future<List<Bill>> getActiveBills() async {
    return getBills();
  }

  Future<List<Bill>> getBillsDueSoon(int days) async {
    final db = await database;
    final cutoff = DateTime.now().add(Duration(days: days));
    final maps = await db.query(
      'bills',
      where: 'is_active = 1 AND next_due_date <= ?',
      whereArgs: [cutoff.toIso8601String()],
      orderBy: 'next_due_date ASC',
    );
    return maps.map((map) => Bill.fromMap(map)).toList();
  }

  Future<Bill?> getBill(int id) async {
    final db = await database;
    final maps = await db.query(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Bill.fromMap(maps.first);
  }

  Future<int> updateBill(Bill bill) async {
    final db = await database;
    final count = await db.update(
      'bills',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
    
    if (count > 0 && bill.id != null) {
      await queueSync(
        tableName: 'bills',
        rowId: bill.id!,
        operation: 'UPDATE',
        data: bill.toMap(),
      );
    }
    
    return count;
  }

  Future<int> deleteBill(int id) async {
    final db = await database;
    final count = await db.delete(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'bills',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }

  /// Calculate total monthly bill expenses
  Future<double> getTotalMonthlyBills() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(
        CASE frequency
          WHEN 'weekly' THEN amount * 4.33
          WHEN 'biweekly' THEN amount * 2.17
          WHEN 'monthly' THEN amount
          WHEN 'quarterly' THEN amount / 3
          WHEN 'yearly' THEN amount / 12
          ELSE amount
        END
      ) as total FROM bills WHERE is_active = 1
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
}
