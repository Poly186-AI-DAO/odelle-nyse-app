import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ElevenLabs API configuration for meditation & voice generation.
///
/// USAGE NOTES:
/// - 10 minutes of audio generation per month on free tier
/// - Use sparingly - prefer daily generation, not hourly
/// - Meditation voices are optimized for calm, therapeutic content
class ElevenLabsConfig {
  ElevenLabsConfig._();

  // API Configuration - loaded from environment
  static String get apiKey => dotenv.env['ELEVENLABS_API_KEY'] ?? '';
  static const String baseUrl = 'https://api.elevenlabs.io/v1';

  // Voice IDs for different content types
  static const Map<VoiceType, String> voiceIds = {
    // Verified User Voices
    VoiceType.meditation: 'UmQN7jS1Ee8B1czsUtQh', // Theo Silk - British Deep Sleep
    VoiceType.affirmation: 'pjcYQlDFKMbcOUp6F5GD', // Brittney - Relaxing/Meditative
    VoiceType.guidance: 'AiJZqQzutCDRG8cUOJwK', // Calm Lady (Generated)

    // Energetic/Strong
    VoiceType.motivation: 'goT3UYdM9bhm0n2lmKQx', // Edward - British, Dark, Low
    VoiceType.workout: 'goT3UYdM9bhm0n2lmKQx', // Edward - Strong British leader

    // Default conversational
    VoiceType.conversational: 'UmQN7jS1Ee8B1czsUtQh', // Default to Theo (Calm)
  };

  // Model settings
  static const String defaultModel = 'eleven_multilingual_v2';
  static const String turboModel = 'eleven_turbo_v2_5'; // Faster, lower quality

  // Audio settings for meditation content
  static const Map<String, dynamic> meditationSettings = {
    'stability': 0.75, // Higher = more consistent
    'similarity_boost': 0.75,
    'style': 0.35, // Lower = more neutral/calm
    'use_speaker_boost': true,
  };

  // Audio settings for energetic content
  static const Map<String, dynamic> motivationSettings = {
    'stability': 0.65,
    'similarity_boost': 0.80,
    'style': 0.60, // Higher = more expressive
    'use_speaker_boost': true,
  };

  /// Get voice ID for content type
  static String getVoiceId(VoiceType type) {
    return voiceIds[type] ?? voiceIds[VoiceType.conversational]!;
  }

  /// Get settings for content type
  static Map<String, dynamic> getSettings(VoiceType type) {
    switch (type) {
      case VoiceType.meditation:
      case VoiceType.affirmation:
      case VoiceType.guidance:
        return meditationSettings;
      case VoiceType.motivation:
      case VoiceType.workout:
        return motivationSettings;
      case VoiceType.conversational:
        return meditationSettings; // Default to calm
    }
  }
}

/// Types of voice content we generate
enum VoiceType {
  meditation, // Calm guided meditations
  affirmation, // Daily mantras/affirmations
  guidance, // Therapeutic guidance
  motivation, // Energetic motivation
  workout, // Workout cues
  conversational, // General conversation
}
