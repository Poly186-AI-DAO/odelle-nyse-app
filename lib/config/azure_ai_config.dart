enum AzureAIDeployment {
  transcription,
  tts,
  realtimeVoice,
  realtimeMini,
  gpt5Chat,
  gpt5Nano,
}

extension AzureAIDeploymentInfo on AzureAIDeployment {
  String get deploymentName {
    switch (this) {
      case AzureAIDeployment.transcription:
        return 'gpt-4o-transcribe';
      case AzureAIDeployment.tts:
        return 'gpt-audio';
      case AzureAIDeployment.realtimeVoice:
        return 'gpt-realtime';
      case AzureAIDeployment.realtimeMini:
        return 'gpt-realtime-mini';
      case AzureAIDeployment.gpt5Chat:
        return 'gpt-5.2-chat';
      case AzureAIDeployment.gpt5Nano:
        return 'gpt-5-nano';
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
      case AzureAIDeployment.gpt5Chat:
        return 'GPT-5.2 Chat (heavy reasoning)';
      case AzureAIDeployment.gpt5Nano:
        return 'GPT-5 Nano (fast/cheap)';
    }
  }

  bool get isChat {
    return this == AzureAIDeployment.gpt5Chat ||
        this == AzureAIDeployment.gpt5Nano;
  }
}

class AzureAIConfig {
  static const AzureAIDeployment defaultRealtimeDeployment =
      AzureAIDeployment.realtimeVoice;
  static const AzureAIDeployment defaultChatDeployment =
      AzureAIDeployment.gpt5Chat;
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
