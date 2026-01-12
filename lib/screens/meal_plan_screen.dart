import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../models/tracking/meal_log.dart';
import '../widgets/widgets.dart';

/// Meal Plan screen showing today's meals, schedule, and meal history.
/// Reuses: WeekDayPicker, MealTimelineRow, MacroPillRow
class MealPlanScreen extends StatefulWidget {
  /// Optional meal to highlight/scroll to on open
  final MealLog? highlightedMeal;

  const MealPlanScreen({super.key, this.highlightedMeal});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen>
    with SingleTickerProviderStateMixin {
  static const double _mealIconSize = 48;
  static const double _mealLineHeight = 2;
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  List<MealLog> _allMeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMeals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMeals() async {
    try {
      final mealsJson =
          await rootBundle.loadString('data/tracking/meal_log.json');
      final List<dynamic> mealsList = json.decode(mealsJson);
      _allMeals = mealsList.map((j) => MealLog.fromJson(j)).toList();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading meals: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  List<MealLog> get _selectedDateMeals {
    return _allMeals.where((m) {
      return m.timestamp.year == _selectedDate.year &&
          m.timestamp.month == _selectedDate.month &&
          m.timestamp.day == _selectedDate.day;
    }).toList();
  }

  /// Group meals by date for history view
  Map<String, List<MealLog>> get _mealsByDate {
    final grouped = <String, List<MealLog>>{};
    for (var meal in _allMeals) {
      final dateKey = _formatDateKey(meal.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(meal);
    }
    return grouped;
  }

  String _formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatDateDisplay(String dateKey) {
    final parts = dateKey.split('-');
    final dt =
        DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.panelWhite,
      appBar: AppBar(
        backgroundColor: ThemeConstants.panelWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ThemeConstants.textOnLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Meal Plan',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ThemeConstants.textOnLight,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: ThemeConstants.textOnLight,
          unselectedLabelColor: ThemeConstants.textSecondary,
          indicatorColor: ThemeConstants.accentBlue,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Plan'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPlanTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildPlanTab() {
    final meals = _selectedDateMeals;
    final totalProtein = meals.fold(0, (sum, m) => sum + (m.proteinGrams ?? 0));
    final totalCarbs = meals.fold(0, (sum, m) => sum + (m.carbsGrams ?? 0));
    final totalFat = meals.fold(0, (sum, m) => sum + (m.fatGrams ?? 0));
    final isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week picker at the top
          WeekDayPicker(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
            },
          ),
          const SizedBox(height: 24),

          // Visual Meal Plan Card
          _buildMealPlanCard(meals),
          const SizedBox(height: 24),

          // Macros row
          MacroPillRow(
            protein: totalProtein.toDouble(),
            fats: totalFat.toDouble(),
            carbs: totalCarbs.toDouble(),
          ),
          const SizedBox(height: 24),

          // Section header
          Text(
            isToday
                ? 'TODAY\'S MEALS'
                : 'MEALS FOR ${_formatDateDisplay(_formatDateKey(_selectedDate)).toUpperCase()}',
            style: ThemeConstants.captionStyle.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Meal cards
          if (meals.isEmpty)
            _buildEmptyState('No meals on this day')
          else
            ...meals.map((meal) {
              final now = DateTime.now();
              String? timeUntil;
              if (meal.timestamp.isAfter(now)) {
                final diff = meal.timestamp.difference(now);
                final hours = diff.inHours;
                final minutes = diff.inMinutes % 60;
                timeUntil = 'in ${hours}h ${minutes}m';
              }
              return MealCard(
                meal: meal,
                timeUntil: timeUntil,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final sortedKeys = _mealsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Calculate insights
    final totalMeals = _allMeals.length;
    final totalCalories = _allMeals.fold(0, (sum, m) => sum + (m.calories ?? 0));
    final totalProtein = _allMeals.fold(0, (sum, m) => sum + (m.proteinGrams ?? 0));
    final avgCaloriesPerDay = sortedKeys.isNotEmpty 
        ? (totalCalories / sortedKeys.length).round() 
        : 0;

    // Count meal types
    final mealTypeCounts = <MealType, int>{};
    for (final meal in _allMeals) {
      mealTypeCounts[meal.type] = (mealTypeCounts[meal.type] ?? 0) + 1;
    }
    final topMealTypes = mealTypeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Find frequently described foods
    final foodCounts = <String, int>{};
    for (final meal in _allMeals) {
      if (meal.description != null && meal.description!.isNotEmpty) {
        // Simple word extraction
        final words = meal.description!.toLowerCase().split(RegExp(r'\s+'));
        for (final word in words) {
          if (word.length > 3) {
            foodCounts[word] = (foodCounts[word] ?? 0) + 1;
          }
        }
      }
    }
    final topFoods = foodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insights summary cards
          _buildInsightsSummary(
            totalMeals: totalMeals,
            avgCaloriesPerDay: avgCaloriesPerDay,
            totalProtein: totalProtein,
          ),
          const SizedBox(height: 24),

          // Meal Categories section
          if (topMealTypes.isNotEmpty) ...[
            _buildSectionHeader('MEAL CATEGORIES'),
            const SizedBox(height: 12),
            _buildMealCategoriesRow(topMealTypes.take(4).toList()),
            const SizedBox(height: 24),
          ],

          // Frequent Foods section
          if (topFoods.length >= 3) ...[
            _buildSectionHeader('FREQUENTLY EATEN'),
            const SizedBox(height: 12),
            _buildFrequentFoodsChips(topFoods.take(6).toList()),
            const SizedBox(height: 24),
          ],

          // Recent History section
          _buildSectionHeader('RECENT HISTORY'),
          const SizedBox(height: 12),
          ...sortedKeys.take(5).map((dateKey) {
            final meals = _mealsByDate[dateKey]!;
            final totalCals = meals.fold(0, (sum, m) => sum + (m.calories ?? 0));
            return _buildHistoryDayCard(dateKey, meals, totalCals);
          }),
        ],
      ),
    );
  }

  Widget _buildInsightsSummary({
    required int totalMeals,
    required int avgCaloriesPerDay,
    required int totalProtein,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildInsightCard(
            '🍽️',
            '$totalMeals',
            'meals logged',
            const Color(0xFFE3F2FD),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightCard(
            '🔥',
            '$avgCaloriesPerDay',
            'avg kcal/day',
            const Color(0xFFFFF3E0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightCard(
            '💪',
            '${totalProtein}g',
            'total protein',
            const Color(0xFFE8F5E9),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String emoji,
    String value,
    String label,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ThemeConstants.textOnLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ThemeConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: ThemeConstants.captionStyle.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMealCategoriesRow(List<MapEntry<MealType, int>> categories) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_getMealIcon(entry.key.name), style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ThemeConstants.textOnLight,
                    ),
                  ),
                  Text(
                    '${entry.value} meals',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequentFoodsChips(List<MapEntry<String, int>> foods) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: foods.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${entry.key} (${entry.value}x)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ThemeConstants.textOnLight,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryDayCard(String dateKey, List<MealLog> meals, int totalCals) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateDisplay(dateKey),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.textOnLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCals kcal',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Meal icons row
          Row(
            children: meals.map((meal) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _getMealIcon(meal.type.name),
                style: const TextStyle(fontSize: 24),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Meal descriptions
          Text(
            meals.map((m) => m.description ?? m.type.displayName).join(' • '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: ThemeConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Visual Meal Plan Card with horizontal timeline (matching reference design)
  Widget _buildMealPlanCard(List<MealLog> meals) {
    // Calculate next meal info
    final now = DateTime.now();
    String nextMealText = '';

    // Find next upcoming meal
    final upcomingMeals = meals.where((m) => m.timestamp.isAfter(now)).toList();
    if (upcomingMeals.isNotEmpty) {
      final nextMeal = upcomingMeals.first;
      final diff = nextMeal.timestamp.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final mealType = nextMeal.type.displayName;
      nextMealText = '$mealType in ${hours}h ${minutes}m';
    } else {
      nextMealText = 'All meals logged';
    }

    // Default meal slots for the day (breakfast, lunch, dinner)
    // These show the scheduled meals - icons are always visible, completion state is tracked
    final mealSlots = [
      _MealSlot(
          time: '8:30',
          icon: _getMealIcon('breakfast'),
          type: 'Breakfast',
          isComplete: false),
      _MealSlot(
          time: '13:00',
          icon: _getMealIcon('lunch'),
          type: 'Lunch',
          isComplete: false),
      _MealSlot(
          time: '18:00',
          icon: _getMealIcon('dinner'),
          type: 'Dinner',
          isComplete: false),
    ];
    final dailyMealCount = mealSlots.length;
    final lineTopPadding = (_mealIconSize / 2) - (_mealLineHeight / 2);

    // Mark completed meals based on what's logged
    for (var meal in meals) {
      final hour = meal.timestamp.hour;
      if (hour < 11) {
        mealSlots[0] = _MealSlot(
          time: _formatTimeShort(meal.timestamp),
          icon: _getMealIcon(meal.type.name),
          type: meal.type.displayName,
          isComplete: true,
        );
      } else if (hour < 16) {
        mealSlots[1] = _MealSlot(
          time: _formatTimeShort(meal.timestamp),
          icon: _getMealIcon(meal.type.name),
          type: meal.type.displayName,
          isComplete: true,
        );
      } else {
        mealSlots[2] = _MealSlot(
          time: _formatTimeShort(meal.timestamp),
          icon: _getMealIcon(meal.type.name),
          type: meal.type.displayName,
          isComplete: true,
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row: Title + Next meal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily $dailyMealCount-Meal Plan',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.textOnLight,
                ),
              ),
              Text(
                nextMealText,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ThemeConstants.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Visual timeline with meal icons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < mealSlots.length; i++) ...[
                  _buildMealNode(mealSlots[i]),
                  if (i < mealSlots.length - 1)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: lineTopPadding),
                        child: Container(
                          height: _mealLineHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: mealSlots[i].isComplete
                                ? const Color(0xFFFFB347)
                                : const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info tags row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoTag('📅', 'Mo - Fr'),
              const SizedBox(width: 16),
              _buildInfoTag(
                  '🍽️', '$dailyMealCount meals daily'),
              const SizedBox(width: 16),
              _buildInfoTag('👨‍👩‍👧‍👦', 'for 2 adults'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealNode(_MealSlot slot) {
    return Column(
      children: [
        // Meal icon with completion indicator
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _mealIconSize,
              height: _mealIconSize,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: slot.isComplete
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                      : const Color(0xFFE8E8E8),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  slot.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            // Checkmark for completed meals
            if (slot.isComplete)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Time label
        Text(
          slot.time,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ThemeConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTag(String icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ThemeConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatTimeShort(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Text(
        message,
        style: ThemeConstants.captionStyle.copyWith(
          color: ThemeConstants.textMuted,
        ),
      ),
    );
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

/// Helper class for meal timeline visualization
class _MealSlot {
  final String time;
  final String icon;
  final String type;
  final bool isComplete;

  const _MealSlot({
    required this.time,
    required this.icon,
    required this.type,
    required this.isComplete,
  });
}
