class ContextSuggestion {
  final String topic;
  final String description;
  final String? icon;

  ContextSuggestion({
    required this.topic,
    required this.description,
    this.icon,
  });

  factory ContextSuggestion.fromJson(Map<String, dynamic> json) {
    return ContextSuggestion(
      topic: json['topic'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'description': description,
      'icon': icon,
    };
  }
}
