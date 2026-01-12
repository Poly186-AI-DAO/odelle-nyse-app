import '../database/app_database.dart';
import '../models/tracking/meal_log.dart';
import '../utils/logger.dart';

/// Repository for meal logs.
class MealRepository {
  static const String _tag = 'MealRepository';
  final AppDatabase _db;

  MealRepository(this._db);

  Future<List<MealLog>> getMeals({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    return _db.getMealLogs(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  Future<MealLog?> getMeal(int id) async {
    return _db.getMealLog(id);
  }

  Future<int> logMeal(MealLog meal) async {
    Logger.info('Logging meal: ${meal.type}', tag: _tag);
    // If we were accepting raw params like logDose, we'd construct MealLog here.
    // For now assuming MealLog is passed fully constructed or we can overload if needed.
    return _db.insertMealLog(meal);
  }

  Future<int> updateMeal(MealLog meal) async {
    Logger.info('Updating meal: ${meal.id}', tag: _tag);
    return _db.updateMealLog(meal);
  }

  Future<int> deleteMeal(int id) async {
    Logger.info('Deleting meal: $id', tag: _tag);
    return _db.deleteMealLog(id);
  }
}
