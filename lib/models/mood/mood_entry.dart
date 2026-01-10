import 'dart:convert';

/// A single mood check-in.
class MoodEntry {
  final int? id;
  final int userId;
  final DateTime timestamp;
  final MoodType mood;
  final int? intensity;

  // Optional details
  final List<MoodType>? secondaryMoods;
  final List<String>? factors;
  final String? notes;

  // Context
  final MoodCheckInType checkInType;
  final int? linkedSessionId;
  final int? linkedWorkoutId;

  // For AI
  final int? journalEntryId;

  MoodEntry({
    this.id,
    required this.userId,
    required this.timestamp,
    required this.mood,
    this.intensity,
    this.secondaryMoods,
    this.factors,
    this.notes,
    this.checkInType = MoodCheckInType.manual,
    this.linkedSessionId,
    this.linkedWorkoutId,
    this.journalEntryId,
  });

  /// Create from database map.
  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      timestamp: DateTime.parse(map['timestamp'] as String),
      mood: _parseMoodType(map['mood'] as String?),
      intensity: map['intensity'] as int?,
      secondaryMoods: _parseMoodList(map['secondary_moods']),
      factors: _parseStringList(map['factors']),
      notes: map['notes'] as String?,
      checkInType: _parseCheckInType(map['check_in_type'] as String?),
      linkedSessionId: map['linked_session_id'] as int?,
      linkedWorkoutId: map['linked_workout_id'] as int?,
      journalEntryId: map['journal_entry_id'] as int?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood.name,
      'intensity': intensity,
      'secondary_moods': _encodeMoodList(secondaryMoods),
      'factors': _encodeStringList(factors),
      'notes': notes,
      'check_in_type': checkInType.name,
      'linked_session_id': linkedSessionId,
      'linked_workout_id': linkedWorkoutId,
      'journal_entry_id': journalEntryId,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry.fromMap(json);
  }

  /// Copy with modifications.
  MoodEntry copyWith({
    int? id,
    int? userId,
    DateTime? timestamp,
    MoodType? mood,
    int? intensity,
    List<MoodType>? secondaryMoods,
    List<String>? factors,
    String? notes,
    MoodCheckInType? checkInType,
    int? linkedSessionId,
    int? linkedWorkoutId,
    int? journalEntryId,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
      intensity: intensity ?? this.intensity,
      secondaryMoods: secondaryMoods ?? this.secondaryMoods,
      factors: factors ?? this.factors,
      notes: notes ?? this.notes,
      checkInType: checkInType ?? this.checkInType,
      linkedSessionId: linkedSessionId ?? this.linkedSessionId,
      linkedWorkoutId: linkedWorkoutId ?? this.linkedWorkoutId,
      journalEntryId: journalEntryId ?? this.journalEntryId,
    );
  }

  @override
  String toString() {
    return 'MoodEntry(id: $id, mood: ${mood.name}, timestamp: $timestamp)';
  }
}

enum MoodType {
  // Positive
  happy,
  calm,
  grateful,
  energized,
  focused,
  confident,
  excited,
  peaceful,
  content,

  // Neutral
  neutral,
  tired,
  distracted,

  // Negative
  anxious,
  stressed,
  sad,
  frustrated,
  angry,
  overwhelmed,
  lonely,
  bored;

  String get emoji {
    switch (this) {
      case MoodType.happy:
        return '😊';
      case MoodType.calm:
        return '😌';
      case MoodType.grateful:
        return '🙏';
      case MoodType.energized:
        return '⚡';
      case MoodType.focused:
        return '🎯';
      case MoodType.confident:
        return '💪';
      case MoodType.excited:
        return '🎉';
      case MoodType.peaceful:
        return '☮️';
      case MoodType.content:
        return '😊';
      case MoodType.neutral:
        return '😐';
      case MoodType.tired:
        return '😴';
      case MoodType.distracted:
        return '🤔';
      case MoodType.anxious:
        return '😰';
      case MoodType.stressed:
        return '😫';
      case MoodType.sad:
        return '😢';
      case MoodType.frustrated:
        return '😤';
      case MoodType.angry:
        return '😠';
      case MoodType.overwhelmed:
        return '🤯';
      case MoodType.lonely:
        return '😔';
      case MoodType.bored:
        return '😑';
    }
  }

  bool get isPositive => index <= 8;
  bool get isNeutral => index >= 9 && index <= 11;
  bool get isNegative => index >= 12;
}

enum MoodCheckInType {
  morning,
  evening,
  postSession,
  manual;
}

MoodType _parseMoodType(String? value) {
  if (value == null || value.isEmpty) return MoodType.neutral;
  return MoodType.values.firstWhere(
    (mood) => mood.name == value,
    orElse: () => MoodType.neutral,
  );
}

MoodCheckInType _parseCheckInType(String? value) {
  if (value == null || value.isEmpty) return MoodCheckInType.manual;
  return MoodCheckInType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => MoodCheckInType.manual,
  );
}

List<MoodType>? _parseMoodList(dynamic value) {
  final items = _parseStringList(value);
  if (items == null) return null;
  return items
      .map(
        (item) => MoodType.values.firstWhere(
          (mood) => mood.name == item,
          orElse: () => MoodType.neutral,
        ),
      )
      .toList();
}

String? _encodeMoodList(List<MoodType>? values) {
  if (values == null) return null;
  return jsonEncode(values.map((value) => value.name).toList());
}

List<String>? _parseStringList(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    if (value.isEmpty) return <String>[];
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return decoded.map((item) => item.toString()).toList();
    }
  }
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return null;
}

String? _encodeStringList(List<String>? values) {
  if (values == null) return null;
  return jsonEncode(values);
}
