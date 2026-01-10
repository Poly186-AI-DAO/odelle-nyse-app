import '../database/app_database.dart';
import '../models/user/user_profile.dart';
import '../utils/logger.dart';

/// Repository for user profile data.
class UserProfileRepository {
  static const String _tag = 'UserProfileRepository';
  final AppDatabase _db;

  UserProfileRepository(this._db);

  Future<UserProfile?> getProfile(int id) async {
    return _db.getUserProfile(id);
  }

  Future<List<UserProfile>> getProfiles({int limit = 50, int offset = 0}) async {
    return _db.getUserProfiles(limit: limit, offset: offset);
  }

  Future<int> createProfile(UserProfile profile) async {
    Logger.info('Creating user profile', tag: _tag);
    return _db.insertUserProfile(profile);
  }

  Future<int> updateProfile(UserProfile profile) async {
    Logger.info('Updating user profile', tag: _tag);
    return _db.updateUserProfile(profile);
  }

  Future<int> saveProfile(UserProfile profile) async {
    if (profile.id == null) {
      return createProfile(profile);
    }
    return updateProfile(profile);
  }

  Future<int> deleteProfile(int id) async {
    Logger.info('Deleting user profile: $id', tag: _tag);
    return _db.deleteUserProfile(id);
  }
}
