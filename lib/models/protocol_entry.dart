import 'dart:convert';

/// Types of protocol entries that can be logged
enum ProtocolType {
  gym,
  meal,
  dose,
  meditation,
  focus,
  sleep;

  String get displayName {
    switch (this) {
      case ProtocolType.gym:
        return 'Gym';
      case ProtocolType.meal:
        return 'Meal';
      case ProtocolType.dose:
        return 'Dose';
      case ProtocolType.meditation:
        return 'Meditation';
      case ProtocolType.focus:
        return 'Focus';
      case ProtocolType.sleep:
        return 'Sleep';
    }
  }

  String get emoji {
    switch (this) {
      case ProtocolType.gym:
        return '💪';
      case ProtocolType.meal:
        return '🥗';
      case ProtocolType.dose:
        return '💊';
      case ProtocolType.meditation:
        return '🧘';
      case ProtocolType.focus:
        return '🎯';
      case ProtocolType.sleep:
        return '😴';
    }
  }
}

/// Represents a protocol log entry (gym, meal, dose, meditation, etc.)
class ProtocolEntry {
  final int? id;
  final DateTime timestamp;
  final ProtocolType type;
  final Map<String, dynamic> data; // Type-specific data
  final String? notes;

  ProtocolEntry({
    this.id,
    required this.timestamp,
    required this.type,
    Map<String, dynamic>? data,
    this.notes,
  }) : data = data ?? {};

  /// Create from database map
  factory ProtocolEntry.fromMap(Map<String, dynamic> map) {
    return ProtocolEntry(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: ProtocolType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ProtocolType.gym,
      ),
      data: map['data'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['data'] as String))
          : {},
      notes: map['notes'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'data': jsonEncode(data),
      'notes': notes,
    };
  }

  /// Create a gym entry
  factory ProtocolEntry.gym({
    int? id,
    DateTime? timestamp,
    int? durationMinutes,
    String? workout,
    String? notes,
  }) {
    return ProtocolEntry(
      id: id,
      timestamp: timestamp ?? DateTime.now(),
      type: ProtocolType.gym,
      data: {
        'duration_minutes': durationMinutes,
        'workout': workout,
      },
      notes: notes,
    );
  }

  /// Create a meal entry
  factory ProtocolEntry.meal({
    int? id,
    DateTime? timestamp,
    int? proteinGrams,
    int? calories,
    String? description,
    String? notes,
  }) {
    return ProtocolEntry(
      id: id,
      timestamp: timestamp ?? DateTime.now(),
      type: ProtocolType.meal,
      data: {
        'protein_grams': proteinGrams,
        'calories': calories,
        'description': description,
      },
      notes: notes,
    );
  }

  /// Create a dose entry
  factory ProtocolEntry.dose({
    int? id,
    DateTime? timestamp,
    double? milligrams,
    String? substance,
    String? notes,
  }) {
    return ProtocolEntry(
      id: id,
      timestamp: timestamp ?? DateTime.now(),
      type: ProtocolType.dose,
      data: {
        'milligrams': milligrams,
        'substance': substance,
      },
      notes: notes,
    );
  }

  /// Create a meditation entry
  factory ProtocolEntry.meditation({
    int? id,
    DateTime? timestamp,
    int? durationMinutes,
    String? technique,
    String? notes,
  }) {
    return ProtocolEntry(
      id: id,
      timestamp: timestamp ?? DateTime.now(),
      type: ProtocolType.meditation,
      data: {
        'duration_minutes': durationMinutes,
        'technique': technique,
      },
      notes: notes,
    );
  }

  /// Create a focus/deep work entry
  factory ProtocolEntry.focus({
    int? id,
    DateTime? timestamp,
    int? durationMinutes,
    String? task,
    String? notes,
  }) {
    return ProtocolEntry(
      id: id,
      timestamp: timestamp ?? DateTime.now(),
      type: ProtocolType.focus,
      data: {
        'duration_minutes': durationMinutes,
        'task': task,
      },
      notes: notes,
    );
  }

  /// Create a sleep entry
  factory ProtocolEntry.sleep({
    int? id,
    DateTime? timestamp,
    int? durationHours,
    int? quality, // 1-10
    String? notes,
  }) {
    return ProtocolEntry(
      id: id,
      timestamp: timestamp ?? DateTime.now(),
      type: ProtocolType.sleep,
      data: {
        'duration_hours': durationHours,
        'quality': quality,
      },
      notes: notes,
    );
  }

  @override
  String toString() {
    return 'ProtocolEntry(id: $id, type: ${type.displayName}, timestamp: $timestamp)';
  }
}
