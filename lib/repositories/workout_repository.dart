import '../database/app_database.dart';
import '../models/tracking/workout_log.dart';
import '../utils/logger.dart';

/// Repository for workout logs.
class WorkoutRepository {
  static const String _tag = 'WorkoutRepository';
  final AppDatabase _db;

  WorkoutRepository(this._db);

  Future<List<WorkoutLog>> getWorkouts({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    return _db.getWorkoutLogs(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  Future<WorkoutLog?> getWorkout(int id) async {
    return _db.getWorkoutLog(id);
  }

  Future<int> logWorkout(WorkoutLog workout) async {
    Logger.info('Logging workout: ${workout.type}', tag: _tag);
    return _db.insertWorkoutLog(workout);
  }

  Future<int> updateWorkout(WorkoutLog workout) async {
    Logger.info('Updating workout: ${workout.id}', tag: _tag);
    return _db.updateWorkoutLog(workout);
  }

  Future<int> deleteWorkout(int id) async {
    Logger.info('Deleting workout: $id', tag: _tag);
    return _db.deleteWorkoutLog(id);
  }
}
