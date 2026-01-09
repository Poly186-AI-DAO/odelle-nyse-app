import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'localhost:8000',
  );

  // API keys should be provided at build time or runtime, never hardcoded
  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  // Throw error if OpenAI key is not provided
  static void validateConfig() {
    if (openAiApiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY environment variable must be set');
    }
  }

  // URLs
  static String get httpUrl =>
      _baseUrl == 'localhost:8000' ? 'http://$_baseUrl' : 'https://$_baseUrl';
  static String get wsUrl =>
      _baseUrl == 'localhost:8000' ? 'ws://$_baseUrl' : 'wss://$_baseUrl';
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String openAiRealtimeUrl =
      'https://realtime-pmd.openai.azure.com/openai/realtime?api-version=2024-10-01-preview&deployment=gpt-4o-realtime-preview';

  // Environment
  static bool get isDevelopment => const bool.fromEnvironment(
        'DEVELOPMENT',
        defaultValue: true,
      );

  // Feature flags
  static bool get isEmailLinkSignInEnabled => const bool.fromEnvironment(
        'EMAIL_LINK_SIGNIN_ENABLED',
        defaultValue:
            false, // Disabled by default until we implement a new deep linking solution
      );
}
