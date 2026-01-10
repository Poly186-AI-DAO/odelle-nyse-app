import '../database/app_database.dart';
import '../models/habits/habit.dart';
import '../models/habits/habit_log.dart';
import '../utils/logger.dart';

/// Repository for habits and habit logs.
class HabitRepository {
  static const String _tag = 'HabitRepository';
  final AppDatabase _db;

  HabitRepository(this._db);

  Future<List<Habit>> getHabits({
    int? userId,
    bool activeOnly = true,
  }) async {
    return _db.getHabits(userId: userId, activeOnly: activeOnly);
  }

  Future<Habit?> getHabit(int id) async {
    return _db.getHabit(id);
  }

  Future<int> createHabit(Habit habit) async {
    Logger.info('Creating habit', tag: _tag);
    return _db.insertHabit(habit);
  }

  Future<int> updateHabit(Habit habit) async {
    Logger.info('Updating habit: ${habit.id}', tag: _tag);
    return _db.updateHabit(habit);
  }

  Future<int> deleteHabit(int id) async {
    Logger.info('Deleting habit: $id', tag: _tag);
    return _db.deleteHabit(id);
  }

  Future<List<HabitLog>> getHabitLogs({
    int? habitId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _db.getHabitLogs(
      habitId: habitId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<HabitLog?> getHabitLog(int id) async {
    return _db.getHabitLog(id);
  }

  Future<int> logHabit({
    required int habitId,
    required DateTime date,
    bool isCompleted = true,
    int? count,
    int? durationMinutes,
    String? notes,
    HabitLogStatus status = HabitLogStatus.completed,
    DateTime? completedAt,
    int? journalEntryId,
  }) async {
    Logger.info('Logging habit completion: $habitId', tag: _tag);
    final log = HabitLog(
      habitId: habitId,
      date: date,
      completedAt: completedAt,
      isCompleted: isCompleted,
      count: count,
      durationMinutes: durationMinutes,
      notes: notes,
      status: status,
      journalEntryId: journalEntryId,
    );
    return _db.insertHabitLog(log);
  }

  Future<int> updateHabitLog(HabitLog log) async {
    Logger.info('Updating habit log: ${log.id}', tag: _tag);
    return _db.updateHabitLog(log);
  }

  Future<int> deleteHabitLog(int id) async {
    Logger.info('Deleting habit log: $id', tag: _tag);
    return _db.deleteHabitLog(id);
  }
}
