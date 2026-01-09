/// Available voice options for the digital worker
enum DigitalWorkerVoice {
  alloy,
  ash,
  ballad,
  coral,
  echo,
  sage,
  shimmer,
  verse;

  /// Convert the enum to a string that matches the API's expected format
  String get value => name.toLowerCase();

  /// Get a human-readable description of the voice
  String get description {
    switch (this) {
      case DigitalWorkerVoice.alloy:
        return 'Alloy - A versatile, general-purpose voice';
      case DigitalWorkerVoice.ash:
        return 'Ash - A calm, measured voice';
      case DigitalWorkerVoice.ballad:
        return 'Ballad - A melodic, emotive voice';
      case DigitalWorkerVoice.coral:
        return 'Coral - A warm, friendly voice';
      case DigitalWorkerVoice.echo:
        return 'Echo - A clear, resonant voice';
      case DigitalWorkerVoice.sage:
        return 'Sage - A wise, knowledgeable voice';
      case DigitalWorkerVoice.shimmer:
        return 'Shimmer - A soft, gentle voice';
      case DigitalWorkerVoice.verse:
        return 'Verse - A lyrical, poetic voice';
    }
  }
}
