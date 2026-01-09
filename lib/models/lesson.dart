class Lesson {
  final int lessonNumber;
  final String title;
  final String description;
  final List<String> objectives;
  final String lessonFolder;
  final List<Phrase> phrases;
  final String duration;
  final PhraseLearningStrategy learningStrategy;

  Lesson({
    required this.lessonNumber,
    required this.title,
    required this.description,
    required this.objectives,
    required this.lessonFolder,
    required this.phrases,
    required this.duration,
    required this.learningStrategy,
  });
}

class PhraseLearningStrategy {
  final int totalRepetitions;
  final List<String> anticipationMethod;

  PhraseLearningStrategy({
    required this.totalRepetitions,
    required this.anticipationMethod,
  });

  factory PhraseLearningStrategy.fromJson(Map<String, dynamic> json) {
    return PhraseLearningStrategy(
      totalRepetitions: json['total_repetitions'],
      anticipationMethod: List<String>.from(json['anticipation_method']),
    );
  }
}

class Phrase {
  final String spanish;
  final String english;
  final List<PhraseComponent> components;
  final List<String> practiceSequence;
  final List<PhraseVariation> variations;
  final String femaleAudio;
  final String maleAudio;
  final Map<String, String> componentAudio;

  Phrase({
    required this.spanish,
    required this.english,
    required this.components,
    required this.practiceSequence,
    required this.variations,
    required this.femaleAudio,
    required this.maleAudio,
    required this.componentAudio,
  });

  factory Phrase.fromJson(Map<String, dynamic> json, String lessonFolder) {
    return Phrase(
      spanish: json['spanish'],
      english: json['english'],
      components: (json['components'] as List)
          .map((e) => PhraseComponent.fromJson(e))
          .toList(),
      practiceSequence: List<String>.from(json['practice_sequence']),
      variations: (json['variations'] as List)
          .map((e) => PhraseVariation.fromJson(e))
          .toList(),
      femaleAudio:
          'dev_assets/elevenlabs/$lessonFolder/female/phrase_1/main.wav',
      maleAudio: 'dev_assets/elevenlabs/$lessonFolder/male/phrase_1/main.wav',
      componentAudio: {
        'practice_step_1':
            'dev_assets/elevenlabs/$lessonFolder/female/phrase_1/practice_step_1.wav',
        'practice_step_2':
            'dev_assets/elevenlabs/$lessonFolder/female/phrase_1/practice_step_2.wav',
        'practice_step_3':
            'dev_assets/elevenlabs/$lessonFolder/female/phrase_1/practice_step_3.wav',
      },
    );
  }
}

class PhraseComponent {
  final String spanish;
  final String english;
  final List<String> anticipationSteps;

  PhraseComponent({
    required this.spanish,
    required this.english,
    required this.anticipationSteps,
  });

  factory PhraseComponent.fromJson(Map<String, dynamic> json) {
    return PhraseComponent(
      spanish: json['spanish'],
      english: json['english'],
      anticipationSteps: List<String>.from(json['anticipation_steps']),
    );
  }
}

class PhraseVariation {
  final String type;
  final List<PhraseExample> examples;

  PhraseVariation({
    required this.type,
    required this.examples,
  });

  factory PhraseVariation.fromJson(Map<String, dynamic> json) {
    return PhraseVariation(
      type: json['type'],
      examples: (json['examples'] as List)
          .map((e) => PhraseExample.fromJson(e))
          .toList(),
    );
  }
}

class PhraseExample {
  final String original;
  final String variation;
  final String explanation;

  PhraseExample({
    required this.original,
    required this.variation,
    required this.explanation,
  });

  factory PhraseExample.fromJson(Map<String, dynamic> json) {
    return PhraseExample(
      original: json['original'],
      variation: json['variation'],
      explanation: json['explanation'],
    );
  }
}
