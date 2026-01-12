import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';
import 'azure_agent_service.dart';
import 'health_kit_service.dart';
import 'weather_service.dart';

/// Bootstrap Service - runs at app startup to ensure all required data exists
///
/// The LLM reviews:
/// 1. Exercise catalog - generates if missing/incomplete
/// 2. Today's workout plan - generates if needed
/// 3. Meal suggestions - generates based on remaining protein target
/// 4. Progress toward experiment targets
///
/// Uses tool calling to let the LLM decide what needs to be done.
class BootstrapService {
  static const String _tag = 'BootstrapService';

  final AzureAgentService _agentService;
  final HealthKitService _healthKitService;
  final WeatherService _weatherService;

  // Cached data
  Map<String, dynamic>? _genesisProfile;
  List<Map<String, dynamic>> _exerciseCatalog = [];
  List<Map<String, dynamic>> _todayMeals = [];
  List<Map<String, dynamic>> _weekWorkouts = [];
  CurrentWeather? _weather;
  SleepData? _lastNightSleep;
  int _healthKitWorkoutMinutes = 0;

  BootstrapService({
    required AzureAgentService agentService,
    required HealthKitService healthKitService,
    required WeatherService weatherService,
  })  : _agentService = agentService,
        _healthKitService = healthKitService,
        _weatherService = weatherService;

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

--- WHAT NEEDS CHECKING ---
1. Exercise catalog has ${_exerciseCatalog.length} exercises - need at least 30 compound movements for a complete program
2. Today's workout plan - does one exist for today?
3. Meal suggestions - if protein remaining > 30g, suggest next meal
4. Weekly progress - are we on track for experiment targets?
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
      'hasWeather': _weather != null,
      'hasSleepData': _lastNightSleep != null,
    });
  }

  Future<String> _toolGenerateExerciseCatalog(
      Map<String, dynamic>? args) async {
    final focusAreas = (args?['focusAreas'] as List?)?.cast<String>() ??
        ['chest', 'back', 'legs', 'shoulders', 'arms'];
    final includeCompounds = args?['includeCompounds'] as bool? ?? true;

    Logger.info('Generating exercise catalog', tag: _tag, data: {
      'focusAreas': focusAreas,
      'includeCompounds': includeCompounds,
    });

    // Use GPT to generate a proper exercise catalog
    final prompt = '''
Generate a JSON array of exercises for a bodybuilding program.
Focus areas: ${focusAreas.join(', ')}
Include compound movements: $includeCompounds
User's goal: Improve squat strength (current: 315 lbs, target: 405 lbs)

For each exercise, include:
- id (integer starting from 1)
- name (string)
- category (string: chest, back, legs, shoulders, arms, core)
- primary_muscle (string)
- secondary_muscles (array of strings)
- equipment (string: barbell, dumbbell, cable, machine, bodyweight)
- instructions (brief string)
- level (beginner, intermediate, advanced)
- force (push, pull)
- mechanic (compound, isolation)
- is_compound (0 or 1)
- is_custom (0)
- created_at (ISO date string)

Generate at least 40 exercises covering all muscle groups.
Prioritize compound movements like squat variations, bench press, deadlifts, rows, overhead press.

Return ONLY the JSON array, no markdown or explanation.
''';

    try {
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'You are a fitness expert. Generate exercise data in valid JSON format only.',
        maxTokens: 4000,
      );

      // Parse and save the catalog
      final exercises = jsonDecode(response) as List;
      _exerciseCatalog = exercises.cast<Map<String, dynamic>>();

      // Save to local storage for persistence
      await _saveGeneratedData(
          'exercise_catalog.json', jsonEncode(_exerciseCatalog));

      return jsonEncode({
        'success': true,
        'exercisesGenerated': _exerciseCatalog.length,
        'message':
            'Generated ${_exerciseCatalog.length} exercises and saved to local storage',
      });
    } catch (e) {
      Logger.error('Failed to generate exercise catalog: $e', tag: _tag);
      return jsonEncode({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  Future<String> _toolGenerateWorkoutPlan(Map<String, dynamic>? args) async {
    final workoutType = args?['workoutType'] as String? ?? 'full_body';
    final focusExercise = args?['focusExercise'] as String?;
    final durationMinutes = args?['durationMinutes'] as int? ?? 60;

    final fitness = _genesisProfile?['fitness'] as Map<String, dynamic>?;

    final prompt = '''
Generate a workout plan for today.
Type: $workoutType
${focusExercise != null ? 'Focus exercise: $focusExercise (user wants to improve this)' : ''}
Duration: $durationMinutes minutes
Training style: ${fitness?['style'] ?? 'bodybuilding/powerlifting hybrid'}
Current squat: ${(fitness?['currentMaxes']?['squat'] as Map?)?['weight'] ?? 315} lbs
Sleep last night: ${_lastNightSleep?.qualityScore ?? 'unknown'}/100

Return a JSON object with:
- name: Workout name
- type: $workoutType
- estimatedDuration: $durationMinutes
- exercises: array of {name, sets, reps, restSeconds, notes}
- warmup: array of warmup exercises
- cooldown: brief cooldown instructions

If user slept poorly (score < 60), reduce volume by 20%.
''';

    try {
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'You are a strength coach. Generate workout plans in valid JSON format only.',
        maxTokens: 2000,
      );

      final workoutPlan = jsonDecode(response) as Map<String, dynamic>;

      // Save today's workout plan
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _saveGeneratedData('workout_$today.json', jsonEncode(workoutPlan));

      return jsonEncode({
        'success': true,
        'workout': workoutPlan,
        'message': 'Generated workout plan for $today',
      });
    } catch (e) {
      Logger.error('Failed to generate workout plan: $e', tag: _tag);
      return jsonEncode({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  Future<String> _toolSuggestNextMeal(Map<String, dynamic>? args) async {
    final proteinNeeded = args?['proteinNeeded'] as int? ?? 50;
    final mealType = args?['mealType'] as String? ?? 'snack';
    final quickPrep = args?['quickPrep'] as bool? ?? true;

    final nutrition = _genesisProfile?['nutrition'] as Map<String, dynamic>?;
    final preferredSources =
        (nutrition?['preferences']?['preferredProteinSources'] as List?)
                ?.cast<String>() ??
            ['chicken', 'eggs', 'greek yogurt'];

    final prompt = '''
Suggest a $mealType that provides approximately ${proteinNeeded}g of protein.
Quick prep preferred: $quickPrep
Preferred protein sources: ${preferredSources.join(', ')}

Return a JSON object with:
- name: Meal name
- description: Brief description
- proteinGrams: estimated protein
- calories: estimated calories
- ingredients: array of ingredient strings
- prepTimeMinutes: prep time
- instructions: brief cooking instructions (if any)
''';

    try {
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'You are a sports nutritionist. Generate meal suggestions in valid JSON format only.',
        maxTokens: 800,
      );

      final mealSuggestion = jsonDecode(response) as Map<String, dynamic>;

      return jsonEncode({
        'success': true,
        'meal': mealSuggestion,
        'message':
            'Suggested: ${mealSuggestion['name']} (~${mealSuggestion['proteinGrams']}g protein)',
      });
    } catch (e) {
      Logger.error('Failed to suggest meal: $e', tag: _tag);
      return jsonEncode({
        'success': false,
        'error': e.toString(),
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
5. Always check weekly progress
6. Always call report_complete at the end with a summary

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
