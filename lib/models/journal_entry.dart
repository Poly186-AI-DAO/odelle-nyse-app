import 'dart:convert';

/// Represents a voice journal entry from the "Kitchen Confessional"
class JournalEntry {
  final int? id;
  final DateTime timestamp;
  final String transcription;
  final double? mood; // 1-10 scale
  final String? sentiment; // positive, negative, neutral
  final List<String> tags;

  JournalEntry({
    this.id,
    required this.timestamp,
    required this.transcription,
    this.mood,
    this.sentiment,
    List<String>? tags,
  }) : tags = tags ?? [];

  /// Create from database map
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      transcription: map['transcription'] as String,
      mood: map['mood'] as double?,
      sentiment: map['sentiment'] as String?,
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.toIso8601String(),
      'transcription': transcription,
      'mood': mood,
      'sentiment': sentiment,
      'tags': jsonEncode(tags),
    };
  }

  /// Copy with modifications
  JournalEntry copyWith({
    int? id,
    DateTime? timestamp,
    String? transcription,
    double? mood,
    String? sentiment,
    List<String>? tags,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      transcription: transcription ?? this.transcription,
      mood: mood ?? this.mood,
      sentiment: sentiment ?? this.sentiment,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'JournalEntry(id: $id, timestamp: $timestamp, transcription: ${transcription.substring(0, transcription.length > 50 ? 50 : transcription.length)}...)';
  }
}
