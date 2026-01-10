/// Personal record tracking for exercises.
class PersonalRecord {
  final int? id;
  final int exerciseTypeId;
  final PRType type;
  final double value;
  final String unit;
  final DateTime achievedAt;
  final int? workoutLogId;
  final int? setId;
  final double? bodyweightLbs;
  final String? notes;

  PersonalRecord({
    this.id,
    required this.exerciseTypeId,
    required this.type,
    required this.value,
    required this.unit,
    required this.achievedAt,
    this.workoutLogId,
    this.setId,
    this.bodyweightLbs,
    this.notes,
  });

  /// Create from database map.
  factory PersonalRecord.fromMap(Map<String, dynamic> map) {
    return PersonalRecord(
      id: map['id'] as int?,
      exerciseTypeId: (map['exercise_type_id'] as int?) ?? 0,
      type: _parsePRType(map['type'] as String?),
      value: (map['value'] as num?)?.toDouble() ?? 0,
      unit: (map['unit'] as String?) ?? 'lbs',
      achievedAt: DateTime.parse(map['achieved_at'] as String),
      workoutLogId: map['workout_log_id'] as int?,
      setId: map['set_id'] as int?,
      bodyweightLbs: (map['bodyweight_lbs'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exercise_type_id': exerciseTypeId,
      'type': type.name,
      'value': value,
      'unit': unit,
      'achieved_at': achievedAt.toIso8601String(),
      'workout_log_id': workoutLogId,
      'set_id': setId,
      'bodyweight_lbs': bodyweightLbs,
      'notes': notes,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord.fromMap(json);
  }

  /// Copy with modifications.
  PersonalRecord copyWith({
    int? id,
    int? exerciseTypeId,
    PRType? type,
    double? value,
    String? unit,
    DateTime? achievedAt,
    int? workoutLogId,
    int? setId,
    double? bodyweightLbs,
    String? notes,
  }) {
    return PersonalRecord(
      id: id ?? this.id,
      exerciseTypeId: exerciseTypeId ?? this.exerciseTypeId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      achievedAt: achievedAt ?? this.achievedAt,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      setId: setId ?? this.setId,
      bodyweightLbs: bodyweightLbs ?? this.bodyweightLbs,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'PersonalRecord(id: $id, type: ${type.name}, value: $value $unit)';
  }
}

enum PRType {
  oneRepMax,
  threeRepMax,
  fiveRepMax,
  tenRepMax,
  maxReps,
  maxWeight,
  maxVolume,
  maxDuration;

  String get displayName {
    switch (this) {
      case oneRepMax:
        return '1 Rep Max';
      case threeRepMax:
        return '3 Rep Max';
      case fiveRepMax:
        return '5 Rep Max';
      case tenRepMax:
        return '10 Rep Max';
      case maxReps:
        return 'Max Reps';
      case maxWeight:
        return 'Max Weight';
      case maxVolume:
        return 'Max Volume';
      case maxDuration:
        return 'Max Duration';
    }
  }
}

PRType _parsePRType(String? value) {
  if (value == null || value.isEmpty) return PRType.oneRepMax;
  return PRType.values.firstWhere(
    (pr) => pr.name == value,
    orElse: () => PRType.oneRepMax,
  );
}
