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
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    try {
      // 1. Load Meals
      final mealsJson = await rootBundle.loadString('data/tracking/meal_log.json');
      final List<dynamic> mealsList = json.decode(mealsJson);
      _meals = mealsList.map((j) => MealLog.fromJson(j)).toList();

      // 2. Load Doses
      final dosesJson = await rootBundle.loadString('data/tracking/dose_log.json');
      final List<dynamic> dosesList = json.decode(dosesJson);
      _doses = dosesList.map((j) => DoseLog.fromJson(j)).toList();

      // 3. Load Supplements (for details)
      final suppsJson = await rootBundle.loadString('data/tracking/supplement.json');
      final List<dynamic> suppsList = json.decode(suppsJson);
      final supps = suppsList.map((j) => Supplement.fromJson(j)).toList();
      _supplements = {for (var s in supps) s.id.toString(): s};

      // 4. Load Exercise Catalog
      final exercisesJson = await rootBundle.loadString('data/tracking/exercise_type.json');
      final List<dynamic> exercisesList = json.decode(exercisesJson);
      final exerciseCatalog = {
        for (var j in exercisesList) 
          j['id'].toString(): ExerciseType.fromJson(j)
      };

      // 5. Load Exercise Sets
      final setsJson = await rootBundle.loadString('data/tracking/exercise_set.json');
      final List<dynamic> setsList = json.decode(setsJson);
      final allSets = setsList.map((j) {
        final set = ExerciseSet.fromJson(j);
        final type = exerciseCatalog[set.exerciseTypeId.toString()];
        return set.copyWith(exercise: type);
      }).toList();

      // 6. Load Workouts & Join Sets
      final workoutsJson = await rootBundle.loadString('data/tracking/workout_log.json');
      final List<dynamic> workoutsList = json.decode(workoutsJson);
      _workouts = workoutsList.map((j) {
        final workout = WorkoutLog.fromJson(j);
        final workoutSets = allSets.where((s) => s.workoutLogId == workout.id).toList();
        return workout.copyWith(sets: workoutSets);
      }).toList();

      // 7. Calculate Nutrition Totals
      _calculateNutrition();

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
    _caloriesBurned = _workouts.fold(0, (sum, w) => sum + (w.caloriesBurned?.toInt() ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      draggableBottomPanel: true,
      bottomPanelMinHeight: MediaQuery.of(context).size.height * 0.38,
      bottomPanelMaxHeight: MediaQuery.of(context).size.height * 0.78,
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
    final caloriesRemaining = _caloriesGoal - _caloriesConsumed + _caloriesBurned;
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
        // Macros Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMacroColumn('Protein', _proteinConsumed, _proteinGoal, ThemeConstants.accentBlue),
            _buildMacroColumn('Carbs', _carbsConsumed, _carbsGoal, Colors.amber),
            _buildMacroColumn('Fat', _fatsConsumed, _fatsGoal, Colors.pink),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Today's Meals
        _buildSectionHeader('TODAY\'S MEALS'),
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

        // Activity
        _buildSectionHeader('ACTIVITY'),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _workouts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final workout = _workouts[index];
              return WorkoutCard(
                title: workout.name ?? 'Workout', 
                duration: '${workout.durationMinutes ?? 0} min',
                exerciseCount: workout.sets?.length ?? 0, 
                calories: workout.caloriesBurned?.toInt(),
                isFeatured: index == 0,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMacroColumn(String label, double consumed, double goal, Color color) {
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

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _getMealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return '🍳';
      case 'lunch': return '🥗';
      case 'dinner': return '🥩';
      case 'snack': return '🍎';
      default: return '🍽️';
    }
  }
}
