import '../database/app_database.dart';
import '../models/gamification/streak.dart';
import '../utils/logger.dart';

/// Repository for streaks.
class StreakRepository {
  static const String _tag = 'StreakRepository';
  final AppDatabase _db;

  StreakRepository(this._db);

  Future<List<Streak>> getStreaks({
    int? userId,
    StreakType? type,
  }) async {
    return _db.getStreaks(userId: userId, type: type);
  }

  Future<Streak?> getStreak(int id) async {
    return _db.getStreak(id);
  }

  Future<int> createStreak(Streak streak) async {
    Logger.info('Creating streak', tag: _tag);
    return _db.insertStreak(streak);
  }

  Future<int> updateStreak(Streak streak) async {
    Logger.info('Updating streak: ${streak.id}', tag: _tag);
    return _db.updateStreak(streak);
  }

  Future<int> saveStreak(Streak streak) async {
    if (streak.id == null) {
      return createStreak(streak);
    }
    return updateStreak(streak);
  }

  Future<int> deleteStreak(int id) async {
    Logger.info('Deleting streak: $id', tag: _tag);
    return _db.deleteStreak(id);
  }
}
