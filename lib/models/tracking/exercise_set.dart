import 'exercise_type.dart';

/// A single set of an exercise within a workout.
class ExerciseSet {
  final int? id;
  final int workoutLogId;
  final int exerciseTypeId;
  final int setNumber;
  final SetType setType;

  // For strength training
  final double? weightLbs;
  final double? weightKg;
  final int? reps;
  final int? targetReps;
  final double? rpe; // 1-10 Rating of Perceived Exertion
  final bool? toFailure;

  // For cardio/timed
  final int? durationSeconds;
  final double? distanceMiles;
  final double? distanceKm;
  final int? caloriesBurned;

  // For tracking PRs
  final bool isPersonalRecord;

  final String? notes;

  // Derived
  final ExerciseType? exercise;

  ExerciseSet({
    this.id,
    required this.workoutLogId,
    required this.exerciseTypeId,
    required this.setNumber,
    this.setType = SetType.working,
    this.weightLbs,
    this.weightKg,
    this.reps,
    this.targetReps,
    this.rpe,
    this.toFailure,
    this.durationSeconds,
    this.distanceMiles,
    this.distanceKm,
    this.caloriesBurned,
    this.isPersonalRecord = false,
    this.notes,
    this.exercise,
  });

  /// Create from database map.
  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      id: map['id'] as int?,
      workoutLogId: (map['workout_log_id'] as int?) ?? 0,
      exerciseTypeId: (map['exercise_type_id'] as int?) ?? 0,
      setNumber: (map['set_number'] as int?) ?? 1,
      setType: _parseSetType(map['set_type'] as String?),
      weightLbs: (map['weight_lbs'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      reps: map['reps'] as int?,
      targetReps: map['target_reps'] as int?,
      rpe: (map['rpe'] as num?)?.toDouble(),
      toFailure: _parseBool(map['to_failure']),
      durationSeconds: map['duration_seconds'] as int?,
      distanceMiles: (map['distance_miles'] as num?)?.toDouble(),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      caloriesBurned: map['calories_burned'] as int?,
      isPersonalRecord: _parseBool(map['is_personal_record']),
      notes: map['notes'] as String?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'workout_log_id': workoutLogId,
      'exercise_type_id': exerciseTypeId,
      'set_number': setNumber,
      'set_type': setType.name,
      'weight_lbs': weightLbs,
      'weight_kg': weightKg,
      'reps': reps,
      'target_reps': targetReps,
      'rpe': rpe,
      'to_failure': toFailure == true ? 1 : 0,
      'duration_seconds': durationSeconds,
      'distance_miles': distanceMiles,
      'distance_km': distanceKm,
      'calories_burned': caloriesBurned,
      'is_personal_record': isPersonalRecord ? 1 : 0,
      'notes': notes,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet.fromMap(json);
  }

  /// Copy with modifications.
  ExerciseSet copyWith({
    int? id,
    int? workoutLogId,
    int? exerciseTypeId,
    int? setNumber,
    SetType? setType,
    double? weightLbs,
    double? weightKg,
    int? reps,
    int? targetReps,
    double? rpe,
    bool? toFailure,
    int? durationSeconds,
    double? distanceMiles,
    double? distanceKm,
    int? caloriesBurned,
    bool? isPersonalRecord,
    String? notes,
    ExerciseType? exercise,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      exerciseTypeId: exerciseTypeId ?? this.exerciseTypeId,
      setNumber: setNumber ?? this.setNumber,
      setType: setType ?? this.setType,
      weightLbs: weightLbs ?? this.weightLbs,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      targetReps: targetReps ?? this.targetReps,
      rpe: rpe ?? this.rpe,
      toFailure: toFailure ?? this.toFailure,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMiles: distanceMiles ?? this.distanceMiles,
      distanceKm: distanceKm ?? this.distanceKm,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      isPersonalRecord: isPersonalRecord ?? this.isPersonalRecord,
      notes: notes ?? this.notes,
      exercise: exercise ?? this.exercise,
    );
  }

  @override
  String toString() {
    return 'ExerciseSet(id: $id, setNumber: $setNumber, reps: $reps, weight: $weightLbs lbs)';
  }
}

enum SetType {
  warmup,
  working,
  topSet,
  backOff,
  dropSet,
  restPause,
  cluster,
  amrap,
  toFailure;

  String get displayName {
    switch (this) {
      case warmup:
        return 'Warm-up';
      case working:
        return 'Working';
      case topSet:
        return 'Top Set';
      case backOff:
        return 'Back-off';
      case dropSet:
        return 'Drop Set';
      case restPause:
        return 'Rest-Pause';
      case cluster:
        return 'Cluster';
      case amrap:
        return 'AMRAP';
      case toFailure:
        return 'To Failure';
    }
  }
}

SetType _parseSetType(String? value) {
  if (value == null || value.isEmpty) return SetType.working;
  return SetType.values.firstWhere(
    (st) => st.name == value,
    orElse: () => SetType.working,
  );
}

bool _parseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
  }
  return defaultValue;
}
