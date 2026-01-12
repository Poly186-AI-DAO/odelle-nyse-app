import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/azure_speech_service.dart';
import '../services/backend_api_service.dart';

import '../services/poly_auth_service.dart';
import '../services/health_kit_service.dart';
import '../database/app_database.dart';

// =============================================================================
// SERVICE PROVIDERS
// =============================================================================
// These providers expose singleton service instances throughout the app.
// Services are stateless - they don't change, they just provide methods.

/// Backend base URL - can be overridden in tests
const _backendBaseUrl = 'https://4b1db0965b44.ngrok-free.app';

/// Poly authentication service
final polyAuthServiceProvider = Provider<PolyAuthService>((ref) {
  return PolyAuthService(baseUrl: _backendBaseUrl);
});

/// Backend API service for general API calls
final backendApiServiceProvider = Provider<BackendApiService>((ref) {
  return BackendApiService(baseUrl: _backendBaseUrl);
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
