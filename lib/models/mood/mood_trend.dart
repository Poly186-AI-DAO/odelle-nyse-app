import 'mood_entry.dart';

/// Aggregated mood data for trends (computed at runtime).
class MoodTrend {
  final DateTime startDate;
  final DateTime endDate;
  final TrendPeriod period;

  // Aggregates
  final Map<MoodType, int> moodCounts;
  final MoodType dominantMood;
  final double averageIntensity;
  final int totalEntries;

  // Patterns
  final MoodType? bestDayMood;
  final int? bestDayOfWeek;
  final double positivePercentage;

  MoodTrend({
    required this.startDate,
    required this.endDate,
    required this.period,
    required this.moodCounts,
    required this.dominantMood,
    required this.averageIntensity,
    required this.totalEntries,
    required this.bestDayMood,
    required this.bestDayOfWeek,
    required this.positivePercentage,
  });

  /// Build a trend summary from mood entries.
  factory MoodTrend.fromEntries({
    required DateTime startDate,
    required DateTime endDate,
    required TrendPeriod period,
    required List<MoodEntry> entries,
  }) {
    final filtered = entries.where((entry) {
      return !entry.timestamp.isBefore(startDate) &&
          !entry.timestamp.isAfter(endDate);
    }).toList();

    final counts = <MoodType, int>{
      for (final mood in MoodType.values) mood: 0,
    };

    double intensitySum = 0;
    int intensityCount = 0;
    int positiveCount = 0;

    for (final entry in filtered) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
      if (entry.intensity != null) {
        intensitySum += entry.intensity!.toDouble();
        intensityCount += 1;
      }
      if (entry.mood.isPositive) {
        positiveCount += 1;
      }
    }

    final totalEntries = filtered.length;
    final double averageIntensity = intensityCount == 0
        ? 0.0
        : double.parse((intensitySum / intensityCount).toStringAsFixed(2));
    final double positivePercentage = totalEntries == 0
        ? 0.0
        : double.parse(
            ((positiveCount / totalEntries) * 100).toStringAsFixed(2),
          );

    MoodType dominantMood = MoodType.neutral;
    int highest = -1;
    for (final entry in counts.entries) {
      if (entry.value > highest) {
        highest = entry.value;
        dominantMood = entry.key;
      }
    }

    int? bestDayOfWeek;
    MoodType? bestDayMood;
    if (filtered.isNotEmpty) {
      final dayBuckets = <int, List<MoodEntry>>{};
      for (final entry in filtered) {
        dayBuckets.putIfAbsent(entry.timestamp.weekday, () => []).add(entry);
      }

      double bestScore = -1;
      dayBuckets.forEach((weekday, dayEntries) {
        double dayIntensitySum = 0;
        int dayIntensityCount = 0;
        int dayPositiveCount = 0;
        final dayCounts = <MoodType, int>{};

        for (final entry in dayEntries) {
          dayCounts[entry.mood] = (dayCounts[entry.mood] ?? 0) + 1;
          if (entry.intensity != null) {
            dayIntensitySum += entry.intensity!.toDouble();
            dayIntensityCount += 1;
          }
          if (entry.mood.isPositive) {
            dayPositiveCount += 1;
          }
        }

        final double dayScore = dayIntensityCount == 0
            ? (dayEntries.isEmpty
                ? 0.0
                : (dayPositiveCount / dayEntries.length) * 100.0)
            : dayIntensitySum / dayIntensityCount;

        if (dayScore > bestScore) {
          bestScore = dayScore;
          bestDayOfWeek = weekday;
          MoodType dayDominant = MoodType.neutral;
          int dayHighest = -1;
          for (final entry in dayCounts.entries) {
            if (entry.value > dayHighest) {
              dayHighest = entry.value;
              dayDominant = entry.key;
            }
          }
          bestDayMood = dayDominant;
        }
      });
    }

    return MoodTrend(
      startDate: startDate,
      endDate: endDate,
      period: period,
      moodCounts: counts,
      dominantMood: dominantMood,
      averageIntensity: averageIntensity,
      totalEntries: totalEntries,
      bestDayMood: bestDayMood,
      bestDayOfWeek: bestDayOfWeek,
      positivePercentage: positivePercentage,
    );
  }
}

enum TrendPeriod {
  week,
  month,
  quarter,
  year,
  allTime;
}
