class LearningContext {
  final String topic;
  final String difficulty;
  final String? dialect;
  final String? culturalContext;

  LearningContext({
    required this.topic,
    required this.difficulty,
    this.dialect,
    this.culturalContext,
  });

  factory LearningContext.fromJson(Map<String, dynamic> json) {
    return LearningContext(
      topic: json['topic'] as String,
      difficulty: json['difficulty'] as String,
      dialect: json['dialect'] as String?,
      culturalContext: json['culturalContext'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'difficulty': difficulty,
      'dialect': dialect,
      'culturalContext': culturalContext,
    };
  }
}
