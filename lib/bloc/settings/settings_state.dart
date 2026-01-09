import 'package:equatable/equatable.dart';
import '../../models/digital_worker_voice.dart';

class SettingsState extends Equatable {
  final bool isCalendarEnabled;
  final bool isDriveEnabled;
  final bool isGmailEnabled;
  final String appVersion;
  final String buildNumber;
  final bool isLoading;

  // Digital Worker Settings
  final String instructions;
  final DigitalWorkerVoice voice;
  final bool enableNoiseSuppression;
  final bool enableEchoCancellation;
  final bool enableAutoGainControl;
  final double vadThreshold;
  final int prefixPaddingMs;
  final int silenceDurationMs;
  final int maxRecordingDuration;
  final int connectionTimeout;

  const SettingsState({
    this.isCalendarEnabled = false,
    this.isDriveEnabled = false,
    this.isGmailEnabled = false,
    this.appVersion = '',
    this.buildNumber = '',
    this.isLoading = false,
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

Always maintain a professional tone and focus on business efficiency while assisting with these tasks.''',
    this.voice = DigitalWorkerVoice.alloy,
    this.enableNoiseSuppression = true,
    this.enableEchoCancellation = true,
    this.enableAutoGainControl = true,
    this.vadThreshold = 0.6,
    this.prefixPaddingMs = 800,
    this.silenceDurationMs = 900,
    this.maxRecordingDuration = 300,
    this.connectionTimeout = 30,
  });

  SettingsState copyWith({
    bool? isCalendarEnabled,
    bool? isDriveEnabled,
    bool? isGmailEnabled,
    String? appVersion,
    String? buildNumber,
    bool? isLoading,
    String? instructions,
    DigitalWorkerVoice? voice,
    bool? enableNoiseSuppression,
    bool? enableEchoCancellation,
    bool? enableAutoGainControl,
    double? vadThreshold,
    int? prefixPaddingMs,
    int? silenceDurationMs,
    int? maxRecordingDuration,
    int? connectionTimeout,
  }) {
    return SettingsState(
      isCalendarEnabled: isCalendarEnabled ?? this.isCalendarEnabled,
      isDriveEnabled: isDriveEnabled ?? this.isDriveEnabled,
      isGmailEnabled: isGmailEnabled ?? this.isGmailEnabled,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      isLoading: isLoading ?? this.isLoading,
      instructions: instructions ?? this.instructions,
      voice: voice ?? this.voice,
      enableNoiseSuppression:
          enableNoiseSuppression ?? this.enableNoiseSuppression,
      enableEchoCancellation:
          enableEchoCancellation ?? this.enableEchoCancellation,
      enableAutoGainControl:
          enableAutoGainControl ?? this.enableAutoGainControl,
      vadThreshold: vadThreshold ?? this.vadThreshold,
      prefixPaddingMs: prefixPaddingMs ?? this.prefixPaddingMs,
      silenceDurationMs: silenceDurationMs ?? this.silenceDurationMs,
      maxRecordingDuration: maxRecordingDuration ?? this.maxRecordingDuration,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
    );
  }

  @override
  List<Object?> get props => [
        isCalendarEnabled,
        isDriveEnabled,
        isGmailEnabled,
        appVersion,
        buildNumber,
        isLoading,
        instructions,
        voice,
        enableNoiseSuppression,
        enableEchoCancellation,
        enableAutoGainControl,
        vadThreshold,
        prefixPaddingMs,
        silenceDurationMs,
        maxRecordingDuration,
        connectionTimeout,
      ];
}
