import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../models/tracking/meal_log.dart';
import '../widgets/widgets.dart';
import '../widgets/effects/breathing_card.dart';
import '../widgets/dashboard/body_stats_card.dart';
import '../providers/viewmodels/viewmodels.dart';
import 'meal_plan_screen.dart';

class BodyScreen extends ConsumerStatefulWidget {
  final double panelVisibility;

  const BodyScreen({super.key, this.panelVisibility = 1.0});

  @override
  ConsumerState<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends ConsumerState<BodyScreen> {
  @override
  void initState() {
    super.initState();
    // Verify data is loaded for today on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bodyViewModelProvider.notifier).selectDate(DateTime.now());
    });
  }

  void _navigateToBodyDetails() {
    // TODO: Navigate to BodyMetricsDetailScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Body details coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bodyViewModelProvider);
    final viewModel = ref.read(bodyViewModelProvider.notifier);

    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;

    // Min panel: 38% of screen
    final minPanelHeight = screenHeight * 0.38;
    // Max panel: Leave room for nav bar + compact stats + padding
    final maxPanelHeight = screenHeight - safeTop - 70 - 100;

// Calculate the stats card position using BOTTOM coordinate
    // This is simpler: card sits N pixels above the panel top
    // Card bottom = distance from screen bottom
    // At rest: card's bottom edge is 20px above panel top
    // At expanded: card sits 16px above the expanded panel
    final cardBottomAtRest = minPanelHeight + 20;
    final cardBottomAtExpanded = maxPanelHeight + 16;

    // Smoothly interpolate using bottom coordinate
    final cardBottom = cardBottomAtRest +
        (state.panelProgress * (cardBottomAtExpanded - cardBottomAtRest));

    // Content crossfade (full card content vs compact bar content)
    final showFullCard = state.panelProgress < 0.6;

    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      draggableBottomPanel: true,
      bottomPanelMinHeight: minPanelHeight,
      bottomPanelMaxHeight: maxPanelHeight,
      bottomPanelShowHandle: true,
      bottomPanelPulseEnabled: true,
      bottomPanelProgressChanged: (progress) {
        viewModel.setPanelProgress(progress);
      },
      bottomPanel: _buildBottomPanelContent(context, state, viewModel),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Single animated stats card that moves and transforms
            if (!state.isLoading)
              Positioned(
                left: 20,
                right: 20,
                bottom: cardBottom,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: showFullCard
                      ? BodyStatsCard(
                          key: const ValueKey('full'),
                          trainingReadiness: state.trainingReadiness,
                          caloriesConsumed: state.caloriesConsumed,
                          caloriesBurned: state.caloriesBurned > 0
                              ? state.caloriesBurned
                              : state.activeCalories,
                          sleepDurationMinutes: state.sleepDurationMinutes,
                          currentWeight: 185.0,
                          currentBodyFat: 18.0,
                          onTap: _navigateToBodyDetails,
                        )
                      : CompactBodyStatsBar(
                          key: const ValueKey('compact'),
                          caloriesConsumed: state.caloriesConsumed,
                          sleepDurationMinutes: state.sleepDurationMinutes,
                          caloriesBurned: state.caloriesBurned > 0
                              ? state.caloriesBurned
                              : state.activeCalories,
                          onTap: _navigateToBodyDetails,
                        ),
                ),
              ),

            // Loading indicator
            if (state.isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  /// Bottom panel content (white panel with logs)
  Widget _buildBottomPanelContent(
      BuildContext context, BodyState state, BodyViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week Day Picker
        WeekDayPicker(
          selectedDate: state.selectedDate,
          headerText: "Let's make progress today!",
          onDateSelected: (date) {
            viewModel.selectDate(date);
          },
        ),

        const SizedBox(height: 20),

        /* 
           Macros Row - Keeping this as it gives quick breakdown 
           even though stats card has Net Cals.
        */
        _buildMacrosRow(state),

        const SizedBox(height: 24),

        // Meals
        _buildSectionHeaderWithAction(
            'MEALS', 'See all', () => _openMealPlan(context)),
        const SizedBox(height: 12),
        if (state.meals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: Text('No meals logged yet',
                    style: GoogleFonts.inter(
                        color: ThemeConstants.textSecondary))),
          )
        else
          ...state.meals.asMap().entries.map((entry) {
            final index = entry.key;
            final meal = entry.value;
            return MealTimelineRow(
              time: _formatTime(meal.timestamp),
              icon: _getMealIcon(meal.type.name),
              mealName: meal.description ?? 'Meal',
              calories: '${meal.calories ?? 0} kcal',
              isFirst: index == 0,
              isLast: index == state.meals.length - 1,
              isComplete: true,
              onTap: () => _openMealPlan(context, meal: meal),
            );
          }),

        const SizedBox(height: 24),

        // Supplements (Doses)
        _buildSectionHeader('SUPPLEMENTS'),
        const SizedBox(height: 12),
        if (state.doses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: Text('No supplements taken',
                    style: GoogleFonts.inter(
                        color: ThemeConstants.textSecondary))),
          )
        else
          ...state.doses.map((dose) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: DoseCard(
                supplementName: 'Supplement ${dose.supplementId}',
                dosage: '${dose.amountMg}${dose.unit ?? "mg"}',
                scheduledTime: _formatTime(dose.timestamp),
                isTaken: true,
                onToggle: () {},
              ),
            );
          }),

        const SizedBox(height: 24),

        // Activity - Combine HealthKit workouts + logged workouts
        // Assuming BodyState has merged list or we display separately
        _buildSectionHeader('ACTIVITY'),
        const SizedBox(height: 12),
        _buildActivitySection(state),
      ],
    );
  }

  Widget _buildMacrosRow(BodyState state) {
    // Goals (hardcoded for now, should come from UserProfile)
    const double proteinGoal = 180;
    const double fatsGoal = 80;
    const double carbsGoal = 250;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMacroColumn('Protein', state.proteinConsumed.toDouble(),
            proteinGoal, ThemeConstants.accentBlue),
        _buildMacroColumn(
            'Carbs', state.carbsConsumed.toDouble(), carbsGoal, Colors.amber),
        _buildMacroColumn(
            'Fat', state.fatConsumed.toDouble(), fatsGoal, Colors.pink),
      ],
    );
  }

  Widget _buildActivitySection(BodyState state) {
    final workouts = state.workouts;
    if (workouts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeConstants.glassBackgroundWeak,
          borderRadius: ThemeConstants.borderRadius,
          border: Border.all(color: ThemeConstants.glassBorderWeak),
        ),
        child: Center(
          child: Text(
            'No workouts recorded',
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
        children: workouts.asMap().entries.map((entry) {
          final index = entry.key;
          final workout = entry.value;
          return Padding(
            padding:
                EdgeInsets.only(right: index < workouts.length - 1 ? 12 : 0),
            child: WorkoutCard(
              title: workout.name ?? workout.type.displayName,
              duration: '${workout.durationMinutes ?? 0} min',
              exerciseCount: 0, // workout.sets?.length ?? 0
              calories: workout.caloriesBurned,
              isFeatured: index == 0,
            ),
          );
        }).toList(),
      ),
    );
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

  void _openMealPlan(BuildContext context, {MealLog? meal}) {
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
