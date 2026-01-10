import 'dart:convert';

/// Daily summary aggregating all tracking for gamification.
class DailyLog {
  final int? id;
  final DateTime date;

  // Counts
  final int dosesLogged;
  final int dosesScheduled;
  final int workoutsCompleted;
  final int mealsLogged;
  final int meditationMinutes;
  final int journalEntries;

  // Macros totals
  final int? totalCalories;
  final int? totalProtein;

  // Sleep (from previous night)
  final int? sleepMinutes;
  final int? sleepQuality;

  // Scores (calculated)
  final double adherenceScore; // 0-100
  final double wellnessScore; // 0-100

  // Mood tracking
  final int? morningMood; // 1-10
  final int? eveningMood; // 1-10
  final double? averageMood;

  // Links to character stats
  final int? characterStatsId;

  // Achievements unlocked today
  final List<String>? achievements;

  final String? notes;

  DailyLog({
    this.id,
    required this.date,
    this.dosesLogged = 0,
    this.dosesScheduled = 0,
    this.workoutsCompleted = 0,
    this.mealsLogged = 0,
    this.meditationMinutes = 0,
    this.journalEntries = 0,
    this.totalCalories,
    this.totalProtein,
    this.sleepMinutes,
    this.sleepQuality,
    this.adherenceScore = 0,
    this.wellnessScore = 0,
    this.morningMood,
    this.eveningMood,
    this.averageMood,
    this.characterStatsId,
    this.achievements,
    this.notes,
  });

  /// Create from database map.
  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      dosesLogged: (map['doses_logged'] as int?) ?? 0,
      dosesScheduled: (map['doses_scheduled'] as int?) ?? 0,
      workoutsCompleted: (map['workouts_completed'] as int?) ?? 0,
      mealsLogged: (map['meals_logged'] as int?) ?? 0,
      meditationMinutes: (map['meditation_minutes'] as int?) ?? 0,
      journalEntries: (map['journal_entries'] as int?) ?? 0,
      totalCalories: map['total_calories'] as int?,
      totalProtein: map['total_protein'] as int?,
      sleepMinutes: map['sleep_minutes'] as int?,
      sleepQuality: map['sleep_quality'] as int?,
      adherenceScore: (map['adherence_score'] as num?)?.toDouble() ?? 0,
      wellnessScore: (map['wellness_score'] as num?)?.toDouble() ?? 0,
      morningMood: map['morning_mood'] as int?,
      eveningMood: map['evening_mood'] as int?,
      averageMood: (map['average_mood'] as num?)?.toDouble(),
      characterStatsId: map['character_stats_id'] as int?,
      achievements: _parseStringList(map['achievements']),
      notes: map['notes'] as String?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': _formatDateOnly(date),
      'doses_logged': dosesLogged,
      'doses_scheduled': dosesScheduled,
      'workouts_completed': workoutsCompleted,
      'meals_logged': mealsLogged,
      'meditation_minutes': meditationMinutes,
      'journal_entries': journalEntries,
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'sleep_minutes': sleepMinutes,
      'sleep_quality': sleepQuality,
      'adherence_score': adherenceScore,
      'wellness_score': wellnessScore,
      'morning_mood': morningMood,
      'evening_mood': eveningMood,
      'average_mood': averageMood,
      'character_stats_id': characterStatsId,
      'achievements': achievements != null ? jsonEncode(achievements) : null,
      'notes': notes,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog.fromMap(json);
  }

  /// Copy with modifications.
  DailyLog copyWith({
    int? id,
    DateTime? date,
    int? dosesLogged,
    int? dosesScheduled,
    int? workoutsCompleted,
    int? mealsLogged,
    int? meditationMinutes,
    int? journalEntries,
    int? totalCalories,
    int? totalProtein,
    int? sleepMinutes,
    int? sleepQuality,
    double? adherenceScore,
    double? wellnessScore,
    int? morningMood,
    int? eveningMood,
    double? averageMood,
    int? characterStatsId,
    List<String>? achievements,
    String? notes,
  }) {
    return DailyLog(
      id: id ?? this.id,
      date: date ?? this.date,
      dosesLogged: dosesLogged ?? this.dosesLogged,
      dosesScheduled: dosesScheduled ?? this.dosesScheduled,
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      mealsLogged: mealsLogged ?? this.mealsLogged,
      meditationMinutes: meditationMinutes ?? this.meditationMinutes,
      journalEntries: journalEntries ?? this.journalEntries,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      adherenceScore: adherenceScore ?? this.adherenceScore,
      wellnessScore: wellnessScore ?? this.wellnessScore,
      morningMood: morningMood ?? this.morningMood,
      eveningMood: eveningMood ?? this.eveningMood,
      averageMood: averageMood ?? this.averageMood,
      characterStatsId: characterStatsId ?? this.characterStatsId,
      achievements: achievements ?? this.achievements,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'DailyLog(id: $id, date: ${_formatDateOnly(date)}, adherence: $adherenceScore%)';
  }
}

String _formatDateOnly(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
