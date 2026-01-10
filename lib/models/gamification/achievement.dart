/// An achievement or badge that can be earned.
class Achievement {
  final String id;
  final String title;
  final String description;
  final String? iconUrl;
  final String? colorHex;
  final AchievementCategory category;
  final int xpReward;

  // Requirements
  final AchievementRequirement requirement;
  final int targetValue;

  // Rarity
  final AchievementRarity rarity;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.iconUrl,
    this.colorHex,
    required this.category,
    this.xpReward = 0,
    required this.requirement,
    required this.targetValue,
    this.rarity = AchievementRarity.common,
  });

  /// Create from database map.
  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      iconUrl: map['icon_url'] as String?,
      colorHex: map['color_hex'] as String?,
      category: _parseAchievementCategory(map['category'] as String?),
      xpReward: (map['xp_reward'] as int?) ?? 0,
      requirement: _parseAchievementRequirement(map['requirement_type'] as String?),
      targetValue: (map['target_value'] as int?) ?? 0,
      rarity: _parseAchievementRarity(map['rarity'] as String?),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_url': iconUrl,
      'color_hex': colorHex,
      'category': category.name,
      'xp_reward': xpReward,
      'requirement_type': requirement.name,
      'target_value': targetValue,
      'rarity': rarity.name,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement.fromMap(json);
  }

  /// Copy with modifications.
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconUrl,
    String? colorHex,
    AchievementCategory? category,
    int? xpReward,
    AchievementRequirement? requirement,
    int? targetValue,
    AchievementRarity? rarity,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      colorHex: colorHex ?? this.colorHex,
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
      requirement: requirement ?? this.requirement,
      targetValue: targetValue ?? this.targetValue,
      rarity: rarity ?? this.rarity,
    );
  }

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, rarity: ${rarity.name})';
  }
}

/// A user's earned achievement.
class UserAchievement {
  final int? id;
  final int userId;
  final String achievementId;
  final DateTime earnedAt;
  final int? value;
  final bool hasBeenViewed;

  final Achievement? achievement;

  UserAchievement({
    this.id,
    required this.userId,
    required this.achievementId,
    required this.earnedAt,
    this.value,
    this.hasBeenViewed = false,
    this.achievement,
  });

  /// Create from database map.
  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      achievementId: (map['achievement_id'] as String?) ?? '',
      earnedAt: DateTime.parse(map['earned_at'] as String),
      value: map['value'] as int?,
      hasBeenViewed: _parseBool(map['has_been_viewed']),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'earned_at': earnedAt.toIso8601String(),
      'value': value,
      'has_been_viewed': hasBeenViewed ? 1 : 0,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement.fromMap(json);
  }

  /// Copy with modifications.
  UserAchievement copyWith({
    int? id,
    int? userId,
    String? achievementId,
    DateTime? earnedAt,
    int? value,
    bool? hasBeenViewed,
    Achievement? achievement,
  }) {
    return UserAchievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      earnedAt: earnedAt ?? this.earnedAt,
      value: value ?? this.value,
      hasBeenViewed: hasBeenViewed ?? this.hasBeenViewed,
      achievement: achievement ?? this.achievement,
    );
  }

  @override
  String toString() {
    return 'UserAchievement(id: $id, achievementId: $achievementId, earnedAt: $earnedAt)';
  }
}

enum AchievementCategory {
  meditation,
  workout,
  habits,
  nutrition,
  sleep,
  social,
  milestones,
  special;

  String get displayName {
    switch (this) {
      case meditation:
        return 'Meditation';
      case workout:
        return 'Workout';
      case habits:
        return 'Habits';
      case nutrition:
        return 'Nutrition';
      case sleep:
        return 'Sleep';
      case social:
        return 'Social';
      case milestones:
        return 'Milestones';
      case special:
        return 'Special';
    }
  }
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  String get displayName {
    switch (this) {
      case common:
        return 'Common';
      case uncommon:
        return 'Uncommon';
      case rare:
        return 'Rare';
      case epic:
        return 'Epic';
      case legendary:
        return 'Legendary';
    }
  }
}

enum AchievementRequirement {
  streakDays,
  totalCount,
  singleSession,
  dailyGoal,
  weeklyGoal;

  String get displayName {
    switch (this) {
      case streakDays:
        return 'Streak Days';
      case totalCount:
        return 'Total Count';
      case singleSession:
        return 'Single Session';
      case dailyGoal:
        return 'Daily Goal';
      case weeklyGoal:
        return 'Weekly Goal';
    }
  }
}

AchievementCategory _parseAchievementCategory(String? value) {
  if (value == null || value.isEmpty) return AchievementCategory.milestones;
  return AchievementCategory.values.firstWhere(
    (ac) => ac.name == value,
    orElse: () => AchievementCategory.milestones,
  );
}

AchievementRarity _parseAchievementRarity(String? value) {
  if (value == null || value.isEmpty) return AchievementRarity.common;
  return AchievementRarity.values.firstWhere(
    (ar) => ar.name == value,
    orElse: () => AchievementRarity.common,
  );
}

AchievementRequirement _parseAchievementRequirement(String? value) {
  if (value == null || value.isEmpty) return AchievementRequirement.totalCount;
  return AchievementRequirement.values.firstWhere(
    (ar) => ar.name == value,
    orElse: () => AchievementRequirement.totalCount,
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
