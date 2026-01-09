import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../config/app_config.dart';
import '../../models/digital_worker_voice.dart';

class OpenAISessionService {
  static const String _sessionEndpoint =
      '${AppConfig.openAiBaseUrl}/realtime/sessions';

  /// Creates an ephemeral API token for use with the Realtime API
  /// Validates the session response and ephemeral token
  bool _isValidSessionResponse(Map<String, dynamic> response) {
    if (!response.containsKey('client_secret')) {
      developer.log('Session response missing client_secret',
          name: 'OpenAISessionService');
      return false;
    }

    final clientSecret = response['client_secret'] as Map<String, dynamic>?;
    if (clientSecret == null) {
      developer.log('client_secret is null', name: 'OpenAISessionService');
      return false;
    }

    if (!clientSecret.containsKey('value') ||
        !clientSecret.containsKey('expires_at')) {
      developer.log('client_secret missing required fields',
          name: 'OpenAISessionService',
          error: 'Missing fields: ${clientSecret.keys.toString()}');
      return false;
    }

    final expiresAt = clientSecret['expires_at'] as int?;
    if (expiresAt == null ||
        expiresAt < DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      developer.log('Token expired or invalid expiration',
          name: 'OpenAISessionService', error: 'Expiration: $expiresAt');
      return false;
    }

    return true;
  }

  Future<Map<String, dynamic>> createSession({
    String model = 'gpt-4o-realtime-preview-2024-12-17',
    List<String> modalities = const ['audio', 'text'],
    String instructions = 'You are a friendly assistant.',
    DigitalWorkerVoice voice = DigitalWorkerVoice.alloy,
    double vadThreshold = 0.6,
    int prefixPaddingMs = 800,
    int silenceDurationMs = 900,
  }) async {
    developer.log(
        'Creating new OpenAI session\n'
        'Model: $model\n'
        'Modalities: $modalities\n'
        'Instructions: $instructions',
        name: 'OpenAISessionService');

    try {
      final sessionConfig = {
        'model': model,
        'modalities': modalities,
        'instructions': instructions,
        'voice': voice.value,
        'tool_choice': 'auto',
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {
          'model': 'whisper-1',
        },
        "turn_detection": {
          "type": "server_vad",
          "threshold": vadThreshold,
          "prefix_padding_ms": prefixPaddingMs,
          "silence_duration_ms": silenceDurationMs
        },
      };
      final response = await http.post(
        Uri.parse(_sessionEndpoint),
        headers: {
          'Authorization': 'Bearer ${AppConfig.openAiApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(sessionConfig),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        developer.log(
            'Session created successfully\n'
            'Response: ${response.body}',
            name: 'OpenAISessionService');

        if (!_isValidSessionResponse(responseData)) {
          final error = 'Invalid session response format: ${response.body}';
          developer.log(error,
              name: 'OpenAISessionService', level: 1000 // Severe error
              );
          throw Exception(error);
        }

        // Validate token expiration
        final clientSecret =
            responseData['client_secret'] as Map<String, dynamic>;
        final expiresAt = clientSecret['expires_at'] as int;
        final expiresIn =
            expiresAt - (DateTime.now().millisecondsSinceEpoch ~/ 1000);

        developer.log('Token expires in $expiresIn seconds',
            name: 'OpenAISessionService');

        // input_audio_transcription will be configured through WebRTC events after connection
        return responseData;
      } else {
        developer.log('Failed to create session',
            name: 'OpenAISessionService',
            error: 'Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to create session: ${response.body}');
      }
    } catch (e, stackTrace) {
      final error = 'Error creating OpenAI session: $e';
      developer.log(error,
          name: 'OpenAISessionService',
          error: e,
          stackTrace: stackTrace,
          level: 1000 // Severe error
          );
      throw Exception(error);
    }
  }

  /// Gets the ephemeral token from the session response
  static String getEphemeralToken(Map<String, dynamic> sessionResponse) {
    try {
      final clientSecret =
          sessionResponse['client_secret'] as Map<String, dynamic>?;
      if (clientSecret == null) {
        developer.log('Failed to get client_secret from session response',
            name: 'OpenAISessionService', error: 'Response: $sessionResponse');
        throw Exception('Missing client_secret in session response');
      }

      final token = clientSecret['value'] as String?;
      if (token == null || token.isEmpty) {
        developer.log('Invalid ephemeral token',
            name: 'OpenAISessionService', error: 'Token: $token');
        throw Exception('Invalid ephemeral token');
      }

      developer.log('Successfully extracted ephemeral token',
          name: 'OpenAISessionService');

      return token;
    } catch (e) {
      developer.log('Failed to extract ephemeral token',
          name: 'OpenAISessionService', error: e.toString());
      throw Exception(
          'Failed to extract ephemeral token from session response: $e');
    }
  }
}
