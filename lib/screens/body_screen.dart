import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../models/tracking/meal_log.dart';
import '../models/tracking/dose_log.dart';
import '../models/tracking/workout_log.dart';
import '../models/tracking/supplement.dart';
import '../models/tracking/exercise_type.dart';
import '../models/tracking/exercise_set.dart';
import '../widgets/widgets.dart';
import '../widgets/effects/breathing_card.dart';
import '../services/health_kit_service.dart';
import '../providers/service_providers.dart';
import 'meal_plan_screen.dart';

class BodyScreen extends ConsumerStatefulWidget {
  final double panelVisibility;

  const BodyScreen({super.key, this.panelVisibility = 1.0});

  @override
  ConsumerState<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends ConsumerState<BodyScreen> {
  // Data State
  List<MealLog> _meals = [];
  List<DoseLog> _doses = [];
  List<WorkoutLog> _workouts = [];
  // Supplements map needed for DoseCard details
  Map<String, Supplement> _supplements = {};

  // HealthKit Data
  bool _healthKitAvailable = false;
  int _healthKitSteps = 0;
  double _healthKitActiveCalories = 0;
  double _healthKitBasalCalories = 0;
  List<WorkoutData> _healthKitWorkouts = [];
  int _healthKitExerciseMinutes = 0;
  double _healthKitDistance = 0; // in meters
  double _healthKitWater = 0; // in liters
  int? _healthKitRestingHR;

  // Nutrition Aggregates
  int _caloriesConsumed = 0;
  final int _caloriesGoal = 2500; // Default goal
  int _caloriesBurned = 0;
  double _proteinConsumed = 0;
  final double _proteinGoal = 180;
  double _fatsConsumed = 0;
  final double _fatsGoal = 80;
  double _carbsConsumed = 0;
  final double _carbsGoal = 250;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load HealthKit and JSON data in parallel
      await Future.wait([
        _loadHealthKitData(),
        _loadJsonData(),
      ]);

      // Use HealthKit calories burned if available
      if (_healthKitAvailable && _healthKitActiveCalories > 0) {
        _caloriesBurned = _healthKitActiveCalories.toInt();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading body data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHealthKitData() async {
    try {
      final healthKit = ref.read(healthKitServiceProvider);
      final authorized = await healthKit.requestAuthorization();

      if (!authorized) {
        debugPrint('[BodyScreen] HealthKit not authorized');
        return;
      }

      _healthKitAvailable = true;
      final now = DateTime.now();

      // Fetch all health data in parallel
      final results = await Future.wait([
        healthKit.getSteps(now),
        healthKit.getActiveCalories(now),
        healthKit.getBasalCalories(now),
        healthKit.getTodayWorkouts(),
        healthKit.getExerciseMinutes(now),
        healthKit.getDistance(now),
        healthKit.getWaterIntake(now),
        healthKit.getRestingHeartRate(),
      ]);

      _healthKitSteps = results[0] as int;
      _healthKitActiveCalories = results[1] as double;
      _healthKitBasalCalories = results[2] as double;
      _healthKitWorkouts = results[3] as List<WorkoutData>;
      _healthKitExerciseMinutes = results[4] as int;
      _healthKitDistance = results[5] as double;
      _healthKitWater = results[6] as double;
      _healthKitRestingHR = results[7] as int?;

      debugPrint('[BodyScreen] HealthKit data loaded: '
          'steps=$_healthKitSteps, '
          'active=${_healthKitActiveCalories.toInt()}kcal, '
          'workouts=${_healthKitWorkouts.length}');
    } catch (e) {
      debugPrint('[BodyScreen] HealthKit error: $e');
    }
  }

  Future<void> _loadJsonData() async {
    // 1. Load Meals
    final mealsJson =
        await rootBundle.loadString('data/tracking/meal_log.json');
    final List<dynamic> mealsList = json.decode(mealsJson);
    _meals = mealsList.map((j) => MealLog.fromJson(j)).toList();

    // 2. Load Doses
    final dosesJson =
        await rootBundle.loadString('data/tracking/dose_log.json');
    final List<dynamic> dosesList = json.decode(dosesJson);
    _doses = dosesList.map((j) => DoseLog.fromJson(j)).toList();

    // 3. Load Supplements (for details)
    final suppsJson =
        await rootBundle.loadString('data/tracking/supplement.json');
    final List<dynamic> suppsList = json.decode(suppsJson);
    final supps = suppsList.map((j) => Supplement.fromJson(j)).toList();
    _supplements = {for (var s in supps) s.id.toString(): s};

    // 4. Load Exercise Catalog
    final exercisesJson =
        await rootBundle.loadString('data/tracking/exercise_type.json');
    final List<dynamic> exercisesList = json.decode(exercisesJson);
    final exerciseCatalog = {
      for (var j in exercisesList) j['id'].toString(): ExerciseType.fromJson(j)
    };

    // 5. Load Exercise Sets
    final setsJson =
        await rootBundle.loadString('data/tracking/exercise_set.json');
    final List<dynamic> setsList = json.decode(setsJson);
    final allSets = setsList.map((j) {
      final set = ExerciseSet.fromJson(j);
      final type = exerciseCatalog[set.exerciseTypeId.toString()];
      return set.copyWith(exercise: type);
    }).toList();

    // 6. Load Workouts & Join Sets
    final workoutsJson =
        await rootBundle.loadString('data/tracking/workout_log.json');
    final List<dynamic> workoutsList = json.decode(workoutsJson);
    _workouts = workoutsList.map((j) {
      final workout = WorkoutLog.fromJson(j);
      final workoutSets =
          allSets.where((s) => s.workoutLogId == workout.id).toList();
      return workout.copyWith(sets: workoutSets);
    }).toList();

    // 7. Calculate Nutrition Totals
    _calculateNutrition();
  }

  void _calculateNutrition() {
    _caloriesConsumed = 0;
    _proteinConsumed = 0;
    _fatsConsumed = 0;
    _carbsConsumed = 0;

    for (var meal in _meals) {
      _caloriesConsumed += meal.calories ?? 0;
      _proteinConsumed += meal.proteinGrams ?? 0;
      _fatsConsumed += meal.fatGrams ?? 0;
      _carbsConsumed += meal.carbsGrams ?? 0;
    }

    // Simple estimation for burned from workouts
    _caloriesBurned =
        _workouts.fold(0, (sum, w) => sum + (w.caloriesBurned?.toInt() ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final screenHeight = MediaQuery.of(context).size.height;
    final minPanelHeight = screenHeight * 0.38;
    final maxPanelHeight = screenHeight * 0.78;

    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      draggableBottomPanel: true,
      bottomPanelMinHeight: minPanelHeight,
      bottomPanelMaxHeight: maxPanelHeight,
      bottomPanelShowHandle: true,
      bottomPanelPulseEnabled: true,
      bottomPanel: _buildBottomPanelContent(),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Space for nav bar
            const SizedBox(height: 70),

            // Hero Content: Nutrition Overview (centered)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildHeroContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The hero content (displayed in the dark breathing card)
  Widget _buildHeroContent() {
    final caloriesRemaining =
        _caloriesGoal - _caloriesConsumed + _caloriesBurned;
    final progress = (_caloriesConsumed / _caloriesGoal).clamp(0.0, 1.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Large calorie number
        Text(
          '$caloriesRemaining',
          style: GoogleFonts.inter(
            fontSize: 72,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            letterSpacing: -2,
          ),
        ),
        Text(
          'calories remaining',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 24),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 1.0 ? Colors.orange : ThemeConstants.accentBlue,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),

        // Sub-stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMiniStat('Eaten', '$_caloriesConsumed'),
            _buildMiniStat('Burned', '$_caloriesBurned'),
            _buildMiniStat('Goal', '$_caloriesGoal'),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  /// Bottom panel content (white panel with logs)
  Widget _buildBottomPanelContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HealthKit Activity Stats - floating style at top of panel
        if (_healthKitAvailable) ...[
          Transform.translate(
            offset: const Offset(0, -20),
            child: _buildHealthKitStatsRow(),
          ),
          const SizedBox(height: 8),
        ],

        // Schedule / Week Day Picker
        WeekDayPicker(
          selectedDate: DateTime.now(),
          headerText: "Let's make progress today!",
          onDateSelected: (date) {
            // TODO: Filter data by selected date
          },
        ),

        const SizedBox(height: 20),

        // Macros Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMacroColumn('Protein', _proteinConsumed, _proteinGoal,
                ThemeConstants.accentBlue),
            _buildMacroColumn(
                'Carbs', _carbsConsumed, _carbsGoal, Colors.amber),
            _buildMacroColumn('Fat', _fatsConsumed, _fatsGoal, Colors.pink),
          ],
        ),

        const SizedBox(height: 24),

        // Today's Meals
        _buildSectionHeaderWithAction('TODAY\'S MEALS', 'See all', _openMealPlan),
        const SizedBox(height: 12),
        ..._meals.asMap().entries.map((entry) {
          final index = entry.key;
          final meal = entry.value;
          return MealTimelineRow(
            time: _formatTime(meal.timestamp),
            icon: _getMealIcon(meal.type.name),
            mealName: meal.description ?? 'Meal',
            calories: '${meal.calories ?? 0} kcal',
            isFirst: index == 0,
            isLast: index == _meals.length - 1,
            isComplete: true,
            onTap: () => _openMealPlan(meal: meal),
          );
        }),

        const SizedBox(height: 24),

        // Supplements
        _buildSectionHeader('SUPPLEMENTS'),
        const SizedBox(height: 12),
        ..._doses.map((dose) {
          final supp = _supplements[dose.supplementId.toString()];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: DoseCard(
              supplementName: supp?.name ?? 'Supplement',
              dosage: '${dose.amountMg}${dose.unit ?? "mg"}',
              scheduledTime: _formatTime(dose.timestamp),
              isTaken: true,
              onToggle: () {},
            ),
          );
        }),

        const SizedBox(height: 24),

        // Activity - Combine HealthKit workouts + JSON workouts
        _buildSectionHeader('ACTIVITY'),
        const SizedBox(height: 12),
        _buildActivitySection(),
      ],
    );
  }

  /// Build HealthKit stats row (steps, distance, exercise, water, HR)
  Widget _buildHealthKitStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeConstants.glassBackgroundWeak,
        borderRadius: ThemeConstants.borderRadius,
        border: Border.all(color: ThemeConstants.glassBorderWeak),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHealthStat('👟', _healthKitSteps.toString(), 'steps'),
          _buildHealthStat(
              '🔥',
              (_healthKitActiveCalories + _healthKitBasalCalories)
                  .toInt()
                  .toString(),
              'kcal'),
          _buildHealthStat(
              '📍', (_healthKitDistance / 1000).toStringAsFixed(1), 'km'),
          _buildHealthStat('⏱️', _healthKitExerciseMinutes.toString(), 'min'),
          if (_healthKitWater > 0)
            _buildHealthStat('💧', _healthKitWater.toStringAsFixed(1), 'L'),
          if (_healthKitRestingHR != null)
            _buildHealthStat('❤️', _healthKitRestingHR.toString(), 'bpm'),
        ],
      ),
    );
  }

  Widget _buildHealthStat(String emoji, String value, String unit) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ThemeConstants.textOnLight,
          ),
        ),
        Text(
          unit,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: ThemeConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Build activity section combining HealthKit + JSON workouts
  Widget _buildActivitySection() {
    // Combine HealthKit workouts with JSON workouts
    final hasHealthKitWorkouts = _healthKitWorkouts.isNotEmpty;
    final hasJsonWorkouts = _workouts.isNotEmpty;

    if (!hasHealthKitWorkouts && !hasJsonWorkouts) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeConstants.glassBackgroundWeak,
          borderRadius: ThemeConstants.borderRadius,
          border: Border.all(color: ThemeConstants.glassBorderWeak),
        ),
        child: Center(
          child: Text(
            'No workouts recorded today',
            style: GoogleFonts.inter(
              color: ThemeConstants.textSecondary,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // HealthKit workouts first (from Apple Watch / Health app)
          ..._healthKitWorkouts.asMap().entries.map((entry) {
            final index = entry.key;
            final workout = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                  right:
                      index < _healthKitWorkouts.length - 1 || hasJsonWorkouts
                          ? 12
                          : 0),
              child: WorkoutCard(
                title: _formatWorkoutType(workout.type),
                duration: '${workout.duration.inMinutes} min',
                exerciseCount: 0, // HealthKit doesn't track exercise count
                calories: workout.caloriesBurned?.toInt(),
                isFeatured: index == 0,
              ),
            );
          }),
          // JSON workouts (manually logged)
          ..._workouts.asMap().entries.map((entry) {
            final index = entry.key;
            final workout = entry.value;
            return Padding(
              padding:
                  EdgeInsets.only(right: index < _workouts.length - 1 ? 12 : 0),
              child: WorkoutCard(
                title: workout.name ?? 'Workout',
                duration: '${workout.durationMinutes ?? 0} min',
                exerciseCount: workout.sets?.length ?? 0,
                calories: workout.caloriesBurned?.toInt(),
                isFeatured: !hasHealthKitWorkouts && index == 0,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Format HealthKit workout type to display name
  String _formatWorkoutType(String type) {
    // Convert RUNNING to Running, TRADITIONAL_STRENGTH_TRAINING to Strength Training, etc.
    return type
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  Widget _buildMacroColumn(
      String label, double consumed, double goal, Color color) {
    final progress = (consumed / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        Text(
          '${consumed.toInt()}g',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ThemeConstants.textOnLight,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: ThemeConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ThemeConstants.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSectionHeaderWithAction(
      String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ThemeConstants.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Row(
            children: [
              Text(
                actionText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.accentBlue,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: ThemeConstants.accentBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openMealPlan({MealLog? meal}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MealPlanScreen(highlightedMeal: meal),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _getMealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🥗';
      case 'dinner':
        return '🥩';
      case 'snack':
        return '🍎';
      default:
        return '🍽️';
    }
  }
}
