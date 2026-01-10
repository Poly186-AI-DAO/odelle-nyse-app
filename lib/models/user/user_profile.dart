import 'dart:convert';
import 'package:flutter/material.dart';

/// The user's profile and account information.
class UserProfile {
  final int? id;
  final String? firebaseUid;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? avatarLocalPath;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  // Gamification
  final int level;
  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final String? title;

  // Preferences
  final String? timezone;
  final bool usesMetric;
  final TimeOfDay? wakeUpTime;
  final TimeOfDay? bedTime;

  // Subscription/Premium
  final bool isPremium;
  final DateTime? premiumExpiresAt;

  // Onboarding
  final bool hasCompletedOnboarding;
  final List<String>? goals;
  final List<String>? focusAreas;

  UserProfile({
    this.id,
    this.firebaseUid,
    required this.name,
    this.email,
    this.avatarUrl,
    this.avatarLocalPath,
    DateTime? createdAt,
    this.lastActiveAt,
    this.level = 1,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.title,
    this.timezone,
    this.usesMetric = false,
    this.wakeUpTime,
    this.bedTime,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.hasCompletedOnboarding = false,
    this.goals,
    this.focusAreas,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from database map.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      firebaseUid: map['firebase_uid'] as String?,
      name: (map['name'] as String?) ?? '',
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      avatarLocalPath: map['avatar_local_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastActiveAt: map['last_active_at'] != null
          ? DateTime.parse(map['last_active_at'] as String)
          : null,
      level: (map['level'] as int?) ?? 1,
      totalXP: (map['total_xp'] as int?) ?? 0,
      currentStreak: (map['current_streak'] as int?) ?? 0,
      longestStreak: (map['longest_streak'] as int?) ?? 0,
      title: map['title'] as String?,
      timezone: map['timezone'] as String?,
      usesMetric: _parseBool(map['uses_metric']),
      wakeUpTime: _parseTime(map['wake_up_time'] as String?),
      bedTime: _parseTime(map['bed_time'] as String?),
      isPremium: _parseBool(map['is_premium']),
      premiumExpiresAt: map['premium_expires_at'] != null
          ? DateTime.parse(map['premium_expires_at'] as String)
          : null,
      hasCompletedOnboarding: _parseBool(map['has_completed_onboarding']),
      goals: _parseStringList(map['goals']),
      focusAreas: _parseStringList(map['focus_areas']),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'firebase_uid': firebaseUid,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'avatar_local_path': avatarLocalPath,
      'level': level,
      'total_xp': totalXP,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'title': title,
      'timezone': timezone,
      'uses_metric': usesMetric ? 1 : 0,
      'wake_up_time': _formatTime(wakeUpTime),
      'bed_time': _formatTime(bedTime),
      'is_premium': isPremium ? 1 : 0,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'has_completed_onboarding': hasCompletedOnboarding ? 1 : 0,
      'goals': _encodeStringList(goals),
      'focus_areas': _encodeStringList(focusAreas),
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile.fromMap(json);
  }

  /// Copy with modifications.
  UserProfile copyWith({
    int? id,
    String? firebaseUid,
    String? name,
    String? email,
    String? avatarUrl,
    String? avatarLocalPath,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    int? level,
    int? totalXP,
    int? currentStreak,
    int? longestStreak,
    String? title,
    String? timezone,
    bool? usesMetric,
    TimeOfDay? wakeUpTime,
    TimeOfDay? bedTime,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    bool? hasCompletedOnboarding,
    List<String>? goals,
    List<String>? focusAreas,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      title: title ?? this.title,
      timezone: timezone ?? this.timezone,
      usesMetric: usesMetric ?? this.usesMetric,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      bedTime: bedTime ?? this.bedTime,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      goals: goals ?? this.goals,
      focusAreas: focusAreas ?? this.focusAreas,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, level: $level, totalXP: $totalXP)';
  }
}

String? _formatTime(TimeOfDay? time) {
  if (time == null) return null;
  final hours = time.hour.toString().padLeft(2, '0');
  final minutes = time.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}

TimeOfDay? _parseTime(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
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
