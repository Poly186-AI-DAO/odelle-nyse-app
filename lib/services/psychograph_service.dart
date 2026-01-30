import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../config/azure_ai_config.dart';
import '../utils/logger.dart';
import 'azure_agent_service.dart';
import 'azure_image_service.dart';
import 'user_context_service.dart';

/// The Psychograph Service - the "subconscious" LLM
///
/// This service runs in the background to:
/// 1. Process user data (mantras, journal entries, mood logs, etc.)
/// 2. Update the psychograph (evolving understanding of the user)
/// 3. Compute the RCA (Raising Conscious Awareness) meter
/// 4. Generate personalized meditations, insights, and notifications
/// 5. Generate daily prophecy readings based on cosmic profile
///
/// Uses gpt-5-nano for fast, cheap background processing.
class PsychographService {
  static const String _tag = 'PsychographService';

  final AzureAgentService _agentService;
  final AzureImageService? _imageService;
  final UserContextService? _userContextService;
  Timer? _periodicTimer;
  bool _isProcessing = false;

  // Cached data
  Map<String, dynamic>? _genesisProfile;
  Map<String, dynamic>? _characterStats;
  List<String>? _mantras;

  // Current psychograph state
  PsychographState _state = PsychographState.initial();

  // Cached prophecy (updated daily)
  String? _dailyProphecy;
  DateTime? _prophecyDate;
  List<String> _prophecyImagePrompts = [];
  DateTime? _prophecyImageDate;
  List<String> _prophecyImagePaths = [];
  DateTime? _prophecyImagePathsDate;

  PsychographService({
    required AzureAgentService agentService,
    AzureImageService? imageService,
    UserContextService? userContextService,
  })  : _agentService = agentService,
        _imageService = imageService,
        _userContextService = userContextService;

  /// Get current psychograph state
  PsychographState get state => _state;

  /// Start the background processing
  /// [intervalMinutes] - How often to run (default: 60 minutes)
  void startBackgroundProcessing({int intervalMinutes = 60}) {
    Logger.info(
      'Starting background processing (every $intervalMinutes min)',
      tag: _tag,
    );

    // Run immediately on start
    _runProcessingCycle();

    // Then run periodically
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _runProcessingCycle(),
    );
  }

  /// Stop background processing
  void stopBackgroundProcessing() {
    Logger.info('Stopping background processing', tag: _tag);
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Trigger an immediate processing cycle
  Future<void> triggerProcessing() async {
    await _runProcessingCycle();
  }

  /// Main processing cycle
  Future<void> _runProcessingCycle() async {
    if (_isProcessing) {
      Logger.debug('Already processing, skipping cycle', tag: _tag);
      return;
    }

    _isProcessing = true;
    Logger.info('Starting psychograph processing cycle', tag: _tag);

    try {
      // 1. Load all source data
      await _loadSourceData();

      // 2. Compute RCA meter
      final rcaScore = await _computeRCAMeter();

      // 3. Update psychograph
      final psychograph = await _generatePsychograph();

      // 4. Generate insights
      final insights = await _generateInsights();

      // 5. Update state
      _state = PsychographState(
        rcaScore: rcaScore,
        psychograph: psychograph,
        insights: insights,
        lastUpdated: DateTime.now(),
        archetypes: _extractArchetypes(),
      );

      Logger.info(
        'Psychograph updated: RCA=${rcaScore.toStringAsFixed(1)}, '
        '${insights.length} insights',
        tag: _tag,
      );
    } catch (e, stack) {
      Logger.error('Processing cycle failed: $e',
          tag: _tag, error: e, stackTrace: stack);
    } finally {
      _isProcessing = false;
    }
  }

  /// Load all source data for processing
  Future<void> _loadSourceData() async {
    // Load genesis profile (Princeps_Prime.md converted to structured data)
    try {
      final genesisJson =
          await rootBundle.loadString('data/user/genesis_profile.json');
      _genesisProfile = jsonDecode(genesisJson) as Map<String, dynamic>;
    } catch (e) {
      Logger.debug('No genesis profile found, will use defaults', tag: _tag);
      _genesisProfile = _getDefaultGenesisProfile();
    }

    // Load character stats
    try {
      final statsJson =
          await rootBundle.loadString('data/misc/character_stats.json');
      final statsList = jsonDecode(statsJson) as List;
      if (statsList.isNotEmpty) {
        _characterStats = statsList.first as Map<String, dynamic>;
      }
    } catch (e) {
      Logger.debug('No character stats found', tag: _tag);
    }

    // Load mantras
    try {
      final mantrasJson = await rootBundle.loadString('data/misc/mantras.json');
      final mantrasList = jsonDecode(mantrasJson) as List;
      _mantras = mantrasList.map((m) => m['text'] as String).toList();
    } catch (e) {
      Logger.debug('No mantras found', tag: _tag);
      _mantras = [];
    }
  }

  /// Compute the RCA (Raising Conscious Awareness) meter
  ///
  /// The RCA meter measures progress toward:
  /// - Presence (being in the now)
  /// - Awareness (noticing thoughts/patterns)
  /// - Integration (embodying insights)
  ///
  /// Returns a score from 0-100
  Future<double> _computeRCAMeter() async {
    if (!_agentService.isInitialized) {
      Logger.warning('Agent service not initialized, using default RCA',
          tag: _tag);
      return 50.0;
    }

    final prompt = '''
Analyze the following user data and compute an RCA (Raising Conscious Awareness) score from 0-100.

The RCA meter measures:
1. PRESENCE - How present is the user in daily life? (based on meditation, mindfulness practices)
2. AWARENESS - How aware are they of their thought patterns? (based on journaling, CBT engagement)
3. INTEGRATION - Are they embodying insights into action? (based on behavioral consistency)

User Data:
- Archetypes: ${_characterStats?['archetypes'] ?? 'Unknown'}
- Current psychograph: ${_characterStats?['psychograph'] ?? 'No previous psychograph'}
- Mantras practiced: ${_mantras?.length ?? 0}
- Genesis mission: ${_genesisProfile?['mission'] ?? 'Self-actualization'}

Respond with ONLY a JSON object:
{"score": <number 0-100>, "breakdown": {"presence": <0-100>, "awareness": <0-100>, "integration": <0-100>}, "reasoning": "<brief explanation>"}
''';

    try {
      // RCA scoring - use quality model for accurate assessment
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'You are a psychological assessment system. Respond only with valid JSON.',
        deployment: AzureAIDeployment.gpt5,
        temperature: 0.3,
        responseFormat: 'json',
      );

      // Use extractJson to handle any residual markdown
      final cleanJson = AzureAgentService.extractJson(response);
      final result = jsonDecode(cleanJson) as Map<String, dynamic>;
      return (result['score'] as num).toDouble();
    } catch (e) {
      Logger.warning('RCA computation failed: $e', tag: _tag);
      return _state.rcaScore; // Return previous score
    }
  }

  /// Generate updated psychograph text
  Future<String> _generatePsychograph() async {
    if (!_agentService.isInitialized) {
      return _state.psychograph;
    }

    final prompt = '''
Based on the following user data, generate a concise psychograph (2-3 sentences) that captures:
- Their current mental/emotional state
- The direction they're moving
- Key patterns or themes

User Data:
- Name: ${_genesisProfile?['name'] ?? 'User'}
- DOB: ${_genesisProfile?['dateOfBirth'] ?? 'Unknown'}
- Archetypes: ${_characterStats?['archetypes'] ?? [
              'Hero',
              'Creator',
              'Magician'
            ]}
- Previous psychograph: ${_characterStats?['psychograph'] ?? 'None'}
- Mission: ${_genesisProfile?['mission'] ?? 'Self-actualization through data-driven behavioral change'}
- Philosophy: ${_genesisProfile?['philosophy'] ?? 'Zen, Jung, CBT'}

Write in second person ("You are...") and be specific, not generic.
Respond with ONLY the psychograph text, no JSON or formatting.
''';

    try {
      // Psychograph is user-facing content - use Chat for quality
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'You are a depth psychologist writing brief, insightful psychographs.',
        deployment: AzureAIDeployment.gpt5,
        temperature: 0.7,
      );

      return response.trim();
    } catch (e) {
      Logger.warning('Psychograph generation failed: $e', tag: _tag);
      return _state.psychograph;
    }
  }

  /// Generate actionable insights
  Future<List<PsychographInsight>> _generateInsights() async {
    if (!_agentService.isInitialized) {
      return [];
    }

    final prompt = '''
Generate 1-3 deep, transformative insights based on this user's psychograph and data.

USER DATA:
- Archetypes: ${_characterStats?['archetypes'] ?? [
              'Hero',
              'Creator',
              'Magician'
            ]}
- Stats: ${_characterStats?['stats'] ?? {}}
- Mantras: ${_mantras?.take(3).join(', ') ?? 'None'}
- Mission: To raise the conscious awareness of the human race through data-driven self-actualization

EACH INSIGHT MUST INCLUDE:
1. "title": A compelling 4-7 word title that captures the essence
2. "body": A substantial paragraph (5-8 sentences) that:
   - Notices a meaningful pattern in their behavior or psychology
   - Connects it to their archetypal journey (Hero/Creator/Magician)
   - Explains WHY this matters for their growth
   - Uses the CBT framework: how thoughts influence emotions and behaviors
   - Feels like wisdom from a trusted mentor, not generic advice
3. "action": A specific, measurable action (2-3 sentences) they can take TODAY
4. "category": One of "presence", "awareness", or "integration"
5. "image_prompts": 3 cinematic image prompts (no text in images)

FORMATTING RULES:
- NEVER use em-dashes (—) or en-dashes (–). Use commas or colons instead.
- No markdown formatting
- Write in second person ("You", "Your")

Respond with JSON array:
[{"title": "...", "body": "...", "action": "...", "category": "presence|awareness|integration", "image_prompts": ["...", "...", "..."]}]
''';

    try {
      // Insights are user-facing content - use Chat for quality
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            '''You are a wise mentor and depth psychologist who generates profound, actionable insights.
Your insights feel like revelations, not platitudes.
You understand Jungian archetypes, CBT cognitive reframing, and the journey of self-actualization.
NEVER use em-dashes (—) or en-dashes (–) in your output.''',
        deployment: AzureAIDeployment.gpt5,
        temperature: 0.6,
        responseFormat: 'json',
      );

      // Use extractJson to handle any residual markdown
      final cleanJson = AzureAgentService.extractJson(response);
      final decoded = jsonDecode(cleanJson);

      // Handle both array format and object-with-array format
      List insightsList;
      if (decoded is List) {
        insightsList = decoded;
      } else if (decoded is Map && decoded.containsKey('insights')) {
        insightsList = decoded['insights'] as List;
      } else if (decoded is Map) {
        // Single insight wrapped in object
        insightsList = [decoded];
      } else {
        return [];
      }

      final insights = insightsList
          .map((i) => PsychographInsight.fromJson(i as Map<String, dynamic>))
          .toList();

      // Generate images for each insight if image service is available
      if (_imageService != null && _imageService!.isInitialized) {
        return await _generateInsightImages(insights);
      }

      return insights;
    } catch (e) {
      Logger.warning('Insight generation failed: $e', tag: _tag);
      return [];
    }
  }

  /// Generate images for insights from their prompts
  Future<List<PsychographInsight>> _generateInsightImages(
    List<PsychographInsight> insights,
  ) async {
    if (_imageService == null || !_imageService!.isInitialized) {
      return insights;
    }

    final result = <PsychographInsight>[];
    final today = DateTime.now().toIso8601String().split('T')[0];

    for (var i = 0; i < insights.length; i++) {
      final insight = insights[i];
      final imagePaths = <String>[];

      // Generate up to 3 images per insight
      for (var j = 0; j < insight.imagePrompts.length && j < 3; j++) {
        try {
          final prompt = insight.imagePrompts[j];
          Logger.info('Generating insight image $j for "${insight.title}"',
              tag: _tag);

          final imageResult = await _imageService!.generateImage(
            prompt: prompt,
            size: ImageSize.square,
          );

          // Save to local file
          final path = await _saveImageFile(
            'insight_${i}_${j}_$today.png',
            imageResult.bytes,
          );
          if (path != null) {
            imagePaths.add(path);
          }
        } catch (e) {
          Logger.warning('Failed to generate insight image $j: $e', tag: _tag);
        }
      }

      result.add(insight.copyWithImages(imagePaths));
    }

    return result;
  }

  /// Save image bytes to local file
  Future<String?> _saveImageFile(String filename, List<int> bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/images/insights/$filename');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      Logger.debug('Saved image: ${file.path}', tag: _tag);
      return file.path;
    } catch (e) {
      Logger.warning('Failed to save image: $e', tag: _tag);
      return null;
    }
  }

  /// Extract archetypes from loaded data
  List<String> _extractArchetypes() {
    final archetypes = _characterStats?['archetypes'];
    if (archetypes != null) {
      // Handle both Map and List formats
      if (archetypes is Map) {
        return List<String>.from(archetypes.values);
      } else if (archetypes is Iterable) {
        return List<String>.from(archetypes);
      }
    }
    // Default from Princeps_Prime
    return ['Hero', 'Creator', 'Magician'];
  }

  /// Default genesis profile based on Princeps_Prime.md
  Map<String, dynamic> _getDefaultGenesisProfile() {
    return {
      'name': 'Princeps Polycap',
      'dateOfBirth': '1996-06-18',
      'mission': 'To raise the conscious awareness of the human race',
      'philosophy': ['Zen Buddhism', 'Carl Jung', 'CBT'],
      'archetypes': {
        'ego': 'Hero',
        'soul': 'Creator',
        'self': 'Magician',
      },
      'coreBeliefs': [
        'Humanity is transitioning from unconsciously crafting its future to consciously shaping it',
        'The purpose of everything is to serve others',
        'Data-driven decisions enable self-determined behavioral change',
      ],
      'thesis':
          'Data-driven behavioral change in pursuit of self-actualization',
    };
  }

  /// Get the daily prophecy reading
  ///
  /// Returns cached prophecy if already generated today, otherwise generates new one.
  /// The prophecy is a mythological, inspiring reading based on cosmic profile.
  Future<String> getDailyProphecy({bool forceRegenerate = false}) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Return cached if still valid
    if (!forceRegenerate &&
        _dailyProphecy != null &&
        _prophecyDate == todayDate) {
      return _dailyProphecy!;
    }

    Logger.info('Generating daily prophecy for $todayDate', tag: _tag);

    try {
      // Use UserContextService if available, otherwise build from genesis profile
      final prompt = _userContextService != null
          ? _userContextService!.generatePsychographPrompt(today)
          : _buildProphecyPrompt(today);

      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            '''You are an ancient oracle channeling the wisdom of Jungian archetypes, astrology, and numerology into transformative prophecies.

FORMATTING RULES (CRITICAL - FOLLOW EXACTLY):
- NEVER use em-dashes (—) or en-dashes (–). Use commas, colons, or periods instead.
- NEVER use markdown formatting (no **, *, #, or bullet points)
- Write in flowing, readable prose only
- Use proper punctuation with spaces

CONTENT STRUCTURE:
- Write 3-4 substantial paragraphs (not 2-3 short ones)
- Each paragraph should be 4-6 sentences
- First paragraph: Set the cosmic stage for today
- Second paragraph: Connect their archetypes to today's energy
- Third paragraph: The transformation or opportunity available
- Fourth paragraph: Close with an actionable insight or mantra

VOICE & TONE:
- Speak in second person ("You are...", "Today you...")
- Be SPECIFIC to their cosmic profile, never generic
- Mythic and powerful, not vague or fluffy
- Like a wise sage who truly knows them
- Reference specific aspects of their chart (Sun/Moon/Rising, Life Path, etc.)

INTEGRATION:
- Connect to their mission of raising conscious awareness
- Reference the journey of self-actualization
- Weave in their Hero/Creator/Magician archetype blend
- Make it feel personally relevant, not like a newspaper horoscope''',
        deployment: AzureAIDeployment.gpt5,
        temperature: 0.8,
      );

      _dailyProphecy = response.trim();
      _prophecyDate = todayDate;

      Logger.info('Prophecy generated: ${_dailyProphecy!.length} chars',
          tag: _tag);
      return _dailyProphecy!;
    } catch (e, stack) {
      Logger.error('Failed to generate prophecy: $e',
          tag: _tag, error: e, stackTrace: stack);
      return _getDefaultProphecy(today);
    }
  }

  /// Build prophecy prompt from genesis profile
  String _buildProphecyPrompt(DateTime date) {
    final dayOfWeek = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ][date.weekday % 7];

    final identity = _genesisProfile?['identity'] as Map<String, dynamic>?;
    final zodiac = identity?['zodiac'] as Map<String, dynamic>?;
    final numerology = identity?['numerology'] as Map<String, dynamic>?;
    final archetypes = _genesisProfile?['archetypes'] as Map<String, dynamic>?;
    final primary = archetypes?['primary'] as Map<String, dynamic>?;
    final cosmic = _genesisProfile?['cosmicProfile'] as Map<String, dynamic>?;

    return '''
Generate a psychograph prophecy reading for $dayOfWeek, ${date.month}/${date.day}/${date.year}.

COSMIC PROFILE:
- Sun: ${zodiac?['sun'] ?? 'Gemini'}
- Moon: ${zodiac?['moon'] ?? 'Libra'}
- Rising: ${zodiac?['rising'] ?? 'Scorpio'}
- Life Path: ${numerology?['lifePathNumber'] ?? 4}
- Birth Number: ${numerology?['birthNumber'] ?? 2}
- Destiny Number: ${numerology?['destinyNumber'] ?? 7}

ARCHETYPES:
- Ego: ${primary?['ego'] ?? 'Hero'}
- Soul: ${primary?['soul'] ?? 'Creator'}
- Self: ${primary?['self'] ?? 'Magician'}

SYNTHESIS:
${cosmic?['synthesis'] ?? 'A Gemini sun\'s intellectual versatility combined with Libra moon\'s emotional equilibrium, projected through Scorpio rising\'s transformative intensity.'}

Write the prophecy now. Make it mythic, personal, and inspiring.
''';
  }

  /// Generate image prompts for today's prophecy
  Future<List<String>> getDailyProphecyImagePrompts({int count = 6}) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (_prophecyImageDate == todayDate && _prophecyImagePrompts.isNotEmpty) {
      return _prophecyImagePrompts;
    }

    if (!_agentService.isInitialized) {
      _prophecyImagePrompts = _fallbackProphecyImagePrompts(todayDate, count);
      _prophecyImageDate = todayDate;
      return _prophecyImagePrompts;
    }

    try {
      final prophecy = await getDailyProphecy();
      final prompt = '''
Based on the daily prophecy below, craft $count distinct image prompts for an AI image generator.

Prophecy:
$prophecy

Requirements:
- Vivid, cinematic, mythic scenes
- No text, letters, or symbols in the image
- Concrete visual elements and atmosphere
- Each prompt under 40 words

Respond with JSON array of strings:
["prompt 1", "prompt 2", "..."]
''';

      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'You are a visual storyteller crafting concise image prompts.',
        deployment: AzureAIDeployment.gpt5,
        temperature: 0.7,
        responseFormat: 'json',
      );

      final cleanJson = AzureAgentService.extractJson(response);
      final decoded = jsonDecode(cleanJson);
      final prompts = _parsePromptList(decoded);
      final normalized =
          prompts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

      if (normalized.isEmpty) {
        throw Exception('No prophecy image prompts generated');
      }

      _prophecyImagePrompts = _normalizePromptCount(
        normalized,
        _fallbackProphecyImagePrompts(todayDate, count),
        count,
      );
      _prophecyImageDate = todayDate;
      return _prophecyImagePrompts;
    } catch (e) {
      Logger.warning('Failed to generate prophecy image prompts: $e',
          tag: _tag);
      _prophecyImagePrompts = _fallbackProphecyImagePrompts(todayDate, count);
      _prophecyImageDate = todayDate;
      return _prophecyImagePrompts;
    }
  }

  /// Generate actual prophecy images from prompts
  /// Returns list of local file paths to generated images
  Future<List<String>> generateDailyProphecyImages({int count = 6}) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Return cached paths if already generated today
    if (_prophecyImagePathsDate == todayDate &&
        _prophecyImagePaths.isNotEmpty) {
      return _prophecyImagePaths;
    }

    if (_imageService == null || !_imageService!.isInitialized) {
      Logger.warning('Image service not available for prophecy images',
          tag: _tag);
      return [];
    }

    try {
      final prompts = await getDailyProphecyImagePrompts(count: count);
      final imagePaths = <String>[];
      final dateStr = todayDate.toIso8601String().split('T')[0];

      for (var i = 0; i < prompts.length; i++) {
        try {
          Logger.info('Generating prophecy image ${i + 1}/${prompts.length}',
              tag: _tag);

          final imageResult = await _imageService!.generateImage(
            prompt: prompts[i],
            size:
                ImageSize.landscape, // Prophecy images look better in landscape
          );

          // Save to local file
          final path = await _saveImageFile(
            'prophecy_${i}_$dateStr.png',
            imageResult.bytes,
          );
          if (path != null) {
            imagePaths.add(path);
          }
        } catch (e) {
          Logger.warning('Failed to generate prophecy image $i: $e', tag: _tag);
        }

        // Small delay to avoid rate limits
        if (i < prompts.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      _prophecyImagePaths = imagePaths;
      _prophecyImagePathsDate = todayDate;
      Logger.info('Generated ${imagePaths.length} prophecy images', tag: _tag);
      return imagePaths;
    } catch (e) {
      Logger.error('Failed to generate prophecy images: $e', tag: _tag);
      return [];
    }
  }

  /// Get cached prophecy image paths (returns empty if not yet generated)
  List<String> get dailyProphecyImagePaths => _prophecyImagePaths;

  /// Default prophecy when generation fails
  String _getDefaultProphecy(DateTime date) {
    final dayOfWeek = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ][date.weekday % 7];

    return '''
On this $dayOfWeek, you stand at the crossroads of creation and action. The Hero within you calls for courage, the Creator for vision, and the Magician for transformation.

Your Life Path 4 grounds you in purpose while Destiny 7 whispers of deeper truths yet to be discovered. Let the Gemini sun illuminate your path with intellectual curiosity, balanced by the Libra moon's harmony.

Today is not merely a day—it is another step in the great work of raising consciousness. Move forward with intention.
''';
  }

  List<String> _fallbackProphecyImagePrompts(DateTime date, int count) {
    final dayOfWeek = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ][date.weekday % 7];

    final prompts = [
      'A lone figure on a cliff at dawn, winds carrying glowing constellations, cinematic lighting, wide horizon',
      'An ancient library with floating astrological charts and luminous orbs, soft gold light, mystical atmosphere',
      'A calm ocean reflecting a star map, silver moonlight, serene and expansive, ultra wide angle',
      'A sculpted mask splitting into three archetypal faces, dramatic chiaroscuro, dark velvet background',
      'A winding path through a crystalline forest, teal mist, warm sunrise rays, ethereal mood',
      'A celestial compass resting on stone, beams of light pointing north, sacred geometry implied',
      'A mythic temple doorway opening to a sky of moving constellations, glowing dust particles',
      'A sunrise over a desert on $dayOfWeek, with a single phoenix silhouette, amber haze',
    ];

    return prompts.take(count).toList();
  }

  List<String> _parsePromptList(dynamic decoded) {
    if (decoded is List) {
      return decoded.whereType<String>().toList();
    }
    if (decoded is Map && decoded['prompts'] is List) {
      return (decoded['prompts'] as List).whereType<String>().toList();
    }
    if (decoded is String) {
      return [decoded];
    }
    return [];
  }

  List<String> _normalizePromptCount(
    List<String> prompts,
    List<String> fallback,
    int count,
  ) {
    final normalized = prompts.take(count).toList();
    var fallbackIndex = 0;
    while (normalized.length < count && fallbackIndex < fallback.length) {
      normalized.add(fallback[fallbackIndex]);
      fallbackIndex += 1;
    }
    return normalized;
  }

  /// Get the cached daily prophecy (returns null if not yet generated)
  String? get dailyProphecy => _dailyProphecy;

  /// Dispose resources
  void dispose() {
    stopBackgroundProcessing();
  }
}

/// Current state of the psychograph system
class PsychographState {
  final double rcaScore;
  final String psychograph;
  final List<PsychographInsight> insights;
  final DateTime lastUpdated;
  final List<String> archetypes;

  const PsychographState({
    required this.rcaScore,
    required this.psychograph,
    required this.insights,
    required this.lastUpdated,
    required this.archetypes,
  });

  factory PsychographState.initial() {
    return PsychographState(
      rcaScore: 50.0,
      psychograph: 'Initializing psychograph...',
      insights: [],
      lastUpdated: DateTime.now(),
      archetypes: ['Hero', 'Creator', 'Magician'],
    );
  }

  /// RCA score as percentage string
  String get rcaPercentage => '${rcaScore.toStringAsFixed(0)}%';

  /// RCA level description
  String get rcaLevel {
    if (rcaScore >= 90) return 'Enlightened';
    if (rcaScore >= 75) return 'Awakened';
    if (rcaScore >= 60) return 'Aware';
    if (rcaScore >= 40) return 'Seeking';
    if (rcaScore >= 20) return 'Stirring';
    return 'Dormant';
  }
}

/// An insight generated by the psychograph system
class PsychographInsight {
  final String title;
  final String body;
  final String action;
  final InsightCategory category;
  final List<String> imagePrompts;
  final List<String> imagePaths; // Generated image file paths

  const PsychographInsight({
    required this.title,
    required this.body,
    required this.action,
    required this.category,
    this.imagePrompts = const [],
    this.imagePaths = const [],
  });

  /// Create a copy with generated image paths
  PsychographInsight copyWithImages(List<String> paths) {
    return PsychographInsight(
      title: title,
      body: body,
      action: action,
      category: category,
      imagePrompts: imagePrompts,
      imagePaths: paths,
    );
  }

  factory PsychographInsight.fromJson(Map<String, dynamic> json) {
    final promptsRaw = json['image_prompts'] ?? json['imagePrompts'];
    final prompts = <String>[];
    if (promptsRaw is List) {
      prompts.addAll(promptsRaw.whereType<String>());
    } else if (promptsRaw is String && promptsRaw.trim().isNotEmpty) {
      prompts.add(promptsRaw);
    }

    return PsychographInsight(
      title: json['title'] as String? ?? 'Insight',
      body: json['body'] as String? ?? '',
      action: json['action'] as String? ?? '',
      category: InsightCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => InsightCategory.awareness,
      ),
      imagePrompts: prompts,
      imagePaths: const [],
    );
  }
}

/// Categories for insights (aligned with RCA pillars)
enum InsightCategory {
  presence, // Being in the now
  awareness, // Noticing patterns
  integration, // Embodying insights
}
