import 'dart:convert';

/// An exercise in the library (catalog).
class ExerciseType {
  final int? id;
  final String name;
  final ExerciseCategory category;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final EquipmentType equipment;
  final String? instructions;
  final String? videoUrl;
  final String? imageUrl;
  final bool isCompound;
  final bool isCustom;
  final DateTime createdAt;

  ExerciseType({
    this.id,
    required this.name,
    required this.category,
    required this.primaryMuscle,
    List<MuscleGroup>? secondaryMuscles,
    this.equipment = EquipmentType.bodyweight,
    this.instructions,
    this.videoUrl,
    this.imageUrl,
    this.isCompound = false,
    this.isCustom = false,
    DateTime? createdAt,
  })  : secondaryMuscles = secondaryMuscles ?? const [],
        createdAt = createdAt ?? DateTime.now();

  /// Create from database map.
  factory ExerciseType.fromMap(Map<String, dynamic> map) {
    return ExerciseType(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      category: _parseExerciseCategory(map['category'] as String?),
      primaryMuscle: _parseMuscleGroup(map['primary_muscle'] as String?),
      secondaryMuscles: _parseMuscleGroupList(map['secondary_muscles']),
      equipment: _parseEquipmentType(map['equipment'] as String?),
      instructions: map['instructions'] as String?,
      videoUrl: map['video_url'] as String?,
      imageUrl: map['image_url'] as String?,
      isCompound: _parseBool(map['is_compound']),
      isCustom: _parseBool(map['is_custom']),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category.name,
      'primary_muscle': primaryMuscle.name,
      'secondary_muscles': _encodeMuscleGroupList(secondaryMuscles),
      'equipment': equipment.name,
      'instructions': instructions,
      'video_url': videoUrl,
      'image_url': imageUrl,
      'is_compound': isCompound ? 1 : 0,
      'is_custom': isCustom ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory ExerciseType.fromJson(Map<String, dynamic> json) {
    return ExerciseType.fromMap(json);
  }

  /// Copy with modifications.
  ExerciseType copyWith({
    int? id,
    String? name,
    ExerciseCategory? category,
    MuscleGroup? primaryMuscle,
    List<MuscleGroup>? secondaryMuscles,
    EquipmentType? equipment,
    String? instructions,
    String? videoUrl,
    String? imageUrl,
    bool? isCompound,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return ExerciseType(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      instructions: instructions ?? this.instructions,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isCompound: isCompound ?? this.isCompound,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ExerciseType(id: $id, name: $name, category: ${category.name})';
  }
}

enum ExerciseCategory {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  quadriceps,
  hamstrings,
  glutes,
  calves,
  core,
  cardio,
  stretching,
  other;

  String get displayName {
    switch (this) {
      case chest:
        return 'Chest';
      case back:
        return 'Back';
      case shoulders:
        return 'Shoulders';
      case biceps:
        return 'Biceps';
      case triceps:
        return 'Triceps';
      case forearms:
        return 'Forearms';
      case quadriceps:
        return 'Quadriceps';
      case hamstrings:
        return 'Hamstrings';
      case glutes:
        return 'Glutes';
      case calves:
        return 'Calves';
      case core:
        return 'Core';
      case cardio:
        return 'Cardio';
      case stretching:
        return 'Stretching';
      case other:
        return 'Other';
    }
  }
}

enum MuscleGroup {
  chest,
  lats,
  traps,
  rhomboids,
  rearDelts,
  frontDelts,
  sideDelts,
  biceps,
  triceps,
  forearms,
  abs,
  obliques,
  lowerBack,
  glutes,
  quads,
  hamstrings,
  calves;

  String get displayName {
    switch (this) {
      case chest:
        return 'Chest';
      case lats:
        return 'Lats';
      case traps:
        return 'Traps';
      case rhomboids:
        return 'Rhomboids';
      case rearDelts:
        return 'Rear Delts';
      case frontDelts:
        return 'Front Delts';
      case sideDelts:
        return 'Side Delts';
      case biceps:
        return 'Biceps';
      case triceps:
        return 'Triceps';
      case forearms:
        return 'Forearms';
      case abs:
        return 'Abs';
      case obliques:
        return 'Obliques';
      case lowerBack:
        return 'Lower Back';
      case glutes:
        return 'Glutes';
      case quads:
        return 'Quads';
      case hamstrings:
        return 'Hamstrings';
      case calves:
        return 'Calves';
    }
  }
}

enum EquipmentType {
  barbell,
  dumbbell,
  kettlebell,
  machine,
  cable,
  bodyweight,
  bands,
  cardioMachine,
  other;

  String get displayName {
    switch (this) {
      case barbell:
        return 'Barbell';
      case dumbbell:
        return 'Dumbbell';
      case kettlebell:
        return 'Kettlebell';
      case machine:
        return 'Machine';
      case cable:
        return 'Cable';
      case bodyweight:
        return 'Bodyweight';
      case bands:
        return 'Resistance Bands';
      case cardioMachine:
        return 'Cardio Machine';
      case other:
        return 'Other';
    }
  }
}

ExerciseCategory _parseExerciseCategory(String? value) {
  if (value == null || value.isEmpty) return ExerciseCategory.other;
  return ExerciseCategory.values.firstWhere(
    (cat) => cat.name == value,
    orElse: () => ExerciseCategory.other,
  );
}

MuscleGroup _parseMuscleGroup(String? value) {
  if (value == null || value.isEmpty) return MuscleGroup.chest;
  return MuscleGroup.values.firstWhere(
    (mg) => mg.name == value,
    orElse: () => MuscleGroup.chest,
  );
}

EquipmentType _parseEquipmentType(String? value) {
  if (value == null || value.isEmpty) return EquipmentType.bodyweight;
  return EquipmentType.values.firstWhere(
    (eq) => eq.name == value,
    orElse: () => EquipmentType.bodyweight,
  );
}

List<MuscleGroup> _parseMuscleGroupList(dynamic value) {
  final items = _parseStringList(value);
  if (items == null) return <MuscleGroup>[];
  return items
      .map(
        (item) => MuscleGroup.values.firstWhere(
          (mg) => mg.name == item,
          orElse: () => MuscleGroup.chest,
        ),
      )
      .toList();
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

String? _encodeMuscleGroupList(List<MuscleGroup> values) {
  if (values.isEmpty) return jsonEncode(<String>[]);
  return jsonEncode(values.map((mg) => mg.name).toList());
}
