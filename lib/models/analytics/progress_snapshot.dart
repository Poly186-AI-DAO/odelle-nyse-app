import '../mood/mood_entry.dart';

/// A snapshot of progress metrics at a point in time.
/// Used to track changes over time for analytics.
class ProgressSnapshot {
  final int? id;
  final int userId;
  final DateTime date;
  final ProgressPeriod period;

  // Meditation stats
  final int meditationSessions;
  final int meditationMinutes;
  final double avgSessionLength;
  final int meditationStreak;

  // Workout stats
  final int workoutsCompleted;
  final int workoutMinutes;
  final int caloriesBurned;
  final int personalRecords;

  // Habit stats
  final int habitsCompleted;
  final int habitsDue;
  final double habitCompletionRate;

  // Nutrition stats
  final int avgDailyCalories;
  final int avgDailyProtein;
  final int mealsLogged;

  // Supplement adherence
  final int dosesLogged;
  final int dosesScheduled;
  final double doseAdherenceRate;

  // Sleep stats
  final double avgSleepHours;
  final double avgSleepQuality;

  // Mood stats
  final double avgMoodScore;
  final MoodType dominantMood;

  // Overall
  final int totalXPEarned;
  final double wellnessScore; // Composite 0-100

  ProgressSnapshot({
    this.id,
    required this.userId,
    required this.date,
    this.period = ProgressPeriod.weekly,
    this.meditationSessions = 0,
    this.meditationMinutes = 0,
    this.avgSessionLength = 0,
    this.meditationStreak = 0,
    this.workoutsCompleted = 0,
    this.workoutMinutes = 0,
    this.caloriesBurned = 0,
    this.personalRecords = 0,
    this.habitsCompleted = 0,
    this.habitsDue = 0,
    this.habitCompletionRate = 0,
    this.avgDailyCalories = 0,
    this.avgDailyProtein = 0,
    this.mealsLogged = 0,
    this.dosesLogged = 0,
    this.dosesScheduled = 0,
    this.doseAdherenceRate = 0,
    this.avgSleepHours = 0,
    this.avgSleepQuality = 0,
    this.avgMoodScore = 0,
    this.dominantMood = MoodType.neutral,
    this.totalXPEarned = 0,
    this.wellnessScore = 0,
  });

  /// Create from database map.
  factory ProgressSnapshot.fromMap(Map<String, dynamic> map) {
    return ProgressSnapshot(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      date: DateTime.parse(map['date'] as String),
      period: _parseProgressPeriod(map['period'] as String?),
      meditationSessions: (map['meditation_sessions'] as int?) ?? 0,
      meditationMinutes: (map['meditation_minutes'] as int?) ?? 0,
      avgSessionLength: (map['avg_session_length'] as num?)?.toDouble() ?? 0,
      meditationStreak: (map['meditation_streak'] as int?) ?? 0,
      workoutsCompleted: (map['workouts_completed'] as int?) ?? 0,
      workoutMinutes: (map['workout_minutes'] as int?) ?? 0,
      caloriesBurned: (map['calories_burned'] as int?) ?? 0,
      personalRecords: (map['personal_records'] as int?) ?? 0,
      habitsCompleted: (map['habits_completed'] as int?) ?? 0,
      habitsDue: (map['habits_due'] as int?) ?? 0,
      habitCompletionRate: (map['habit_completion_rate'] as num?)?.toDouble() ?? 0,
      avgDailyCalories: (map['avg_daily_calories'] as int?) ?? 0,
      avgDailyProtein: (map['avg_daily_protein'] as int?) ?? 0,
      mealsLogged: (map['meals_logged'] as int?) ?? 0,
      dosesLogged: (map['doses_logged'] as int?) ?? 0,
      dosesScheduled: (map['doses_scheduled'] as int?) ?? 0,
      doseAdherenceRate: (map['dose_adherence_rate'] as num?)?.toDouble() ?? 0,
      avgSleepHours: (map['avg_sleep_hours'] as num?)?.toDouble() ?? 0,
      avgSleepQuality: (map['avg_sleep_quality'] as num?)?.toDouble() ?? 0,
      avgMoodScore: (map['avg_mood_score'] as num?)?.toDouble() ?? 0,
      dominantMood: _parseMoodType(map['dominant_mood'] as String?),
      totalXPEarned: (map['total_xp_earned'] as int?) ?? 0,
      wellnessScore: (map['wellness_score'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'period': period.name,
      'meditation_sessions': meditationSessions,
      'meditation_minutes': meditationMinutes,
      'avg_session_length': avgSessionLength,
      'meditation_streak': meditationStreak,
      'workouts_completed': workoutsCompleted,
      'workout_minutes': workoutMinutes,
      'calories_burned': caloriesBurned,
      'personal_records': personalRecords,
      'habits_completed': habitsCompleted,
      'habits_due': habitsDue,
      'habit_completion_rate': habitCompletionRate,
      'avg_daily_calories': avgDailyCalories,
      'avg_daily_protein': avgDailyProtein,
      'meals_logged': mealsLogged,
      'doses_logged': dosesLogged,
      'doses_scheduled': dosesScheduled,
      'dose_adherence_rate': doseAdherenceRate,
      'avg_sleep_hours': avgSleepHours,
      'avg_sleep_quality': avgSleepQuality,
      'avg_mood_score': avgMoodScore,
      'dominant_mood': dominantMood.name,
      'total_xp_earned': totalXPEarned,
      'wellness_score': wellnessScore,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory ProgressSnapshot.fromJson(Map<String, dynamic> json) {
    return ProgressSnapshot.fromMap(json);
  }

  /// Copy with modifications.
  ProgressSnapshot copyWith({
    int? id,
    int? userId,
    DateTime? date,
    ProgressPeriod? period,
    int? meditationSessions,
    int? meditationMinutes,
    double? avgSessionLength,
    int? meditationStreak,
    int? workoutsCompleted,
    int? workoutMinutes,
    int? caloriesBurned,
    int? personalRecords,
    int? habitsCompleted,
    int? habitsDue,
    double? habitCompletionRate,
    int? avgDailyCalories,
    int? avgDailyProtein,
    int? mealsLogged,
    int? dosesLogged,
    int? dosesScheduled,
    double? doseAdherenceRate,
    double? avgSleepHours,
    double? avgSleepQuality,
    double? avgMoodScore,
    MoodType? dominantMood,
    int? totalXPEarned,
    double? wellnessScore,
  }) {
    return ProgressSnapshot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      period: period ?? this.period,
      meditationSessions: meditationSessions ?? this.meditationSessions,
      meditationMinutes: meditationMinutes ?? this.meditationMinutes,
      avgSessionLength: avgSessionLength ?? this.avgSessionLength,
      meditationStreak: meditationStreak ?? this.meditationStreak,
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      workoutMinutes: workoutMinutes ?? this.workoutMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      personalRecords: personalRecords ?? this.personalRecords,
      habitsCompleted: habitsCompleted ?? this.habitsCompleted,
      habitsDue: habitsDue ?? this.habitsDue,
      habitCompletionRate: habitCompletionRate ?? this.habitCompletionRate,
      avgDailyCalories: avgDailyCalories ?? this.avgDailyCalories,
      avgDailyProtein: avgDailyProtein ?? this.avgDailyProtein,
      mealsLogged: mealsLogged ?? this.mealsLogged,
      dosesLogged: dosesLogged ?? this.dosesLogged,
      dosesScheduled: dosesScheduled ?? this.dosesScheduled,
      doseAdherenceRate: doseAdherenceRate ?? this.doseAdherenceRate,
      avgSleepHours: avgSleepHours ?? this.avgSleepHours,
      avgSleepQuality: avgSleepQuality ?? this.avgSleepQuality,
      avgMoodScore: avgMoodScore ?? this.avgMoodScore,
      dominantMood: dominantMood ?? this.dominantMood,
      totalXPEarned: totalXPEarned ?? this.totalXPEarned,
      wellnessScore: wellnessScore ?? this.wellnessScore,
    );
  }

  @override
  String toString() {
    return 'ProgressSnapshot(id: $id, period: ${period.name}, wellnessScore: $wellnessScore)';
  }
}

enum ProgressPeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly;

  String get displayName {
    switch (this) {
      case daily:
        return 'Daily';
      case weekly:
        return 'Weekly';
      case monthly:
        return 'Monthly';
      case quarterly:
        return 'Quarterly';
      case yearly:
        return 'Yearly';
    }
  }
}

ProgressPeriod _parseProgressPeriod(String? value) {
  if (value == null || value.isEmpty) return ProgressPeriod.weekly;
  return ProgressPeriod.values.firstWhere(
    (pp) => pp.name == value,
    orElse: () => ProgressPeriod.weekly,
  );
}

MoodType _parseMoodType(String? value) {
  if (value == null || value.isEmpty) return MoodType.neutral;
  return MoodType.values.firstWhere(
    (mt) => mt.name == value,
    orElse: () => MoodType.neutral,
  );
}
