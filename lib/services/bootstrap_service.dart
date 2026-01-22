import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../config/azure_ai_config.dart';
import '../database/app_database.dart';
import '../models/mantra.dart';
import '../models/tracking/supplement.dart';
import '../models/tracking/workout_log.dart';
import '../utils/logger.dart';
import 'azure_agent_service.dart';
import 'health_kit_service.dart';
import 'user_context_service.dart';
import 'weather_service.dart';

/// Bootstrap Service - runs at app startup to ensure all required data exists
///
/// The LLM reviews:
/// 1. Exercise catalog - generates if missing/incomplete
/// 2. Today's workout plan - generates if needed
/// 3. Meal suggestions - generates based on remaining protein target
/// 4. Supplements - seeds catalog if empty
/// 5. Mantras - seeds from Princeps_Mantras.md if empty
/// 6. Progress toward experiment targets
///
/// Uses tool calling to let the LLM decide what needs to be done.
class BootstrapService {
  static const String _tag = 'BootstrapService';

  final AzureAgentService _agentService;
  final HealthKitService _healthKitService;
  final WeatherService _weatherService;
  final UserContextService _userContextService;
  final AppDatabase _database;

  // Cached data
  Map<String, dynamic>? _genesisProfile;
  List<Map<String, dynamic>> _exerciseCatalog = [];
  List<Map<String, dynamic>> _todayMeals = [];
  List<Map<String, dynamic>> _weekWorkouts = [];
  int _supplementCount = 0;
  int _mantraCount = 0;
  CurrentWeather? _weather;
  SleepData? _lastNightSleep;
  int _healthKitWorkoutMinutes = 0;

  BootstrapService({
    required AzureAgentService agentService,
    required HealthKitService healthKitService,
    required WeatherService weatherService,
    required UserContextService userContextService,
    required AppDatabase database,
  })  : _agentService = agentService,
        _healthKitService = healthKitService,
        _weatherService = weatherService,
        _userContextService = userContextService,
        _database = database;

  /// Run bootstrap check - call this at app startup
  /// Returns a summary of what was done
  Future<BootstrapResult> run() async {
    Logger.info('Starting bootstrap check...', tag: _tag);

    final result = BootstrapResult();

    try {
      // 1. Load all existing data
      await _loadExistingData();

      // 2. Get current context (weather, health)
      await _loadCurrentContext();

      // 3. Build the context for the LLM
      final contextSummary = _buildContextSummary();

      // 4. Run the agent with tools to decide what to do
      final response = await _runBootstrapAgent(contextSummary);

      result.agentSummary = response;
      result.success = true;

      Logger.info('Bootstrap complete', tag: _tag, data: {
        'exerciseCount': _exerciseCatalog.length,
        'todayMeals': _todayMeals.length,
        'weekWorkouts': _weekWorkouts.length,
      });
    } catch (e, stackTrace) {
      Logger.error('Bootstrap failed: $e', tag: _tag, data: {
        'stackTrace': stackTrace.toString(),
      });
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Load all existing data from JSON files
  Future<void> _loadExistingData() async {
    // Genesis profile
    try {
      final profileJson =
          await rootBundle.loadString('data/user/genesis_profile.json');
      _genesisProfile = jsonDecode(profileJson) as Map<String, dynamic>;
      Logger.info('Loaded genesis profile', tag: _tag);
    } catch (e) {
      Logger.warning('No genesis profile found', tag: _tag);
    }

    // Exercise catalog
    try {
      final exerciseJson =
          await rootBundle.loadString('data/tracking/exercise_type.json');
      final list = jsonDecode(exerciseJson) as List;
      _exerciseCatalog = list.cast<Map<String, dynamic>>();
      Logger.info('Loaded ${_exerciseCatalog.length} exercises', tag: _tag);
    } catch (e) {
      Logger.warning('No exercise catalog found', tag: _tag);
    }

    // Today's meals
    try {
      final mealsJson =
          await rootBundle.loadString('data/tracking/meal_log.json');
      final list = jsonDecode(mealsJson) as List;
      final allMeals = list.cast<Map<String, dynamic>>();
      final today = DateTime.now();
      _todayMeals = allMeals.where((m) {
        final ts = DateTime.tryParse(m['timestamp'] as String? ?? '');
        return ts != null &&
            ts.year == today.year &&
            ts.month == today.month &&
            ts.day == today.day;
      }).toList();
      Logger.info('Found ${_todayMeals.length} meals today', tag: _tag);
    } catch (e) {
      Logger.warning('No meal log found', tag: _tag);
    }

    // This week's workouts
    try {
      final workoutsJson =
          await rootBundle.loadString('data/tracking/workout_log.json');
      final list = jsonDecode(workoutsJson) as List;
      final allWorkouts = list.cast<Map<String, dynamic>>();
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      _weekWorkouts = allWorkouts.where((w) {
        final ts = DateTime.tryParse(w['start_time'] as String? ?? '');
        return ts != null && ts.isAfter(weekStart);
      }).toList();
      Logger.info('Found ${_weekWorkouts.length} workouts this week',
          tag: _tag);
    } catch (e) {
      Logger.warning('No workout log found', tag: _tag);
    }

    // Load user context (mantras, supplements from docs)
    await _userContextService.loadContext();

    // Check supplements in database
    try {
      final supplements = await _database.getSupplements();
      _supplementCount = supplements.length;
      Logger.info('Found $_supplementCount supplements in database', tag: _tag);
    } catch (e) {
      Logger.warning('Could not get supplements: $e', tag: _tag);
    }

    // Check mantras in database
    try {
      final mantras = await _database.getMantras();
      _mantraCount = mantras.length;
      Logger.info('Found $_mantraCount mantras in database', tag: _tag);
    } catch (e) {
      Logger.warning('Could not get mantras: $e', tag: _tag);
    }
  }

  /// Load current context from HealthKit and Weather
  Future<void> _loadCurrentContext() async {
    final now = DateTime.now();

    // Weather
    try {
      _weather = await _weatherService.getCurrentWeather();
      Logger.info('Weather: ${_weather?.temperature}°C ${_weather?.condition}',
          tag: _tag);
    } catch (e) {
      Logger.warning('Could not get weather: $e', tag: _tag);
    }

    // Sleep
    try {
      _lastNightSleep = await _healthKitService.getLastNightSleep();
      Logger.info('Sleep: ${_lastNightSleep?.totalDuration.inHours}h',
          tag: _tag);
    } catch (e) {
      Logger.warning('Could not get sleep data: $e', tag: _tag);
    }

    // Exercise minutes
    try {
      _healthKitWorkoutMinutes =
          await _healthKitService.getExerciseMinutes(now);
      Logger.info('Exercise minutes today: $_healthKitWorkoutMinutes',
          tag: _tag);
    } catch (e) {
      Logger.warning('Could not get exercise minutes: $e', tag: _tag);
    }
  }

  /// Build a summary of all context for the LLM
  String _buildContextSummary() {
    final fitness = _genesisProfile?['fitness'] as Map<String, dynamic>?;
    final nutrition = _genesisProfile?['nutrition'] as Map<String, dynamic>?;
    final experiment = _genesisProfile?['experiment'] as Map<String, dynamic>?;
    final identity = _genesisProfile?['identity'] as Map<String, dynamic>?;

    final proteinTarget =
        (nutrition?['proteinTarget'] as Map?)?['grams'] ?? 150;
    final proteinConsumed = _todayMeals.fold<int>(
        0, (sum, m) => sum + ((m['protein_grams'] as int?) ?? 0));
    final proteinRemaining = proteinTarget - proteinConsumed;

    final gymTarget =
        (experiment?['targets'] as Map?)?['gym'] as String? ?? '5x/week';
    final workoutsThisWeek = _weekWorkouts.length;

    final today = DateTime.now();
    final dayOfWeek = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ][today.weekday % 7];

    final doseSchedule =
        (experiment?['protocol'] as Map?)?['schedule'] as List? ?? [];
    final isTrainingDay = doseSchedule.contains(dayOfWeek);

    return '''
=== BOOTSTRAP CONTEXT ===
Date: ${today.toIso8601String().split('T')[0]} ($dayOfWeek)
User: ${identity?['name'] ?? 'User'}

--- CURRENT STATUS ---
Exercise catalog: ${_exerciseCatalog.length} exercises
Today's meals logged: ${_todayMeals.length}
This week's workouts: $workoutsThisWeek
Is training day (per protocol): $isTrainingDay

--- HEALTH DATA ---
Last night sleep: ${_lastNightSleep?.totalDuration.inHours ?? 'unknown'}h ${(_lastNightSleep?.totalDuration.inMinutes ?? 0) % 60}m (score: ${_lastNightSleep?.qualityScore ?? 'N/A'})
Exercise minutes today (HealthKit): $_healthKitWorkoutMinutes

--- WEATHER ---
${_weather != null ? '${_weather!.temperature.round()}°C (${_weather!.temperatureF.round()}°F) - ${_weather!.condition}' : 'Unknown'}
${_weather != null ? 'Good for outdoor cardio: ${_weather!.temperature >= 10 && _weather!.temperature <= 30 && _weather!.condition != 'Rain'}' : ''}

--- EXPERIMENT TARGETS ---
Gym: $gymTarget (done this week: $workoutsThisWeek)
Protein: ${experiment?['targets']?['protein'] ?? '150g/day'} (consumed today: ${proteinConsumed}g, remaining: ${proteinRemaining}g)
Deep work: ${experiment?['targets']?['deepWork'] ?? '6hrs/day'}

--- FITNESS PROFILE ---
Training style: ${fitness?['style'] ?? 'bodybuilding'}
Preferred split: ${(fitness?['splits'] as List?)?.join(', ') ?? 'upper/lower'}
Primary goal: ${(fitness?['goals'] as Map?)?['primary'] ?? 'Improve squat strength'}
Current squat: ${(fitness?['currentMaxes']?['squat'] as Map?)?['weight'] ?? 315} lbs
Target squat: ${(fitness?['goals'] as Map?)?['targetSquat'] ?? 405} lbs
Preferred compounds: ${(fitness?['preferredCompounds'] as List?)?.take(5).join(', ') ?? 'squat, bench, deadlift'}

--- NUTRITION PROFILE ---
Protein target: ${proteinTarget}g/day
Preferred protein sources: ${(nutrition?['preferences']?['preferredProteinSources'] as List?)?.take(4).join(', ') ?? 'chicken, eggs'}

--- DATABASE STATUS ---
Supplements in catalog: $_supplementCount (need at least 3 for basic stack)
Mantras in database: $_mantraCount (have ${_userContextService.allMantras.length} in source documents)

--- WHAT NEEDS CHECKING ---
1. Exercise catalog has ${_exerciseCatalog.length} exercises - need at least 30 compound movements for a complete program
2. Today's workout plan - does one exist for today?
3. Meal suggestions - if protein remaining > 30g, suggest next meal
4. Supplements - if catalog is empty, seed from user context
5. Mantras - if database has < 10, seed from Princeps_Mantras.md
6. Weekly progress - are we on track for experiment targets?
''';
  }

  /// Define the tools the agent can use
  List<ToolDefinition> _getTools() {
    return [
      ToolDefinition(
        name: 'get_data_status',
        description:
            'Get the current status of all data: exercise catalog count, today\'s meals, this week\'s workouts, and what\'s missing.',
        parameters: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'generate_exercise_catalog',
        description:
            'Generate a complete exercise catalog with compound movements for bodybuilding. Only call if catalog has fewer than 30 exercises.',
        parameters: {
          'type': 'object',
          'properties': {
            'focusAreas': {
              'type': 'array',
              'items': {'type': 'string'},
              'description':
                  'Muscle groups to focus on, e.g. ["chest", "back", "legs", "shoulders", "arms"]',
            },
            'includeCompounds': {
              'type': 'boolean',
              'description': 'Whether to include compound movements',
            },
          },
          'required': ['focusAreas', 'includeCompounds'],
        },
      ),
      ToolDefinition(
        name: 'generate_workout_plan',
        description:
            'Generate today\'s workout plan based on training split, recovery status, and goals.',
        parameters: {
          'type': 'object',
          'properties': {
            'workoutType': {
              'type': 'string',
              'description':
                  'Type of workout: "upper", "lower", "push", "pull", "legs", "full_body", "rest"',
            },
            'focusExercise': {
              'type': 'string',
              'description':
                  'Primary exercise to emphasize (e.g. "squat" for squat improvement goal)',
            },
            'durationMinutes': {
              'type': 'integer',
              'description': 'Target workout duration in minutes',
            },
          },
          'required': ['workoutType', 'durationMinutes'],
        },
      ),
      ToolDefinition(
        name: 'suggest_next_meal',
        description:
            'Suggest a meal to hit remaining protein target. Only call if protein remaining > 30g.',
        parameters: {
          'type': 'object',
          'properties': {
            'proteinNeeded': {
              'type': 'integer',
              'description': 'Grams of protein still needed today',
            },
            'mealType': {
              'type': 'string',
              'description':
                  'Type of meal: "breakfast", "lunch", "dinner", "snack"',
            },
            'quickPrep': {
              'type': 'boolean',
              'description': 'Whether the meal should be quick to prepare',
            },
          },
          'required': ['proteinNeeded', 'mealType'],
        },
      ),
      ToolDefinition(
        name: 'check_weekly_progress',
        description:
            'Check progress toward weekly experiment targets and provide status.',
        parameters: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'seed_supplements',
        description:
            'Seed the supplements catalog from user context. Call if supplements count is 0.',
        parameters: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'seed_mantras',
        description:
            'Seed mantras from Princeps_Mantras.md into the database. Call if mantras count < 10.',
        parameters: {
          'type': 'object',
          'properties': {
            'maxMantras': {
              'type': 'integer',
              'description': 'Maximum number of mantras to seed (default: all)',
            },
          },
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'report_complete',
        description:
            'Call this when bootstrap check is complete. Summarize what was reviewed and any actions taken.',
        parameters: {
          'type': 'object',
          'properties': {
            'summary': {
              'type': 'string',
              'description':
                  'Brief summary of bootstrap status and any actions taken',
            },
            'needsAttention': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of items that need user attention',
            },
          },
          'required': ['summary'],
        },
      ),
    ];
  }

  /// Execute a tool call
  Future<String> _executeTool(String name, Map<String, dynamic>? args) async {
    Logger.info('Executing tool: $name', tag: _tag, data: args);

    switch (name) {
      case 'get_data_status':
        return _toolGetDataStatus();

      case 'generate_exercise_catalog':
        return await _toolGenerateExerciseCatalog(args);

      case 'generate_workout_plan':
        return await _toolGenerateWorkoutPlan(args);

      case 'suggest_next_meal':
        return await _toolSuggestNextMeal(args);

      case 'check_weekly_progress':
        return _toolCheckWeeklyProgress();

      case 'seed_supplements':
        return await _toolSeedSupplements();

      case 'seed_mantras':
        return await _toolSeedMantras(args);

      case 'report_complete':
        return _toolReportComplete(args);

      default:
        return 'Unknown tool: $name';
    }
  }

  String _toolGetDataStatus() {
    final nutrition = _genesisProfile?['nutrition'] as Map<String, dynamic>?;
    final proteinTarget =
        (nutrition?['proteinTarget'] as Map?)?['grams'] ?? 150;
    final proteinConsumed = _todayMeals.fold<int>(
        0, (sum, m) => sum + ((m['protein_grams'] as int?) ?? 0));

    return jsonEncode({
      'exerciseCatalogCount': _exerciseCatalog.length,
      'exerciseCatalogSufficient': _exerciseCatalog.length >= 30,
      'todayMealsCount': _todayMeals.length,
      'proteinConsumed': proteinConsumed,
      'proteinTarget': proteinTarget,
      'proteinRemaining': proteinTarget - proteinConsumed,
      'weekWorkoutsCount': _weekWorkouts.length,
      'supplementsInCatalog': _supplementCount,
      'supplementsNeeded': _supplementCount == 0,
      'mantrasInDatabase': _mantraCount,
      'mantrasAvailableToSeed': _userContextService.allMantras.length,
      'mantrasNeeded': _mantraCount < 10,
      'hasWeather': _weather != null,
      'hasSleepData': _lastNightSleep != null,
    });
  }

  /// Standard exercise catalog for powerlifting/bodybuilding
  static const List<Map<String, dynamic>> _standardExercises = [
    // Legs - Compounds
    {
      'name': 'Barbell Back Squat',
      'category': 'legs',
      'equipment': 'barbell',
      'is_compound': 1
    },
    {
      'name': 'Barbell Front Squat',
      'category': 'legs',
      'equipment': 'barbell',
      'is_compound': 1
    },
    {
      'name': 'Leg Press',
      'category': 'legs',
      'equipment': 'machine',
      'is_compound': 1
    },
    {
      'name': 'Walking Lunges',
      'category': 'legs',
      'equipment': 'dumbbell',
      'is_compound': 1
    },
    {
      'name': 'Bulgarian Split Squat',
      'category': 'legs',
      'equipment': 'dumbbell',
      'is_compound': 1
    },
    {
      'name': 'Romanian Deadlift',
      'category': 'legs',
      'equipment': 'barbell',
      'is_compound': 1
    },
    {
      'name': 'Leg Curl',
      'category': 'legs',
      'equipment': 'machine',
      'is_compound': 0
    },
    {
      'name': 'Leg Extension',
      'category': 'legs',
      'equipment': 'machine',
      'is_compound': 0
    },
    {
      'name': 'Calf Raises',
      'category': 'legs',
      'equipment': 'machine',
      'is_compound': 0
    },
    {
      'name': 'Hip Thrust',
      'category': 'legs',
      'equipment': 'barbell',
      'is_compound': 1
    },
    // Chest
    {
      'name': 'Barbell Bench Press',
      'category': 'chest',
      'equipment': 'barbell',
      'is_compound': 1
    },
    {
      'name': 'Incline Barbell Press',
      'category': 'chest',
      'equipment': 'barbell',
      'is_compound': 1
    },
    {
      'name': 'Dumbbell Bench Press',
      'category': 'chest',
      'equipment': 'dumbbell',
      'is_compound': 1
    },
    {
      'name': 'Incline Dumbbell Press',
      'category': 'chest',
      'equipment': 'dumbbell',
      'is_compound': 1
    },
    {
      'name': 'Cable Fly',
      'category': 'chest',
      'equipment': 'cable',
      'is_compound': 0
    },
    {
      'name': 'Dumbbell Fly',
      'category': 'chest',
      'equipment': 'dumbbell',
      'is_compound': 0
    },
    {
      'name': 'Push-Ups',
      'category': 'chest',
      'equipment': 'bodyweight',
      'is_compound': 1
    },
    {
      'name': 'Chest Dips',
      'category': 'chest',
      'equipment': 'bodyweight',
      'is_compound': 1
    },
    // Back
    {
      'name': 'Conventional Deadlift',
      'category': 'back',
      'equipment': 'barbell',
      'is_compound': 1
    },
    {
      'name': 'Barbell Row',
      'category': 'back',
      'equipment': 'barbell',
      'is_compound': 1
    },
    {
      'name': 'Dumbbell Row',
      'category': 'back',
      'equipment': 'dumbbell',
      'is_compound': 1
    },
    {
      'name': 'Pull-Ups',
      'category': 'back',
      'equipment': 'bodyweight',
      'is_compound': 1
    },
    {
      'name': 'Lat Pulldown',
      'category': 'back',
      'equipment': 'cable',
      'is_compound': 1
    },
    {
      'name': 'Seated Cable Row',
      'category': 'back',
      'equipment': 'cable',
      'is_compound': 1
    },
    {
      'name': 'T-Bar Row',
      'category': 'back',
      'equipment': 'barbell',
      'is_compound': 1
    },
    {
      'name': 'Face Pulls',
      'category': 'back',
      'equipment': 'cable',
      'is_compound': 0
    },
    // Shoulders
    {
      'name': 'Overhead Press',
      'category': 'shoulders',
      'equipment': 'barbell',
      'is_compound': 1
    },
    {
      'name': 'Dumbbell Shoulder Press',
      'category': 'shoulders',
      'equipment': 'dumbbell',
      'is_compound': 1
    },
    {
      'name': 'Lateral Raises',
      'category': 'shoulders',
      'equipment': 'dumbbell',
      'is_compound': 0
    },
    {
      'name': 'Front Raises',
      'category': 'shoulders',
      'equipment': 'dumbbell',
      'is_compound': 0
    },
    {
      'name': 'Rear Delt Fly',
      'category': 'shoulders',
      'equipment': 'dumbbell',
      'is_compound': 0
    },
    {
      'name': 'Arnold Press',
      'category': 'shoulders',
      'equipment': 'dumbbell',
      'is_compound': 1
    },
    {
      'name': 'Shrugs',
      'category': 'shoulders',
      'equipment': 'barbell',
      'is_compound': 0
    },
    // Arms
    {
      'name': 'Barbell Curl',
      'category': 'arms',
      'equipment': 'barbell',
      'is_compound': 0
    },
    {
      'name': 'Dumbbell Curl',
      'category': 'arms',
      'equipment': 'dumbbell',
      'is_compound': 0
    },
    {
      'name': 'Hammer Curl',
      'category': 'arms',
      'equipment': 'dumbbell',
      'is_compound': 0
    },
    {
      'name': 'Preacher Curl',
      'category': 'arms',
      'equipment': 'barbell',
      'is_compound': 0
    },
    {
      'name': 'Tricep Pushdown',
      'category': 'arms',
      'equipment': 'cable',
      'is_compound': 0
    },
    {
      'name': 'Skull Crushers',
      'category': 'arms',
      'equipment': 'barbell',
      'is_compound': 0
    },
    {
      'name': 'Overhead Tricep Extension',
      'category': 'arms',
      'equipment': 'dumbbell',
      'is_compound': 0
    },
    {
      'name': 'Tricep Dips',
      'category': 'arms',
      'equipment': 'bodyweight',
      'is_compound': 1
    },
  ];

  Future<String> _toolGenerateExerciseCatalog(
      Map<String, dynamic>? args) async {
    final focusAreas = (args?['focusAreas'] as List?)?.cast<String>() ??
        ['chest', 'back', 'legs', 'shoulders', 'arms'];

    Logger.info('Loading standard exercise catalog', tag: _tag, data: {
      'focusAreas': focusAreas,
    });

    final createdAt = DateTime.now().toIso8601String();

    // Use the standard exercise catalog - filter by focus areas if specified
    final filteredExercises = _standardExercises
        .where((ex) => focusAreas.contains(ex['category']))
        .toList();

    // Build full exercise records with all required fields
    final allExercises = <Map<String, dynamic>>[];
    int id = 1;
    for (final ex in filteredExercises) {
      final category = ex['category'] as String;
      allExercises.add({
        'id': id++,
        'name': ex['name'],
        'category': category,
        'primary_muscle': category,
        'secondary_muscles': '[]',
        'equipment': ex['equipment'],
        'instructions': '',
        'level': 'intermediate',
        'force': category == 'back' ? 'pull' : 'push',
        'mechanic': ex['is_compound'] == 1 ? 'compound' : 'isolation',
        'is_compound': ex['is_compound'],
        'is_custom': 0,
        'created_at': createdAt,
      });
    }

    _exerciseCatalog = allExercises;

    // Save to local storage for persistence
    await _saveGeneratedData(
        'exercise_catalog.json', jsonEncode(_exerciseCatalog));

    Logger.info('Exercise catalog loaded', tag: _tag, data: {
      'count': _exerciseCatalog.length,
    });

    return jsonEncode({
      'success': true,
      'exercisesGenerated': _exerciseCatalog.length,
      'message': 'Loaded ${_exerciseCatalog.length} standard exercises',
    });
  }

  Future<String> _toolGenerateWorkoutPlan(Map<String, dynamic>? args) async {
    final workoutType = args?['workoutType'] as String? ?? 'full_body';
    final focusExercise = args?['focusExercise'] as String?;
    final durationMinutes = args?['durationMinutes'] as int? ?? 60;

    // Use compact prompt to minimize token usage
    final prompt = '''
$workoutType workout, ${durationMinutes}min${focusExercise != null ? ', focus: $focusExercise' : ''}.
JSON only: {"name":"X","exercises":[{"name":"X","sets":3,"reps":8}],"warmup":["X"]}
''';

    try {
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt: 'Strength coach. JSON only, 5-7 exercises.',
        deployment: AzureAIDeployment.gpt5,
        maxTokens: 1500,
        responseFormat: 'json',
      );

      // Clean response of markdown (fallback for edge cases)
      var cleanResponse = response.trim();
      if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse
            .replaceAll(RegExp(r'^```\w*\n?'), '')
            .replaceAll(RegExp(r'\n?```$'), '');
      }

      final workoutPlan = jsonDecode(cleanResponse) as Map<String, dynamic>;
      workoutPlan['type'] = workoutType;
      workoutPlan['estimatedDuration'] = durationMinutes;

      final today = DateTime.now().toIso8601String().split('T')[0];

      // Save to database so it shows in UI
      final workoutId =
          await _saveWorkoutToDatabase(workoutPlan, durationMinutes);

      // Also save JSON as backup/cache
      await _saveGeneratedData('workout_$today.json', jsonEncode(workoutPlan));

      Logger.info('Generated workout plan', tag: _tag, data: {
        'name': workoutPlan['name'],
        'exercises': (workoutPlan['exercises'] as List?)?.length ?? 0,
        'workoutId': workoutId,
      });

      return jsonEncode({
        'success': true,
        'workout': workoutPlan,
        'workoutId': workoutId,
        'message': 'Generated workout plan for $today',
      });
    } catch (e) {
      Logger.warning('Failed to generate workout plan: $e', tag: _tag);
      // Return a default workout on failure
      final defaultWorkout = _getDefaultWorkout(workoutType);
      final workoutId =
          await _saveWorkoutToDatabase(defaultWorkout, durationMinutes);
      return jsonEncode({
        'success': true,
        'workout': defaultWorkout,
        'workoutId': workoutId,
        'message': 'Using default $workoutType workout',
      });
    }
  }

  /// Save generated workout to database so it appears in the UI
  Future<int> _saveWorkoutToDatabase(
    Map<String, dynamic> workoutPlan,
    int durationMinutes,
  ) async {
    final now = DateTime.now();
    final workoutType = _parseWorkoutTypeFromString(
      workoutPlan['type'] as String? ?? 'strength',
    );
    final workoutName = workoutPlan['name'] as String? ?? 'Generated Workout';

    // Build notes from exercises list
    final exercises = workoutPlan['exercises'] as List? ?? [];
    final exerciseNames =
        exercises.map((e) => e['name'] as String? ?? 'Exercise').join(', ');
    final notes = 'AI-generated plan: $exerciseNames';

    final workoutLog = WorkoutLog(
      startTime: now,
      durationMinutes: durationMinutes,
      type: workoutType,
      name: workoutName,
      notes: notes,
      source: WorkoutSource.manual,
    );

    final id = await _database.insertWorkoutLog(workoutLog);
    Logger.info('Saved workout to database', tag: _tag, data: {'id': id});
    return id;
  }

  /// Parse workout type string to enum
  WorkoutType _parseWorkoutTypeFromString(String typeString) {
    final normalized =
        typeString.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    switch (normalized) {
      case 'lower':
      case 'lowerbody':
      case 'legs':
        return WorkoutType.strength;
      case 'upper':
      case 'upperbody':
        return WorkoutType.strength;
      case 'hypertrophy':
        return WorkoutType.hypertrophy;
      case 'powerlifting':
        return WorkoutType.powerlifting;
      case 'cardio':
        return WorkoutType.cardio;
      case 'hiit':
        return WorkoutType.hiit;
      case 'flexibility':
        return WorkoutType.flexibility;
      case 'yoga':
        return WorkoutType.yoga;
      case 'sports':
        return WorkoutType.sports;
      case 'mixed':
      case 'fullbody':
      default:
        return WorkoutType.strength;
    }
  }

  Map<String, dynamic> _getDefaultWorkout(String type) {
    final exercises = <Map<String, dynamic>>[];
    switch (type) {
      case 'lower':
        exercises.addAll([
          {'name': 'Barbell Back Squat', 'sets': 5, 'reps': 5},
          {'name': 'Romanian Deadlift', 'sets': 3, 'reps': 10},
          {'name': 'Leg Press', 'sets': 3, 'reps': 12},
          {'name': 'Walking Lunges', 'sets': 3, 'reps': 12},
          {'name': 'Leg Curl', 'sets': 3, 'reps': 12},
          {'name': 'Calf Raises', 'sets': 4, 'reps': 15},
        ]);
        break;
      case 'upper':
        exercises.addAll([
          {'name': 'Barbell Bench Press', 'sets': 4, 'reps': 6},
          {'name': 'Barbell Row', 'sets': 4, 'reps': 8},
          {'name': 'Overhead Press', 'sets': 3, 'reps': 10},
          {'name': 'Pull-Ups', 'sets': 3, 'reps': 8},
          {'name': 'Dumbbell Curl', 'sets': 3, 'reps': 12},
          {'name': 'Tricep Pushdown', 'sets': 3, 'reps': 12},
        ]);
        break;
      default:
        exercises.addAll([
          {'name': 'Barbell Back Squat', 'sets': 4, 'reps': 6},
          {'name': 'Barbell Bench Press', 'sets': 4, 'reps': 6},
          {'name': 'Barbell Row', 'sets': 4, 'reps': 8},
          {'name': 'Overhead Press', 'sets': 3, 'reps': 10},
          {'name': 'Romanian Deadlift', 'sets': 3, 'reps': 10},
        ]);
    }
    return {
      'name': '${type.replaceAll('_', ' ').toUpperCase()} Day',
      'type': type,
      'estimatedDuration': 60,
      'exercises': exercises,
      'warmup': ['5 min cardio', 'Dynamic stretching', 'Warm-up sets'],
    };
  }

  Future<String> _toolSuggestNextMeal(Map<String, dynamic>? args) async {
    final proteinNeeded = args?['proteinNeeded'] as int? ?? 50;
    final mealType = args?['mealType'] as String? ?? 'snack';
    final quickPrep = args?['quickPrep'] as bool? ?? true;

    // Compact prompt to minimize token usage
    final prompt = '''
$mealType, ${proteinNeeded}g protein${quickPrep ? ', quick prep' : ''}.
JSON: {"name":"X","protein":50,"cal":400,"ingredients":["X"]}
''';

    try {
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt: 'Nutritionist. JSON only.',
        deployment: AzureAIDeployment.gpt5,
        maxTokens: 800,
        responseFormat: 'json',
      );

      // Clean response of markdown (fallback for edge cases)
      var cleanResponse = response.trim();
      if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse
            .replaceAll(RegExp(r'^```\w*\n?'), '')
            .replaceAll(RegExp(r'\n?```$'), '');
      }

      // Handle both array and object responses
      final decoded = jsonDecode(cleanResponse);
      final Map<String, dynamic> mealSuggestion;
      if (decoded is List && decoded.isNotEmpty) {
        mealSuggestion = decoded.first as Map<String, dynamic>;
      } else {
        mealSuggestion = decoded as Map<String, dynamic>;
      }

      Logger.info('Suggested meal', tag: _tag, data: {
        'name': mealSuggestion['name'],
        'protein': mealSuggestion['protein'] ?? mealSuggestion['proteinGrams'],
      });

      return jsonEncode({
        'success': true,
        'meal': mealSuggestion,
        'message': 'Suggested: ${mealSuggestion['name']}',
      });
    } catch (e) {
      Logger.warning('Failed to suggest meal: $e', tag: _tag);
      // Return a default meal on failure
      return jsonEncode({
        'success': true,
        'meal': _getDefaultMeal(mealType, proteinNeeded),
        'message': 'Default $mealType suggestion',
      });
    }
  }

  Map<String, dynamic> _getDefaultMeal(String mealType, int proteinNeeded) {
    switch (mealType) {
      case 'breakfast':
        return {
          'name': 'Protein Scramble',
          'protein': 40,
          'cal': 450,
          'ingredients': ['4 eggs', '2 egg whites', 'spinach', 'cheese'],
        };
      case 'lunch':
        return {
          'name': 'Grilled Chicken Bowl',
          'protein': 50,
          'cal': 550,
          'ingredients': ['8oz chicken breast', 'rice', 'vegetables'],
        };
      case 'dinner':
        return {
          'name': 'Salmon with Quinoa',
          'protein': 45,
          'cal': 600,
          'ingredients': ['6oz salmon', 'quinoa', 'asparagus'],
        };
      default:
        return {
          'name': 'Greek Yogurt Parfait',
          'protein': 30,
          'cal': 350,
          'ingredients': [
            'Greek yogurt',
            'protein powder',
            'berries',
            'granola'
          ],
        };
    }
  }

  /// Seed supplements from user context into database
  Future<String> _toolSeedSupplements() async {
    Logger.info('Seeding supplements from user context...', tag: _tag);

    final supplements = _userContextService.supplements;
    if (supplements.isEmpty) {
      return jsonEncode({
        'success': false,
        'error': 'No supplements defined in user context',
      });
    }

    int inserted = 0;
    try {
      for (final supp in supplements) {
        // Convert to the model format expected by the database
        final supplement = Supplement(
          name: supp.name,
          brand: supp.brand,
          category: _mapCategory(supp.category),
          defaultDoseMg: supp.defaultDoseMg,
          unit: supp.unit,
          notes: supp.notes,
          isActive: supp.isActive,
          takeWithFood: supp.takeWithFood,
          takeWithFat: supp.takeWithFat,
          maxDailyMg: supp.maxDailyMg,
          preferredTimes: supp.preferredTimes?.map(_mapDoseTime).toList(),
        );

        await _database.insertSupplement(supplement);
        inserted++;
      }

      _supplementCount = inserted;
      Logger.info('Seeded $inserted supplements', tag: _tag);

      return jsonEncode({
        'success': true,
        'supplementsSeeded': inserted,
        'supplements': supplements.map((s) => s.name).toList(),
      });
    } catch (e, stack) {
      Logger.error('Failed to seed supplements: $e',
          tag: _tag, error: e, stackTrace: stack);
      return jsonEncode({
        'success': false,
        'error': e.toString(),
        'seededBeforeError': inserted,
      });
    }
  }

  /// Map category string to SupplementCategory enum
  SupplementCategory _mapCategory(String category) {
    switch (category.toLowerCase()) {
      case 'vitamin':
        return SupplementCategory.vitamin;
      case 'mineral':
        return SupplementCategory.mineral;
      case 'nootropic':
        return SupplementCategory.nootropic;
      case 'amino_acid':
      case 'aminoacid':
        return SupplementCategory.aminoAcid;
      case 'herb':
        return SupplementCategory.herb;
      case 'probiotic':
        return SupplementCategory.probiotic;
      case 'omega':
      case 'essential_fatty_acid':
        return SupplementCategory.omega;
      case 'hormone':
        return SupplementCategory.hormone;
      case 'medication':
        return SupplementCategory.medication;
      default:
        return SupplementCategory.other;
    }
  }

  /// Map time string to DoseTime enum
  DoseTime _mapDoseTime(String time) {
    switch (time.toLowerCase()) {
      case 'wakeup':
      case 'wake_up':
        return DoseTime.wakeUp;
      case 'morning':
        return DoseTime.morning;
      case 'midday':
        return DoseTime.midday;
      case 'afternoon':
        return DoseTime.afternoon;
      case 'evening':
        return DoseTime.evening;
      case 'bedtime':
        return DoseTime.bedtime;
      default:
        return DoseTime.asNeeded;
    }
  }

  /// Seed mantras from Princeps_Mantras.md into database
  Future<String> _toolSeedMantras(Map<String, dynamic>? args) async {
    Logger.info('Seeding mantras from user context...', tag: _tag);

    final maxMantras = args?['maxMantras'] as int?;
    final categories = _userContextService.mantraCategories;

    if (categories.isEmpty) {
      return jsonEncode({
        'success': false,
        'error': 'No mantras found in user context',
      });
    }

    int inserted = 0;
    try {
      for (final category in categories) {
        final mantrasToSeed = maxMantras != null
            ? category.mantras.take(maxMantras)
            : category.mantras;

        for (final mantraText in mantrasToSeed) {
          if (mantraText.length < 10) continue; // Skip very short lines

          final mantra = Mantra(
            text: mantraText,
            category: category.name.toLowerCase().replaceAll(' ', '_'),
            isActive: true,
          );

          await _database.insertMantra(mantra);
          inserted++;

          // Respect maxMantras total across all categories
          if (maxMantras != null && inserted >= maxMantras) break;
        }

        if (maxMantras != null && inserted >= maxMantras) break;
      }

      _mantraCount = inserted;
      Logger.info(
          'Seeded $inserted mantras across ${categories.length} categories',
          tag: _tag);

      return jsonEncode({
        'success': true,
        'mantrasSeeded': inserted,
        'categories': categories.map((c) => c.name).toList(),
      });
    } catch (e, stack) {
      Logger.error('Failed to seed mantras: $e',
          tag: _tag, error: e, stackTrace: stack);
      return jsonEncode({
        'success': false,
        'error': e.toString(),
        'seededBeforeError': inserted,
      });
    }
  }

  String _toolCheckWeeklyProgress() {
    final experiment = _genesisProfile?['experiment'] as Map<String, dynamic>?;
    final targets = experiment?['targets'] as Map<String, dynamic>? ?? {};

    final gymTarget = targets['gym'] as String? ?? '5x/week';
    final gymTargetNum =
        int.tryParse(gymTarget.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;
    final workoutsCompleted = _weekWorkouts.length;
    final workoutsRemaining = gymTargetNum - workoutsCompleted;

    final today = DateTime.now();
    final daysLeftInWeek = 7 - today.weekday;

    final onTrack = workoutsRemaining <= daysLeftInWeek;

    return jsonEncode({
      'gymTarget': gymTargetNum,
      'workoutsCompleted': workoutsCompleted,
      'workoutsRemaining': workoutsRemaining,
      'daysLeftInWeek': daysLeftInWeek,
      'onTrack': onTrack,
      'status': onTrack
          ? 'On track for gym goal'
          : 'Behind on gym goal - need to prioritize',
    });
  }

  String _toolReportComplete(Map<String, dynamic>? args) {
    final summary = args?['summary'] as String? ?? 'Bootstrap complete';
    final needsAttention =
        (args?['needsAttention'] as List?)?.cast<String>() ?? [];

    Logger.info('Bootstrap report: $summary', tag: _tag, data: {
      'needsAttention': needsAttention,
    });

    return jsonEncode({
      'acknowledged': true,
      'summary': summary,
      'needsAttention': needsAttention,
    });
  }

  /// Run the bootstrap agent
  Future<String> _runBootstrapAgent(String context) async {
    final systemPrompt = '''
You are the Odelle Bootstrap Agent. Your job is to review the app's data status at startup and ensure everything is ready for the user's day.

IMPORTANT: Do NOT generate new data unless it's actually needed. Your priority is:
1. Check what data exists using get_data_status
2. Only generate exercise catalog if fewer than 30 exercises exist
3. Only generate workout plan if it's a training day AND no workout logged today
4. Only suggest meal if protein remaining > 30g
5. If supplements catalog is empty (0), call seed_supplements to populate it
6. If mantras < 10 in database, call seed_mantras to populate from user's personal mantras
7. Always check weekly progress
8. Always call report_complete at the end with a summary

Be efficient - don't generate content unnecessarily. The user may already have everything they need.
''';

    final response = await _agentService.runAgent(
      messages: [
        ChatMessage.system(systemPrompt),
        ChatMessage.user(context),
      ],
      tools: _getTools(),
      executor: _executeTool,
      maxIterations: 5,
    );

    return response.message.content ?? 'Bootstrap complete';
  }

  /// Save generated data to local storage
  Future<void> _saveGeneratedData(String filename, String data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/generated/$filename');
      await file.parent.create(recursive: true);
      await file.writeAsString(data);
      Logger.info('Saved generated data: $filename', tag: _tag);
    } catch (e) {
      Logger.warning('Could not save generated data: $e', tag: _tag);
    }
  }
}

/// Result of bootstrap process
class BootstrapResult {
  bool success = false;
  String? error;
  String? agentSummary;

  @override
  String toString() =>
      'BootstrapResult(success: $success, summary: $agentSummary)';
}
