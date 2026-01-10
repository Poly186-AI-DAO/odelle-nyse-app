import 'package:flutter/material.dart';

/// A scheduled/planned activity on the calendar.
class ScheduledEvent {
  final int? id;
  final int userId;
  final DateTime date;
  final TimeOfDay? scheduledTime;

  // What's scheduled
  final ScheduledEventType type;
  final int? sessionId;
  final int? workoutId;
  final int? habitId;
  final String? customTitle;

  // Recurrence
  final bool isRecurring;
  final RecurrencePattern? pattern;

  // Reminder
  final bool reminderEnabled;
  final int? reminderMinutesBefore;

  // Status
  final bool isCompleted;
  final DateTime? completedAt;

  // Notes
  final String? notes;

  ScheduledEvent({
    this.id,
    required this.userId,
    required this.date,
    this.scheduledTime,
    required this.type,
    this.sessionId,
    this.workoutId,
    this.habitId,
    this.customTitle,
    this.isRecurring = false,
    this.pattern,
    this.reminderEnabled = false,
    this.reminderMinutesBefore,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
  });

  /// Create from database map.
  factory ScheduledEvent.fromMap(Map<String, dynamic> map) {
    return ScheduledEvent(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      date: DateTime.parse(map['date'] as String),
      scheduledTime: _parseTimeOfDay(map['scheduled_time'] as String?),
      type: _parseScheduledEventType(map['event_type'] as String?),
      sessionId: map['session_id'] as int?,
      workoutId: map['workout_id'] as int?,
      habitId: map['habit_id'] as int?,
      customTitle: map['custom_title'] as String?,
      isRecurring: _parseBool(map['is_recurring']),
      pattern: _parseRecurrencePattern(map['recurrence_pattern'] as String?),
      reminderEnabled: _parseBool(map['reminder_enabled']),
      reminderMinutesBefore: map['reminder_minutes_before'] as int?,
      isCompleted: _parseBool(map['is_completed']),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': _formatDateOnly(date),
      'scheduled_time': scheduledTime != null
          ? '${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'event_type': type.name,
      'session_id': sessionId,
      'workout_id': workoutId,
      'habit_id': habitId,
      'custom_title': customTitle,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_pattern': pattern?.name,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_minutes_before': reminderMinutesBefore,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory ScheduledEvent.fromJson(Map<String, dynamic> json) {
    return ScheduledEvent.fromMap(json);
  }

  /// Get display title for this event.
  String get displayTitle {
    if (customTitle != null && customTitle!.isNotEmpty) {
      return customTitle!;
    }
    return type.displayName;
  }

  /// Copy with modifications.
  ScheduledEvent copyWith({
    int? id,
    int? userId,
    DateTime? date,
    TimeOfDay? scheduledTime,
    ScheduledEventType? type,
    int? sessionId,
    int? workoutId,
    int? habitId,
    String? customTitle,
    bool? isRecurring,
    RecurrencePattern? pattern,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    bool? isCompleted,
    DateTime? completedAt,
    String? notes,
  }) {
    return ScheduledEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      type: type ?? this.type,
      sessionId: sessionId ?? this.sessionId,
      workoutId: workoutId ?? this.workoutId,
      habitId: habitId ?? this.habitId,
      customTitle: customTitle ?? this.customTitle,
      isRecurring: isRecurring ?? this.isRecurring,
      pattern: pattern ?? this.pattern,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'ScheduledEvent(id: $id, type: ${type.name}, date: ${_formatDateOnly(date)})';
  }
}

enum ScheduledEventType {
  meditationSession,
  workout,
  dose,
  habit,
  custom;

  String get displayName {
    switch (this) {
      case meditationSession:
        return 'Meditation Session';
      case workout:
        return 'Workout';
      case dose:
        return 'Supplement Dose';
      case habit:
        return 'Habit';
      case custom:
        return 'Custom Event';
    }
  }
}

enum RecurrencePattern {
  daily,
  weekdays,
  weekends,
  weekly,
  biweekly,
  monthly;

  String get displayName {
    switch (this) {
      case daily:
        return 'Daily';
      case weekdays:
        return 'Weekdays';
      case weekends:
        return 'Weekends';
      case weekly:
        return 'Weekly';
      case biweekly:
        return 'Bi-weekly';
      case monthly:
        return 'Monthly';
    }
  }
}

String _formatDateOnly(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

TimeOfDay? _parseTimeOfDay(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 0,
    minute: int.tryParse(parts[1]) ?? 0,
  );
}

ScheduledEventType _parseScheduledEventType(String? value) {
  if (value == null || value.isEmpty) return ScheduledEventType.custom;
  return ScheduledEventType.values.firstWhere(
    (set) => set.name == value,
    orElse: () => ScheduledEventType.custom,
  );
}

RecurrencePattern? _parseRecurrencePattern(String? value) {
  if (value == null || value.isEmpty) return null;
  return RecurrencePattern.values.firstWhere(
    (rp) => rp.name == value,
    orElse: () => RecurrencePattern.daily,
  );
}

bool _parseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
  }
  return defaultValue;
}
