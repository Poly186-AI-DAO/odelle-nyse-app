import '../database/app_database.dart';
import '../models/mood/mood_entry.dart';
import '../utils/logger.dart';

/// Repository for mood entries.
class MoodRepository {
  static const String _tag = 'MoodRepository';
  final AppDatabase _db;

  MoodRepository(this._db);

  Future<List<MoodEntry>> getMoodEntries({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _db.getMoodEntries(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<MoodEntry?> getMoodEntry(int id) async {
    return _db.getMoodEntry(id);
  }

  Future<int> logMood(MoodEntry entry) async {
    Logger.info('Logging mood entry', tag: _tag);
    return _db.insertMoodEntry(entry);
  }

  Future<int> updateMood(MoodEntry entry) async {
    Logger.info('Updating mood entry: ${entry.id}', tag: _tag);
    return _db.updateMoodEntry(entry);
  }

  Future<int> deleteMood(int id) async {
    Logger.info('Deleting mood entry: $id', tag: _tag);
    return _db.deleteMoodEntry(id);
  }
}
