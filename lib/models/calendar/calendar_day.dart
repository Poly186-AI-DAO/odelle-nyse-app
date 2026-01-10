import '../mood/mood_entry.dart';

/// Represents a single day in calendar views (computed at runtime).
class CalendarDay {
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool isFutureDay;

  // Activity summary
  final List<CalendarActivity> activities;
  final int activityCount;

  // Visual indicators
  final bool hasAnyActivity;
  final bool allGoalsComplete;
  final String? primaryColor;

  // Mood if tracked
  final MoodType? mood;

  CalendarDay({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.isFutureDay,
    required this.activities,
    required this.activityCount,
    required this.hasAnyActivity,
    required this.allGoalsComplete,
    required this.primaryColor,
    required this.mood,
  });

  /// Build a calendar day from activities.
  factory CalendarDay.fromActivities({
    required DateTime date,
    required List<CalendarActivity> activities,
    MoodType? mood,
    bool isSelected = false,
  }) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfDate = DateTime(date.year, date.month, date.day);

    final isToday = startOfDate == startOfToday;
    final isFutureDay = startOfDate.isAfter(startOfToday);
    final activityCount = activities.length;
    final hasAnyActivity = activities.isNotEmpty;
    final allGoalsComplete =
        activities.isNotEmpty && activities.every((activity) => activity.isCompleted);
    final primaryColor = activities.isNotEmpty ? activities.first.colorHex : null;

    return CalendarDay(
      date: date,
      isToday: isToday,
      isSelected: isSelected,
      isFutureDay: isFutureDay,
      activities: activities,
      activityCount: activityCount,
      hasAnyActivity: hasAnyActivity,
      allGoalsComplete: allGoalsComplete,
      primaryColor: primaryColor,
      mood: mood,
    );
  }
}

class CalendarActivity {
  final CalendarActivityType type;
  final String colorHex;
  final bool isCompleted;
  final String? label;

  CalendarActivity({
    required this.type,
    required this.colorHex,
    required this.isCompleted,
    this.label,
  });
}

enum CalendarActivityType {
  meditation,
  workout,
  dose,
  habit,
  sleep,
  meal,
  session;
}
