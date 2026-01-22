/// Represents a user mantra or affirmation for CBT layer
class Mantra {
  final int? id;
  final String text;
  final bool isActive;
  final DateTime createdAt;
  final String? category; // e.g., "morning", "stress", "focus"
  final String? imagePath; // Local path to generated image

  Mantra({
    this.id,
    required this.text,
    this.isActive = true,
    DateTime? createdAt,
    this.category,
    this.imagePath,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from database map
  factory Mantra.fromMap(Map<String, dynamic> map) {
    return Mantra(
      id: map['id'] as int?,
      text: map['text'] as String,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      category: map['category'] as String?,
      imagePath: map['image_path'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'text': text,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'category': category,
      'image_path': imagePath,
    };
  }

  /// Copy with modifications
  Mantra copyWith({
    int? id,
    String? text,
    bool? isActive,
    DateTime? createdAt,
    String? category,
    String? imagePath,
  }) {
    return Mantra(
      id: id ?? this.id,
      text: text ?? this.text,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'Mantra(id: $id, text: ${text.substring(0, text.length > 30 ? 30 : text.length)}..., active: $isActive)';
  }
}

/// Default mantras to seed the database
class DefaultMantras {
  static List<Mantra> get all => [
        Mantra(
          text:
              "I am updating my source code. Every day I become a better version.",
          category: "morning",
        ),
        Mantra(
          text: "The world needs what I'm building. I am not a broke Tesla.",
          category: "focus",
        ),
        Mantra(
          text: "This is my inflection point. It starts now.",
          category: "motivation",
        ),
        Mantra(
          text:
              "I am the architect of my neural pathways. What I focus on, I become.",
          category: "meditation",
        ),
        Mantra(
          text: "Self-actualization is the foundation of world improvement.",
          category: "morning",
        ),
      ];
}
