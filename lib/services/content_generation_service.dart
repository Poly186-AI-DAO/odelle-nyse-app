import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/elevenlabs_config.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';
import 'azure_agent_service.dart';
import 'azure_image_service.dart';

/// Content types that can be generated
enum ContentType {
  cosmicStory, // One-time epic narration of user's cosmic profile
  mantras, // Personalized mantras for swipeable cards
  workout, // Daily workout plan
  mealPlan, // Daily meal suggestions
  meditation, // Meditation scripts with audio
  exercises, // Exercise catalog with images
}

/// Status of a generation task
enum GenerationStatus {
  pending,
  inProgress,
  completed,
  failed,
}

/// A single generation task
class GenerationTask {
  final String id;
  final ContentType type;
  final String title;
  final Map<String, dynamic>? inputData;
  GenerationStatus status;
  double progress;
  String? outputData;
  String? error;
  DateTime createdAt;
  DateTime? completedAt;

  GenerationTask({
    required this.id,
    required this.type,
    required this.title,
    this.inputData,
    this.status = GenerationStatus.pending,
    this.progress = 0.0,
    this.outputData,
    this.error,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'title': title,
        'input_data': inputData != null ? jsonEncode(inputData) : null,
        'status': status.name,
        'progress': progress,
        'output_data': outputData,
        'error': error,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };
}

/// Callback for progress updates
typedef ProgressCallback = void Function(
  ContentType type,
  String message,
  double progress,
);

/// Content Generation Service
///
/// Generates personalized content in parallel:
/// 1. Cosmic Story - Epic narration of zodiac, numerology, archetypes (one-time)
/// 2. Mantras - Personalized affirmations for swipeable cards
/// 3. Workouts - Daily workout plans based on goals
/// 4. Meal Plans - Protein-focused meal suggestions
/// 5. Meditations - Scripts with ElevenLabs audio
/// 6. Exercises - Exercise catalog with AI-generated images
///
/// All content ties back to the 10-Week Protocol experiment.
class ContentGenerationService {
  static const String _tag = 'ContentGenerationService';
  static const int _batchSize = 10; // Generate in batches to avoid rate limits

  final AzureAgentService _agentService;
  final AzureImageService _imageService;
  final AppDatabase _database;
  final http.Client _httpClient;

  // Progress tracking
  final Map<ContentType, GenerationTask> _activeTasks = {};
  ProgressCallback? onProgress;

  // Cached profile data
  Map<String, dynamic>? _genesisProfile;

  ContentGenerationService({
    required AzureAgentService agentService,
    required AzureImageService imageService,
    required AppDatabase database,
    http.Client? httpClient,
  })  : _agentService = agentService,
        _imageService = imageService,
        _database = database,
        _httpClient = httpClient ?? http.Client();

  /// Initialize and load profile
  Future<void> initialize() async {
    try {
      final profileJson =
          await rootBundle.loadString('data/user/genesis_profile.json');
      _genesisProfile = jsonDecode(profileJson) as Map<String, dynamic>;
      Logger.info('ContentGenerationService initialized', tag: _tag);
    } catch (e) {
      Logger.error('Failed to load genesis profile: $e', tag: _tag);
    }
  }

  /// Run all one-time generations in parallel
  /// Call this on first app launch or when user requests regeneration
  Future<Map<ContentType, bool>> runInitialGeneration() async {
    Logger.info('Starting initial content generation', tag: _tag);

    final results = <ContentType, bool>{};

    // Check what already exists
    final db = await _database.database;

    // Check for existing cosmic story
    final cosmicExists = await _checkContentExists(db, 'cosmic_story');
    final mantrasCount = await _getMantrasCount(db);
    final exercisesCount = await _getExercisesCount(db);

    // Run generations in parallel
    final futures = <Future<void>>[];

    // 1. Cosmic Story (one-time, ~2 min with audio)
    if (!cosmicExists) {
      futures.add(_generateCosmicStory().then(
        (success) => results[ContentType.cosmicStory] = success,
      ));
    } else {
      results[ContentType.cosmicStory] = true;
      _notifyProgress(ContentType.cosmicStory, 'Already generated', 1.0);
    }

    // 2. Mantras (generate 20 personalized mantras)
    if (mantrasCount < 20) {
      futures.add(_generateMantras(20 - mantrasCount).then(
        (success) => results[ContentType.mantras] = success,
      ));
    } else {
      results[ContentType.mantras] = true;
      _notifyProgress(
          ContentType.mantras, 'Already have $mantrasCount mantras', 1.0);
    }

    // 3. Exercises (generate 10 at a time with images)
    if (exercisesCount < 30) {
      futures.add(_generateExercisesBatch(_batchSize).then(
        (success) => results[ContentType.exercises] = success,
      ));
    } else {
      results[ContentType.exercises] = true;
      _notifyProgress(
          ContentType.exercises, 'Already have $exercisesCount exercises', 1.0);
    }

    // Wait for all parallel tasks
    await Future.wait(futures);

    Logger.info('Initial generation complete', tag: _tag, data: results);
    return results;
  }

  /// Generate daily content (call each morning or on demand)
  Future<Map<ContentType, bool>> generateDailyContent() async {
    Logger.info('Generating daily content', tag: _tag);

    final results = <ContentType, bool>{};
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Check what exists for today
    final db = await _database.database;
    final todayWorkoutExists = await _checkTodayWorkout(db, today);
    final todayMeditationsCount = await _getTodayMeditationsCount(db, today);

    final futures = <Future<void>>[];

    // 1. Today's Workout (if training day)
    if (!todayWorkoutExists && _isTrainingDay()) {
      futures.add(_generateTodayWorkout().then(
        (success) => results[ContentType.workout] = success,
      ));
    } else {
      results[ContentType.workout] = true;
    }

    // 2. Today's Meditations (3 per day: morning, midday, evening)
    if (todayMeditationsCount < 3) {
      futures.add(_generateMeditation(_getMeditationType()).then(
        (success) => results[ContentType.meditation] = success,
      ));
    } else {
      results[ContentType.meditation] = true;
    }

    // 3. Meal suggestions based on remaining protein
    futures.add(_generateMealSuggestion().then(
      (success) => results[ContentType.mealPlan] = success,
    ));

    await Future.wait(futures);

    Logger.info('Daily content complete', tag: _tag, data: results);
    return results;
  }

  // ============================================================
  // COSMIC STORY GENERATION
  // ============================================================

  Future<bool> _generateCosmicStory() async {
    _notifyProgress(
        ContentType.cosmicStory, 'Crafting your cosmic narrative...', 0.1);

    try {
      final identity = _genesisProfile?['identity'] as Map<String, dynamic>?;
      final archetypes =
          _genesisProfile?['archetypes'] as Map<String, dynamic>?;
      final mission = _genesisProfile?['mission'] as Map<String, dynamic>?;
      final origin = _genesisProfile?['origin'] as Map<String, dynamic>?;
      final rca = _genesisProfile?['rca'] as Map<String, dynamic>?;

      final prompt = '''
Create an epic, heroic narrative about this person's cosmic identity. Write in second person ("You are...").
Make it inspiring, mystical, and empowering - like a prophecy being revealed.

IDENTITY:
- Name: ${identity?['name']}
- Born: ${identity?['dateOfBirth']} in ${identity?['birthplace']}
- Sun Sign: ${identity?['zodiac']?['sun']} (communication, intellect, curiosity)
- Moon Sign: ${identity?['zodiac']?['moon']} (harmony, balance, relationships)  
- Rising Sign: ${identity?['zodiac']?['rising']} (intensity, transformation, depth)
- Life Path Number: ${identity?['numerology']?['lifePathNumber']} (builder, foundation, discipline)
- Birth Number: ${identity?['numerology']?['birthNumber']} (partnership, duality)
- Destiny Number: ${identity?['numerology']?['destinyNumber']} (seeker, wisdom, introspection)
- MBTI: ${identity?['mbti']}

ARCHETYPES:
- Ego (how they act): ${archetypes?['primary']?['ego']} - ${archetypes?['traits']?['Hero']?['motto']}
- Soul (what they create): ${archetypes?['primary']?['soul']} - ${archetypes?['traits']?['Creator']?['motto']}
- Self (their magic): ${archetypes?['primary']?['self']} - ${archetypes?['traits']?['Magician']?['motto']}

MISSION:
${mission?['primary']}
Vision: ${mission?['vision']}

ORIGIN STORY:
${origin?['summary']}

RCA PHILOSOPHY:
${rca?['thesis']}

Write a 400-500 word cosmic narrative that:
1. Opens with their celestial configuration (zodiac + numerology)
2. Reveals their archetypal nature (Hero-Creator-Magician)
3. Speaks to their origin journey
4. Affirms their mission and destiny
5. Ends with an empowering call to action

Style: Epic, mythological, like a cosmic being revealing their true nature.
Tone: Reverent but personal, mystical but grounded.
''';

      _notifyProgress(ContentType.cosmicStory, 'Writing your story...', 0.3);

      final script = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'You are a cosmic narrator revealing someone\'s true mythological identity. Write with reverence and power.',
        maxTokens: 1500,
      );

      _notifyProgress(
          ContentType.cosmicStory, 'Generating audio narration...', 0.5);

      // Generate audio with ElevenLabs
      final audioBytes = await _generateAudio(script, 'narrator');
      final audioPath = audioBytes != null
          ? await _saveAudioFile('cosmic_story', audioBytes)
          : null;

      _notifyProgress(ContentType.cosmicStory, 'Saving cosmic story...', 0.8);

      // Save to database
      final createdAt = DateTime.now().toIso8601String();
      final contentDate = createdAt.split('T')[0];
      final db = await _database.database;
      await db.insert('generation_queue', {
        'type': 'cosmic_story',
        'status': 'completed',
        'input_data': jsonEncode({
          'identity': identity,
          'archetypes': archetypes?['primary'],
        }),
        'output_data': jsonEncode({
          'script': script,
          'audioPath': audioPath,
        }),
        'content_date': contentDate,
        'image_path': null,
        'audio_path': audioPath,
        'created_at': createdAt,
        'completed_at': createdAt,
      });

      _notifyProgress(
          ContentType.cosmicStory, 'Your cosmic story is ready!', 1.0);
      return true;
    } catch (e) {
      Logger.error('Failed to generate cosmic story: $e', tag: _tag);
      _notifyProgress(ContentType.cosmicStory, 'Failed: $e', 0.0);
      return false;
    }
  }

  // ============================================================
  // MANTRAS GENERATION
  // ============================================================

  Future<bool> _generateMantras(int count) async {
    _notifyProgress(
        ContentType.mantras, 'Creating personalized mantras...', 0.1);

    try {
      final mission = _genesisProfile?['mission'] as Map<String, dynamic>?;
      final archetypes =
          _genesisProfile?['archetypes'] as Map<String, dynamic>?;
      final currentFocus =
          _genesisProfile?['currentFocus'] as Map<String, dynamic>?;
      final experiment =
          _genesisProfile?['experiment'] as Map<String, dynamic>?;

      final prompt = '''
Generate $count personalized mantras/affirmations for daily practice.

CONTEXT:
- Mission: ${mission?['primary']}
- Archetypes: Hero (courage), Creator (vision), Magician (transformation)
- Current Focus:
  * Body: ${(currentFocus?['body'] as List?)?.join(', ')}
  * Mind: ${(currentFocus?['mind'] as List?)?.join(', ')}
  * Spirit: ${(currentFocus?['spirit'] as List?)?.join(', ')}
- Experiment: ${experiment?['name']} - targets: gym 5x/week, protein 150g/day, deep work 6hrs

Generate mantras in these categories:
1. Flow State (5) - entering and maintaining peak performance
2. Strength (5) - physical and mental power
3. Focus (5) - concentration and deep work
4. Presence (5) - mindfulness and awareness

Return a JSON array with objects containing:
- text: The mantra (first person, present tense, "I am...", "I...")
- category: flow_state, strength, focus, presence
- context: When to use this mantra

Make them powerful, personal, and actionable.
''';

      _notifyProgress(ContentType.mantras, 'Generating $count mantras...', 0.4);

      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'Generate mantras in valid JSON array format only. No markdown.',
        maxTokens: 2000,
      );

      final mantras = jsonDecode(response) as List;

      _notifyProgress(
          ContentType.mantras, 'Saving mantras to database...', 0.8);

      // Save to database
      final db = await _database.database;
      for (final mantra in mantras) {
        await db.insert('mantras', {
          'text': mantra['text'],
          'category': mantra['category'],
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      _notifyProgress(
          ContentType.mantras, '${mantras.length} mantras ready!', 1.0);
      return true;
    } catch (e) {
      Logger.error('Failed to generate mantras: $e', tag: _tag);
      _notifyProgress(ContentType.mantras, 'Failed: $e', 0.0);
      return false;
    }
  }

  // ============================================================
  // EXERCISES GENERATION (with images)
  // ============================================================

  Future<bool> _generateExercisesBatch(int count) async {
    _notifyProgress(ContentType.exercises, 'Creating exercise catalog...', 0.1);

    try {
      final fitness = _genesisProfile?['fitness'] as Map<String, dynamic>?;

      final prompt = '''
Generate $count exercises for a ${fitness?['style']} training program.
Focus on compound movements for someone wanting to improve squat strength.

Current lifts:
- Squat: ${(fitness?['currentMaxes']?['squat'] as Map?)?['weight']} lbs
- Bench: ${(fitness?['currentMaxes']?['bench'] as Map?)?['weight']} lbs

Generate a mix of:
- Squat variations (3)
- Pressing movements (2)
- Pulling movements (2)
- Accessory work (3)

Return JSON array with:
- name: Exercise name
- category: legs, chest, back, shoulders, arms, core
- primary_muscle: main muscle worked
- secondary_muscles: array of secondary muscles
- equipment: barbell, dumbbell, cable, machine, bodyweight
- instructions: 2-3 sentences on proper form
- level: beginner, intermediate, advanced
- is_compound: true/false
- image_prompt: A prompt for generating an illustration of this exercise
''';

      _notifyProgress(
          ContentType.exercises, 'Generating $count exercises...', 0.3);

      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt: 'Generate exercises in valid JSON array format only.',
        maxTokens: 3000,
      );

      final exercises = jsonDecode(response) as List;

      // Generate images for each exercise (in batches to avoid rate limits)
      final db = await _database.database;
      int completed = 0;

      for (final exercise in exercises) {
        completed++;
        final progress = 0.3 + (0.6 * completed / exercises.length);
        _notifyProgress(
          ContentType.exercises,
          'Creating ${exercise['name']} (${completed}/${exercises.length})...',
          progress,
        );

        String? imagePath;
        try {
          // Generate image for exercise
          final imageResult = await _imageService.generateImage(
            prompt: exercise['image_prompt'] ??
                'Minimalist illustration of ${exercise['name']} exercise, fitness, gym, clean style',
            size: ImageSize.square,
          );

          if (imageResult.success && imageResult.imageBytes != null) {
            imagePath = await _saveImageFile(
              'exercise_${exercise['name'].toString().toLowerCase().replaceAll(' ', '_')}',
              imageResult.imageBytes!,
            );
          }
        } catch (e) {
          Logger.warning('Failed to generate image for ${exercise['name']}: $e',
              tag: _tag);
        }

        // Save to database
        await db.insert('exercise_types', {
          'name': exercise['name'],
          'category': exercise['category'],
          'primary_muscle': exercise['primary_muscle'],
          'secondary_muscles': jsonEncode(exercise['secondary_muscles']),
          'equipment': exercise['equipment'],
          'instructions': exercise['instructions'],
          'level': exercise['level'],
          'is_compound': (exercise['is_compound'] == true) ? 1 : 0,
          'is_generated': 1,
          'image_local_path': imagePath,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Small delay to avoid rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _notifyProgress(
          ContentType.exercises, '${exercises.length} exercises ready!', 1.0);
      return true;
    } catch (e) {
      Logger.error('Failed to generate exercises: $e', tag: _tag);
      _notifyProgress(ContentType.exercises, 'Failed: $e', 0.0);
      return false;
    }
  }

  // ============================================================
  // WORKOUT GENERATION
  // ============================================================

  Future<bool> _generateTodayWorkout() async {
    _notifyProgress(ContentType.workout, 'Creating today\'s workout...', 0.1);

    try {
      final fitness = _genesisProfile?['fitness'] as Map<String, dynamic>?;
      final today = DateTime.now();
      final dayName =
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][today.weekday - 1];

      // Determine workout type based on day and split
      final workoutType = _getWorkoutTypeForDay(today.weekday);

      final prompt = '''
Create a workout for $dayName focused on: $workoutType
Training style: ${fitness?['style']}
Primary goal: Improve squat (current 315 lbs, target 405 lbs)
Duration: 60-75 minutes

Return JSON object:
{
  "name": "Workout name",
  "type": "$workoutType",
  "duration_minutes": 60,
  "warmup": ["warmup exercise 1", "warmup exercise 2"],
  "exercises": [
    {"name": "Exercise", "sets": 4, "reps": "6-8", "rest_seconds": 180, "notes": "Focus cue"},
    ...
  ],
  "cooldown": "Brief cooldown instructions",
  "focus_tip": "One key focus for this workout"
}

For leg days, prioritize squat variations.
Include RPE guidelines for main lifts.
''';

      _notifyProgress(ContentType.workout, 'Planning exercises...', 0.4);

      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt: 'Generate workout plans in valid JSON format only.',
        maxTokens: 1500,
      );

      final workout = jsonDecode(response) as Map<String, dynamic>;

      _notifyProgress(ContentType.workout, 'Saving workout...', 0.8);

      // Save to database
      final db = await _database.database;
      await db.insert('workout_logs', {
        'start_time': today.toIso8601String(),
        'type': workoutType,
        'name': workout['name'],
        'notes': jsonEncode(workout),
        'source': 'generated',
      });

      _notifyProgress(
          ContentType.workout, 'Workout ready: ${workout['name']}', 1.0);
      return true;
    } catch (e) {
      Logger.error('Failed to generate workout: $e', tag: _tag);
      _notifyProgress(ContentType.workout, 'Failed: $e', 0.0);
      return false;
    }
  }

  // ============================================================
  // MEDITATION GENERATION
  // ============================================================

  Future<bool> _generateMeditation(String type) async {
    _notifyProgress(
        ContentType.meditation, 'Creating $type meditation...', 0.1);

    try {
      final rca = _genesisProfile?['rca'] as Map<String, dynamic>?;
      final archetypes =
          _genesisProfile?['archetypes'] as Map<String, dynamic>?;

      final prompt = '''
Create a ${_getMeditationDuration(type)} minute $type meditation script.

Philosophy: ${rca?['thesis']}
Archetypes: Hero (courage), Creator (vision), Magician (transformation)

Type-specific focus:
${_getMeditationFocus(type)}

Format the script for voice narration:
- Include [pause 3 seconds] markers
- Use second person ("You are...")
- Include breathing cues
- End with an empowering affirmation

Return JSON:
{
  "title": "Meditation title",
  "type": "$type",
  "duration_minutes": X,
  "script": "Full meditation script with pause markers",
  "theme": "Core theme/intention"
}
''';

      _notifyProgress(ContentType.meditation, 'Writing script...', 0.3);

      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt: 'Generate meditation scripts in valid JSON format only.',
        maxTokens: 2000,
      );

      final meditation = jsonDecode(response) as Map<String, dynamic>;
      final script = meditation['script'] as String;

      _notifyProgress(ContentType.meditation, 'Generating audio...', 0.5);

      // Generate audio
      final audioBytes = await _generateAudio(
        script.replaceAll(RegExp(r'\[pause \d+ seconds?\]'), '...'),
        'meditation',
      );

      _notifyProgress(ContentType.meditation, 'Saving meditation...', 0.8);

      // Save to database
      final db = await _database.database;
      final audioPath = audioBytes != null
          ? await _saveAudioFile(
              'meditation_${type}_${DateTime.now().millisecondsSinceEpoch}',
              audioBytes)
          : null;
      final createdAt = DateTime.now().toIso8601String();
      final contentDate = createdAt.split('T')[0];

      await db.insert('generation_queue', {
        'type': 'meditation',
        'status': 'completed',
        'input_data': jsonEncode({'type': type}),
        'output_data': jsonEncode({
          ...meditation,
          'audioPath': audioPath,
        }),
        'content_date': contentDate,
        'image_path': null,
        'audio_path': audioPath,
        'created_at': createdAt,
        'completed_at': createdAt,
      });

      _notifyProgress(
          ContentType.meditation, '${meditation['title']} ready!', 1.0);
      return true;
    } catch (e) {
      Logger.error('Failed to generate meditation: $e', tag: _tag);
      _notifyProgress(ContentType.meditation, 'Failed: $e', 0.0);
      return false;
    }
  }

  // ============================================================
  // MEAL SUGGESTION
  // ============================================================

  Future<bool> _generateMealSuggestion() async {
    _notifyProgress(
        ContentType.mealPlan, 'Calculating nutrition needs...', 0.1);

    try {
      final nutrition = _genesisProfile?['nutrition'] as Map<String, dynamic>?;
      final proteinTarget =
          (nutrition?['proteinTarget'] as Map?)?['grams'] ?? 150;

      // Get today's consumed protein from database
      final db = await _database.database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final meals = await db.query(
        'meal_logs',
        where: "timestamp LIKE ?",
        whereArgs: ['$today%'],
      );

      final proteinConsumed = meals.fold<int>(
        0,
        (sum, m) => sum + ((m['protein_grams'] as int?) ?? 0),
      );
      final proteinRemaining = proteinTarget - proteinConsumed;

      if (proteinRemaining <= 20) {
        _notifyProgress(ContentType.mealPlan, 'Protein target met! 💪', 1.0);
        return true;
      }

      final hour = DateTime.now().hour;
      final mealType = hour < 10
          ? 'breakfast'
          : hour < 14
              ? 'lunch'
              : hour < 18
                  ? 'snack'
                  : 'dinner';

      final preferredSources =
          (nutrition?['preferences']?['preferredProteinSources'] as List?)
                  ?.cast<String>() ??
              [];

      final prompt = '''
Suggest a $mealType with ~${proteinRemaining}g protein.
Preferred sources: ${preferredSources.take(4).join(', ')}

Return JSON:
{
  "name": "Meal name",
  "description": "Brief description",
  "protein_grams": X,
  "calories": X,
  "ingredients": ["ingredient 1", ...],
  "prep_time_minutes": X,
  "instructions": "Brief prep instructions"
}
''';

      _notifyProgress(ContentType.mealPlan, 'Finding meal options...', 0.5);

      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt: 'Generate meal suggestions in valid JSON format only.',
        maxTokens: 600,
      );

      final meal = jsonDecode(response) as Map<String, dynamic>;

      _notifyProgress(ContentType.mealPlan, 'Suggested: ${meal['name']}', 1.0);
      return true;
    } catch (e) {
      Logger.error('Failed to generate meal suggestion: $e', tag: _tag);
      _notifyProgress(ContentType.mealPlan, 'Failed: $e', 0.0);
      return false;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  void _notifyProgress(ContentType type, String message, double progress) {
    Logger.info('[$type] $message ($progress)', tag: _tag);
    onProgress?.call(type, message, progress);
  }

  bool _isTrainingDay() {
    final experiment = _genesisProfile?['experiment'] as Map<String, dynamic>?;
    final schedule =
        (experiment?['protocol'] as Map?)?['schedule'] as List? ?? [];
    final today = DateTime.now();
    final dayName = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ][today.weekday % 7];
    return schedule.contains(dayName);
  }

  String _getWorkoutTypeForDay(int weekday) {
    // Upper/Lower split example
    switch (weekday) {
      case 1:
        return 'lower'; // Monday - Squat focus
      case 2:
        return 'upper'; // Tuesday
      case 4:
        return 'lower'; // Thursday - Squat focus
      case 5:
        return 'upper'; // Friday
      case 6:
        return 'full_body'; // Saturday
      default:
        return 'rest';
    }
  }

  String _getMeditationType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'morning';
    if (hour < 17) return 'focus';
    return 'evening';
  }

  int _getMeditationDuration(String type) {
    switch (type) {
      case 'morning':
        return 10;
      case 'focus':
        return 5;
      case 'evening':
        return 15;
      default:
        return 10;
    }
  }

  String _getMeditationFocus(String type) {
    switch (type) {
      case 'morning':
        return 'Set intentions for the day. Connect with inner Hero. Visualize successful training and deep work.';
      case 'focus':
        return 'Quick reset. Return to presence. Clear mental fog. Prepare for deep work.';
      case 'evening':
        return 'Review the day with gratitude. Release tension. Prepare for restorative sleep.';
      default:
        return 'General mindfulness and presence.';
    }
  }

  Future<bool> _checkContentExists(Database db, String type) async {
    final result = await db.query(
      'generation_queue',
      where: "type = ? AND status = 'completed'",
      whereArgs: [type],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> _getMantrasCount(Database db) async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM mantras');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> _getExercisesCount(Database db) async {
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM exercise_types');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<bool> _checkTodayWorkout(Database db, String today) async {
    final result = await db.query(
      'workout_logs',
      where: "start_time LIKE ? AND source = 'generated'",
      whereArgs: ['$today%'],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> _getTodayMeditationsCount(Database db, String today) async {
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM generation_queue WHERE type = 'meditation' AND (content_date = ? OR created_at LIKE ?)",
      [today, '$today%'],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<Uint8List?> _generateAudio(String text, String voiceType) async {
    try {
      final apiKey = ElevenLabsConfig.apiKey;
      if (apiKey.isEmpty) {
        Logger.warning('ElevenLabs API key not configured', tag: _tag);
        return null;
      }

      final voiceId = ElevenLabsConfig.getVoiceId(voiceType);
      final settings = ElevenLabsConfig.getSettings(voiceType);

      final uri = Uri.parse(
          '${ElevenLabsConfig.baseUrl}/text-to-speech/$voiceId?output_format=mp3_44100_128');

      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': apiKey,
        },
        body: jsonEncode({
          'text': text,
          'model_id': ElevenLabsConfig.defaultModel,
          'voice_settings': settings,
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        Logger.error('ElevenLabs error: ${response.statusCode}', tag: _tag);
        return null;
      }
    } catch (e) {
      Logger.error('Audio generation failed: $e', tag: _tag);
      return null;
    }
  }

  Future<String> _saveAudioFile(String name, Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/audio/$name.mp3');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String> _saveImageFile(String name, Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/images/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  void dispose() {
    _httpClient.close();
  }
}
