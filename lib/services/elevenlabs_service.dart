import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/elevenlabs_config.dart';
import '../utils/logger.dart';

/// Centralized ElevenLabs TTS service.
///
/// Consolidates audio generation logic previously duplicated in:
/// - DailyContentService._generateAudio()
/// - ContentGenerationService._generateAudio()
///
/// Features:
/// - Quota checking before generation
/// - Consistent error handling
/// - Retry logic for transient failures
class ElevenLabsService {
  static const String _tag = 'ElevenLabsService';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  final http.Client _client;
  bool _isInitialized = false;

  ElevenLabsService({http.Client? client}) : _client = client ?? http.Client();

  bool get isInitialized =>
      _isInitialized && ElevenLabsConfig.apiKey.isNotEmpty;

  /// Initialize the service
  Future<void> initialize() async {
    if (ElevenLabsConfig.apiKey.isEmpty) {
      Logger.warning('ElevenLabs API key not configured', tag: _tag);
      return;
    }
    _isInitialized = true;
    Logger.info('ElevenLabsService initialized', tag: _tag);
  }

  /// Check quota before generating audio
  /// Returns quota info including remaining characters
  Future<ElevenLabsQuota> checkQuota() async {
    final apiKey = ElevenLabsConfig.apiKey;
    if (apiKey.isEmpty) {
      return ElevenLabsQuota.unavailable('API key not configured');
    }

    try {
      final response = await _client.get(
        Uri.parse('${ElevenLabsConfig.baseUrl}/user/subscription'),
        headers: {'xi-api-key': apiKey},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ElevenLabsQuota.fromJson(json);
      }
      return ElevenLabsQuota.unavailable(
          'Failed to fetch quota: ${response.statusCode}');
    } catch (e) {
      Logger.error('Failed to check ElevenLabs quota: $e', tag: _tag);
      return ElevenLabsQuota.unavailable('Error: $e');
    }
  }

  /// Generate audio from text using ElevenLabs TTS.
  ///
  /// [text] - The text to convert to speech
  /// [voiceType] - The type of voice to use (determines voice ID and settings)
  /// [checkQuotaFirst] - If true, checks quota before generation (recommended)
  ///
  /// Returns audio bytes as Uint8List, or null if generation failed.
  /// Includes retry logic for transient failures.
  Future<Uint8List?> generateAudio({
    required String text,
    required VoiceType voiceType,
    bool checkQuotaFirst = true,
  }) async {
    final apiKey = ElevenLabsConfig.apiKey;
    if (apiKey.isEmpty) {
      Logger.warning('ElevenLabs API key not configured', tag: _tag);
      return null;
    }

    // Optional quota check
    if (checkQuotaFirst) {
      final quota = await checkQuota();
      if (!quota.hasQuota) {
        Logger.warning(
          'Insufficient ElevenLabs quota: ${quota.remaining} chars remaining',
          tag: _tag,
        );
        return null;
      }

      // Warn if quota is low (less than 5000 chars)
      if (quota.remaining < 5000) {
        Logger.warning(
          'Low ElevenLabs quota: ${quota.remaining} chars remaining',
          tag: _tag,
        );
      }
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

    Logger.info('Generating audio with ElevenLabs', tag: _tag, data: {
      'voiceId': voiceId,
      'voiceType': voiceType.name,
      'charCount': text.length,
    });

    // Retry logic for transient failures
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _client.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'xi-api-key': apiKey,
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          Logger.info('Audio generated successfully', tag: _tag, data: {
            'bytes': response.bodyBytes.length,
          });
          return response.bodyBytes;
        }

        // Check for rate limiting
        if (response.statusCode == 429) {
          Logger.warning(
            'ElevenLabs rate limited, attempt $attempt of $_maxRetries',
            tag: _tag,
          );
          if (attempt < _maxRetries) {
            await Future.delayed(_retryDelay * attempt);
            continue;
          }
        }

        // Non-retryable error
        Logger.error(
          'ElevenLabs API error: ${response.statusCode}',
          tag: _tag,
          data: {'body': response.body},
        );
        return null;
      } catch (e) {
        Logger.error(
          'ElevenLabs request failed, attempt $attempt of $_maxRetries',
          tag: _tag,
          error: e,
        );
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
        return null;
      }
    }

    return null;
  }

  /// Get generation history from ElevenLabs.
  ///
  /// Returns a list of previous TTS generations, optionally filtered by voice.
  /// Use this to recover audio that was generated but not saved locally.
  ///
  /// [voiceType] - Filter by a specific voice type (meditation, affirmation, etc.)
  /// [pageSize] - Number of items to fetch (max 1000)
  /// [startAfter] - Pagination: start after this history_item_id
  /// [afterDate] - Only fetch items generated after this date
  Future<ElevenLabsHistoryResult> getHistory({
    VoiceType? voiceType,
    int pageSize = 100,
    String? startAfter,
    DateTime? afterDate,
  }) async {
    final apiKey = ElevenLabsConfig.apiKey;
    if (apiKey.isEmpty) {
      return ElevenLabsHistoryResult.error('API key not configured');
    }

    try {
      final queryParams = <String, String>{
        'page_size': pageSize.toString(),
        'source': 'TTS', // Only text-to-speech generations
      };

      // Filter by voice if specified
      if (voiceType != null) {
        queryParams['voice_id'] = ElevenLabsConfig.getVoiceId(voiceType);
      }

      // Pagination
      if (startAfter != null) {
        queryParams['start_after_history_item_id'] = startAfter;
      }

      // Date filter
      if (afterDate != null) {
        queryParams['date_after_unix'] =
            (afterDate.millisecondsSinceEpoch ~/ 1000).toString();
      }

      final uri = Uri.parse('${ElevenLabsConfig.baseUrl}/history')
          .replace(queryParameters: queryParams);

      Logger.info('Fetching ElevenLabs history', tag: _tag, data: {
        'voiceType': voiceType?.name,
        'pageSize': pageSize,
        'afterDate': afterDate?.toIso8601String(),
      });

      final response = await _client.get(
        uri,
        headers: {'xi-api-key': apiKey},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final historyList = json['history'] as List<dynamic>? ?? [];
        final items = historyList
            .map((item) =>
                ElevenLabsHistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();

        Logger.info('Fetched ${items.length} history items', tag: _tag);

        return ElevenLabsHistoryResult(
          items: items,
          hasMore: json['has_more'] as bool? ?? false,
          lastItemId: json['last_history_item_id'] as String?,
        );
      }

      Logger.error('Failed to fetch history: ${response.statusCode}',
          tag: _tag, data: {'body': response.body});
      return ElevenLabsHistoryResult.error('API error: ${response.statusCode}');
    } catch (e) {
      Logger.error('Failed to fetch ElevenLabs history', tag: _tag, error: e);
      return ElevenLabsHistoryResult.error('Error: $e');
    }
  }

  /// Download audio for a specific history item.
  ///
  /// [historyItemId] - The ID of the history item to download
  /// Returns audio bytes as Uint8List, or null if download failed.
  Future<Uint8List?> downloadHistoryAudio(String historyItemId) async {
    final apiKey = ElevenLabsConfig.apiKey;
    if (apiKey.isEmpty) {
      Logger.warning('ElevenLabs API key not configured', tag: _tag);
      return null;
    }

    try {
      final uri =
          Uri.parse('${ElevenLabsConfig.baseUrl}/history/$historyItemId/audio');

      Logger.info('Downloading history audio', tag: _tag, data: {
        'historyItemId': historyItemId,
      });

      final response = await _client.get(
        uri,
        headers: {'xi-api-key': apiKey},
      );

      if (response.statusCode == 200) {
        Logger.info('Downloaded history audio', tag: _tag, data: {
          'bytes': response.bodyBytes.length,
        });
        return response.bodyBytes;
      }

      Logger.error('Failed to download history audio: ${response.statusCode}',
          tag: _tag);
      return null;
    } catch (e) {
      Logger.error('Failed to download history audio', tag: _tag, error: e);
      return null;
    }
  }

  /// Get all meditation history items (filtered by meditation voice).
  ///
  /// Convenience method that fetches all TTS generations using the meditation voice.
  Future<List<ElevenLabsHistoryItem>> getMeditationHistory({
    int pageSize = 100,
    DateTime? afterDate,
  }) async {
    final result = await getHistory(
      voiceType: VoiceType.meditation,
      pageSize: pageSize,
      afterDate: afterDate,
    );
    return result.items;
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// ElevenLabs quota information
class ElevenLabsQuota {
  final String tier;
  final int characterLimit;
  final int characterCount;
  final int remaining;
  final DateTime? resetDate;
  final bool isAvailable;
  final String? error;

  const ElevenLabsQuota({
    required this.tier,
    required this.characterLimit,
    required this.characterCount,
    required this.remaining,
    this.resetDate,
    this.isAvailable = true,
    this.error,
  });

  factory ElevenLabsQuota.fromJson(Map<String, dynamic> json) {
    final limit = (json['character_limit'] as num?)?.toInt() ?? 0;
    final used = (json['character_count'] as num?)?.toInt() ?? 0;
    final resetUnix = json['next_character_count_reset_unix'] as int?;

    return ElevenLabsQuota(
      tier: json['tier']?.toString() ?? 'unknown',
      characterLimit: limit,
      characterCount: used,
      remaining: limit - used,
      resetDate: resetUnix != null
          ? DateTime.fromMillisecondsSinceEpoch(resetUnix * 1000)
          : null,
      isAvailable: true,
    );
  }

  factory ElevenLabsQuota.unavailable(String error) {
    return ElevenLabsQuota(
      tier: 'unknown',
      characterLimit: 0,
      characterCount: 0,
      remaining: 0,
      isAvailable: false,
      error: error,
    );
  }

  /// Check if there's enough quota for a request
  bool get hasQuota => isAvailable && remaining > 0;

  /// Estimate if we have enough quota for a given text length
  bool hasQuotaFor(int charCount) => isAvailable && remaining >= charCount;

  /// Convert to map for UI display
  Map<String, dynamic> toMap() => {
        'tier': tier,
        'character_limit': characterLimit,
        'character_count': characterCount,
        'remaining': remaining,
        'reset_date': resetDate?.toIso8601String(),
        'is_available': isAvailable,
        'error': error,
      };

  @override
  String toString() =>
      'ElevenLabsQuota(tier: $tier, remaining: $remaining/$characterLimit)';
}

/// A single history item from ElevenLabs generation history.
class ElevenLabsHistoryItem {
  final String historyItemId;
  final DateTime dateCreated;
  final String? voiceId;
  final String? voiceName;
  final String? modelId;
  final String text;
  final int characterCount;
  final String? requestId;

  const ElevenLabsHistoryItem({
    required this.historyItemId,
    required this.dateCreated,
    this.voiceId,
    this.voiceName,
    this.modelId,
    required this.text,
    required this.characterCount,
    this.requestId,
  });

  factory ElevenLabsHistoryItem.fromJson(Map<String, dynamic> json) {
    final dateUnix = json['date_unix'] as int? ?? 0;
    final charFrom = json['character_count_change_from'] as int? ?? 0;
    final charTo = json['character_count_change_to'] as int? ?? 0;

    return ElevenLabsHistoryItem(
      historyItemId: json['history_item_id'] as String? ?? '',
      dateCreated: DateTime.fromMillisecondsSinceEpoch(dateUnix * 1000),
      voiceId: json['voice_id'] as String?,
      voiceName: json['voice_name'] as String?,
      modelId: json['model_id'] as String?,
      text: json['text'] as String? ?? '',
      characterCount: charTo - charFrom,
      requestId: json['request_id'] as String?,
    );
  }

  /// Get the date as a formatted string (yyyy-MM-dd)
  String get dateString {
    return '${dateCreated.year}-${dateCreated.month.toString().padLeft(2, '0')}-${dateCreated.day.toString().padLeft(2, '0')}';
  }

  /// Check if text looks like a meditation script (heuristic)
  bool get looksLikeMeditation {
    final lower = text.toLowerCase();
    return lower.contains('breathe') ||
        lower.contains('relax') ||
        lower.contains('meditation') ||
        lower.contains('inhale') ||
        lower.contains('exhale') ||
        lower.contains('peace') ||
        lower.contains('calm') ||
        text.length > 500; // Meditation scripts are typically long
  }

  @override
  String toString() =>
      'ElevenLabsHistoryItem(id: $historyItemId, date: $dateString, chars: $characterCount)';
}

/// Result from fetching ElevenLabs history
class ElevenLabsHistoryResult {
  final List<ElevenLabsHistoryItem> items;
  final bool hasMore;
  final String? lastItemId;
  final String? error;

  const ElevenLabsHistoryResult({
    this.items = const [],
    this.hasMore = false,
    this.lastItemId,
    this.error,
  });

  factory ElevenLabsHistoryResult.error(String message) {
    return ElevenLabsHistoryResult(error: message);
  }

  bool get isSuccess => error == null;
  bool get isEmpty => items.isEmpty;
}
