part of 'app_database.dart';

mixin IncomeCrud on AppDatabaseBase {
  // ===================
  // Income CRUD (Wealth Pillar)
  // ===================

  Future<int> insertIncome(Income income) async {
    final db = await database;
    final id = await db.insert('incomes', income.toMap());
    Logger.info('Inserted income: $id', tag: AppDatabase._tag);
    return id;
  }

  Future<List<Income>> getIncomes({
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'incomes',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'amount DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Income.fromMap(map)).toList();
  }

  Future<List<Income>> getActiveIncomes() async {
    return getIncomes();
  }

  Future<List<Income>> getRecurringIncomes() async {
    final db = await database;
    final maps = await db.query(
      'incomes',
      where: 'is_active = 1 AND is_recurring = 1',
      orderBy: 'amount DESC',
    );
    return maps.map((map) => Income.fromMap(map)).toList();
  }

  Future<Income?> getIncome(int id) async {
    final db = await database;
    final maps = await db.query(
      'incomes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Income.fromMap(maps.first);
  }

  Future<int> updateIncome(Income income) async {
    final db = await database;
    return await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return await db.delete(
      'incomes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Calculate total monthly income
  Future<double> getTotalMonthlyIncome() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(
        CASE frequency
          WHEN 'weekly' THEN amount * 4.33
          WHEN 'biweekly' THEN amount * 2.17
          WHEN 'monthly' THEN amount
          WHEN 'quarterly' THEN amount / 3
          WHEN 'yearly' THEN amount / 12
          WHEN 'oneTime' THEN 0
          ELSE amount
        END
      ) as total FROM incomes WHERE is_active = 1 AND is_recurring = 1
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
}
