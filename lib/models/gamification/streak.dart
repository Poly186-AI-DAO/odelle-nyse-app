/// Tracks various streak types.
class Streak {
  final int? id;
  final int userId;
  final StreakType type;

  // Current streak
  final int currentCount;
  final DateTime? streakStartDate;
  final DateTime? lastActivityDate;

  // Best streak
  final int longestCount;
  final DateTime? longestStartDate;
  final DateTime? longestEndDate;

  // Lifetime
  final int totalActiveDays;

  Streak({
    this.id,
    required this.userId,
    required this.type,
    this.currentCount = 0,
    this.streakStartDate,
    this.lastActivityDate,
    this.longestCount = 0,
    this.longestStartDate,
    this.longestEndDate,
    this.totalActiveDays = 0,
  });

  /// Create from database map.
  factory Streak.fromMap(Map<String, dynamic> map) {
    return Streak(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      type: _parseStreakType(map['streak_type'] as String?),
      currentCount: (map['current_count'] as int?) ?? 0,
      streakStartDate: map['streak_start_date'] != null
          ? DateTime.parse(map['streak_start_date'] as String)
          : null,
      lastActivityDate: map['last_activity_date'] != null
          ? DateTime.parse(map['last_activity_date'] as String)
          : null,
      longestCount: (map['longest_count'] as int?) ?? 0,
      longestStartDate: map['longest_start_date'] != null
          ? DateTime.parse(map['longest_start_date'] as String)
          : null,
      longestEndDate: map['longest_end_date'] != null
          ? DateTime.parse(map['longest_end_date'] as String)
          : null,
      totalActiveDays: (map['total_active_days'] as int?) ?? 0,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'streak_type': type.name,
      'current_count': currentCount,
      'streak_start_date': streakStartDate?.toIso8601String(),
      'last_activity_date': lastActivityDate?.toIso8601String(),
      'longest_count': longestCount,
      'longest_start_date': longestStartDate?.toIso8601String(),
      'longest_end_date': longestEndDate?.toIso8601String(),
      'total_active_days': totalActiveDays,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak.fromMap(json);
  }

  /// Copy with modifications.
  Streak copyWith({
    int? id,
    int? userId,
    StreakType? type,
    int? currentCount,
    DateTime? streakStartDate,
    DateTime? lastActivityDate,
    int? longestCount,
    DateTime? longestStartDate,
    DateTime? longestEndDate,
    int? totalActiveDays,
  }) {
    return Streak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      currentCount: currentCount ?? this.currentCount,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      longestCount: longestCount ?? this.longestCount,
      longestStartDate: longestStartDate ?? this.longestStartDate,
      longestEndDate: longestEndDate ?? this.longestEndDate,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
    );
  }

  @override
  String toString() {
    return 'Streak(id: $id, type: ${type.name}, current: $currentCount)';
  }
}

enum StreakType {
  overall,
  meditation,
  workout,
  habits,
  doses,
  journaling;
}

StreakType _parseStreakType(String? value) {
  if (value == null || value.isEmpty) return StreakType.overall;
  return StreakType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => StreakType.overall,
  );
}
