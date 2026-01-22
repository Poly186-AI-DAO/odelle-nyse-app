import 'dart:convert';

/// Types of smart reminders the system can generate
enum ReminderType {
  water,
  meal,
  workout,
  supplement,
  habit,
  meditation,
  insight,
  surprise,
  custom,
}

/// Repeat patterns for reminders
enum RepeatPattern {
  none,
  daily,
  weekdays,
  weekends,
  weekly,
  custom,
}

/// Priority levels for reminders
enum ReminderPriority {
  low(0),
  normal(1),
  high(2),
  critical(3);

  final int value;
  const ReminderPriority(this.value);

  static ReminderPriority fromValue(int value) {
    return ReminderPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => ReminderPriority.normal,
    );
  }
}

/// A smart reminder that can be scheduled by the AI or user
class SmartReminder {
  final int? id;
  final ReminderType type;
  final String title;
  final String? message;
  final DateTime? scheduledTime;
  final RepeatPattern repeatPattern;
  final bool isEnabled;
  final bool isSmart;
  final ReminderPriority priority;
  final Map<String, dynamic>? contextData;
  final DateTime? lastTriggeredAt;
  final DateTime? lastDismissedAt;
  final DateTime? snoozeUntil;
  final DateTime createdAt;

  SmartReminder({
    this.id,
    required this.type,
    required this.title,
    this.message,
    this.scheduledTime,
    this.repeatPattern = RepeatPattern.none,
    this.isEnabled = true,
    this.isSmart = true,
    this.priority = ReminderPriority.normal,
    this.contextData,
    this.lastTriggeredAt,
    this.lastDismissedAt,
    this.snoozeUntil,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from database map
  factory SmartReminder.fromMap(Map<String, dynamic> map) {
    return SmartReminder(
      id: map['id'] as int?,
      type: _parseReminderType(map['type'] as String?),
      title: (map['title'] as String?) ?? '',
      message: map['message'] as String?,
      scheduledTime: _parseDateTime(map['scheduled_time'] as String?),
      repeatPattern: _parseRepeatPattern(map['repeat_pattern'] as String?),
      isEnabled: (map['is_enabled'] as int?) == 1,
      isSmart: (map['is_smart'] as int?) == 1,
      priority: ReminderPriority.fromValue((map['priority'] as int?) ?? 1),
      contextData: _parseJson(map['context_data'] as String?),
      lastTriggeredAt: _parseDateTime(map['last_triggered_at'] as String?),
      lastDismissedAt: _parseDateTime(map['last_dismissed_at'] as String?),
      snoozeUntil: _parseDateTime(map['snooze_until'] as String?),
      createdAt: _parseDateTime(map['created_at'] as String?) ?? DateTime.now(),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'repeat_pattern': repeatPattern.name,
      'is_enabled': isEnabled ? 1 : 0,
      'is_smart': isSmart ? 1 : 0,
      'priority': priority.value,
      'context_data': contextData != null ? jsonEncode(contextData) : null,
      'last_triggered_at': lastTriggeredAt?.toIso8601String(),
      'last_dismissed_at': lastDismissedAt?.toIso8601String(),
      'snooze_until': snoozeUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  SmartReminder copyWith({
    int? id,
    ReminderType? type,
    String? title,
    String? message,
    DateTime? scheduledTime,
    RepeatPattern? repeatPattern,
    bool? isEnabled,
    bool? isSmart,
    ReminderPriority? priority,
    Map<String, dynamic>? contextData,
    DateTime? lastTriggeredAt,
    DateTime? lastDismissedAt,
    DateTime? snoozeUntil,
    DateTime? createdAt,
  }) {
    return SmartReminder(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeatPattern: repeatPattern ?? this.repeatPattern,
      isEnabled: isEnabled ?? this.isEnabled,
      isSmart: isSmart ?? this.isSmart,
      priority: priority ?? this.priority,
      contextData: contextData ?? this.contextData,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      lastDismissedAt: lastDismissedAt ?? this.lastDismissedAt,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if reminder is currently snoozed
  bool get isSnoozed {
    if (snoozeUntil == null) return false;
    return DateTime.now().isBefore(snoozeUntil!);
  }

  /// Check if reminder should trigger now
  bool get shouldTriggerNow {
    if (!isEnabled || isSnoozed) return false;
    if (scheduledTime == null) return false;
    final now = DateTime.now();
    return now.isAfter(scheduledTime!) || now.isAtSameMomentAs(scheduledTime!);
  }

  @override
  String toString() => 'SmartReminder($type: $title @ $scheduledTime)';

  // Parse helpers
  static ReminderType _parseReminderType(String? value) {
    if (value == null) return ReminderType.custom;
    return ReminderType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ReminderType.custom,
    );
  }

  static RepeatPattern _parseRepeatPattern(String? value) {
    if (value == null) return RepeatPattern.none;
    return RepeatPattern.values.firstWhere(
      (p) => p.name == value,
      orElse: () => RepeatPattern.none,
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static Map<String, dynamic>? _parseJson(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
