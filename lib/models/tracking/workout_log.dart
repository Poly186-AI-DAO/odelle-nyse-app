import 'exercise_set.dart';

/// A workout session log entry.
class WorkoutLog {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final WorkoutType type;
  final String? name;
  final String? notes;
  final WorkoutSource source;

  // Location
  final String? locationName;
  final double? latitude;
  final double? longitude;

  // Metrics
  final int? caloriesBurned;
  final int? avgHeartRate;
  final int? maxHeartRate;

  // Subjective
  final int? perceivedEffort; // 1-10 RPE
  final int? energyLevel; // 1-10 before workout
  final String? mood;

  // For AI parsing
  final int? journalEntryId;

  // Generated image
  final String? imagePath;

  // Child exercises
  final List<ExerciseSet>? sets;

  WorkoutLog({
    this.id,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.type = WorkoutType.strength,
    this.name,
    this.notes,
    this.source = WorkoutSource.manual,
    this.locationName,
    this.latitude,
    this.longitude,
    this.caloriesBurned,
    this.avgHeartRate,
    this.maxHeartRate,
    this.perceivedEffort,
    this.energyLevel,
    this.mood,
    this.journalEntryId,
    this.imagePath,
    this.sets,
  });

  /// Create from database map.
  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    return WorkoutLog(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      durationMinutes: map['duration_minutes'] as int?,
      type: _parseWorkoutType(map['type'] as String?),
      name: map['name'] as String?,
      notes: map['notes'] as String?,
      source: _parseWorkoutSource(map['source'] as String?),
      locationName: map['location_name'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      caloriesBurned: map['calories_burned'] as int?,
      avgHeartRate: map['avg_heart_rate'] as int?,
      maxHeartRate: map['max_heart_rate'] as int?,
      perceivedEffort: map['perceived_effort'] as int?,
      energyLevel: map['energy_level'] as int?,
      mood: map['mood'] as String?,
      journalEntryId: map['journal_entry_id'] as int?,
      imagePath: map['image_path'] as String?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'type': type.name,
      'name': name,
      'notes': notes,
      'source': source.name,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'calories_burned': caloriesBurned,
      'avg_heart_rate': avgHeartRate,
      'max_heart_rate': maxHeartRate,
      'perceived_effort': perceivedEffort,
      'energy_level': energyLevel,
      'mood': mood,
      'journal_entry_id': journalEntryId,
      'image_path': imagePath,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog.fromMap(json);
  }

  /// Copy with modifications.
  WorkoutLog copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    WorkoutType? type,
    String? name,
    String? notes,
    WorkoutSource? source,
    String? locationName,
    double? latitude,
    double? longitude,
    int? caloriesBurned,
    int? avgHeartRate,
    int? maxHeartRate,
    int? perceivedEffort,
    int? energyLevel,
    String? mood,
    int? journalEntryId,
    String? imagePath,
    List<ExerciseSet>? sets,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      perceivedEffort: perceivedEffort ?? this.perceivedEffort,
      energyLevel: energyLevel ?? this.energyLevel,
      mood: mood ?? this.mood,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      imagePath: imagePath ?? this.imagePath,
      sets: sets ?? this.sets,
    );
  }

  @override
  String toString() {
    return 'WorkoutLog(id: $id, name: $name, type: ${type.name})';
  }
}

enum WorkoutType {
  strength,
  hypertrophy,
  powerlifting,
  cardio,
  hiit,
  flexibility,
  yoga,
  sports,
  mixed;

  String get displayName {
    switch (this) {
      case strength:
        return 'Strength';
      case hypertrophy:
        return 'Hypertrophy';
      case powerlifting:
        return 'Powerlifting';
      case cardio:
        return 'Cardio';
      case hiit:
        return 'HIIT';
      case flexibility:
        return 'Flexibility';
      case yoga:
        return 'Yoga';
      case sports:
        return 'Sports';
      case mixed:
        return 'Mixed';
    }
  }
}

enum WorkoutSource {
  manual,
  voice,
  healthKit,
  googleFit,
  import_;

  String get displayName {
    switch (this) {
      case manual:
        return 'Manual';
      case voice:
        return 'Voice';
      case healthKit:
        return 'Apple Health';
      case googleFit:
        return 'Google Fit';
      case import_:
        return 'Import';
    }
  }
}

WorkoutType _parseWorkoutType(String? value) {
  if (value == null || value.isEmpty) return WorkoutType.strength;
  return WorkoutType.values.firstWhere(
    (wt) => wt.name == value,
    orElse: () => WorkoutType.strength,
  );
}

WorkoutSource _parseWorkoutSource(String? value) {
  if (value == null || value.isEmpty) return WorkoutSource.manual;
  // Handle legacy 'import' value
  if (value == 'import') return WorkoutSource.import_;
  return WorkoutSource.values.firstWhere(
    (ws) => ws.name == value,
    orElse: () => WorkoutSource.manual,
  );
}
