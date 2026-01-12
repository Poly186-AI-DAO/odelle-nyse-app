import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../models/tracking/meal_log.dart';
import '../../services/health_kit_service.dart';
import '../../models/tracking/workout_log.dart';
import '../../models/tracking/dose_log.dart';
import '../../services/azure_image_service.dart';
import '../repository_providers.dart';
import '../service_providers.dart';
import '../../utils/logger.dart';

// State class for Body Screen
class BodyState {
  final DateTime selectedDate;
  final List<MealLog> meals;
  final List<WorkoutLog> workouts;
  final List<DoseLog> doses;
  final bool isLoading;
  final String? error;
  final double panelProgress;

  // Nutrition Stats
  final int caloriesConsumed;
  final int proteinConsumed;
  final int carbsConsumed;
  final int fatConsumed;
  final int caloriesBurned;

  // HealthKit Stats
  final int steps;
  final int activeCalories;
  final int basalCalories;
  final int exerciseMinutes;
  final double distance; // meters
  final double waterLiters;
  final int? restingHeartRate;

  // Sleep (from HealthKit)
  final int sleepDurationMinutes; // Actual sleep duration in minutes

  // Computed / Content stats
  final int trainingReadiness; // 0-100
  final int recoveryScore; // 0-100
  final int sleepScore; // 0-100

  const BodyState({
    required this.selectedDate,
    this.meals = const [],
    this.workouts = const [],
    this.doses = const [],
    this.isLoading = false,
    this.error,
    this.panelProgress = 0.0,
    this.caloriesConsumed = 0,
    this.proteinConsumed = 0,
    this.carbsConsumed = 0,
    this.fatConsumed = 0,
    this.caloriesBurned = 0,
    this.steps = 0,
    this.activeCalories = 0,
    this.basalCalories = 0,
    this.exerciseMinutes = 0,
    this.distance = 0,
    this.waterLiters = 0,
    this.restingHeartRate,
    this.sleepDurationMinutes = 0,
    this.trainingReadiness = 85,
    this.recoveryScore = 80,
    this.sleepScore = 75,
  });

  BodyState copyWith({
    DateTime? selectedDate,
    List<MealLog>? meals,
    List<WorkoutLog>? workouts,
    List<DoseLog>? doses,
    bool? isLoading,
    String? error,
    double? panelProgress,
    int? caloriesConsumed,
    int? proteinConsumed,
    int? carbsConsumed,
    int? fatConsumed,
    int? caloriesBurned,
    int? steps,
    int? activeCalories,
    int? basalCalories,
    int? exerciseMinutes,
    double? distance,
    double? waterLiters,
    int? restingHeartRate,
    int? sleepDurationMinutes,
    int? trainingReadiness,
    int? recoveryScore,
    int? sleepScore,
  }) {
    return BodyState(
      selectedDate: selectedDate ?? this.selectedDate,
      meals: meals ?? this.meals,
      workouts: workouts ?? this.workouts,
      doses: doses ?? this.doses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      panelProgress: panelProgress ?? this.panelProgress,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      proteinConsumed: proteinConsumed ?? this.proteinConsumed,
      carbsConsumed: carbsConsumed ?? this.carbsConsumed,
      fatConsumed: fatConsumed ?? this.fatConsumed,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      steps: steps ?? this.steps,
      activeCalories: activeCalories ?? this.activeCalories,
      basalCalories: basalCalories ?? this.basalCalories,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      distance: distance ?? this.distance,
      waterLiters: waterLiters ?? this.waterLiters,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      sleepDurationMinutes: sleepDurationMinutes ?? this.sleepDurationMinutes,
      trainingReadiness: trainingReadiness ?? this.trainingReadiness,
      recoveryScore: recoveryScore ?? this.recoveryScore,
      sleepScore: sleepScore ?? this.sleepScore,
    );
  }
}

// ViewModel
class BodyViewModel extends Notifier<BodyState> {
  static const String _tag = 'BodyViewModel';

  @override
  BodyState build() {
    final initialDate = DateTime.now();
    Future.microtask(() => loadData(initialDate));
    return BodyState(selectedDate: initialDate);
  }

  Future<void> selectDate(DateTime date) async {
    state = state.copyWith(selectedDate: date, isLoading: true);
    await loadData(date);
  }

  Future<void> loadData(DateTime date) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Start of day
      final startOfDay = DateTime(date.year, date.month, date.day);
      // End of day
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Repositories
      final mealRepo = ref.read(mealRepositoryProvider);
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final doseRepo = ref.read(doseRepositoryProvider);
      final healthKit = ref.read(healthKitServiceProvider);

      // Fetch DB Data
      final dbResults = await Future.wait([
        mealRepo.getMeals(startDate: startOfDay, endDate: endOfDay),
        workoutRepo.getWorkouts(startDate: startOfDay, endDate: endOfDay),
        doseRepo.getDoseLogs(startDate: startOfDay, endDate: endOfDay),
      ]);

      final meals = dbResults[0] as List<MealLog>;
      final workouts = dbResults[1] as List<WorkoutLog>;
      final doses = dbResults[2] as List<DoseLog>;

      // Calculate Nutrition Stats
      int cals = 0, protein = 0, carbs = 0, fat = 0;
      int workoutCals = 0;
      for (final meal in meals) {
        cals += meal.calories ?? 0;
        protein += meal.proteinGrams ?? 0;
        carbs += meal.carbsGrams ?? 0;
        fat += meal.fatGrams ?? 0;
      }
      for (final workout in workouts) {
        workoutCals += workout.caloriesBurned ?? 0;
      }

      // Fetch HealthKit Data (only if today, or if we have historical support)
      // For now, HealthKitService mostly fetches "now" or specific queries.
      // Assuming we want data for [date].
      int hkSteps = 0;
      int hkActiveCals = 0;
      int hkBasalCals = 0;
      int hkExerciseMins = 0;
      double hkDistance = 0;
      double hkWater = 0;
      int? hkHR;
      int hkSleepMinutes = 0;

      bool authorized = await healthKit.requestAuthorization();
      if (authorized) {
        final hkResults = await Future.wait([
          healthKit.getSteps(date),
          healthKit.getActiveCalories(date),
          healthKit.getBasalCalories(date),
          healthKit.getExerciseMinutes(date),
          healthKit.getDistance(date),
          healthKit.getWaterIntake(date),
          healthKit.getRestingHeartRate(),
          healthKit.getLastNightSleep(),
        ]);

        hkSteps = hkResults[0] as int;
        hkActiveCals = (hkResults[1] as double).toInt();
        hkBasalCals = (hkResults[2] as double).toInt();
        hkExerciseMins = hkResults[3] as int;
        hkDistance = hkResults[4] as double;
        hkWater = hkResults[5] as double;
        hkHR = hkResults[6] as int?;
        final sleepData = hkResults[7] as SleepData?;
        hkSleepMinutes = sleepData?.totalDuration.inMinutes ?? 0;
      }

      state = state.copyWith(
        meals: meals,
        workouts: workouts,
        doses: doses,
        isLoading: false,
        caloriesConsumed: cals,
        proteinConsumed: protein,
        carbsConsumed: carbs,
        fatConsumed: fat,
        caloriesBurned: workoutCals,
        steps: hkSteps,
        activeCalories: hkActiveCals,
        basalCalories: hkBasalCals,
        exerciseMinutes: hkExerciseMins,
        distance: hkDistance,
        waterLiters: hkWater,
        restingHeartRate: hkHR,
        sleepDurationMinutes: hkSleepMinutes,
      );

      // Trigger image generation checks (fire and forget)
      _checkForMissingImages(meals, workouts);
    } catch (e, stack) {
      Logger.error('Error loading body data',
          tag: _tag, error: e, stackTrace: stack);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setPanelProgress(double progress) {
    final clamped = progress.clamp(0.0, 1.0);
    state = state.copyWith(panelProgress: clamped);
  }

  Future<void> _checkForMissingImages(
      List<MealLog> meals, List<WorkoutLog> workouts) async {
    for (final meal in meals) {
      if ((meal.photoPath == null || meal.photoPath!.isEmpty) &&
          meal.description != null &&
          meal.description!.isNotEmpty) {
        Logger.info('Missing image for meal ${meal.id}, queuing generation',
            tag: _tag);
        _generateMealImage(meal);
      }
    }
  }

  Future<void> _generateMealImage(MealLog meal) async {
    try {
      final imageService = ref.read(imageServiceProvider);
      final prompt =
          "A delicious, high-quality food photography shot of ${meal.description}. Pro lighting, 8k, appetizing.";

      final imageResult = await imageService.generateImage(
        prompt: prompt,
        size: ImageSize.square,
      );
      final imagePath = await _saveMealImage(meal, imageResult.bytes);

      final updatedMeal = meal.copyWith(photoPath: imagePath);
      await ref.read(mealRepositoryProvider).updateMeal(updatedMeal);

      // Refresh local state if still valid
      if (state.meals.any((m) => m.id == meal.id)) {
        final updatedMeals =
            state.meals.map((m) => m.id == meal.id ? updatedMeal : m).toList();
        state = state.copyWith(meals: updatedMeals);
      }
    } catch (e) {
      Logger.error('Failed to generate image for meal ${meal.id}',
          tag: _tag, error: e);
    }
  }

  Future<String> _saveMealImage(MealLog meal, Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final id = meal.id ?? DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/images/meals/meal_$id.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file.path;
  }
}

final bodyViewModelProvider = NotifierProvider<BodyViewModel, BodyState>(
  BodyViewModel.new,
);
