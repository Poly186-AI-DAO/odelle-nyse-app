import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Offline-first sync service for Firebase
/// Monitors the local sync_queue and pushes changes to Firestore when online.
class SyncService {
  static const String _tag = 'SyncService';
  
  final AppDatabase _database;
  final FirebaseFirestore _firestore;
  
  bool _isSyncing = false;
  
  SyncService({
    AppDatabase? database,
    FirebaseFirestore? firestore,
  })  : _database = database ?? AppDatabase.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Queue a local change for sync
  Future<void> queueChange({
    required String tableName,
    required int rowId,
    required String operation,
    Map<String, dynamic>? data,
  }) async {
    final db = await _database.database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'row_id': rowId,
      'operation': operation,
      'data': data != null ? jsonEncode(data) : null,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
      'attempts': 0,
    });
    Logger.debug('Queued $operation for $tableName:$rowId', tag: _tag);
  }

  /// Process all pending sync items
  Future<void> syncPendingChanges() async {
    if (_isSyncing) {
      Logger.debug('Sync already in progress, skipping', tag: _tag);
      return;
    }
    
    _isSyncing = true;
    Logger.info('Starting sync of pending changes', tag: _tag);
    
    try {
      final db = await _database.database;
      final pending = await db.query(
        'sync_queue',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
        limit: 50,
      );
      
      if (pending.isEmpty) {
        Logger.debug('No pending changes to sync', tag: _tag);
        return;
      }
      
      Logger.info('Found ${pending.length} pending changes', tag: _tag);
      
      for (final item in pending) {
        await _syncItem(item);
      }
      
      Logger.info('Sync completed', tag: _tag);
    } catch (e) {
      Logger.error('Sync failed: $e', tag: _tag);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncItem(Map<String, dynamic> item) async {
    final id = item['id'] as int;
    final tableName = item['table_name'] as String;
    final rowId = item['row_id'] as int;
    final operation = item['operation'] as String;
    final dataJson = item['data'] as String?;
    final attempts = (item['attempts'] as int?) ?? 0;
    
    try {
      final docRef = _firestore
          .collection(tableName)
          .doc(rowId.toString());
      
      switch (operation) {
        case 'INSERT':
        case 'UPDATE':
          if (dataJson != null) {
            final data = jsonDecode(dataJson) as Map<String, dynamic>;
            data['lastSyncedAt'] = FieldValue.serverTimestamp();
            await docRef.set(data, SetOptions(merge: true));
          }
          break;
        case 'DELETE':
          await docRef.delete();
          break;
      }
      
      // Mark as synced
      final db = await _database.database;
      await db.update(
        'sync_queue',
        {
          'status': 'synced',
          'synced_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.debug('Synced $operation for $tableName:$rowId', tag: _tag);
    } catch (e) {
      Logger.warning('Failed to sync $tableName:$rowId: $e', tag: _tag);
      
      // Update attempts and mark as failed if max attempts reached
      final db = await _database.database;
      final newAttempts = attempts + 1;
      await db.update(
        'sync_queue',
        {
          'attempts': newAttempts,
          'error': e.toString(),
          'status': newAttempts >= 3 ? 'failed' : 'pending',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Get count of pending sync items
  Future<int> getPendingCount() async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE status = ?',
      ['pending'],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Clear all synced items from the queue
  Future<void> clearSyncedItems() async {
    final db = await _database.database;
    await db.delete(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['synced'],
    );
    Logger.debug('Cleared synced items from queue', tag: _tag);
  }
}
