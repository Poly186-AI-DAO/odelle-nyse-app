part of 'app_database.dart';

mixin SyncQueueCrud on AppDatabaseBase {
  // =================
  // Sync Queue CRUD
  // =================

  /// Queue a change for Firebase sync
  @override
  Future<void> queueSync({
    required String tableName,
    required int rowId,
    required String operation, // INSERT, UPDATE, DELETE
    Map<String, dynamic>? data,
  }) async {
    final db = await database;
    try {
      await db.insert('sync_queue', {
        'table_name': tableName,
        'row_id': rowId,
        'operation': operation,
        'data': data != null ? jsonEncode(data) : null,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
        'attempts': 0,
      });
      Logger.debug('Queued $operation for $tableName:$rowId',
          tag: AppDatabase._tag);
    } catch (e) {
      Logger.error('Failed to queue sync for $tableName:$rowId: $e',
          tag: AppDatabase._tag);
    }
  }
}
