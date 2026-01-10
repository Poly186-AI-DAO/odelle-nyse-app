import 'supplement.dart';

/// A single dose taken - the actual event.
class DoseLog {
  final int? id;
  final int supplementId;
  final DateTime timestamp;
  final double amountMg;
  final String? unit;
  final DoseSource source;
  final String? notes;

  // Context
  final bool takenWithFood;
  final bool takenWithFat;
  final String? mealContext;

  // For AI parsing
  final int? journalEntryId;
  final double? confidence;

  // Derived (for UI)
  final Supplement? supplement;

  DoseLog({
    this.id,
    required this.supplementId,
    required this.timestamp,
    required this.amountMg,
    this.unit,
    this.source = DoseSource.manual,
    this.notes,
    this.takenWithFood = false,
    this.takenWithFat = false,
    this.mealContext,
    this.journalEntryId,
    this.confidence,
    this.supplement,
  });

  /// Create from database map.
  factory DoseLog.fromMap(Map<String, dynamic> map) {
    return DoseLog(
      id: map['id'] as int?,
      supplementId: (map['supplement_id'] as int?) ?? 0,
      timestamp: DateTime.parse(map['timestamp'] as String),
      amountMg: (map['amount_mg'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String?,
      source: _parseDoseSource(map['source'] as String?),
      notes: map['notes'] as String?,
      takenWithFood: _parseBool(map['taken_with_food']),
      takenWithFat: _parseBool(map['taken_with_fat']),
      mealContext: map['meal_context'] as String?,
      journalEntryId: map['journal_entry_id'] as int?,
      confidence: (map['confidence'] as num?)?.toDouble(),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'supplement_id': supplementId,
      'timestamp': timestamp.toIso8601String(),
      'amount_mg': amountMg,
      'unit': unit,
      'source': source.name,
      'taken_with_food': takenWithFood ? 1 : 0,
      'taken_with_fat': takenWithFat ? 1 : 0,
      'meal_context': mealContext,
      'journal_entry_id': journalEntryId,
      'confidence': confidence,
      'notes': notes,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory DoseLog.fromJson(Map<String, dynamic> json) {
    return DoseLog.fromMap(json);
  }

  /// Copy with modifications.
  DoseLog copyWith({
    int? id,
    int? supplementId,
    DateTime? timestamp,
    double? amountMg,
    String? unit,
    DoseSource? source,
    String? notes,
    bool? takenWithFood,
    bool? takenWithFat,
    String? mealContext,
    int? journalEntryId,
    double? confidence,
    Supplement? supplement,
  }) {
    return DoseLog(
      id: id ?? this.id,
      supplementId: supplementId ?? this.supplementId,
      timestamp: timestamp ?? this.timestamp,
      amountMg: amountMg ?? this.amountMg,
      unit: unit ?? this.unit,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      takenWithFood: takenWithFood ?? this.takenWithFood,
      takenWithFat: takenWithFat ?? this.takenWithFat,
      mealContext: mealContext ?? this.mealContext,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      confidence: confidence ?? this.confidence,
      supplement: supplement ?? this.supplement,
    );
  }

  @override
  String toString() {
    return 'DoseLog(id: $id, supplementId: $supplementId, amountMg: $amountMg)';
  }
}

enum DoseSource {
  manual,
  voice,
  schedule,
  import;
}

DoseSource _parseDoseSource(String? value) {
  if (value == null || value.isEmpty) return DoseSource.manual;
  return DoseSource.values.firstWhere(
    (source) => source.name == value,
    orElse: () => DoseSource.manual,
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
