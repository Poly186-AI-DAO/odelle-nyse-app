/// Record of completing a habit on a specific day.
class HabitLog {
  final int? id;
  final int habitId;
  final DateTime date;
  final DateTime? completedAt;

  // Completion data
  final bool isCompleted;
  final int? count;
  final int? durationMinutes;

  // Notes
  final String? notes;

  // Status
  final HabitLogStatus status;

  // Context
  final int? journalEntryId;

  HabitLog({
    this.id,
    required this.habitId,
    required this.date,
    this.completedAt,
    this.isCompleted = false,
    this.count,
    this.durationMinutes,
    this.notes,
    this.status = HabitLogStatus.pending,
    this.journalEntryId,
  });

  /// Create from database map.
  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as int?,
      habitId: (map['habit_id'] as int?) ?? 0,
      date: DateTime.parse(map['date'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      isCompleted: _parseBool(map['is_completed']),
      count: map['count'] as int?,
      durationMinutes: map['duration_minutes'] as int?,
      notes: map['notes'] as String?,
      status: _parseHabitLogStatus(map['status'] as String?),
      journalEntryId: map['journal_entry_id'] as int?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String().split('T')[0],
      'completed_at': completedAt?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'count': count,
      'duration_minutes': durationMinutes,
      'notes': notes,
      'status': status.name,
      'journal_entry_id': journalEntryId,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog.fromMap(json);
  }

  /// Copy with modifications.
  HabitLog copyWith({
    int? id,
    int? habitId,
    DateTime? date,
    DateTime? completedAt,
    bool? isCompleted,
    int? count,
    int? durationMinutes,
    String? notes,
    HabitLogStatus? status,
    int? journalEntryId,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      count: count ?? this.count,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      journalEntryId: journalEntryId ?? this.journalEntryId,
    );
  }

  @override
  String toString() {
    return 'HabitLog(id: $id, habitId: $habitId, date: $date)';
  }
}

enum HabitLogStatus {
  pending,
  completed,
  skipped,
  missed;
}

HabitLogStatus _parseHabitLogStatus(String? value) {
  if (value == null || value.isEmpty) return HabitLogStatus.pending;
  return HabitLogStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => HabitLogStatus.pending,
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
