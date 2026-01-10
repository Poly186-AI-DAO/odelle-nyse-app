import 'dart:convert';

import 'supplement.dart';

/// A scheduled/recurring dose for reminders.
class DoseSchedule {
  final int? id;
  final int supplementId;
  final double amountMg;
  final List<DoseTime> times;
  final List<int> daysOfWeek; // 1-7, empty = every day
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate; // For cycles
  final bool reminderEnabled;
  final DateTime createdAt;

  // Derived
  final Supplement? supplement;

  DoseSchedule({
    this.id,
    required this.supplementId,
    required this.amountMg,
    required this.times,
    List<int>? daysOfWeek,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.reminderEnabled = true,
    DateTime? createdAt,
    this.supplement,
  })  : daysOfWeek = daysOfWeek ?? const [],
        createdAt = createdAt ?? DateTime.now();

  /// Create from database map.
  factory DoseSchedule.fromMap(Map<String, dynamic> map) {
    return DoseSchedule(
      id: map['id'] as int?,
      supplementId: (map['supplement_id'] as int?) ?? 0,
      amountMg: (map['amount_mg'] as num?)?.toDouble() ?? 0,
      times: _parseDoseTimes(map['times']),
      daysOfWeek: _parseIntList(map['days_of_week']),
      isActive: _parseBool(map['is_active'], defaultValue: true),
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      reminderEnabled: _parseBool(map['reminder_enabled'], defaultValue: true),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'supplement_id': supplementId,
      'amount_mg': amountMg,
      'times': _encodeEnumList(times),
      'days_of_week': daysOfWeek.isNotEmpty ? jsonEncode(daysOfWeek) : null,
      'is_active': isActive ? 1 : 0,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory DoseSchedule.fromJson(Map<String, dynamic> json) {
    return DoseSchedule.fromMap(json);
  }

  /// Check if this schedule applies to a specific day of week (1-7, Monday = 1).
  bool appliesTo(int dayOfWeek) {
    if (daysOfWeek.isEmpty) return true;
    return daysOfWeek.contains(dayOfWeek);
  }

  /// Copy with modifications.
  DoseSchedule copyWith({
    int? id,
    int? supplementId,
    double? amountMg,
    List<DoseTime>? times,
    List<int>? daysOfWeek,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    bool? reminderEnabled,
    DateTime? createdAt,
    Supplement? supplement,
  }) {
    return DoseSchedule(
      id: id ?? this.id,
      supplementId: supplementId ?? this.supplementId,
      amountMg: amountMg ?? this.amountMg,
      times: times ?? this.times,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      supplement: supplement ?? this.supplement,
    );
  }

  @override
  String toString() {
    return 'DoseSchedule(id: $id, supplementId: $supplementId, times: ${times.map((t) => t.name).join(", ")})';
  }
}

List<DoseTime> _parseDoseTimes(dynamic value) {
  final items = _parseStringList(value);
  if (items == null) return <DoseTime>[];
  return items
      .map(
        (item) => DoseTime.values.firstWhere(
          (time) => time.name == item,
          orElse: () => DoseTime.asNeeded,
        ),
      )
      .toList();
}

List<int> _parseIntList(dynamic value) {
  if (value == null) return <int>[];
  if (value is String) {
    if (value.isEmpty) return <int>[];
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return decoded.map((item) => item as int).toList();
    }
  }
  if (value is List) {
    return value.map((item) => item as int).toList();
  }
  return <int>[];
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

List<String>? _parseStringList(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    if (value.isEmpty) return <String>[];
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return decoded.map((item) => item.toString()).toList();
    }
  }
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return null;
}

String? _encodeEnumList(List<DoseTime> values) {
  if (values.isEmpty) return jsonEncode(<String>[]);
  return jsonEncode(values.map((value) => value.name).toList());
}
