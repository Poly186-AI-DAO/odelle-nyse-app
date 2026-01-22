import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/azure_agent_service.dart';
import '../services/azure_image_service.dart';
import '../services/azure_speech_service.dart';
import '../services/bootstrap_service.dart';
import '../services/daily_content_service.dart';
import '../services/psychograph_service.dart';
import '../services/user_context_service.dart';
import '../services/voice_action_service.dart';
import '../services/weather_service.dart';
import '../services/sync_service.dart';
import '../services/agent_scheduler_service.dart';
import '../services/live_activity_service.dart';
import '../services/notification_service.dart';
import '../services/smart_reminder_service.dart';
import '../utils/logger.dart';

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
  final userContextService = ref.watch(userContextServiceProvider);
  final service = PsychographService(
    agentService: agentService,
    userContextService: userContextService,
  );

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

/// Psychograph state stream for UI updates
final psychographStateStreamProvider =
    StreamProvider<PsychographState>((ref) async* {
  final service = ref.watch(psychographServiceProvider);
  yield service.state;
  yield* Stream.periodic(const Duration(seconds: 30), (_) => service.state);
});

/// Daily prophecy text
final dailyProphecyProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(psychographServiceProvider);
  return service.getDailyProphecy();
});

/// Daily prophecy image prompts (for gallery previews)
final dailyProphecyImagePromptsProvider = FutureProvider<List<String>>((ref) {
  final service = ref.watch(psychographServiceProvider);
  return service.getDailyProphecyImagePrompts();
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

/// User Context Service - loads full documents for LLM context
final userContextServiceProvider = Provider<UserContextService>((ref) {
  return UserContextService();
});

/// Daily Content Generation Service
/// Generates personalized meditations, affirmations, and images once per day
/// Uses ElevenLabs for voice synthesis, Azure for images, WeatherKit for weather context
final dailyContentServiceProvider = Provider<DailyContentService>((ref) {
  final agentService = ref.watch(azureAgentServiceProvider);
  final imageService = ref.watch(imageServiceProvider);
  final weatherService = ref.watch(weatherServiceProvider);
  final database = ref.watch(databaseProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  final service = DailyContentService(
    agentService: agentService,
    imageService: imageService,
    database: database,
    weatherService: weatherService,
    notificationService: notificationService,
  );

  return service;
});

/// Bootstrap Service - runs at app startup to check/generate required data
/// Uses tool calling to let the LLM decide what needs to be done
final bootstrapServiceProvider = Provider<BootstrapService>((ref) {
  final agentService = ref.watch(azureAgentServiceProvider);
  final healthKitService = ref.watch(healthKitServiceProvider);
  final weatherService = ref.watch(weatherServiceProvider);
  final userContextService = ref.watch(userContextServiceProvider);
  final database = ref.watch(databaseProvider);

  return BootstrapService(
    agentService: agentService,
    healthKitService: healthKitService,
    weatherService: weatherService,
    userContextService: userContextService,
    database: database,
  );
});

/// Bootstrap result state - tracks if bootstrap has run and its result
/// Also triggers daily content generation and psychograph processing
final bootstrapResultProvider = FutureProvider<BootstrapResult>((ref) async {
  final bootstrapService = ref.watch(bootstrapServiceProvider);
  final dailyContentService = ref.watch(dailyContentServiceProvider);
  final psychographService = ref.watch(psychographServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final smartReminderService = ref.watch(smartReminderServiceProvider);

  // Initialize notification service first
  try {
    await notificationService.initialize();
    await notificationService.requestPermissions();
    Logger.info('Notification service initialized', tag: 'BootstrapResult');
  } catch (e) {
    Logger.warning('Notification service init failed: $e',
        tag: 'BootstrapResult');
  }

  // Run bootstrap
  final result = await bootstrapService.run();

  // After bootstrap, check if we need to generate daily content
  if (result.success) {
    try {
      final shouldGenerate = await dailyContentService.shouldGenerateForToday();
      if (shouldGenerate) {
        // Initialize and generate today's meditation content
        await dailyContentService.initialize();
        await dailyContentService.generateDailyMeditation();
      }
    } catch (e) {
      // Don't fail bootstrap if daily content fails
      Logger.warning('Daily content generation failed: $e',
          tag: 'BootstrapResult');
    }

    // Trigger psychograph processing (already started via provider)
    // Just ensure it runs an initial cycle
    try {
      await psychographService.triggerProcessing();
    } catch (e) {
      Logger.warning('Psychograph processing failed: $e',
          tag: 'BootstrapResult');
    }

    // Sync smart reminders with OS notification scheduler
    try {
      await smartReminderService.syncWithOS();
      Logger.info('Smart reminders synced with OS', tag: 'BootstrapResult');
    } catch (e) {
      Logger.warning('Reminder sync failed: $e', tag: 'BootstrapResult');
    }
  }

  return result;
});

/// Voice Action Service - processes voice commands and executes actions
/// Flow: Voice → LLM (intent) → Execute action → Return confirmation
final voiceActionServiceProvider = Provider<VoiceActionService>((ref) {
  final agentService = ref.watch(azureAgentServiceProvider);
  final userContextService = ref.watch(userContextServiceProvider);
  final database = ref.watch(databaseProvider);

  return VoiceActionService(
    agentService: agentService,
    userContextService: userContextService,
    database: database,
  );
});

/// Firebase Sync Service - syncs local SQLite changes to Firestore
/// Offline-first: queues changes locally and pushes when online
/// Auto-syncs every 5 minutes
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();

  // Auto-start periodic sync when provider is first accessed
  service.startPeriodicSync();

  // Clean up when disposed
  ref.onDispose(() {
    service.stopPeriodicSync();
  });

  return service;
});

/// Agent Scheduler Service - runs AI agents on intervals
/// GPT-5 Nano: Every 5 minutes (fast processing)
/// GPT-5 Chat: Every 30 minutes (supervisor, reviews Nano's work)
final agentSchedulerProvider = Provider<AgentSchedulerService>((ref) {
  final agentService = ref.watch(azureAgentServiceProvider);
  final database = ref.watch(databaseProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  final scheduler = AgentSchedulerService(
    agentService: agentService,
    db: database,
    notificationService: notificationService,
  );

  // Auto-start the scheduler when provider is first accessed
  scheduler.start();

  // Clean up when disposed
  ref.onDispose(() {
    scheduler.dispose();
  });

  return scheduler;
});

/// iOS Live Activity Service - Dynamic Island and Lock Screen notifications
/// Bridges Flutter to native iOS ActivityKit via MethodChannel
final liveActivityServiceProvider = Provider<LiveActivityService>((ref) {
  return LiveActivityService();
});

/// Unified Notification Service - orchestrates all notification types
/// - Live Activities (Dynamic Island) for agent status
/// - Local notifications for reminders and alerts
/// - Rich notifications with images for surprise content
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final liveActivityService = ref.watch(liveActivityServiceProvider);

  final service = NotificationService(
    liveActivityService: liveActivityService,
  );

  return service;
});

/// Smart Reminder Service - manages scheduled reminders
/// - CRUD operations for reminders in database
/// - Syncs reminders with OS notification scheduler
/// - Supports water, meal, supplement, habit, and AI-generated reminders
final smartReminderServiceProvider = Provider<SmartReminderService>((ref) {
  final database = ref.watch(databaseProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return SmartReminderService(
    database: database,
    notificationService: notificationService,
  );
});
