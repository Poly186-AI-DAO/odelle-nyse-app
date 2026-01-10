import 'dart:convert';
import 'package:flutter/material.dart';

/// A habit or recurring task the user wants to track.
class Habit {
  final int? id;
  final int userId;
  final String title;
  final String? description;
  final String? emoji;
  final String colorHex;

  // Category
  final HabitCategory category;
  final String? customCategory;

  // Frequency
  final HabitFrequency frequency;
  final List<int>? daysOfWeek;
  final int? timesPerDay;
  final int? timesPerWeek;

  // Timing
  final TimeOfDay? reminderTime;
  final bool reminderEnabled;
  final TimeOfDay? targetTime;
  final bool isTimeSensitive;

  // Tracking type
  final HabitType type;
  final int? targetCount;
  final int? targetMinutes;

  // Gamification
  final int xpPerCompletion;

  // Metadata
  final DateTime createdAt;
  final bool isActive;
  final bool isArchived;
  final int sortOrder;

  Habit({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    this.emoji,
    this.colorHex = '#FFFFFF',
    required this.category,
    this.customCategory,
    this.frequency = HabitFrequency.daily,
    this.daysOfWeek,
    this.timesPerDay,
    this.timesPerWeek,
    this.reminderTime,
    this.reminderEnabled = false,
    this.targetTime,
    this.isTimeSensitive = false,
    this.type = HabitType.boolean,
    this.targetCount,
    this.targetMinutes,
    this.xpPerCompletion = 10,
    DateTime? createdAt,
    this.isActive = true,
    this.isArchived = false,
    this.sortOrder = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from database map.
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      emoji: map['emoji'] as String?,
      colorHex: (map['color_hex'] as String?) ?? '#FFFFFF',
      category: _parseHabitCategory(map['category'] as String?),
      customCategory: map['custom_category'] as String?,
      frequency: _parseHabitFrequency(map['frequency'] as String?),
      daysOfWeek: _parseIntList(map['days_of_week']),
      timesPerDay: map['times_per_day'] as int?,
      timesPerWeek: map['times_per_week'] as int?,
      reminderTime: _parseTime(map['reminder_time'] as String?),
      reminderEnabled: _parseBool(map['reminder_enabled']),
      targetTime: _parseTime(map['target_time'] as String?),
      isTimeSensitive: _parseBool(map['is_time_sensitive']),
      type: _parseHabitType(map['habit_type'] as String?),
      targetCount: map['target_count'] as int?,
      targetMinutes: map['target_minutes'] as int?,
      xpPerCompletion: (map['xp_per_completion'] as int?) ?? 10,
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: _parseBool(map['is_active'], defaultValue: true),
      isArchived: _parseBool(map['is_archived']),
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'emoji': emoji,
      'color_hex': colorHex,
      'category': category.name,
      'custom_category': customCategory,
      'frequency': frequency.name,
      'days_of_week': _encodeIntList(daysOfWeek),
      'times_per_day': timesPerDay,
      'times_per_week': timesPerWeek,
      'reminder_time': _formatTime(reminderTime),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'target_time': _formatTime(targetTime),
      'is_time_sensitive': isTimeSensitive ? 1 : 0,
      'habit_type': type.name,
      'target_count': targetCount,
      'target_minutes': targetMinutes,
      'xp_per_completion': xpPerCompletion,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit.fromMap(json);
  }

  /// Copy with modifications.
  Habit copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? emoji,
    String? colorHex,
    HabitCategory? category,
    String? customCategory,
    HabitFrequency? frequency,
    List<int>? daysOfWeek,
    int? timesPerDay,
    int? timesPerWeek,
    TimeOfDay? reminderTime,
    bool? reminderEnabled,
    TimeOfDay? targetTime,
    bool? isTimeSensitive,
    HabitType? type,
    int? targetCount,
    int? targetMinutes,
    int? xpPerCompletion,
    DateTime? createdAt,
    bool? isActive,
    bool? isArchived,
    int? sortOrder,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      timesPerWeek: timesPerWeek ?? this.timesPerWeek,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      targetTime: targetTime ?? this.targetTime,
      isTimeSensitive: isTimeSensitive ?? this.isTimeSensitive,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      xpPerCompletion: xpPerCompletion ?? this.xpPerCompletion,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'Habit(id: $id, title: $title, category: ${category.name})';
  }
}

enum HabitCategory {
  morning,
  workload,
  health,
  mindfulness,
  fitness,
  nutrition,
  sleep,
  social,
  learning,
  custom;
}

enum HabitFrequency {
  daily,
  weekdays,
  weekends,
  specificDays,
  timesPerWeek;
}

enum HabitType {
  boolean,
  counter,
  duration;
}

HabitCategory _parseHabitCategory(String? value) {
  if (value == null || value.isEmpty) return HabitCategory.custom;
  return HabitCategory.values.firstWhere(
    (category) => category.name == value,
    orElse: () => HabitCategory.custom,
  );
}

HabitFrequency _parseHabitFrequency(String? value) {
  if (value == null || value.isEmpty) return HabitFrequency.daily;
  return HabitFrequency.values.firstWhere(
    (frequency) => frequency.name == value,
    orElse: () => HabitFrequency.daily,
  );
}

HabitType _parseHabitType(String? value) {
  if (value == null || value.isEmpty) return HabitType.boolean;
  return HabitType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => HabitType.boolean,
  );
}

String? _formatTime(TimeOfDay? time) {
  if (time == null) return null;
  final hours = time.hour.toString().padLeft(2, '0');
  final minutes = time.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}

TimeOfDay? _parseTime(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
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

List<int>? _parseIntList(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    if (value.isEmpty) return <int>[];
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return decoded.map((item) => int.tryParse(item.toString()) ?? 0).toList();
    }
  }
  if (value is List) {
    return value.map((item) => int.tryParse(item.toString()) ?? 0).toList();
  }
  return null;
}

String? _encodeIntList(List<int>? values) {
  if (values == null) return null;
  return jsonEncode(values);
}
