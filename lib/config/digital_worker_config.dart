import 'package:flutter/foundation.dart';
import '../models/digital_worker_voice.dart';

/// Configuration for the Digital Worker WebRTC client
class DigitalWorkerConfig {
  /// Instructions that define the assistant's behavior and capabilities
  final String instructions;

  /// Modalities supported by the assistant (e.g., ['audio', 'text'])
  final List<String> modalities;

  /// Whether to enable debug logging
  final bool enableDebugLogs;

  /// Maximum duration for a single audio recording session (in seconds)
  final int maxRecordingDuration;

  /// Timeout duration for establishing WebRTC connection (in seconds)
  final int connectionTimeout;

  /// Whether to use noise suppression in audio recording
  final bool enableNoiseSuppression;

  /// Whether to use echo cancellation in audio recording
  final bool enableEchoCancellation;

  /// Whether to use auto gain control in audio recording
  final bool enableAutoGainControl;

  /// The voice to use for the digital worker
  final DigitalWorkerVoice voice;

  /// Voice Activity Detection (VAD) threshold (0.0 to 1.0)
  /// Higher values mean more sensitivity to speech
  final double vadThreshold;

  /// Amount of audio to include before speech is detected (in milliseconds)
  final int prefixPaddingMs;

  /// Duration of silence before considering speech ended (in milliseconds)
  final int silenceDurationMs;

  const DigitalWorkerConfig({
    this.instructions =
        '''You are a professional AI business assistant from the Agency of Poly, specializing in workflow automation and task management. You communicate naturally through voice and text while maintaining a professional demeanor.

You have access to the following business tools:
1. Calendar Management:
   - Create and schedule events
   - Manage appointments
   
2. Document Handling (Google Drive):
   - Create new documents
   - Find and access existing documents
   
3. Email Management (Gmail):
   - Read emails
   - Send emails
   - List and organize emails

Your role is to help streamline business workflows by:
- Managing calendar appointments and scheduling
- Handling document organization and creation
- Processing and responding to emails
- Providing clear, professional communication
- Executing business tasks efficiently

Always maintain a professional tone and focus on business efficiency while assisting with these tasks.

 IMPORTANT!!: Always let the user know when you are going to use a tool like email or calendar as it can take
 some time to execute the task and we want to ensure they are aware of the process.

 Example:
 "User: Hey goodmorning, how are you today?"
 "AI: Good morning! I'm doing well. Would you like me to pull up your recent emails to discuss?"
 "User: Yes, that would be great!"
 "AI: Great! Give me a moment to retrieve that information for you, this may take a few seconds so please be patient with me."

''',
    this.modalities = const ['audio', 'text'],
    this.enableDebugLogs = kDebugMode,
    this.maxRecordingDuration = 300, // 5 minutes
    this.connectionTimeout = 30,
    this.enableNoiseSuppression = true,
    this.enableEchoCancellation = true,
    this.enableAutoGainControl = true,
    this.voice = DigitalWorkerVoice.alloy,
    this.vadThreshold = 0.6,
    this.prefixPaddingMs = 800,
    this.silenceDurationMs = 900,
  });

  /// Default configuration for development environment
  static const DigitalWorkerConfig development = DigitalWorkerConfig(
    enableDebugLogs: true,
    maxRecordingDuration: 600, // 10 minutes for testing
    connectionTimeout: 60, // Longer timeout for development
  );

  /// Default configuration for production environment
  static const DigitalWorkerConfig production = DigitalWorkerConfig(
    enableDebugLogs: false,
    maxRecordingDuration: 300, // 5 minutes
    connectionTimeout: 30,
  );

  /// Create a copy of this configuration with some properties replaced
  DigitalWorkerConfig copyWith({
    String? instructions,
    List<String>? modalities,
    bool? enableDebugLogs,
    int? maxRecordingDuration,
    int? connectionTimeout,
    bool? enableNoiseSuppression,
    bool? enableEchoCancellation,
    bool? enableAutoGainControl,
    DigitalWorkerVoice? voice,
    double? vadThreshold,
    int? prefixPaddingMs,
    int? silenceDurationMs,
  }) {
    return DigitalWorkerConfig(
      instructions: instructions ?? this.instructions,
      modalities: modalities ?? this.modalities,
      enableDebugLogs: enableDebugLogs ?? this.enableDebugLogs,
      maxRecordingDuration: maxRecordingDuration ?? this.maxRecordingDuration,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      enableNoiseSuppression:
          enableNoiseSuppression ?? this.enableNoiseSuppression,
      enableEchoCancellation:
          enableEchoCancellation ?? this.enableEchoCancellation,
      enableAutoGainControl:
          enableAutoGainControl ?? this.enableAutoGainControl,
      voice: voice ?? this.voice,
      vadThreshold: vadThreshold ?? this.vadThreshold,
      prefixPaddingMs: prefixPaddingMs ?? this.prefixPaddingMs,
      silenceDurationMs: silenceDurationMs ?? this.silenceDurationMs,
    );
  }

  @override
  String toString() {
    return '''DigitalWorkerConfig(
      instructions: $instructions,
      modalities: $modalities,
      enableDebugLogs: $enableDebugLogs,
      maxRecordingDuration: $maxRecordingDuration,
      connectionTimeout: $connectionTimeout,
      enableNoiseSuppression: $enableNoiseSuppression,
      enableEchoCancellation: $enableEchoCancellation,
      enableAutoGainControl: $enableAutoGainControl,
      voice: $voice,
      vadThreshold: $vadThreshold,
      prefixPaddingMs: $prefixPaddingMs,
      silenceDurationMs: $silenceDurationMs
    )''';
  }
}
