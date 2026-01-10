import '../habits/habit_log.dart';
import '../mood/mood_entry.dart';
import '../tracking/dose_log.dart';

/// Progress data for a single week (computed at runtime).
class WeeklyProgress {
  final DateTime weekStartDate;
  final DateTime weekEndDate;

  // Day-by-day breakdown
  final List<DayProgress> days;

  // Week totals
  final int totalMeditationMinutes;
  final int totalWorkoutMinutes;
  final int totalHabitsCompleted;
  final int totalXPEarned;

  // Streak info
  final int streakDays;
  final bool weekCompleted;

  // Comparison
  final double vsLastWeek;

  WeeklyProgress({
    required this.weekStartDate,
    required this.weekEndDate,
    required this.days,
    required this.totalMeditationMinutes,
    required this.totalWorkoutMinutes,
    required this.totalHabitsCompleted,
    required this.totalXPEarned,
    required this.streakDays,
    required this.weekCompleted,
    required this.vsLastWeek,
  });

  /// Build a weekly summary from day progress entries.
  factory WeeklyProgress.fromDayProgress({
    required DateTime weekStartDate,
    required List<DayProgress> days,
    int totalXPEarned = 0,
    double vsLastWeek = 0,
  }) {
    final sortedDays = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final weekEndDate = weekStartDate.add(const Duration(days: 6));

    final totalMeditationMinutes =
        sortedDays.fold<int>(0, (sum, day) => sum + day.meditationMinutes);
    final totalWorkoutMinutes =
        sortedDays.fold<int>(0, (sum, day) => sum + day.workoutMinutes);
    final totalHabitsCompleted =
        sortedDays.fold<int>(0, (sum, day) => sum + day.habitsCompleted);

    int currentStreak = 0;
    int maxStreak = 0;
    for (final day in sortedDays) {
      if (day.status == DayStatus.missed || day.status == DayStatus.upcoming) {
        currentStreak = 0;
      } else {
        currentStreak += 1;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      }
    }

    final weekCompleted = sortedDays.isNotEmpty &&
        sortedDays.every(
          (day) =>
              day.status != DayStatus.missed &&
              day.status != DayStatus.upcoming,
        );

    return WeeklyProgress(
      weekStartDate: weekStartDate,
      weekEndDate: weekEndDate,
      days: sortedDays,
      totalMeditationMinutes: totalMeditationMinutes,
      totalWorkoutMinutes: totalWorkoutMinutes,
      totalHabitsCompleted: totalHabitsCompleted,
      totalXPEarned: totalXPEarned,
      streakDays: maxStreak,
      weekCompleted: weekCompleted,
      vsLastWeek: vsLastWeek,
    );
  }
}

/// Single day's progress (computed at runtime).
class DayProgress {
  final DateTime date;
  final int dayOfWeek;

  // Activity indicators
  final bool hasMeditation;
  final bool hasWorkout;
  final bool habitsComplete;
  final bool dosesComplete;

  // Metrics
  final int meditationMinutes;
  final int workoutMinutes;
  final int habitsCompleted;
  final int habitsDue;

  // Mood (if tracked)
  final MoodType? mood;

  // Visual indicator
  final DayStatus status;

  DayProgress({
    required this.date,
    required this.dayOfWeek,
    required this.hasMeditation,
    required this.hasWorkout,
    required this.habitsComplete,
    required this.dosesComplete,
    required this.meditationMinutes,
    required this.workoutMinutes,
    required this.habitsCompleted,
    required this.habitsDue,
    required this.mood,
    required this.status,
  });

  /// Build day progress from logged entries.
  factory DayProgress.fromLogs({
    required DateTime date,
    required List<HabitLog> habitLogs,
    required List<DoseLog> doseLogs,
    MoodEntry? moodEntry,
    int meditationMinutes = 0,
    int workoutMinutes = 0,
    int habitsDue = 0,
  }) {
    final habitsCompleted =
        habitLogs.where((log) => log.isCompleted).length;
    final resolvedHabitsDue = habitsDue == 0 ? habitLogs.length : habitsDue;
    final habitsComplete =
        resolvedHabitsDue > 0 && habitsCompleted >= resolvedHabitsDue;
    final hasMeditation = meditationMinutes > 0;
    final hasWorkout = workoutMinutes > 0;
    final dosesComplete = doseLogs.isNotEmpty;

    final status = _calculateStatus(
      date: date,
      hasMeditation: hasMeditation,
      hasWorkout: hasWorkout,
      habitsComplete: habitsComplete,
      dosesComplete: dosesComplete,
    );

    return DayProgress(
      date: date,
      dayOfWeek: date.weekday,
      hasMeditation: hasMeditation,
      hasWorkout: hasWorkout,
      habitsComplete: habitsComplete,
      dosesComplete: dosesComplete,
      meditationMinutes: meditationMinutes,
      workoutMinutes: workoutMinutes,
      habitsCompleted: habitsCompleted,
      habitsDue: resolvedHabitsDue,
      mood: moodEntry?.mood,
      status: status,
    );
  }
}

enum DayStatus {
  perfect,
  good,
  partial,
  missed,
  upcoming;
}

DayStatus _calculateStatus({
  required DateTime date,
  required bool hasMeditation,
  required bool hasWorkout,
  required bool habitsComplete,
  required bool dosesComplete,
}) {
  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);
  final startOfDate = DateTime(date.year, date.month, date.day);

  if (startOfDate.isAfter(startOfToday)) {
    return DayStatus.upcoming;
  }

  int score = 0;
  if (hasMeditation) score += 1;
  if (hasWorkout) score += 1;
  if (habitsComplete) score += 1;
  if (dosesComplete) score += 1;

  if (score == 4) return DayStatus.perfect;
  if (score >= 2) return DayStatus.good;
  if (score == 1) return DayStatus.partial;
  return DayStatus.missed;
}
