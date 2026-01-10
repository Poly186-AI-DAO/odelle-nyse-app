import 'dart:convert';

/// A supplement or medication in the user's stack.
class Supplement {
  final int? id;
  final String name;
  final String? brand;
  final SupplementCategory category;
  final double defaultDoseMg;
  final String? unit;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final String? imageUrl;

  // Timing preferences
  final List<DoseTime> preferredTimes;
  final bool takeWithFood;
  final bool takeWithFat;

  // Safety info
  final double? maxDailyMg;
  final List<String>? interactions;

  Supplement({
    this.id,
    required this.name,
    this.brand,
    required this.category,
    required this.defaultDoseMg,
    this.unit,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
    this.imageUrl,
    List<DoseTime>? preferredTimes,
    this.takeWithFood = false,
    this.takeWithFat = false,
    this.maxDailyMg,
    this.interactions,
  })  : createdAt = createdAt ?? DateTime.now(),
        preferredTimes = preferredTimes ?? const [];

  /// Create from database map.
  factory Supplement.fromMap(Map<String, dynamic> map) {
    return Supplement(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      brand: map['brand'] as String?,
      category: _parseSupplementCategory(map['category'] as String?),
      defaultDoseMg: (map['default_dose_mg'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String?,
      notes: map['notes'] as String?,
      isActive: _parseBool(map['is_active'], defaultValue: true),
      createdAt: DateTime.parse(map['created_at'] as String),
      imageUrl: map['image_url'] as String?,
      preferredTimes: _parseDoseTimes(map['preferred_times']),
      takeWithFood: _parseBool(map['take_with_food']),
      takeWithFat: _parseBool(map['take_with_fat']),
      maxDailyMg: (map['max_daily_mg'] as num?)?.toDouble(),
      interactions: _parseStringList(map['interactions']),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'brand': brand,
      'category': category.name,
      'default_dose_mg': defaultDoseMg,
      'unit': unit,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'take_with_food': takeWithFood ? 1 : 0,
      'take_with_fat': takeWithFat ? 1 : 0,
      'max_daily_mg': maxDailyMg,
      'preferred_times': _encodeEnumList(preferredTimes),
      'interactions': _encodeStringList(interactions),
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Supplement.fromJson(Map<String, dynamic> json) {
    return Supplement.fromMap(json);
  }

  /// Copy with modifications.
  Supplement copyWith({
    int? id,
    String? name,
    String? brand,
    SupplementCategory? category,
    double? defaultDoseMg,
    String? unit,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    String? imageUrl,
    List<DoseTime>? preferredTimes,
    bool? takeWithFood,
    bool? takeWithFat,
    double? maxDailyMg,
    List<String>? interactions,
  }) {
    return Supplement(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      defaultDoseMg: defaultDoseMg ?? this.defaultDoseMg,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      preferredTimes: preferredTimes ?? this.preferredTimes,
      takeWithFood: takeWithFood ?? this.takeWithFood,
      takeWithFat: takeWithFat ?? this.takeWithFat,
      maxDailyMg: maxDailyMg ?? this.maxDailyMg,
      interactions: interactions ?? this.interactions,
    );
  }

  @override
  String toString() {
    return 'Supplement(id: $id, name: $name, category: ${category.name})';
  }
}

enum SupplementCategory {
  vitamin,
  mineral,
  aminoAcid,
  herb,
  nootropic,
  probiotic,
  omega,
  hormone,
  medication,
  other;
}

enum DoseTime {
  wakeUp,
  morning,
  midday,
  afternoon,
  evening,
  bedtime,
  asNeeded;
}

SupplementCategory _parseSupplementCategory(String? value) {
  if (value == null || value.isEmpty) return SupplementCategory.other;
  return SupplementCategory.values.firstWhere(
    (category) => category.name == value,
    orElse: () => SupplementCategory.other,
  );
}

List<DoseTime> _parseDoseTimes(dynamic value) {
  final items = _parseStringList(value);
  if (items == null) return <DoseTime>[];
  return items
      .map(
        (item) => DoseTime.values.firstWhere(
          (time) => time.name == item,
          orElse: () => DoseTime.asNeeded,
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

String? _encodeStringList(List<String>? values) {
  if (values == null) return null;
  return jsonEncode(values);
}

String? _encodeEnumList(List<DoseTime> values) {
  if (values.isEmpty) return jsonEncode(<String>[]);
  return jsonEncode(values.map((value) => value.name).toList());
}
