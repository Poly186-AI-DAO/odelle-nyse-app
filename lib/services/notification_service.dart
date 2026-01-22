import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../models/agent_output.dart';
import '../models/smart_reminder.dart';
import '../utils/logger.dart';
import 'live_activity_service.dart';

/// Callback type for notification tap
typedef NotificationTapCallback = void Function(String? payload);

/// Unified notification service for Odelle
///
/// Handles:
/// - Live Activities (Dynamic Island) for agent status
/// - Local notifications for reminders and alerts
/// - Rich notifications with images for surprise content
///
/// Architecture:
/// ```
/// NotificationService
///   ├── LiveActivityService (iOS Dynamic Island)
///   └── FlutterLocalNotificationsPlugin (Local push)
/// ```
class NotificationService {
  static const String _tag = 'NotificationService';

  final LiveActivityService _liveActivityService;
  final FlutterLocalNotificationsPlugin _localNotifications;

  bool _isInitialized = false;
  NotificationTapCallback? _onNotificationTap;

  // Notification channel IDs
  static const String _agentChannelId = 'odelle_agent';
  static const String _reminderChannelId = 'odelle_reminders';
  static const String _surpriseChannelId = 'odelle_surprise';

  NotificationService({
    required LiveActivityService liveActivityService,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _liveActivityService = liveActivityService,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  /// Initialize notification systems
  Future<void> initialize({NotificationTapCallback? onTap}) async {
    if (_isInitialized) return;

    _onNotificationTap = onTap;

    // Initialize timezone data
    tz_data.initializeTimeZones();

    // iOS settings
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'agent_status',
          actions: [
            DarwinNotificationAction.plain('view', 'View'),
          ],
        ),
        DarwinNotificationCategory(
          'reminder',
          actions: [
            DarwinNotificationAction.plain('done', 'Done'),
            DarwinNotificationAction.plain('snooze', 'Snooze'),
          ],
        ),
      ],
    );

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize plugin
    final InitializationSettings settings = InitializationSettings(
      iOS: iosSettings,
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createAndroidChannels();
    }

    _isInitialized = true;
    Logger.info('NotificationService initialized', tag: _tag);
  }

  /// Create Android notification channels
  Future<void> _createAndroidChannels() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Agent status channel (silent, for background updates)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _agentChannelId,
        'Agent Activity',
        description: 'Updates when AI agents are processing',
        importance: Importance.low,
        enableVibration: false,
        playSound: false,
      ),
    );

    // Reminder channel (normal priority)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        'Reminders',
        description: 'Smart reminders and scheduled notifications',
        importance: Importance.high,
        enableVibration: true,
      ),
    );

    // Surprise content channel (high visibility)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _surpriseChannelId,
        'Surprise Content',
        description: 'AI-generated insights and images',
        importance: Importance.high,
        enableVibration: true,
      ),
    );
  }

  /// Handle notification tap response
  void _handleNotificationResponse(NotificationResponse response) {
    Logger.debug('Notification tapped: ${response.payload}', tag: _tag);

    if (response.actionId == 'snooze') {
      // Handle snooze action - could emit an event or call a callback
      Logger.info('Reminder snoozed: ${response.payload}', tag: _tag);
    } else if (response.actionId == 'done') {
      Logger.info('Reminder marked done: ${response.payload}', tag: _tag);
    }

    _onNotificationTap?.call(response.payload);
  }

  // ===========================================================================
  // LIVE ACTIVITY (Dynamic Island) - Agent Status
  // ===========================================================================

  /// Show agent working status on Dynamic Island (iOS)
  Future<void> showAgentWorking({
    required AgentType agentType,
    required String message,
  }) async {
    // Use Live Activity on iOS for real-time updates
    if (Platform.isIOS) {
      await _liveActivityService.startAgentActivity(
        agentType: agentType,
        message: message,
      );
    }

    Logger.debug('Agent working: ${agentType.displayName} - $message',
        tag: _tag);
  }

  /// Update agent status
  Future<void> updateAgentStatus({
    required AgentType agentType,
    required String message,
    bool isError = false,
    bool isComplete = false,
  }) async {
    if (Platform.isIOS) {
      await _liveActivityService.updateActivity(
        agentType: agentType,
        message: message,
        isError: isError,
        isComplete: isComplete,
      );
    }

    Logger.debug('Agent status: ${agentType.displayName} - $message',
        tag: _tag);
  }

  /// Hide agent status (end Live Activity)
  Future<void> hideAgentStatus() async {
    if (Platform.isIOS) {
      await _liveActivityService.endActivity();
    }
  }

  /// Show agent completion notification (when app is backgrounded)
  Future<void> showAgentComplete({
    required AgentType agentType,
    required String summary,
  }) async {
    await _showLocalNotification(
      id: _generateNotificationId('agent_complete'),
      title: '${agentType.emoji} ${agentType.displayName} Complete',
      body: summary,
      channelId: _agentChannelId,
      payload: 'agent_complete:${agentType.name}',
    );
  }

  // ===========================================================================
  // SCHEDULED REMINDERS
  // ===========================================================================

  /// Schedule a reminder notification
  Future<void> scheduleReminder(SmartReminder reminder) async {
    if (reminder.scheduledTime == null) {
      Logger.warning('Cannot schedule reminder without time', tag: _tag);
      return;
    }

    final notificationId =
        reminder.id ?? _generateNotificationId(reminder.title);

    // Convert to timezone-aware datetime
    final scheduledDate = tz.TZDateTime.from(
      reminder.scheduledTime!,
      tz.local,
    );

    // Don't schedule if in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      Logger.warning('Reminder time is in the past: ${reminder.title}',
          tag: _tag);
      return;
    }

    final matchDateTimeComponents =
        _getDateTimeComponents(reminder.repeatPattern);

    await _localNotifications.zonedSchedule(
      notificationId,
      reminder.title,
      reminder.message,
      scheduledDate,
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'reminder',
          threadIdentifier: 'reminders',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          _reminderChannelId,
          'Reminders',
          channelDescription: 'Smart reminders',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: 'reminder:${reminder.id ?? reminder.title}',
    );

    Logger.info('Scheduled reminder: ${reminder.title} at $scheduledDate',
        tag: _tag);
  }

  /// Get date time matching components for repeat pattern
  DateTimeComponents? _getDateTimeComponents(RepeatPattern pattern) {
    switch (pattern) {
      case RepeatPattern.daily:
        return DateTimeComponents.time;
      case RepeatPattern.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatPattern.weekdays:
      case RepeatPattern.weekends:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatPattern.none:
      case RepeatPattern.custom:
        return null;
    }
  }

  /// Cancel a scheduled reminder
  Future<void> cancelReminder(int id) async {
    await _localNotifications.cancel(id);
    Logger.debug('Cancelled reminder: $id', tag: _tag);
  }

  /// Cancel all scheduled reminders
  Future<void> cancelAllReminders() async {
    await _localNotifications.cancelAll();
    Logger.info('Cancelled all reminders', tag: _tag);
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // ===========================================================================
  // PROACTIVE/SURPRISE CONTENT
  // ===========================================================================

  /// Show a surprise insight notification
  Future<void> showInsight({
    required String title,
    required String insight,
    String? payload,
  }) async {
    await _showLocalNotification(
      id: _generateNotificationId('insight'),
      title: '✨ $title',
      body: insight,
      channelId: _surpriseChannelId,
      payload: payload ?? 'insight',
    );
  }

  /// Show a notification with an attached image
  Future<void> showSurpriseImage({
    required String title,
    required String body,
    required String imagePath,
  }) async {
    final BigPictureStyleInformation? bigPictureStyle = Platform.isAndroid
        ? BigPictureStyleInformation(
            FilePathAndroidBitmap(imagePath),
            contentTitle: title,
            summaryText: body,
            hideExpandedLargeIcon: true,
          )
        : null;

    await _localNotifications.show(
      _generateNotificationId('surprise'),
      '🎁 $title',
      body,
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'surprise',
          threadIdentifier: 'surprises',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          attachments: [
            DarwinNotificationAttachment(imagePath),
          ],
        ),
        android: AndroidNotificationDetails(
          _surpriseChannelId,
          'Surprise Content',
          channelDescription: 'AI-generated content',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: bigPictureStyle,
          largeIcon: FilePathAndroidBitmap(imagePath),
        ),
      ),
      payload: 'surprise:$imagePath',
    );

    Logger.info('Showed surprise image notification: $title', tag: _tag);
  }

  /// Show a celebration notification (streak milestones, achievements)
  Future<void> showCelebration({
    required String title,
    required String message,
    String emoji = '🎉',
  }) async {
    await _showLocalNotification(
      id: _generateNotificationId('celebration'),
      title: '$emoji $title',
      body: message,
      channelId: _surpriseChannelId,
      payload: 'celebration',
    );
  }

  // ===========================================================================
  // INTERNAL HELPERS
  // ===========================================================================

  /// Show a local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          channelId,
          channelId == _agentChannelId
              ? 'Agent Activity'
              : channelId == _reminderChannelId
                  ? 'Reminders'
                  : 'Surprise Content',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }

  /// Generate a unique notification ID from a string
  int _generateNotificationId(String seed) {
    // Use hash code but ensure it's positive and within int32 range
    return seed.hashCode.abs() % 2147483647;
  }

  /// Request notification permissions (call early in app lifecycle)
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final result = await androidPlugin?.requestNotificationsPermission();
      return result ?? false;
    }
    return false;
  }

  /// Check if Live Activities are supported
  Future<bool> isLiveActivitySupported() async {
    if (!Platform.isIOS) return false;
    return await _liveActivityService.isSupported();
  }

  bool get isInitialized => _isInitialized;
}
