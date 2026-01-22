import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/azure_ai_config.dart';
import '../config/elevenlabs_config.dart';
import '../database/app_database.dart';
import '../models/tracking/meditation_log.dart';
import '../utils/logger.dart';
import 'azure_agent_service.dart';
import 'azure_image_service.dart';
import 'notification_service.dart';
import 'weather_service.dart';

/// Service to generate daily meditations and visualizations.
///
/// Orchestrates:
/// - Azure AI (script generation)
/// - FLUX.2-pro (image generation)
/// - ElevenLabs (audio generation)
/// - WeatherKit (weather context)
/// - Mantras & Prime data (personalization seed)
///
/// Model Strategy:
/// - GPT-5 Nano: Processing tasks (image prompts, summarization, extraction)
/// - GPT-5.2 Chat: User-facing content (meditation scripts, affirmations)
///
/// Token Limits:
/// - Nano: 128k output, needs min 1000 tokens, cheapest
/// - Chat: 16k output, works with 500+ tokens, quality
class DailyContentService {
  static const String _tag = 'DailyContentService';
  static const String _lastGeneratedKey = 'daily_content_last_generated';

  final AzureAgentService _agentService;
  final AzureImageService _imageService;
  final WeatherService _weatherService;
  final AppDatabase _database;
  final http.Client _client;
  NotificationService? _notificationService;
  bool _isInitialized = false;

  // Cached seed data from Princeps files
  List<String> _mantras = [];
  Map<String, dynamic> _primeData = {};

  DailyContentService({
    required AzureAgentService agentService,
    required AzureImageService imageService,
    required AppDatabase database,
    WeatherService? weatherService,
    http.Client? client,
    NotificationService? notificationService,
  })  : _agentService = agentService,
        _imageService = imageService,
        _weatherService = weatherService ?? WeatherService(),
        _database = database,
        _client = client ?? http.Client(),
        _notificationService = notificationService;

  /// Set notification service (can be injected after construction)
  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  /// Initialize service and load seed data
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadSeedData();
    _isInitialized = true;
    Logger.info('DailyContentService initialized', tag: _tag);
  }

  /// Load mantras and prime data from docs
  Future<void> _loadSeedData() async {
    try {
      // Load Mantras
      final mantrasContent =
          await rootBundle.loadString('docs/Princeps_Mantras.md');
      _mantras = _parseMantras(mantrasContent);
      Logger.debug('Loaded ${_mantras.length} mantras', tag: _tag);
    } catch (e) {
      Logger.warning('Could not load Princeps_Mantras.md: $e', tag: _tag);
      _mantras = _getDefaultMantras();
    }

    try {
      // Load Prime data
      final primeContent =
          await rootBundle.loadString('docs/Princeps_Prime.md');
      _primeData = _parsePrimeData(primeContent);
      Logger.debug('Loaded Prime data', tag: _tag);
    } catch (e) {
      Logger.warning('Could not load Princeps_Prime.md: $e', tag: _tag);
      _primeData = _getDefaultPrimeData();
    }
  }

  /// Parse mantras from markdown file
  List<String> _parseMantras(String content) {
    final lines = content.split('\n');
    final mantras = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      // Skip headers, empty lines, and non-affirmation lines
      if (trimmed.isEmpty ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('-') ||
          trimmed.startsWith('To ') ||
          trimmed.startsWith('Do ') ||
          trimmed.startsWith('Am ') ||
          trimmed.startsWith('Can ') ||
          trimmed.startsWith('Are ') ||
          trimmed.startsWith('Have ') ||
          trimmed.contains('?')) {
        continue;
      }
      // Only include lines that start with "I " or "My " or "We "
      if (trimmed.startsWith('I ') ||
          trimmed.startsWith('My ') ||
          trimmed.startsWith('We ')) {
        mantras.add(trimmed);
      }
    }

    return mantras;
  }

  /// Parse prime data from markdown file
  Map<String, dynamic> _parsePrimeData(String content) {
    return {
      'name': 'Princeps Polycap',
      'birthDate': 'June 18, 1996',
      'mission': 'To elevate the conscious awareness of the human race',
      'archetypes': {
        'ego': 'Hero',
        'soul': 'Creator',
        'self': 'Magician',
      },
      'coreBeliefs': [
        'Humanity is transitioning from unconsciously crafting its future to consciously shaping it',
        'The purpose of everything is to serve others',
        'We are the architects of our future',
      ],
      'philosophy': ['Zen Buddhism', 'Carl Jung', 'CBT'],
      'rawContent': content,
    };
  }

  /// Default mantras if file not found
  List<String> _getDefaultMantras() {
    return [
      'I am present in this moment',
      'I am fully aware of my surroundings',
      'I trust the light within',
      'I choose to embrace my full potential',
      'I am creating the life I desire',
      'My flow states increase my confidence',
      'I am at peace with all',
    ];
  }

  /// Default prime data if file not found
  Map<String, dynamic> _getDefaultPrimeData() {
    return {
      'name': 'Seeker',
      'mission': 'To raise conscious awareness',
      'archetypes': {
        'ego': 'Hero',
        'soul': 'Creator',
        'self': 'Magician',
      },
    };
  }

  /// Get a random mantra
  String getRandomMantra() {
    if (_mantras.isEmpty) return 'I am present in this moment';
    return _mantras[Random().nextInt(_mantras.length)];
  }

  /// Get mantras by category/protocol
  List<String> getMantrasForState(String state) {
    final stateKeywords = state.toLowerCase().split(' ');
    return _mantras.where((m) {
      final lower = m.toLowerCase();
      return stateKeywords.any((k) => lower.contains(k));
    }).toList();
  }

  /// Get archetypes from prime data
  Map<String, String> get archetypes {
    final arch = _primeData['archetypes'];
    if (arch is Map) {
      return Map<String, String>.from(arch);
    }
    return {'ego': 'Hero', 'soul': 'Creator', 'self': 'Magician'};
  }

  /// Check if we need to generate content for today
  Future<bool> shouldGenerateForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastGeneratedKey);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return lastDate != today;
  }

  /// Generate a daily meditation with audio and image
  /// Returns a [MeditationLog] representing the generated session
  Future<MeditationLog?> generateDailyMeditation({
    String? mood,
    String? focus,
  }) async {
    if (!_isInitialized) await initialize();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Logger.info('Generating daily meditation for $today', tag: _tag);

    try {
      // 1. Get weather context
      final weather = await _getWeatherContext();

      // 2. Generate Script with weather + mantras context
      final script = await _generateMeditationScript(mood, focus, weather);
      Logger.info('Generated script: ${script.length} chars', tag: _tag);

      // 3. Generate Image
      final imagePrompt = await _generateImagePrompt(script, weather);
      final imageResult = await _imageService.generateImage(
        prompt: imagePrompt,
        size: ImageSize.portrait,
      );

      // Save image locally
      final imagePath =
          await _saveLocalFile('meditation_$today.png', imageResult.bytes);

      // 4. Generate Audio
      final audioBytes = await _generateAudio(
        text: script,
        voiceType: VoiceType.meditation,
      );

      // Save audio locally
      final audioPath =
          await _saveLocalFile('meditation_$today.mp3', audioBytes);

      // 5. Persist generation metadata (date-linked assets)
      final createdAt = DateTime.now().toIso8601String();
      try {
        final db = await _database.database;
        await db.insert('generation_queue', {
          'type': 'meditation',
          'status': 'completed',
          'priority': 0,
          'input_data': jsonEncode({
            'mood': mood,
            'focus': focus,
            'weather': weather,
          }),
          'output_data': jsonEncode({
            'script': script,
            'imagePath': imagePath,
            'audioPath': audioPath,
          }),
          'content_date': today,
          'image_path': imagePath,
          'audio_path': audioPath,
          'created_at': createdAt,
          'completed_at': createdAt,
        });
        Logger.info('Saved daily meditation metadata', tag: _tag, data: {
          'contentDate': today,
          'imagePath': imagePath,
          'audioPath': audioPath,
        });
      } catch (e) {
        Logger.warning('Failed to persist meditation metadata: $e', tag: _tag);
      }

      // 6. Mark as generated
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastGeneratedKey, today);

      Logger.info('Daily content generated successfully', tag: _tag, data: {
        'imagePath': imagePath,
        'audioPath': audioPath,
      });

      return MeditationLog(
        startTime: DateTime.now(),
        durationMinutes: 5,
        type: MeditationType.visualization,
        source: MeditationSource.appSync, // Generated by app
        guidedSession: true,
        audioTrackName: audioPath,
        notes: script,
      );
    } catch (e, stack) {
      Logger.error('Failed to generate daily content',
          tag: _tag, error: e, stackTrace: stack);
      return null;
    }
  }

  /// Generate multiple daily meditations (morning, focus, evening).
  Future<List<Map<String, dynamic>>> generateDailyMeditations({
    List<String>? types,
  }) async {
    if (!_isInitialized) await initialize();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final weather = await _getWeatherContext();
    final selectedTypes = types ?? const ['morning', 'focus', 'evening'];
    final results = <Map<String, dynamic>>[];

    for (final type in selectedTypes) {
      final preset = _buildMeditationPreset(type);
      try {
        final script =
            await _generateMeditationScript(preset.mood, preset.focus, weather);
        final imagePrompt = await _generateImagePrompt(script, weather);

        String? imagePath;
        try {
          final imageResult = await _imageService.generateImage(
            prompt: imagePrompt,
            size: ImageSize.portrait,
          );
          imagePath = await _saveLocalFile(
            'meditation_${type}_$today.png',
            imageResult.bytes,
          );
        } catch (e) {
          Logger.warning('Failed to generate meditation image: $e', tag: _tag);
        }

        String? audioPath;
        try {
          final audioBytes = await _generateAudio(
            text: script,
            voiceType: VoiceType.meditation,
          );
          audioPath = await _saveLocalFile(
            'meditation_${type}_$today.mp3',
            audioBytes,
          );
        } catch (e) {
          Logger.warning('Failed to generate meditation audio: $e', tag: _tag);
        }

        final description = _summarizeScript(script);
        final createdAt = DateTime.now().toIso8601String();

        final outputData = {
          'title': preset.title,
          'description': description,
          'type': preset.type,
          'duration_minutes': preset.durationMinutes,
          'script': script,
          'mood': preset.mood,
          'focus': preset.focus,
          'imagePath': imagePath,
          'audioPath': audioPath,
        };

        final db = await _database.database;
        await db.insert('generation_queue', {
          'type': 'meditation',
          'status': 'completed',
          'priority': 0,
          'input_data': jsonEncode({
            'type': preset.type,
            'mood': preset.mood,
            'focus': preset.focus,
            'weather': weather,
          }),
          'output_data': jsonEncode(outputData),
          'content_date': today,
          'image_path': imagePath,
          'audio_path': audioPath,
          'created_at': createdAt,
          'completed_at': createdAt,
        });

        results.add(outputData);
      } catch (e, stack) {
        Logger.error('Failed to generate meditation: $e',
            tag: _tag, error: e, stackTrace: stack);
      }
    }

    return results;
  }

  /// Generate a daily set of mantras and store for today.
  Future<List<String>> generateDailyMantras({
    int count = 4,
    String? mood,
    String? focus,
  }) async {
    if (!_isInitialized) await initialize();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final weather = await _getWeatherContext();
    final seedMantras = _selectSessionMantras(mood, focus);
    final arch = archetypes;

    final prompt = '''
Create $count original daily mantras.

Context:
- Weather: ${weather['emoji']} ${weather['condition']} (${weather['description']})
- Archetypes: ${arch['ego']}, ${arch['soul']}, ${arch['self']}
- Mood: ${mood ?? 'Open'}
- Focus: ${focus ?? 'Presence and awareness'}

Seed inspiration (do not repeat verbatim):
${seedMantras.map((m) => '- "$m"').join('\n')}

Requirements:
- First person ("I am...", "I...")
- 8-16 words each
- Distinct from each other
- Return ONLY a JSON array of strings
''';

    List<String> mantras = [];
    try {
      final response = await _agentService.complete(
        prompt: prompt,
        deployment: AzureAIDeployment.gpt5,
        temperature: 0.7,
        maxTokens: 800,
        responseFormat: 'json',
      );

      final decoded = jsonDecode(response) as List;
      mantras = decoded.map((m) => m.toString()).toList();
    } catch (e) {
      Logger.warning('Mantra generation failed, using seed mantras: $e',
          tag: _tag);
      mantras = _selectSessionMantras(mood, focus);
    }

    if (mantras.isEmpty) {
      mantras = _getDefaultMantras().take(count).toList();
    }
    if (mantras.length < count) {
      final fallback = _getDefaultMantras();
      var index = 0;
      while (mantras.length < count && index < fallback.length) {
        if (!mantras.contains(fallback[index])) {
          mantras.add(fallback[index]);
        }
        index++;
      }
    }

    final createdAt = DateTime.now().toIso8601String();
    final db = await _database.database;
    await db.insert('generation_queue', {
      'type': 'mantras',
      'status': 'completed',
      'priority': 0,
      'input_data': jsonEncode({
        'mood': mood,
        'focus': focus,
        'weather': weather,
      }),
      'output_data': jsonEncode({'mantras': mantras}),
      'content_date': today,
      'created_at': createdAt,
      'completed_at': createdAt,
    });

    // Fire-and-forget image generation for mantras
    _generateMantraImages(mantras, today);

    return mantras;
  }

  /// Generate images for mantras in the background
  Future<void> _generateMantraImages(
      List<String> mantras, String dateKey) async {
    if (!_imageService.isInitialized) {
      Logger.warning('Image service not available for mantra images',
          tag: _tag);
      return;
    }

    final db = await _database.database;

    for (var i = 0; i < mantras.length; i++) {
      try {
        final mantra = mantras[i];
        Logger.info('Generating image for mantra ${i + 1}/${mantras.length}',
            tag: _tag);

        // Create visual prompt from mantra
        final imagePrompt = await _createMantraImagePrompt(mantra);

        final imageResult = await _imageService.generateImage(
          prompt: imagePrompt,
          size: ImageSize.landscape,
        );

        // Save to local file
        final dir = await getApplicationDocumentsDirectory();
        final filename = 'mantra_${i}_$dateKey.png';
        final file = File('${dir.path}/images/mantras/$filename');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(imageResult.bytes);

        // Store path in generation_queue metadata
        await db.insert('mantra_images', {
          'mantra_text': mantra,
          'image_path': file.path,
          'date_key': dateKey,
          'created_at': DateTime.now().toIso8601String(),
        });

        Logger.debug('Saved mantra image: ${file.path}', tag: _tag);

        // Small delay to avoid rate limits
        if (i < mantras.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        Logger.warning('Failed to generate image for mantra $i: $e', tag: _tag);
      }
    }

    Logger.info('Completed mantra image generation', tag: _tag);
  }

  /// Create a visual image prompt from a mantra
  Future<String> _createMantraImagePrompt(String mantra) async {
    final prompt = '''
Create a concise image prompt for an AI image generator based on this mantra:
"$mantra"

Requirements:
- Ethereal, inspirational, cinematic scene
- No text, letters, or symbols
- Symbolic visual representation of the mantra's essence
- Under 30 words

Return ONLY the image prompt, nothing else.
''';

    try {
      final response = await _agentService.complete(
        prompt: prompt,
        deployment: AzureAIDeployment.gpt5Nano,
        maxTokens: 100,
      );
      return response.trim();
    } catch (e) {
      // Fallback to a generic prompt based on category keywords
      if (mantra.toLowerCase().contains('source code') ||
          mantra.toLowerCase().contains('version')) {
        return 'A luminous digital consciousness evolving, ethereal circuits and light, cinematic, peaceful transformation';
      }
      if (mantra.toLowerCase().contains('building') ||
          mantra.toLowerCase().contains('create')) {
        return 'An architect of light constructing a magnificent structure, golden rays, cosmic scale, inspiring';
      }
      return 'A serene figure in meditation, surrounded by soft golden light, cosmic backdrop, peaceful and powerful';
    }
  }

  /// Get mantra image path for a given mantra text
  Future<String?> getMantraImagePath(String mantraText) async {
    final db = await _database.database;
    final rows = await db.query(
      'mantra_images',
      where: 'mantra_text = ?',
      whereArgs: [mantraText],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['image_path'] as String?;
  }

  /// Mark today's daily content as generated.
  Future<void> markGeneratedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString(_lastGeneratedKey, today);
  }

  /// Get weather context for personalization
  Future<Map<String, dynamic>> _getWeatherContext() async {
    try {
      final weather = await _weatherService.getCurrentWeather();
      if (weather != null) {
        return {
          'temperature': weather.temperature,
          'condition': weather.condition,
          'description': weather.conditionDescription,
          'emoji': weather.emoji,
          'greeting': weather.morningGreeting,
          'isDaylight': weather.isDaylight,
        };
      }
    } catch (e) {
      Logger.warning('Could not fetch weather: $e', tag: _tag);
    }

    // Default fallback
    return {
      'temperature': 20,
      'condition': 'Clear',
      'description': 'A peaceful day',
      'emoji': '☀️',
      'greeting': 'Have a wonderful day.',
      'isDaylight': true,
    };
  }

  /// Generate the text script using Azure Agent with full context
  Future<String> _generateMeditationScript(
    String? mood,
    String? focus,
    Map<String, dynamic> weather,
  ) async {
    // Select relevant mantras for this session
    final sessionMantras = _selectSessionMantras(mood, focus);
    final arch = archetypes;

    final prompt = '''
Create a short, calming daily meditation script (approx 150-200 words).

Context:
- Date: ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}
- Weather: ${weather['emoji']} ${weather['condition']} - ${weather['description']}
- Temperature: ${weather['temperature']}°C
- ${weather['greeting']}

User Context:
- Current Mood: ${mood ?? 'Neutral/Open'}
- Focus Area: ${focus ?? 'General presence and awareness'}
- Dominant Archetype: ${arch['ego']} (action), ${arch['soul']} (expression), ${arch['self']} (transformation)

Seed Mantras to weave in naturally:
${sessionMantras.map((m) => '- "$m"').join('\n')}

Structure:
1. Weather-aware greeting and grounding (acknowledge the ${weather['condition'].toString().toLowerCase()} day)
2. Breath awareness with archetype alignment
3. Main visualization or insight (related to ${focus ?? 'presence'})
4. Integration of one mantra theme
5. Positive affirmation and closing

Format: Pure spoken text, no markdown, no headers. 
Tone: Wise, warm, like a trusted guide. Use "you" to address the listener.
Pace: Include natural pauses marked with "..."
''';

    // Use GPT-5.2 Chat for user-facing meditation scripts (quality content)
    final response = await _agentService.chat(
      messages: [
        ChatMessage.system(
            'You are a wise, calming meditation guide embodying Zen philosophy and Jungian depth. '
            'You help people raise their conscious awareness through presence and insight.'),
        ChatMessage.user(prompt),
      ],
      deployment: AzureAIDeployment.gpt5, // Quality model for user content
      temperature: 0.7,
      maxTokens: 2000, // Meditation scripts need room
    );

    return response.message.content ??
        'Take a deep breath... and begin your day with presence.';
  }

  /// Select mantras relevant to the session
  List<String> _selectSessionMantras(String? mood, String? focus) {
    if (_mantras.isEmpty) return _getDefaultMantras().take(3).toList();

    final selected = <String>[];
    final random = Random();

    // Try to find focus-related mantras
    if (focus != null) {
      final related = getMantrasForState(focus);
      if (related.isNotEmpty) {
        selected.add(related[random.nextInt(related.length)]);
      }
    }

    // Add some random mantras
    while (selected.length < 3 && _mantras.isNotEmpty) {
      final mantra = _mantras[random.nextInt(_mantras.length)];
      if (!selected.contains(mantra)) {
        selected.add(mantra);
      }
    }

    return selected;
  }

  /// Extract a visual prompt from the script with weather context
  Future<String> _generateImagePrompt(
    String script,
    Map<String, dynamic> weather,
  ) async {
    final arch = archetypes;
    final prompt = '''
Based on this meditation script and context, create a detailed prompt for FLUX.2-pro image generator.

Weather: ${weather['condition']} - ${weather['description']}
Time: ${weather['isDaylight'] == true ? 'Daytime' : 'Evening/Night'}
Archetype theme: ${arch['self']} (transformation, vision)

Script excerpt:
"${script.substring(0, script.length > 400 ? 400 : script.length)}..."

Requirements:
- Abstract, symbolic, no faces or text
- Calming color palette matching the weather (${weather['condition']})
- Include subtle sacred geometry elements
- Minimalist zen aesthetic
- Soft gradients, elegant negative space
- Portrait orientation (phone wallpaper)

Output: ONLY the image prompt string, nothing else.
''';

    // Use GPT-5 for quality image prompts
    final response = await _agentService.complete(
      prompt: prompt,
      deployment: AzureAIDeployment.gpt5Nano,
    );

    return response;
  }

  /// Generate audio using ElevenLabs
  Future<List<int>> _generateAudio({
    required String text,
    required VoiceType voiceType,
  }) async {
    final apiKey = ElevenLabsConfig.apiKey;
    if (apiKey.isEmpty) {
      throw Exception('ElevenLabs API key not configured');
    }

    final voiceId = ElevenLabsConfig.getVoiceId(voiceType);
    final settings = ElevenLabsConfig.getSettings(voiceType);

    final uri = Uri.parse(
        '${ElevenLabsConfig.baseUrl}/text-to-speech/$voiceId?output_format=mp3_44100_128');

    final body = {
      'text': text,
      'model_id': ElevenLabsConfig.defaultModel,
      'voice_settings': settings,
    };

    Logger.info('Calling ElevenLabs TTS', tag: _tag, data: {
      'voiceId': voiceId,
      'charCount': text.length,
    });

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'xi-api-key': apiKey,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'ElevenLabs API error: ${response.statusCode} - ${response.body}');
    }

    return response.bodyBytes;
  }

  /// Helper to save bytes to local file
  Future<String> _saveLocalFile(String filename, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    // Determine subdirectory based on file extension
    String subdir = 'generated';
    if (filename.endsWith('.png') || filename.endsWith('.jpg')) {
      if (filename.startsWith('meditation')) {
        subdir = 'images/meditations';
      } else {
        subdir = 'images';
      }
    } else if (filename.endsWith('.mp3')) {
      subdir = 'audio/meditations';
    }
    final genDir = Directory('${dir.path}/$subdir');
    if (!await genDir.exists()) {
      await genDir.create(recursive: true);
    }
    final file = File('${genDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Get a daily affirmation based on current context
  Future<String> getDailyAffirmation() async {
    if (!_isInitialized) await initialize();

    try {
      final weather = await _getWeatherContext();
      final mantra = getRandomMantra();
      final arch = archetypes;

      final prompt = '''
Create a single powerful affirmation for today.

Context:
- Weather: ${weather['emoji']} ${weather['condition']}
- Base mantra: "$mantra"
- Archetype: ${arch['ego']} energy

Requirements:
- 1-2 sentences maximum
- First person ("I am...", "I...")
- Empowering, not forced
- Connect to conscious awareness
- Specific yet universal

Return only the affirmation text.
''';

      // Use GPT-5.2 Chat for user-facing affirmations (quality content)
      final response = await _agentService.complete(
        prompt: prompt,
        deployment: AzureAIDeployment.gpt5, // Quality model for user content
        temperature: 0.7,
        maxTokens: 500, // Affirmations are short
      );

      return response.trim();
    } catch (e) {
      Logger.warning('Could not generate affirmation: $e', tag: _tag);
      return getRandomMantra();
    }
  }

  /// Get usage statistics
  Future<Map<String, dynamic>> checkQuota() async {
    final apiKey = ElevenLabsConfig.apiKey;
    if (apiKey.isEmpty) return {'error': 'No API Key'};

    try {
      final response = await _client.get(
        Uri.parse('${ElevenLabsConfig.baseUrl}/user/subscription'),
        headers: {'xi-api-key': apiKey},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'tier': json['tier'],
          'character_count': json['character_count'],
          'character_limit': json['character_limit'],
          'can_extend_limit': json['can_extend_character_limit'],
          'remaining': json['character_limit'] - json['character_count'],
          'reset_date': json['next_character_count_reset_unix'],
        };
      }
      return {'error': 'Failed to fetch usage: ${response.statusCode}'};
    } catch (e) {
      return {'error': 'Error: $e'};
    }
  }

  /// Get all loaded mantras
  List<String> get mantras => List.unmodifiable(_mantras);

  /// Get prime data
  Map<String, dynamic> get primeData => Map.unmodifiable(_primeData);

  _MeditationPreset _buildMeditationPreset(String type) {
    switch (type) {
      case 'morning':
        return const _MeditationPreset(
          type: 'morning',
          title: 'Morning Energy',
          mood: 'energized',
          focus: 'Set intentions and align your day with clarity.',
          durationMinutes: 8,
        );
      case 'focus':
        return const _MeditationPreset(
          type: 'focus',
          title: 'Focused Reset',
          mood: 'centered',
          focus: 'Clear mental fog and return to deep focus.',
          durationMinutes: 6,
        );
      case 'evening':
        return const _MeditationPreset(
          type: 'evening',
          title: 'Evening Release',
          mood: 'calm',
          focus: 'Release tension and prepare for restorative rest.',
          durationMinutes: 12,
        );
      default:
        return const _MeditationPreset(
          type: 'general',
          title: 'Daily Meditation',
          mood: 'open',
          focus: 'Return to presence and awareness.',
          durationMinutes: 8,
        );
    }
  }

  String _summarizeScript(String script) {
    final cleaned = script.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= 140) return cleaned;
    return '${cleaned.substring(0, 140)}...';
  }

  // ===========================================================================
  // SURPRISE CONTENT GENERATION
  // ===========================================================================

  /// Generate a surprise image based on agent insights
  /// Called by AgentSchedulerService when the AI decides to delight the user
  Future<String?> generateSurpriseImage({
    required String triggerContext,
    String? customPrompt,
  }) async {
    if (!_isInitialized) await initialize();

    Logger.info('Generating surprise image...', tag: _tag);

    try {
      // Generate an image prompt from the context
      final imagePrompt =
          customPrompt ?? await _generateSurpriseImagePrompt(triggerContext);

      // Generate the image
      final imageResult = await _imageService.generateImage(
        prompt: imagePrompt,
        size: ImageSize.square,
      );

      // Save locally
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = await _saveLocalFile(
        'surprise_$timestamp.png',
        imageResult.bytes,
      );

      Logger.info('Surprise image generated: $imagePath', tag: _tag);

      // Show notification with the image
      if (_notificationService != null) {
        await _notificationService!.showSurpriseImage(
          title: 'A gift for you',
          body: _extractInsightFromContext(triggerContext),
          imagePath: imagePath,
        );
      }

      return imagePath;
    } catch (e, stack) {
      Logger.error('Failed to generate surprise image',
          tag: _tag, error: e, stackTrace: stack);
      return null;
    }
  }

  /// Generate a surprise insight notification (no image)
  Future<void> generateSurpriseInsight({
    required String insight,
    String? title,
  }) async {
    if (_notificationService == null) {
      Logger.warning('NotificationService not available for surprise insight',
          tag: _tag);
      return;
    }

    await _notificationService!.showInsight(
      title: title ?? 'Insight for you',
      insight: insight,
    );

    Logger.info('Surprise insight sent: $insight', tag: _tag);
  }

  /// Determine if we should surprise the user based on context and timing
  bool shouldSurpriseUser({
    required String agentOutput,
    DateTime? lastSurpriseTime,
    int minHoursBetweenSurprises = 4,
  }) {
    // Don't surprise too frequently
    if (lastSurpriseTime != null) {
      final hoursSinceLastSurprise =
          DateTime.now().difference(lastSurpriseTime).inHours;
      if (hoursSinceLastSurprise < minHoursBetweenSurprises) {
        return false;
      }
    }

    // Check if the output contains something worth sharing
    final output = agentOutput.toLowerCase();

    // Look for positive indicators
    final positiveIndicators = [
      'insight',
      'achievement',
      'milestone',
      'breakthrough',
      'completed',
      'success',
      'great job',
      'well done',
      'congratulations',
      'streak',
      'progress',
    ];

    // Check productivity score if present
    final scoreMatch =
        RegExp(r'"productivity_score"\s*:\s*(\d+)').firstMatch(output);
    if (scoreMatch != null) {
      final score = int.tryParse(scoreMatch.group(1) ?? '0') ?? 0;
      if (score >= 8) return true; // High productivity moment
    }

    // Check for positive indicators
    for (final indicator in positiveIndicators) {
      if (output.contains(indicator)) {
        // 30% chance to surprise when positive indicator found
        return Random().nextDouble() < 0.30;
      }
    }

    // Base 5% chance for any output
    return Random().nextDouble() < 0.05;
  }

  /// Generate an image prompt for surprise content
  Future<String> _generateSurpriseImagePrompt(String context) async {
    final prompt = '''
Based on this AI agent insight, create a SHORT, evocative image prompt (max 100 words) 
for a beautiful, inspiring visualization. Focus on abstract beauty, nature, or cosmic themes.
Do NOT include text or words in the image. Make it visually stunning and emotionally uplifting.

Agent Insight:
$context

Respond with ONLY the image prompt, no explanations.
''';

    final response = await _agentService.complete(
      prompt: prompt,
      systemPrompt:
          'You are an expert at creating concise, beautiful image prompts for AI art generation.',
      deployment: AzureAIDeployment.gpt5Nano,
      maxTokens: 200,
    );

    return response.trim();
  }

  /// Extract a short insight message from agent context
  String _extractInsightFromContext(String context) {
    // Try to extract the insight field from JSON
    try {
      final jsonMatch =
          RegExp(r'"insight"\s*:\s*"([^"]+)"').firstMatch(context);
      if (jsonMatch != null) {
        return jsonMatch.group(1) ?? 'A moment of inspiration for you';
      }
    } catch (_) {}

    // Fallback: use first sentence or truncate
    final firstSentence = context.split(RegExp(r'[.!?]')).first.trim();
    if (firstSentence.length <= 100) return firstSentence;
    return '${firstSentence.substring(0, 97)}...';
  }
}

class _MeditationPreset {
  final String type;
  final String title;
  final String mood;
  final String focus;
  final int durationMinutes;

  const _MeditationPreset({
    required this.type,
    required this.title,
    required this.mood,
    required this.focus,
    required this.durationMinutes,
  });
}
