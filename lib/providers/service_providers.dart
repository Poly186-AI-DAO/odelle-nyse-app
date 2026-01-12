import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/azure_agent_service.dart';
import '../services/azure_image_service.dart';
import '../services/azure_speech_service.dart';
import '../services/bootstrap_service.dart';
import '../services/daily_content_service.dart';
import '../services/psychograph_service.dart';
import '../services/weather_service.dart';

import '../services/health_kit_service.dart';
import '../database/app_database.dart';

// =============================================================================
// SERVICE PROVIDERS
// =============================================================================
// These providers expose singleton service instances throughout the app.
// Services are stateless - they don't change, they just provide methods.

/// Azure Agent Service for LLM completions
final azureAgentServiceProvider = Provider<AzureAgentService>((ref) {
  return AzureAgentService();
});

/// Psychograph Service - the "subconscious" background LLM
/// Processes user data, updates RCA meter, generates insights
final psychographServiceProvider = Provider<PsychographService>((ref) {
  final agentService = ref.watch(azureAgentServiceProvider);
  final service = PsychographService(agentService: agentService);

  // Start background processing (every 60 minutes)
  service.startBackgroundProcessing(intervalMinutes: 60);

  // Clean up when disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Current psychograph state (reactive)
final psychographStateProvider = Provider<PsychographState>((ref) {
  final service = ref.watch(psychographServiceProvider);
  return service.state;
});

/// Azure speech/voice recognition service
final voiceServiceProvider = Provider<AzureSpeechService>((ref) {
  return AzureSpeechService();
});

/// SQLite database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// Apple HealthKit service for health data access
final healthKitServiceProvider = Provider<HealthKitService>((ref) {
  return HealthKitService();
});

/// Azure Image Generation service
final imageServiceProvider = Provider<AzureImageService>((ref) {
  return AzureImageService();
});

/// Apple WeatherKit service for weather data
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// Daily Content Generation Service
/// Generates personalized meditations, affirmations, and images once per day
/// Uses ElevenLabs for voice synthesis, Azure for images, WeatherKit for weather context
final dailyContentServiceProvider = Provider<DailyContentService>((ref) {
  final agentService = ref.watch(azureAgentServiceProvider);
  final imageService = ref.watch(imageServiceProvider);
  final weatherService = ref.watch(weatherServiceProvider);
  final database = ref.watch(databaseProvider);

  final service = DailyContentService(
    agentService: agentService,
    imageService: imageService,
    database: database,
    weatherService: weatherService,
  );

  return service;
});

/// Bootstrap Service - runs at app startup to check/generate required data
/// Uses tool calling to let the LLM decide what needs to be done
final bootstrapServiceProvider = Provider<BootstrapService>((ref) {
  final agentService = ref.watch(azureAgentServiceProvider);
  final healthKitService = ref.watch(healthKitServiceProvider);
  final weatherService = ref.watch(weatherServiceProvider);

  return BootstrapService(
    agentService: agentService,
    healthKitService: healthKitService,
    weatherService: weatherService,
  );
});

/// Bootstrap result state - tracks if bootstrap has run and its result
final bootstrapResultProvider = FutureProvider<BootstrapResult>((ref) async {
  final bootstrapService = ref.watch(bootstrapServiceProvider);
  return bootstrapService.run();
});
