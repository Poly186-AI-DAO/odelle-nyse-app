import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Data class for sleep metrics
class SleepData {
  final Duration totalDuration;
  final Duration? deepSleep;
  final Duration? remSleep;
  final Duration? lightSleep;
  final Duration? awake;
  final DateTime? bedTime;
  final DateTime? wakeTime;
  final int qualityScore; // 0-100 estimated score

  SleepData({
    required this.totalDuration,
    this.deepSleep,
    this.remSleep,
    this.lightSleep,
    this.awake,
    this.bedTime,
    this.wakeTime,
    required this.qualityScore,
  });

  @override
  String toString() =>
      'SleepData(total: ${totalDuration.inHours}h ${totalDuration.inMinutes % 60}m, score: $qualityScore)';
}

/// Data class for workout metrics
class WorkoutData {
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double? caloriesBurned;
  final double? distance; // in meters
  final int? steps;
  final String? sourceName;

  WorkoutData({
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.caloriesBurned,
    this.distance,
    this.steps,
    this.sourceName,
  });

  @override
  String toString() =>
      'WorkoutData($type, ${duration.inMinutes}min, ${caloriesBurned?.toInt() ?? 0}kcal)';
}

/// Data class for mindfulness/meditation sessions
class MindfulnessData {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final String? sourceName;

  MindfulnessData({
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.sourceName,
  });
}

/// Aggregated daily health summary
class DailyHealthSummary {
  final DateTime date;
  final int steps;
  final double activeCalories;
  final double basalCalories;
  final int? restingHeartRate;
  final int? averageHeartRate;
  final Duration? mindfulMinutes;
  final SleepData? lastNightSleep;
  final List<WorkoutData> workouts;

  DailyHealthSummary({
    required this.date,
    required this.steps,
    required this.activeCalories,
    required this.basalCalories,
    this.restingHeartRate,
    this.averageHeartRate,
    this.mindfulMinutes,
    this.lastNightSleep,
    required this.workouts,
  });

  double get totalCaloriesBurned => activeCalories + basalCalories;
}

/// Service for interacting with Apple HealthKit via the health package
class HealthKitService {
  static final HealthKitService _instance = HealthKitService._internal();
  factory HealthKitService() => _instance;
  HealthKitService._internal();

  final Health _health = Health();
  bool _isAuthorized = false;
  bool _isConfigured = false;

  /// Data types we want to READ from HealthKit
  static const List<HealthDataType> _readTypes = [
    // Sleep
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_IN_BED,
    // Heart
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    // Activity
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.WORKOUT,
    // Body
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    // Mindfulness
    HealthDataType.MINDFULNESS,
    // Water
    HealthDataType.WATER,
  ];

  /// Data types we want to WRITE to HealthKit
  static const List<HealthDataType> _writeTypes = [
    // Activity (log workouts, steps if manual)
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
    // Body measurements
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    // Mindfulness (meditation sessions)
    HealthDataType.MINDFULNESS,
    // Nutrition/Hydration
    HealthDataType.WATER,
    // Sleep (if logging manually)
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
  ];

  /// Request authorization for HealthKit access (both read and write)
  /// Returns true if authorized, false otherwise
  Future<bool> requestAuthorization() async {
    try {
      // Configure health plugin before use (required in v12+)
      if (!_isConfigured) {
        await _health.configure();
        _isConfigured = true;
        debugPrint('[HealthKit] Plugin configured');
      }

      // Combine read and write types, avoiding duplicates
      final allTypes = <HealthDataType>{..._readTypes, ..._writeTypes}.toList();

      // Build permissions list: READ_WRITE for types in both lists, READ for read-only
      final permissions = allTypes.map((type) {
        if (_writeTypes.contains(type)) {
          return HealthDataAccess.READ_WRITE;
        }
        return HealthDataAccess.READ;
      }).toList();

      // Request authorization
      final authorized = await _health.requestAuthorization(
        allTypes,
        permissions: permissions,
      );

      _isAuthorized = authorized;
      debugPrint('[HealthKit] Authorization result: $authorized');
      return authorized;
    } catch (e) {
      debugPrint('[HealthKit] Authorization error: $e');
      return false;
    }
  }

  /// Check if we have authorization
  bool get isAuthorized => _isAuthorized;

  /// Get a complete daily health summary for today
  Future<DailyHealthSummary> getTodaySummary() async {
    if (!_isAuthorized) {
      await requestAuthorization();
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Fetch all data in parallel for better performance
    final results = await Future.wait([
      getSteps(now),
      getActiveCalories(now),
      getBasalCalories(now),
      getRestingHeartRate(),
      getAverageHeartRate(startOfDay, now),
      getMindfulMinutes(now),
      getLastNightSleep(),
      getTodayWorkouts(),
    ]);

    return DailyHealthSummary(
      date: startOfDay,
      steps: results[0] as int,
      activeCalories: results[1] as double,
      basalCalories: results[2] as double,
      restingHeartRate: results[3] as int?,
      averageHeartRate: results[4] as int?,
      mindfulMinutes: results[5] as Duration?,
      lastNightSleep: results[6] as SleepData?,
      workouts: results[7] as List<WorkoutData>,
    );
  }

  /// Get sleep data for last night (yesterday 8pm to today 10am by default)
  Future<SleepData?> getLastNightSleep() async {
    if (!_isAuthorized) {
      debugPrint('[HealthKit] Not authorized, attempting authorization...');
      await requestAuthorization();
      if (!_isAuthorized) return null;
    }

    try {
      final now = DateTime.now();
      // Look for sleep data from yesterday 6pm to today noon
      final startTime = DateTime(now.year, now.month, now.day - 1, 18, 0);
      final endTime = DateTime(now.year, now.month, now.day, 12, 0);

      final sleepTypes = [
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
      ];

      final data = await _health.getHealthDataFromTypes(
        types: sleepTypes,
        startTime: startTime,
        endTime: endTime,
      );

      if (data.isEmpty) {
        debugPrint('[HealthKit] No sleep data found');
        return null;
      }

      // Aggregate durations by sleep type
      Duration asleepTotal = Duration.zero;
      Duration inBedTotal = Duration.zero;
      Duration deepSleepTotal = Duration.zero;
      Duration remSleepTotal = Duration.zero;
      Duration lightSleepTotal = Duration.zero;
      Duration awakeTotal = Duration.zero;
      bool hasAwakeData = false;

      DateTime? earliestStart;
      DateTime? latestEnd;
      DateTime? inBedStart;
      DateTime? inBedEnd;

      for (final point in data) {
        final duration = point.dateTo.difference(point.dateFrom);

        if (earliestStart == null || point.dateFrom.isBefore(earliestStart)) {
          earliestStart = point.dateFrom;
        }
        if (latestEnd == null || point.dateTo.isAfter(latestEnd)) {
          latestEnd = point.dateTo;
        }

        switch (point.type) {
          case HealthDataType.SLEEP_IN_BED:
            inBedTotal += duration;
            if (inBedStart == null || point.dateFrom.isBefore(inBedStart)) {
              inBedStart = point.dateFrom;
            }
            if (inBedEnd == null || point.dateTo.isAfter(inBedEnd)) {
              inBedEnd = point.dateTo;
            }
            break;
          case HealthDataType.SLEEP_ASLEEP:
            asleepTotal += duration;
            break;
          case HealthDataType.SLEEP_DEEP:
            deepSleepTotal += duration;
            break;
          case HealthDataType.SLEEP_REM:
            remSleepTotal += duration;
            break;
          case HealthDataType.SLEEP_LIGHT:
            lightSleepTotal += duration;
            break;
          case HealthDataType.SLEEP_AWAKE:
            awakeTotal += duration;
            hasAwakeData = true;
            break;
          default:
            break;
        }
      }

      final stageTotal = deepSleepTotal + remSleepTotal + lightSleepTotal;
      final hasStageData = stageTotal > Duration.zero;
      Duration totalAsleep = hasStageData ? stageTotal : asleepTotal;

      if (totalAsleep == Duration.zero && inBedTotal > Duration.zero) {
        totalAsleep = inBedTotal;
      }

      if (!hasAwakeData && inBedTotal > Duration.zero) {
        final inferredAwake = inBedTotal - totalAsleep;
        if (!inferredAwake.isNegative) {
          awakeTotal = inferredAwake;
          hasAwakeData = true;
        }
      }

      // Calculate a simple quality score based on deep sleep percentage
      final totalMinutes = totalAsleep.inMinutes;
      final deepMinutes = deepSleepTotal.inMinutes;
      final awakeMinutes = awakeTotal.inMinutes;

      int qualityScore = 75; // Default
      if (totalMinutes > 0 && (hasStageData || hasAwakeData)) {
        // More deep sleep = better (target ~20%)
        final deepPercentage = deepMinutes / totalMinutes;
        // Less awake time = better
        final awakeRatio = awakeMinutes / (totalMinutes + awakeMinutes);

        qualityScore = ((0.5 + deepPercentage * 1.5 - awakeRatio * 0.5) * 100)
            .clamp(0, 100)
            .toInt();
      }

      debugPrint(
          '[HealthKit] Sleep data: ${totalAsleep.inHours}h ${totalAsleep.inMinutes % 60}m, score: $qualityScore');

      return SleepData(
        totalDuration: totalAsleep,
        deepSleep: hasStageData ? deepSleepTotal : null,
        remSleep: hasStageData ? remSleepTotal : null,
        lightSleep: hasStageData ? lightSleepTotal : null,
        awake: hasAwakeData ? awakeTotal : null,
        bedTime: inBedStart ?? earliestStart,
        wakeTime: inBedEnd ?? latestEnd,
        qualityScore: qualityScore,
      );
    } catch (e) {
      debugPrint('[HealthKit] Error fetching sleep data: $e');
      return null;
    }
  }

  /// Get step count for a specific date
  Future<int> getSteps(DateTime date) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return 0;
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final steps = await _health.getTotalStepsInInterval(startOfDay, endOfDay);
      debugPrint(
          '[HealthKit] Steps for ${date.day}/${date.month}: ${steps ?? 0}');
      return steps ?? 0;
    } catch (e) {
      debugPrint('[HealthKit] Error fetching steps: $e');
      return 0;
    }
  }

  /// Get heart rate samples for a date range
  Future<List<int>> getHeartRateSamples(DateTime start, DateTime end) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return [];
    }

    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );

      return data
          .map((point) =>
              (point.value as NumericHealthValue).numericValue.toInt())
          .toList();
    } catch (e) {
      debugPrint('[HealthKit] Error fetching heart rate: $e');
      return [];
    }
  }

  /// Get average resting heart rate for today
  Future<int?> getRestingHeartRate() async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return null;
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.RESTING_HEART_RATE],
        startTime: startOfDay,
        endTime: now,
      );

      if (data.isEmpty) return null;

      // Get the most recent resting HR
      final latest = data.last;
      return (latest.value as NumericHealthValue).numericValue.toInt();
    } catch (e) {
      debugPrint('[HealthKit] Error fetching resting HR: $e');
      return null;
    }
  }

  /// Get workouts for a date range
  Future<List<WorkoutData>> getWorkouts(DateTime start, DateTime end) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return [];
    }

    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: start,
        endTime: end,
      );

      return data.map((point) {
        final workout = point.value as WorkoutHealthValue;
        return WorkoutData(
          type: workout.workoutActivityType.name,
          startTime: point.dateFrom,
          endTime: point.dateTo,
          duration: point.dateTo.difference(point.dateFrom),
          caloriesBurned: workout.totalEnergyBurned?.toDouble(),
          distance: workout.totalDistance?.toDouble(),
          steps: workout.totalSteps?.toInt(),
          sourceName: point.sourceName,
        );
      }).toList();
    } catch (e) {
      debugPrint('[HealthKit] Error fetching workouts: $e');
      return [];
    }
  }

  /// Get today's workouts
  Future<List<WorkoutData>> getTodayWorkouts() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return getWorkouts(startOfDay, now);
  }

  /// Get active energy burned for a date
  Future<double> getActiveCalories(DateTime date) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return 0;
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      double total = 0;
      for (final point in data) {
        total += (point.value as NumericHealthValue).numericValue;
      }

      debugPrint('[HealthKit] Active calories: $total');
      return total;
    } catch (e) {
      debugPrint('[HealthKit] Error fetching active calories: $e');
      return 0;
    }
  }

  /// Get basal (resting) energy burned for a date
  Future<double> getBasalCalories(DateTime date) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return 0;
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BASAL_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      double total = 0;
      for (final point in data) {
        total += (point.value as NumericHealthValue).numericValue;
      }

      debugPrint('[HealthKit] Basal calories: $total');
      return total;
    } catch (e) {
      debugPrint('[HealthKit] Error fetching basal calories: $e');
      return 0;
    }
  }

  /// Get average heart rate for a date range
  Future<int?> getAverageHeartRate(DateTime start, DateTime end) async {
    final samples = await getHeartRateSamples(start, end);
    if (samples.isEmpty) return null;

    final sum = samples.reduce((a, b) => a + b);
    return sum ~/ samples.length;
  }

  /// Get mindfulness/meditation minutes for a date
  Future<Duration?> getMindfulMinutes(DateTime date) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return null;
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.MINDFULNESS],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      if (data.isEmpty) return null;

      // Sum up all mindfulness sessions
      Duration total = Duration.zero;
      for (final point in data) {
        total += point.dateTo.difference(point.dateFrom);
      }

      debugPrint('[HealthKit] Mindful minutes: ${total.inMinutes}');
      return total;
    } catch (e) {
      debugPrint('[HealthKit] Error fetching mindfulness: $e');
      return null;
    }
  }

  /// Get mindfulness sessions for a date range
  Future<List<MindfulnessData>> getMindfulnessSessions(
      DateTime start, DateTime end) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return [];
    }

    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.MINDFULNESS],
        startTime: start,
        endTime: end,
      );

      return data
          .map((point) => MindfulnessData(
                startTime: point.dateFrom,
                endTime: point.dateTo,
                duration: point.dateTo.difference(point.dateFrom),
                sourceName: point.sourceName,
              ))
          .toList();
    } catch (e) {
      debugPrint('[HealthKit] Error fetching mindfulness sessions: $e');
      return [];
    }
  }

  /// Get exercise minutes for a date
  Future<int> getExerciseMinutes(DateTime date) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return 0;
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.EXERCISE_TIME],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      double total = 0;
      for (final point in data) {
        total += (point.value as NumericHealthValue).numericValue;
      }

      debugPrint('[HealthKit] Exercise minutes: ${total.toInt()}');
      return total.toInt();
    } catch (e) {
      debugPrint('[HealthKit] Error fetching exercise time: $e');
      return 0;
    }
  }

  /// Get water intake for a date (in liters)
  Future<double> getWaterIntake(DateTime date) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return 0;
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      double total = 0;
      for (final point in data) {
        total += (point.value as NumericHealthValue).numericValue;
      }

      debugPrint('[HealthKit] Water intake: ${total}L');
      return total;
    } catch (e) {
      debugPrint('[HealthKit] Error fetching water intake: $e');
      return 0;
    }
  }

  /// Get latest weight reading
  Future<double?> getLatestWeight() async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return null;
    }

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: thirtyDaysAgo,
        endTime: now,
      );

      if (data.isEmpty) return null;

      // Return the most recent reading
      final latest = data.last;
      return (latest.value as NumericHealthValue).numericValue.toDouble();
    } catch (e) {
      debugPrint('[HealthKit] Error fetching weight: $e');
      return null;
    }
  }

  /// Get flights climbed for a date
  Future<int> getFlightsClimbed(DateTime date) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return 0;
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.FLIGHTS_CLIMBED],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      double total = 0;
      for (final point in data) {
        total += (point.value as NumericHealthValue).numericValue;
      }

      return total.toInt();
    } catch (e) {
      debugPrint('[HealthKit] Error fetching flights climbed: $e');
      return 0;
    }
  }

  /// Get walking/running distance for a date (in meters)
  Future<double> getDistance(DateTime date) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return 0;
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      double total = 0;
      for (final point in data) {
        total += (point.value as NumericHealthValue).numericValue;
      }

      debugPrint(
          '[HealthKit] Distance: ${(total / 1000).toStringAsFixed(2)}km');
      return total;
    } catch (e) {
      debugPrint('[HealthKit] Error fetching distance: $e');
      return 0;
    }
  }

  // ============================================================
  // WRITE METHODS - Save data to Apple Health
  // ============================================================

  /// Write a workout to HealthKit
  /// Returns true if successful
  Future<bool> writeWorkout({
    required HealthWorkoutActivityType activityType,
    required DateTime start,
    required DateTime end,
    int? totalEnergyBurned,
    int? totalDistance,
  }) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return false;
    }

    try {
      final success = await _health.writeWorkoutData(
        activityType: activityType,
        start: start,
        end: end,
        totalEnergyBurned: totalEnergyBurned,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
        totalDistance: totalDistance,
        totalDistanceUnit: HealthDataUnit.METER,
      );
      debugPrint('[HealthKit] Wrote workout: $success');
      return success;
    } catch (e) {
      debugPrint('[HealthKit] Error writing workout: $e');
      return false;
    }
  }

  /// Write water intake to HealthKit (in liters)
  Future<bool> writeWater(double liters, DateTime time) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return false;
    }

    try {
      final success = await _health.writeHealthData(
        value: liters,
        type: HealthDataType.WATER,
        startTime: time,
        endTime: time,
        unit: HealthDataUnit.LITER,
      );
      debugPrint('[HealthKit] Wrote water: ${liters}L - $success');
      return success;
    } catch (e) {
      debugPrint('[HealthKit] Error writing water: $e');
      return false;
    }
  }

  /// Write a mindfulness/meditation session to HealthKit
  Future<bool> writeMindfulness({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return false;
    }

    try {
      final durationMinutes = end.difference(start).inMinutes.toDouble();
      final success = await _health.writeHealthData(
        value: durationMinutes,
        type: HealthDataType.MINDFULNESS,
        startTime: start,
        endTime: end,
        unit: HealthDataUnit.MINUTE,
      );
      debugPrint(
          '[HealthKit] Wrote mindfulness: ${durationMinutes}min - $success');
      return success;
    } catch (e) {
      debugPrint('[HealthKit] Error writing mindfulness: $e');
      return false;
    }
  }

  /// Write weight to HealthKit (in kg)
  Future<bool> writeWeight(double kg, DateTime time) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return false;
    }

    try {
      final success = await _health.writeHealthData(
        value: kg,
        type: HealthDataType.WEIGHT,
        startTime: time,
        endTime: time,
        unit: HealthDataUnit.KILOGRAM,
      );
      debugPrint('[HealthKit] Wrote weight: ${kg}kg - $success');
      return success;
    } catch (e) {
      debugPrint('[HealthKit] Error writing weight: $e');
      return false;
    }
  }

  /// Write body fat percentage to HealthKit
  Future<bool> writeBodyFat(double percentage, DateTime time) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return false;
    }

    try {
      final success = await _health.writeHealthData(
        value: percentage,
        type: HealthDataType.BODY_FAT_PERCENTAGE,
        startTime: time,
        endTime: time,
        unit: HealthDataUnit.PERCENT,
      );
      debugPrint('[HealthKit] Wrote body fat: $percentage% - $success');
      return success;
    } catch (e) {
      debugPrint('[HealthKit] Error writing body fat: $e');
      return false;
    }
  }

  /// Write sleep data to HealthKit
  Future<bool> writeSleep({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return false;
    }

    try {
      // Write the main "asleep" period
      final success = await _health.writeHealthData(
        value: end.difference(start).inMinutes.toDouble(),
        type: HealthDataType.SLEEP_ASLEEP,
        startTime: start,
        endTime: end,
        unit: HealthDataUnit.MINUTE,
      );
      debugPrint('[HealthKit] Wrote sleep: $success');
      return success;
    } catch (e) {
      debugPrint('[HealthKit] Error writing sleep: $e');
      return false;
    }
  }

  /// Write active calories burned to HealthKit
  Future<bool> writeActiveCalories(
      double kcal, DateTime start, DateTime end) async {
    if (!_isAuthorized) {
      await requestAuthorization();
      if (!_isAuthorized) return false;
    }

    try {
      final success = await _health.writeHealthData(
        value: kcal,
        type: HealthDataType.ACTIVE_ENERGY_BURNED,
        startTime: start,
        endTime: end,
        unit: HealthDataUnit.KILOCALORIE,
      );
      debugPrint('[HealthKit] Wrote active calories: $kcal kcal - $success');
      return success;
    } catch (e) {
      debugPrint('[HealthKit] Error writing active calories: $e');
      return false;
    }
  }
}
