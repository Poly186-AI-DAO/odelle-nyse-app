import 'dart:async';

import '../database/app_database.dart';
import '../models/smart_reminder.dart';
import '../utils/logger.dart';
import 'notification_service.dart';

/// Service to manage smart reminders
///
/// Handles:
/// - CRUD operations for reminders in the database
/// - Syncing reminders with OS notification scheduler
/// - AI-generated reminder suggestions
///
/// Flow:
/// ```
/// SmartReminderService
///   ├── AppDatabase (persistence)
///   └── NotificationService (OS scheduling)
/// ```
class SmartReminderService {
  static const String _tag = 'SmartReminderService';

  final AppDatabase _database;
  final NotificationService _notificationService;

  SmartReminderService({
    required AppDatabase database,
    required NotificationService notificationService,
  })  : _database = database,
        _notificationService = notificationService;

  // ===========================================================================
  // SYNC WITH OS
  // ===========================================================================

  /// Sync all enabled reminders with the OS notification scheduler
  /// Call this at app startup and after any reminder changes
  Future<void> syncWithOS() async {
    Logger.info('Syncing reminders with OS...', tag: _tag);

    try {
      // Cancel all existing scheduled notifications first
      await _notificationService.cancelAllReminders();

      // Get all enabled reminders from database
      final reminders = await getEnabledReminders();

      int scheduled = 0;
      for (final reminder in reminders) {
        if (reminder.scheduledTime != null && !reminder.isSnoozed) {
          await _notificationService.scheduleReminder(reminder);
          scheduled++;
        }
      }

      Logger.info('Synced $scheduled reminders with OS', tag: _tag);
    } catch (e) {
      Logger.error('Failed to sync reminders with OS', tag: _tag, error: e);
    }
  }

  // ===========================================================================
  // CRUD OPERATIONS
  // ===========================================================================

  /// Create a new reminder
  Future<int> createReminder(SmartReminder reminder) async {
    final db = await _database.database;

    final id = await db.insert('smart_reminders', reminder.toMap());
    Logger.info('Created reminder: ${reminder.title} (id: $id)', tag: _tag);

    // Schedule with OS if enabled
    if (reminder.isEnabled && reminder.scheduledTime != null) {
      await _notificationService.scheduleReminder(reminder.copyWith(id: id));
    }

    return id;
  }

  /// Update an existing reminder
  Future<void> updateReminder(SmartReminder reminder) async {
    if (reminder.id == null) {
      throw ArgumentError('Cannot update reminder without id');
    }

    final db = await _database.database;

    await db.update(
      'smart_reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );

    Logger.info('Updated reminder: ${reminder.title}', tag: _tag);

    // Re-schedule with OS
    await _notificationService.cancelReminder(reminder.id!);
    if (reminder.isEnabled &&
        reminder.scheduledTime != null &&
        !reminder.isSnoozed) {
      await _notificationService.scheduleReminder(reminder);
    }
  }

  /// Delete a reminder
  Future<void> deleteReminder(int id) async {
    final db = await _database.database;

    await db.delete(
      'smart_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Cancel from OS
    await _notificationService.cancelReminder(id);

    Logger.info('Deleted reminder: $id', tag: _tag);
  }

  /// Get all reminders
  Future<List<SmartReminder>> getAllReminders() async {
    final db = await _database.database;

    final maps = await db.query(
      'smart_reminders',
      orderBy: 'scheduled_time ASC',
    );

    return maps.map((m) => SmartReminder.fromMap(m)).toList();
  }

  /// Get all enabled reminders
  Future<List<SmartReminder>> getEnabledReminders() async {
    final db = await _database.database;

    final maps = await db.query(
      'smart_reminders',
      where: 'is_enabled = ?',
      whereArgs: [1],
      orderBy: 'scheduled_time ASC',
    );

    return maps.map((m) => SmartReminder.fromMap(m)).toList();
  }

  /// Get reminders by type
  Future<List<SmartReminder>> getRemindersByType(ReminderType type) async {
    final db = await _database.database;

    final maps = await db.query(
      'smart_reminders',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'scheduled_time ASC',
    );

    return maps.map((m) => SmartReminder.fromMap(m)).toList();
  }

  /// Get a single reminder by ID
  Future<SmartReminder?> getReminderById(int id) async {
    final db = await _database.database;

    final maps = await db.query(
      'smart_reminders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return SmartReminder.fromMap(maps.first);
  }

  // ===========================================================================
  // SMART FEATURES
  // ===========================================================================

  /// Toggle reminder enabled state
  Future<void> toggleReminder(int id, bool enabled) async {
    final reminder = await getReminderById(id);
    if (reminder == null) return;

    await updateReminder(reminder.copyWith(isEnabled: enabled));
  }

  /// Snooze a reminder for a duration
  Future<void> snoozeReminder(int id, Duration duration) async {
    final reminder = await getReminderById(id);
    if (reminder == null) return;

    final snoozeUntil = DateTime.now().add(duration);

    await updateReminder(reminder.copyWith(
      snoozeUntil: snoozeUntil,
      lastDismissedAt: DateTime.now(),
    ));

    Logger.info('Snoozed reminder $id until $snoozeUntil', tag: _tag);
  }

  /// Mark a reminder as triggered
  Future<void> markTriggered(int id) async {
    final db = await _database.database;

    await db.update(
      'smart_reminders',
      {'last_triggered_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark a reminder as dismissed
  Future<void> markDismissed(int id) async {
    final db = await _database.database;

    await db.update(
      'smart_reminders',
      {'last_dismissed_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===========================================================================
  // QUICK CREATE HELPERS
  // ===========================================================================

  /// Create a water reminder
  Future<int> createWaterReminder({
    required DateTime time,
    RepeatPattern repeat = RepeatPattern.daily,
  }) async {
    return await createReminder(SmartReminder(
      type: ReminderType.water,
      title: '💧 Time to hydrate',
      message: 'Drink a glass of water to stay healthy',
      scheduledTime: time,
      repeatPattern: repeat,
      priority: ReminderPriority.normal,
    ));
  }

  /// Create a meal reminder
  Future<int> createMealReminder({
    required String mealName,
    required DateTime time,
    RepeatPattern repeat = RepeatPattern.daily,
  }) async {
    return await createReminder(SmartReminder(
      type: ReminderType.meal,
      title: '🍽️ $mealName time',
      message: 'Time to eat and fuel your body',
      scheduledTime: time,
      repeatPattern: repeat,
      priority: ReminderPriority.normal,
    ));
  }

  /// Create a supplement reminder
  Future<int> createSupplementReminder({
    required String supplementName,
    required DateTime time,
    RepeatPattern repeat = RepeatPattern.daily,
  }) async {
    return await createReminder(SmartReminder(
      type: ReminderType.supplement,
      title: '💊 Take $supplementName',
      message: 'Time for your supplement',
      scheduledTime: time,
      repeatPattern: repeat,
      priority: ReminderPriority.high,
    ));
  }

  /// Create an AI-generated insight reminder
  Future<int> createInsightReminder({
    required String title,
    required String insight,
    required DateTime time,
  }) async {
    return await createReminder(SmartReminder(
      type: ReminderType.insight,
      title: title,
      message: insight,
      scheduledTime: time,
      repeatPattern: RepeatPattern.none,
      isSmart: true,
      priority: ReminderPriority.normal,
    ));
  }

  /// Create a surprise content reminder
  Future<int> createSurpriseReminder({
    required String title,
    String? message,
    required DateTime time,
    Map<String, dynamic>? contextData,
  }) async {
    return await createReminder(SmartReminder(
      type: ReminderType.surprise,
      title: title,
      message: message,
      scheduledTime: time,
      repeatPattern: RepeatPattern.none,
      isSmart: true,
      priority: ReminderPriority.normal,
      contextData: contextData,
    ));
  }

  // ===========================================================================
  // STATISTICS
  // ===========================================================================

  /// Get count of reminders by type
  Future<Map<ReminderType, int>> getReminderCounts() async {
    final db = await _database.database;

    final result = await db.rawQuery('''
      SELECT type, COUNT(*) as count 
      FROM smart_reminders 
      WHERE is_enabled = 1 
      GROUP BY type
    ''');

    final counts = <ReminderType, int>{};
    for (final row in result) {
      final type = ReminderType.values.firstWhere(
        (t) => t.name == row['type'],
        orElse: () => ReminderType.custom,
      );
      counts[type] = row['count'] as int;
    }

    return counts;
  }

  /// Get upcoming reminders (next 24 hours)
  Future<List<SmartReminder>> getUpcomingReminders() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(hours: 24));

    final db = await _database.database;

    final maps = await db.query(
      'smart_reminders',
      where: 'is_enabled = 1 AND scheduled_time >= ? AND scheduled_time <= ?',
      whereArgs: [now.toIso8601String(), tomorrow.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );

    return maps.map((m) => SmartReminder.fromMap(m)).toList();
  }
}
