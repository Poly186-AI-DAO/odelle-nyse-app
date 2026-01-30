import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AzureAIDeployment {
  transcription,
  tts,
  realtimeVoice,
  realtimeMini,
  gpt5,
  gpt5Chat,
  gpt5Nano,
}

extension AzureAIDeploymentInfo on AzureAIDeployment {
  /// Returns the actual deployment name from env vars or falls back to defaults.
  /// Azure deployment names must match exactly what's deployed in Azure AI Foundry.
  String get deploymentName {
    switch (this) {
      case AzureAIDeployment.transcription:
        return dotenv.env['AZURE_TRANSCRIBE_DEPLOYMENT'] ?? 'gpt-4o-transcribe';
      case AzureAIDeployment.tts:
        return dotenv.env['AZURE_TTS_DEPLOYMENT'] ?? 'gpt-audio';
      case AzureAIDeployment.realtimeVoice:
        return dotenv.env['AZURE_REALTIME_DEPLOYMENT'] ?? 'gpt-realtime';
      case AzureAIDeployment.realtimeMini:
        return dotenv.env['AZURE_REALTIME_MINI_DEPLOYMENT'] ??
            'gpt-realtime-mini';
      case AzureAIDeployment.gpt5:
        // GPT-5.2 base model - main workhorse
        return dotenv.env['AZURE_GPT_5_2_DEPLOYMENT'] ?? 'gpt-5.2';
      case AzureAIDeployment.gpt5Chat:
        // GPT-5.2-chat - optimized for conversation
        return dotenv.env['AZURE_GPT_5_2_CHAT_DEPLOYMENT'] ?? 'gpt-5.2-chat';
      case AzureAIDeployment.gpt5Nano:
        return dotenv.env['AZURE_GPT_5_NANO_DEPLOYMENT'] ?? 'gpt-5-nano';
    }
  }

  String get description {
    switch (this) {
      case AzureAIDeployment.transcription:
        return 'Transcription';
      case AzureAIDeployment.tts:
        return 'TTS';
      case AzureAIDeployment.realtimeVoice:
        return 'Realtime voice';
      case AzureAIDeployment.realtimeMini:
        return 'Realtime mini';
      case AzureAIDeployment.gpt5:
        return 'GPT-5.2 (main)';
      case AzureAIDeployment.gpt5Chat:
        return 'GPT-5.2-chat (conversation)';
      case AzureAIDeployment.gpt5Nano:
        return 'GPT-5 Nano (fast/cheap)';
    }
  }

  bool get isChat {
    return this == AzureAIDeployment.gpt5 ||
        this == AzureAIDeployment.gpt5Chat ||
        this == AzureAIDeployment.gpt5Nano;
  }
}

class AzureAIConfig {
  static const AzureAIDeployment defaultRealtimeDeployment =
      AzureAIDeployment.realtimeVoice;
  static const AzureAIDeployment defaultChatDeployment = AzureAIDeployment.gpt5;
  static const AzureAIDeployment fastChatDeployment =
      AzureAIDeployment.gpt5Nano;

  static const String realtimeApiVersion = '2024-10-01-preview';
  static const String chatApiVersion = '2025-01-01-preview';
  static const String realtimePath = '/openai/realtime';
  static const String chatCompletionsPath = '/openai/deployments';

  static Uri buildRealtimeUri({
    required String endpoint,
    required AzureAIDeployment deployment,
  }) {
    final baseUri = Uri.parse(endpoint);
    final normalizedPath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;

    return baseUri.replace(
      path: '$normalizedPath$realtimePath',
      queryParameters: {
        'api-version': realtimeApiVersion,
        'deployment': deployment.deploymentName,
      },
    );
  }

  static Uri buildChatCompletionsUri({
    required String endpoint,
    required AzureAIDeployment deployment,
  }) {
    final baseUri = Uri.parse(endpoint);
    final normalizedPath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;

    return baseUri.replace(
      path:
          '$normalizedPath$chatCompletionsPath/${deployment.deploymentName}/chat/completions',
      queryParameters: {
        'api-version': chatApiVersion,
      },
    );
  }
}
