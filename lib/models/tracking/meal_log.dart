

/// A meal or eating event log entry.
class MealLog {
  final int? id;
  final DateTime timestamp;
  final MealType type;
  final String? description;
  final MealSource source;

  // Macros (all optional - filled in if known)
  final int? calories;
  final int? proteinGrams;
  final int? carbsGrams;
  final int? fatGrams;
  final int? fiberGrams;

  // Quick logging
  final ProteinLevel? proteinLevel;
  final MealQuality? quality;

  // Context
  final String? location;
  final bool homemade;
  final bool mealPrepped;

  // Photo
  final String? photoPath;

  // For AI parsing
  final int? journalEntryId;
  final double? confidence;

  final String? notes;

  // Child items (optional detailed logging)
  final List<MealItem>? items;

  MealLog({
    this.id,
    required this.timestamp,
    this.type = MealType.other,
    this.description,
    this.source = MealSource.manual,
    this.calories,
    this.proteinGrams,
    this.carbsGrams,
    this.fatGrams,
    this.fiberGrams,
    this.proteinLevel,
    this.quality,
    this.location,
    this.homemade = false,
    this.mealPrepped = false,
    this.photoPath,
    this.journalEntryId,
    this.confidence,
    this.notes,
    this.items,
  });

  /// Create from database map.
  factory MealLog.fromMap(Map<String, dynamic> map) {
    return MealLog(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: _parseMealType(map['type'] as String?),
      description: map['description'] as String?,
      source: _parseMealSource(map['source'] as String?),
      calories: map['calories'] as int?,
      proteinGrams: map['protein_grams'] as int?,
      carbsGrams: map['carbs_grams'] as int?,
      fatGrams: map['fat_grams'] as int?,
      fiberGrams: map['fiber_grams'] as int?,
      proteinLevel: _parseProteinLevel(map['protein_level'] as String?),
      quality: _parseMealQuality(map['quality'] as String?),
      location: map['location'] as String?,
      homemade: _parseBool(map['homemade']),
      mealPrepped: _parseBool(map['meal_prepped']),
      photoPath: map['photo_path'] as String?,
      journalEntryId: map['journal_entry_id'] as int?,
      confidence: (map['confidence'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'description': description,
      'source': source.name,
      'calories': calories,
      'protein_grams': proteinGrams,
      'carbs_grams': carbsGrams,
      'fat_grams': fatGrams,
      'fiber_grams': fiberGrams,
      'protein_level': proteinLevel?.name,
      'quality': quality?.name,
      'location': location,
      'homemade': homemade ? 1 : 0,
      'meal_prepped': mealPrepped ? 1 : 0,
      'photo_path': photoPath,
      'journal_entry_id': journalEntryId,
      'confidence': confidence,
      'notes': notes,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog.fromMap(json);
  }

  /// Copy with modifications.
  MealLog copyWith({
    int? id,
    DateTime? timestamp,
    MealType? type,
    String? description,
    MealSource? source,
    int? calories,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
    int? fiberGrams,
    ProteinLevel? proteinLevel,
    MealQuality? quality,
    String? location,
    bool? homemade,
    bool? mealPrepped,
    String? photoPath,
    int? journalEntryId,
    double? confidence,
    String? notes,
    List<MealItem>? items,
  }) {
    return MealLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      description: description ?? this.description,
      source: source ?? this.source,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      proteinLevel: proteinLevel ?? this.proteinLevel,
      quality: quality ?? this.quality,
      location: location ?? this.location,
      homemade: homemade ?? this.homemade,
      mealPrepped: mealPrepped ?? this.mealPrepped,
      photoPath: photoPath ?? this.photoPath,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }

  @override
  String toString() {
    return 'MealLog(id: $id, type: ${type.name}, calories: $calories)';
  }
}

/// Individual food item within a meal (optional detail).
class MealItem {
  final int? id;
  final int mealLogId;
  final String name;
  final double? servingSize;
  final String? servingUnit;

  // Macros for this item
  final int? calories;
  final int? proteinGrams;
  final int? carbsGrams;
  final int? fatGrams;

  // Barcode lookup
  final String? barcode;
  final String? brandName;

  MealItem({
    this.id,
    required this.mealLogId,
    required this.name,
    this.servingSize,
    this.servingUnit,
    this.calories,
    this.proteinGrams,
    this.carbsGrams,
    this.fatGrams,
    this.barcode,
    this.brandName,
  });

  /// Create from database map.
  factory MealItem.fromMap(Map<String, dynamic> map) {
    return MealItem(
      id: map['id'] as int?,
      mealLogId: (map['meal_log_id'] as int?) ?? 0,
      name: (map['name'] as String?) ?? '',
      servingSize: (map['serving_size'] as num?)?.toDouble(),
      servingUnit: map['serving_unit'] as String?,
      calories: map['calories'] as int?,
      proteinGrams: map['protein_grams'] as int?,
      carbsGrams: map['carbs_grams'] as int?,
      fatGrams: map['fat_grams'] as int?,
      barcode: map['barcode'] as String?,
      brandName: map['brand_name'] as String?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'meal_log_id': mealLogId,
      'name': name,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'calories': calories,
      'protein_grams': proteinGrams,
      'carbs_grams': carbsGrams,
      'fat_grams': fatGrams,
      'barcode': barcode,
      'brand_name': brandName,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem.fromMap(json);
  }

  /// Copy with modifications.
  MealItem copyWith({
    int? id,
    int? mealLogId,
    String? name,
    double? servingSize,
    String? servingUnit,
    int? calories,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
    String? barcode,
    String? brandName,
  }) {
    return MealItem(
      id: id ?? this.id,
      mealLogId: mealLogId ?? this.mealLogId,
      name: name ?? this.name,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      barcode: barcode ?? this.barcode,
      brandName: brandName ?? this.brandName,
    );
  }

  @override
  String toString() {
    return 'MealItem(id: $id, name: $name, calories: $calories)';
  }
}

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  preworkout,
  postworkout,
  other;

  String get displayName {
    switch (this) {
      case breakfast:
        return 'Breakfast';
      case lunch:
        return 'Lunch';
      case dinner:
        return 'Dinner';
      case snack:
        return 'Snack';
      case preworkout:
        return 'Pre-Workout';
      case postworkout:
        return 'Post-Workout';
      case other:
        return 'Other';
    }
  }
}

enum MealSource {
  manual,
  voice,
  photo,
  barcode,
  import_;

  String get displayName {
    switch (this) {
      case manual:
        return 'Manual';
      case voice:
        return 'Voice';
      case photo:
        return 'Photo';
      case barcode:
        return 'Barcode';
      case import_:
        return 'Import';
    }
  }
}

enum ProteinLevel {
  low,
  moderate,
  high,
  veryHigh;

  String get displayName {
    switch (this) {
      case low:
        return 'Low';
      case moderate:
        return 'Moderate';
      case high:
        return 'High';
      case veryHigh:
        return 'Very High';
    }
  }
}

enum MealQuality {
  poor,
  okay,
  good,
  excellent;

  String get displayName {
    switch (this) {
      case poor:
        return 'Poor';
      case okay:
        return 'Okay';
      case good:
        return 'Good';
      case excellent:
        return 'Excellent';
    }
  }
}

MealType _parseMealType(String? value) {
  if (value == null || value.isEmpty) return MealType.other;
  return MealType.values.firstWhere(
    (mt) => mt.name == value,
    orElse: () => MealType.other,
  );
}

MealSource _parseMealSource(String? value) {
  if (value == null || value.isEmpty) return MealSource.manual;
  if (value == 'import') return MealSource.import_;
  return MealSource.values.firstWhere(
    (ms) => ms.name == value,
    orElse: () => MealSource.manual,
  );
}

ProteinLevel? _parseProteinLevel(String? value) {
  if (value == null || value.isEmpty) return null;
  return ProteinLevel.values.firstWhere(
    (pl) => pl.name == value,
    orElse: () => ProteinLevel.moderate,
  );
}

MealQuality? _parseMealQuality(String? value) {
  if (value == null || value.isEmpty) return null;
  return MealQuality.values.firstWhere(
    (mq) => mq.name == value,
    orElse: () => MealQuality.okay,
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
