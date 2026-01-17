part of 'app_database.dart';

mixin ContactCrud on AppDatabaseBase {
  // ===================
  // Contacts CRUD (Bonds Pillar)
  // ===================

  Future<int> insertContact(Contact contact) async {
    final db = await database;
    final id = await db.insert('contacts', contact.toMap());
    Logger.info('Inserted contact: $id', tag: AppDatabase._tag);
    
    await queueSync(
      tableName: 'contacts',
      rowId: id,
      operation: 'INSERT',
      data: contact.toMap(),
    );
    
    return id;
  }

  Future<List<Contact>> getContacts({
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'contacts',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'priority DESC, name ASC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Contact.fromMap(map)).toList();
  }

  Future<List<Contact>> getActiveContacts() async {
    return getContacts();
  }

  Future<List<Contact>> getContactsByRelationship(
      RelationshipType relationship) async {
    final db = await database;
    final maps = await db.query(
      'contacts',
      where: 'is_active = 1 AND relationship = ?',
      whereArgs: [relationship.name],
      orderBy: 'priority DESC, name ASC',
    );
    return maps.map((map) => Contact.fromMap(map)).toList();
  }

  Future<List<Contact>> getOverdueContacts() async {
    final db = await database;
    final now = DateTime.now();
    final maps = await db.rawQuery('''
      SELECT * FROM contacts 
      WHERE is_active = 1 
      AND (
        last_contact IS NULL 
        OR julianday(?) - julianday(last_contact) > contact_frequency_days
      )
      ORDER BY priority DESC, 
        CASE WHEN last_contact IS NULL THEN 0 ELSE 1 END,
        last_contact ASC
    ''', [now.toIso8601String()]);
    return maps.map((map) => Contact.fromMap(map)).toList();
  }

  Future<List<Contact>> getContactsWithUpcomingBirthdays(int days) async {
    final db = await database;
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));

    // Query contacts with birthdays in the next N days (handles year wrapping)
    final maps = await db.rawQuery('''
      SELECT * FROM contacts 
      WHERE is_active = 1 AND birthday IS NOT NULL
      AND (
        (strftime('%m-%d', birthday) >= strftime('%m-%d', ?) 
         AND strftime('%m-%d', birthday) <= strftime('%m-%d', ?))
        OR 
        (strftime('%m-%d', ?) > strftime('%m-%d', ?) 
         AND (strftime('%m-%d', birthday) >= strftime('%m-%d', ?) 
              OR strftime('%m-%d', birthday) <= strftime('%m-%d', ?)))
      )
      ORDER BY strftime('%m-%d', birthday) ASC
    ''', [
      now.toIso8601String(),
      cutoff.toIso8601String(),
      cutoff.toIso8601String(),
      now.toIso8601String(),
      now.toIso8601String(),
      cutoff.toIso8601String(),
    ]);
    return maps.map((map) => Contact.fromMap(map)).toList();
  }

  Future<Contact?> getContact(int id) async {
    final db = await database;
    final maps = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Contact.fromMap(maps.first);
  }

  Future<int> updateContact(Contact contact) async {
    final db = await database;
    final count = await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
    
    if (count > 0 && contact.id != null) {
      await queueSync(
        tableName: 'contacts',
        rowId: contact.id!,
        operation: 'UPDATE',
        data: contact.toMap(),
      );
    }
    
    return count;
  }

  Future<int> updateContactLastContact(int id, DateTime lastContact) async {
    final db = await database;
    final count = await db.update(
      'contacts',
      {'last_contact': lastContact.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'contacts',
        rowId: id,
        operation: 'UPDATE',
        data: {'last_contact': lastContact.toIso8601String()},
      );
    }
    
    return count;
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    final count = await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'contacts',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }
}
