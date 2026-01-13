part of 'app_database.dart';

mixin InteractionCrud on AppDatabaseBase {
  // ===================
  // Interactions CRUD (Bonds Pillar)
  // ===================

  Future<int> insertInteraction(Interaction interaction) async {
    final db = await database;
    final id = await db.insert('interactions', interaction.toMap());

    // Update the contact's last_contact timestamp
    await db.update(
      'contacts',
      {'last_contact': interaction.timestamp.toIso8601String()},
      where: 'id = ?',
      whereArgs: [interaction.contactId],
    );

    Logger.info('Inserted interaction: $id', tag: AppDatabase._tag);
    return id;
  }

  Future<List<Interaction>> getInteractions({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'interactions',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Interaction.fromMap(map)).toList();
  }

  Future<List<Interaction>> getInteractionsForContact(int contactId,
      {int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'interactions',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => Interaction.fromMap(map)).toList();
  }

  Future<List<Interaction>> getRecentInteractions(int days) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final maps = await db.query(
      'interactions',
      where: 'timestamp >= ?',
      whereArgs: [cutoff.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => Interaction.fromMap(map)).toList();
  }

  Future<Interaction?> getInteraction(int id) async {
    final db = await database;
    final maps = await db.query(
      'interactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Interaction.fromMap(maps.first);
  }

  Future<int> updateInteraction(Interaction interaction) async {
    final db = await database;
    return await db.update(
      'interactions',
      interaction.toMap(),
      where: 'id = ?',
      whereArgs: [interaction.id],
    );
  }

  Future<int> deleteInteraction(int id) async {
    final db = await database;
    return await db.delete(
      'interactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get interaction count for a contact
  Future<int> getInteractionCount(int contactId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM interactions WHERE contact_id = ?',
      [contactId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get average interaction quality for a contact
  Future<double> getAverageQuality(int contactId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(quality) as avg FROM interactions WHERE contact_id = ?',
      [contactId],
    );
    return (result.first['avg'] as num?)?.toDouble() ?? 0;
  }
}
