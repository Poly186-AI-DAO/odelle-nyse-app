/// Represents the user's RPG-style character stats
/// Visualized in a radar chart
class CharacterStats {
  final int? id;
  final DateTime date;
  final double strength; // From gym entries (0-100)
  final double intellect; // From focus/work entries (0-100)
  final double spirit; // From meditation/mood entries (0-100)
  final double sales; // From outreach/deals (0-100)
  final int totalXP;
  final int level;

  CharacterStats({
    this.id,
    required this.date,
    this.strength = 0,
    this.intellect = 0,
    this.spirit = 0,
    this.sales = 0,
    this.totalXP = 0,
    this.level = 1,
  });

  /// Create from database map
  factory CharacterStats.fromMap(Map<String, dynamic> map) {
    return CharacterStats(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      strength: (map['strength'] as num?)?.toDouble() ?? 0,
      intellect: (map['intellect'] as num?)?.toDouble() ?? 0,
      spirit: (map['spirit'] as num?)?.toDouble() ?? 0,
      sales: (map['sales'] as num?)?.toDouble() ?? 0,
      totalXP: (map['total_xp'] as int?) ?? 0,
      level: (map['level'] as int?) ?? 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String().split('T')[0], // Just the date part
      'strength': strength,
      'intellect': intellect,
      'spirit': spirit,
      'sales': sales,
      'total_xp': totalXP,
      'level': level,
    };
  }

  /// Calculate average of all stats
  double get average => (strength + intellect + spirit + sales) / 4;

  /// Get the dominant stat
  String get dominantStat {
    final stats = {
      'Strength': strength,
      'Intellect': intellect,
      'Spirit': spirit,
      'Sales': sales,
    };
    return stats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Calculate level from total XP (simple formula)
  static int calculateLevel(int xp) {
    // Every 100 XP = 1 level
    return (xp / 100).floor() + 1;
  }

  /// Copy with modifications
  CharacterStats copyWith({
    int? id,
    DateTime? date,
    double? strength,
    double? intellect,
    double? spirit,
    double? sales,
    int? totalXP,
    int? level,
  }) {
    return CharacterStats(
      id: id ?? this.id,
      date: date ?? this.date,
      strength: strength ?? this.strength,
      intellect: intellect ?? this.intellect,
      spirit: spirit ?? this.spirit,
      sales: sales ?? this.sales,
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
    );
  }

  /// Create empty stats for today
  factory CharacterStats.today() {
    return CharacterStats(
      date: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CharacterStats(level: $level, strength: $strength, intellect: $intellect, spirit: $spirit, sales: $sales)';
  }
}
