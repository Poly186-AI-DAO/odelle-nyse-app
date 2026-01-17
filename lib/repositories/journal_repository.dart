import '../database/app_database.dart';
import '../models/journal_entry.dart';
import '../utils/logger.dart';

/// Repository for journal entries.
class JournalRepository {
  static const String _tag = 'JournalRepository';
  final AppDatabase _db;

  JournalRepository(this._db);

  Future<List<JournalEntry>> getJournalEntries({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    return _db.getJournalEntries(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  Future<JournalEntry?> getJournalEntry(int id) async {
    return _db.getJournalEntry(id);
  }

  Future<int> createJournalEntry(JournalEntry entry) async {
    Logger.info('Creating journal entry', tag: _tag);
    return _db.insertJournalEntry(entry);
  }

  Future<int> updateJournalEntry(JournalEntry entry) async {
    Logger.info('Updating journal entry: ${entry.id}', tag: _tag);
    return _db.updateJournalEntry(entry);
  }

  Future<int> deleteJournalEntry(int id) async {
    Logger.info('Deleting journal entry: $id', tag: _tag);
    return _db.deleteJournalEntry(id);
  }
}
