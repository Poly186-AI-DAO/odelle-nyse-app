import '../database/app_database.dart';
import '../models/tracking/dose_log.dart';
import '../models/tracking/supplement.dart';
import '../utils/logger.dart';

/// Repository for supplements and dose logs.
class DoseRepository {
  static const String _tag = 'DoseRepository';
  final AppDatabase _db;

  DoseRepository(this._db);

  Future<List<Supplement>> getSupplements({bool activeOnly = true}) async {
    return _db.getSupplements(activeOnly: activeOnly);
  }

  Future<Supplement?> getSupplement(int id) async {
    return _db.getSupplement(id);
  }

  Future<int> createSupplement(Supplement supplement) async {
    Logger.info('Creating supplement', tag: _tag);
    return _db.insertSupplement(supplement);
  }

  Future<int> updateSupplement(Supplement supplement) async {
    Logger.info('Updating supplement: ${supplement.id}', tag: _tag);
    return _db.updateSupplement(supplement);
  }

  Future<int> deleteSupplement(int id) async {
    Logger.info('Deleting supplement: $id', tag: _tag);
    return _db.deleteSupplement(id);
  }

  Future<List<DoseLog>> getDoseLogs({
    int? supplementId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    return _db.getDoseLogs(
      supplementId: supplementId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  Future<DoseLog?> getDoseLog(int id) async {
    return _db.getDoseLog(id);
  }

  Future<int> logDose({
    required int supplementId,
    required double amountMg,
    DateTime? timestamp,
    String? unit,
    DoseSource source = DoseSource.manual,
    bool takenWithFood = false,
    bool takenWithFat = false,
    String? mealContext,
    int? journalEntryId,
    double? confidence,
    String? notes,
  }) async {
    Logger.info('Logging dose for supplement: $supplementId', tag: _tag);
    final log = DoseLog(
      supplementId: supplementId,
      timestamp: timestamp ?? DateTime.now(),
      amountMg: amountMg,
      unit: unit,
      source: source,
      takenWithFood: takenWithFood,
      takenWithFat: takenWithFat,
      mealContext: mealContext,
      journalEntryId: journalEntryId,
      confidence: confidence,
      notes: notes,
    );
    return _db.insertDoseLog(log);
  }

  Future<int> updateDoseLog(DoseLog log) async {
    Logger.info('Updating dose log: ${log.id}', tag: _tag);
    return _db.updateDoseLog(log);
  }

  Future<int> deleteDoseLog(int id) async {
    Logger.info('Deleting dose log: $id', tag: _tag);
    return _db.deleteDoseLog(id);
  }
}
