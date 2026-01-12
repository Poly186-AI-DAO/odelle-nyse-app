import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../config/azure_ai_config.dart';
import '../utils/logger.dart';
import 'azure_agent_service.dart';

/// The Psychograph Service - the "subconscious" LLM
///
/// This service runs in the background to:
/// 1. Process user data (mantras, journal entries, mood logs, etc.)
/// 2. Update the psychograph (evolving understanding of the user)
/// 3. Compute the RCA (Raising Conscious Awareness) meter
/// 4. Generate personalized meditations, insights, and notifications
///
/// Uses gpt-5-nano for fast, cheap background processing.
class PsychographService {
  static const String _tag = 'PsychographService';

  final AzureAgentService _agentService;
  Timer? _periodicTimer;
  bool _isProcessing = false;

  // Cached data
  Map<String, dynamic>? _genesisProfile;
  Map<String, dynamic>? _characterStats;
  List<String>? _mantras;

  // Current psychograph state
  PsychographState _state = PsychographState.initial();

  PsychographService({
    required AzureAgentService agentService,
  }) : _agentService = agentService;

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
      // RCA scoring is internal processing - use Nano
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'You are a psychological assessment system. Respond only with valid JSON.',
        deployment: AzureAIDeployment.gpt5Nano, // Processing (JSON parsing)
        temperature: 0.3,
        maxTokens: 1000, // Nano needs min 1000
      );

      final result = jsonDecode(response) as Map<String, dynamic>;
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
        deployment: AzureAIDeployment.gpt5Chat, // Quality for user content
        temperature: 0.7,
        maxTokens: 500, // Short psychograph text
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
Based on the user's psychograph and data, generate 1-3 actionable insights.

User Data:
- Archetypes: ${_characterStats?['archetypes'] ?? []}
- Stats: ${_characterStats?['stats'] ?? {}}
- Mantras: ${_mantras?.take(3).join(', ') ?? 'None'}

Each insight should:
1. Notice a pattern
2. Suggest a small action
3. Connect to their growth

Respond with JSON array:
[{"title": "...", "body": "...", "action": "...", "category": "presence|awareness|integration"}]
''';

    try {
      // Insights are user-facing content - use Chat for quality
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'You are a wise mentor generating concise, actionable insights.',
        deployment: AzureAIDeployment.gpt5Chat, // Quality for user content
        temperature: 0.6,
        maxTokens: 800, // Multiple insights
      );

      final insightsList = jsonDecode(response) as List;
      return insightsList
          .map((i) => PsychographInsight.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Logger.warning('Insight generation failed: $e', tag: _tag);
      return [];
    }
  }

  /// Extract archetypes from loaded data
  List<String> _extractArchetypes() {
    if (_characterStats?['archetypes'] != null) {
      return List<String>.from(_characterStats!['archetypes']);
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

  const PsychographInsight({
    required this.title,
    required this.body,
    required this.action,
    required this.category,
  });

  factory PsychographInsight.fromJson(Map<String, dynamic> json) {
    return PsychographInsight(
      title: json['title'] as String? ?? 'Insight',
      body: json['body'] as String? ?? '',
      action: json['action'] as String? ?? '',
      category: InsightCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => InsightCategory.awareness,
      ),
    );
  }
}

/// Categories for insights (aligned with RCA pillars)
enum InsightCategory {
  presence, // Being in the now
  awareness, // Noticing patterns
  integration, // Embodying insights
}
