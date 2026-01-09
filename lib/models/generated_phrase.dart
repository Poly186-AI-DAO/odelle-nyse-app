class GeneratedPhrase {
  final String text;
  final String? translation;
  final String? context;
  final List<String>? variations;
  final String? history;
  final List<String>? components;

  GeneratedPhrase({
    required this.text,
    this.translation,
    this.context,
    this.variations,
    this.history,
    this.components,
  });

  factory GeneratedPhrase.fromJson(Map<String, dynamic> json) {
    return GeneratedPhrase(
      text: json['text'] as String,
      translation: json['translation'] as String?,
      context: json['context'] as String?,
      variations: (json['variations'] as List<dynamic>?)?.cast<String>(),
      history: json['history'] as String?,
      components: (json['components'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'translation': translation,
      'context': context,
      'variations': variations,
      'history': history,
      'components': components,
    };
  }
}
