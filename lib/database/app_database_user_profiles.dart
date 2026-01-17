part of 'app_database.dart';

mixin UserProfileCrud on AppDatabaseBase {
  // ===================
  // User Profile CRUD
  // ===================

  Future<int> insertUserProfile(UserProfile profile) async {
    final db = await database;
    final id = await db.insert('user_profiles', profile.toMap());
    Logger.info('Inserted user profile: $id', tag: AppDatabase._tag);
    
    await queueSync(
      tableName: 'user_profiles',
      rowId: id,
      operation: 'INSERT',
      data: profile.toMap(),
    );
    
    return id;
  }

  Future<UserProfile?> getUserProfile(int id) async {
    final db = await database;
    final maps = await db.query(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<List<UserProfile>> getUserProfiles({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'user_profiles',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => UserProfile.fromMap(map)).toList();
  }

  Future<int> updateUserProfile(UserProfile profile) async {
    final db = await database;
    final count = await db.update(
      'user_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
    
    if (count > 0 && profile.id != null) {
      await queueSync(
        tableName: 'user_profiles',
        rowId: profile.id!,
        operation: 'UPDATE',
        data: profile.toMap(),
      );
    }
    
    return count;
  }

  Future<int> deleteUserProfile(int id) async {
    final db = await database;
    final count = await db.delete(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'user_profiles',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }
}
