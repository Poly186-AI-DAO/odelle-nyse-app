enum AzureAIDeployment {
  transcription,
  tts,
  realtimeVoice,
  realtimeMini,
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
    }
  }
}

class AzureAIConfig {
  static const AzureAIDeployment defaultRealtimeDeployment =
      AzureAIDeployment.realtimeVoice;
  static const String realtimeApiVersion = '2024-10-01-preview';
  static const String realtimePath = '/openai/realtime';

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
}
