part of 'app_database.dart';

mixin SubscriptionCrud on AppDatabaseBase {
  // ===================
  // Subscriptions CRUD (Wealth Pillar)
  // ===================

  Future<int> insertSubscription(Subscription subscription) async {
    final db = await database;
    final id = await db.insert('subscriptions', subscription.toMap());
    Logger.info('Inserted subscription: $id', tag: AppDatabase._tag);
    
    await queueSync(
      tableName: 'subscriptions',
      rowId: id,
      operation: 'INSERT',
      data: subscription.toMap(),
    );
    
    return id;
  }

  Future<List<Subscription>> getSubscriptions({
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'subscriptions',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Subscription.fromMap(map)).toList();
  }

  Future<List<Subscription>> getActiveSubscriptions() async {
    return getSubscriptions();
  }

  Future<List<Subscription>> getSubscriptionsByCategory(
      SubscriptionCategory category) async {
    final db = await database;
    final maps = await db.query(
      'subscriptions',
      where: 'is_active = 1 AND category = ?',
      whereArgs: [category.name],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Subscription.fromMap(map)).toList();
  }

  Future<Subscription?> getSubscription(int id) async {
    final db = await database;
    final maps = await db.query(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Subscription.fromMap(maps.first);
  }

  Future<int> updateSubscription(Subscription subscription) async {
    final db = await database;
    final count = await db.update(
      'subscriptions',
      subscription.toMap(),
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
    
    if (count > 0 && subscription.id != null) {
      await queueSync(
        tableName: 'subscriptions',
        rowId: subscription.id!,
        operation: 'UPDATE',
        data: subscription.toMap(),
      );
    }
    
    return count;
  }

  Future<int> deleteSubscription(int id) async {
    final db = await database;
    final count = await db.delete(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'subscriptions',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }

  /// Calculate total monthly subscription cost
  Future<double> getTotalMonthlySubscriptions() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(
        CASE frequency
          WHEN 'weekly' THEN amount * 4.33
          WHEN 'monthly' THEN amount
          WHEN 'quarterly' THEN amount / 3
          WHEN 'yearly' THEN amount / 12
          ELSE amount
        END
      ) as total FROM subscriptions WHERE is_active = 1
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
}
