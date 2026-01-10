import 'dart:convert';
import 'instructor.dart';
import 'session.dart';

/// A program or course containing multiple sessions.
class Program {
  final int? id;
  final String title;
  final String? subtitle;
  final String shortDescription;
  final String? longDescription;

  // Media
  final String? thumbnailUrl;
  final String? coverImageUrl;
  final String? promoVideoUrl;

  // Structure
  final int totalLessons;
  final int totalDurationMinutes;
  final int durationDays;
  final ProgramPace pace;

  // Classification
  final int categoryId;
  final int? instructorId;
  final ProgramDifficulty difficulty;
  final bool isFree;
  final bool isFeatured;

  // Content details
  final List<String> learningOutcomes;
  final List<String>? requirements;
  final String? targetAudience;

  // Stats
  final int enrollmentCount;
  final int completionCount;
  final double? averageRating;
  final int ratingCount;

  // Gamification
  final int xpReward;
  final String? badgeId;

  // Metadata
  final DateTime publishedAt;
  final bool isActive;

  // Loaded separately
  List<Session>? sessions;
  Instructor? instructor;

  Program({
    this.id,
    required this.title,
    this.subtitle,
    required this.shortDescription,
    this.longDescription,
    this.thumbnailUrl,
    this.coverImageUrl,
    this.promoVideoUrl,
    required this.totalLessons,
    required this.totalDurationMinutes,
    required this.durationDays,
    this.pace = ProgramPace.daily,
    required this.categoryId,
    this.instructorId,
    this.difficulty = ProgramDifficulty.beginner,
    this.isFree = true,
    this.isFeatured = false,
    List<String>? learningOutcomes,
    this.requirements,
    this.targetAudience,
    this.enrollmentCount = 0,
    this.completionCount = 0,
    this.averageRating,
    this.ratingCount = 0,
    this.xpReward = 0,
    this.badgeId,
    DateTime? publishedAt,
    this.isActive = true,
    this.sessions,
    this.instructor,
  })  : learningOutcomes = learningOutcomes ?? const [],
        publishedAt = publishedAt ?? DateTime.now();

  /// Create from database map.
  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      subtitle: map['subtitle'] as String?,
      shortDescription: (map['short_description'] as String?) ?? '',
      longDescription: map['long_description'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      coverImageUrl: map['cover_image_url'] as String?,
      promoVideoUrl: map['promo_video_url'] as String?,
      totalLessons: (map['total_lessons'] as int?) ?? 0,
      totalDurationMinutes: (map['total_duration_minutes'] as int?) ?? 0,
      durationDays: (map['duration_days'] as int?) ?? 0,
      pace: _parseProgramPace(map['pace'] as String?),
      categoryId: (map['category_id'] as int?) ?? 0,
      instructorId: map['instructor_id'] as int?,
      difficulty: _parseProgramDifficulty(map['difficulty'] as String?),
      isFree: _parseBool(map['is_free'], defaultValue: true),
      isFeatured: _parseBool(map['is_featured']),
      learningOutcomes: _parseStringList(map['learning_outcomes']) ?? const [],
      requirements: _parseStringList(map['requirements']),
      targetAudience: map['target_audience'] as String?,
      enrollmentCount: (map['enrollment_count'] as int?) ?? 0,
      completionCount: (map['completion_count'] as int?) ?? 0,
      averageRating: (map['average_rating'] as num?)?.toDouble(),
      ratingCount: (map['rating_count'] as int?) ?? 0,
      xpReward: (map['xp_reward'] as int?) ?? 0,
      badgeId: map['badge_id'] as String?,
      publishedAt: DateTime.parse(map['published_at'] as String),
      isActive: _parseBool(map['is_active'], defaultValue: true),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'subtitle': subtitle,
      'short_description': shortDescription,
      'long_description': longDescription,
      'thumbnail_url': thumbnailUrl,
      'cover_image_url': coverImageUrl,
      'promo_video_url': promoVideoUrl,
      'total_lessons': totalLessons,
      'total_duration_minutes': totalDurationMinutes,
      'duration_days': durationDays,
      'pace': pace.name,
      'category_id': categoryId,
      'instructor_id': instructorId,
      'difficulty': difficulty.name,
      'is_free': isFree ? 1 : 0,
      'is_featured': isFeatured ? 1 : 0,
      'learning_outcomes': _encodeStringList(learningOutcomes),
      'requirements': _encodeStringList(requirements),
      'target_audience': targetAudience,
      'enrollment_count': enrollmentCount,
      'completion_count': completionCount,
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'xp_reward': xpReward,
      'badge_id': badgeId,
      'published_at': publishedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Program.fromJson(Map<String, dynamic> json) {
    return Program.fromMap(json);
  }

  /// Copy with modifications.
  Program copyWith({
    int? id,
    String? title,
    String? subtitle,
    String? shortDescription,
    String? longDescription,
    String? thumbnailUrl,
    String? coverImageUrl,
    String? promoVideoUrl,
    int? totalLessons,
    int? totalDurationMinutes,
    int? durationDays,
    ProgramPace? pace,
    int? categoryId,
    int? instructorId,
    ProgramDifficulty? difficulty,
    bool? isFree,
    bool? isFeatured,
    List<String>? learningOutcomes,
    List<String>? requirements,
    String? targetAudience,
    int? enrollmentCount,
    int? completionCount,
    double? averageRating,
    int? ratingCount,
    int? xpReward,
    String? badgeId,
    DateTime? publishedAt,
    bool? isActive,
    List<Session>? sessions,
    Instructor? instructor,
  }) {
    return Program(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      promoVideoUrl: promoVideoUrl ?? this.promoVideoUrl,
      totalLessons: totalLessons ?? this.totalLessons,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      durationDays: durationDays ?? this.durationDays,
      pace: pace ?? this.pace,
      categoryId: categoryId ?? this.categoryId,
      instructorId: instructorId ?? this.instructorId,
      difficulty: difficulty ?? this.difficulty,
      isFree: isFree ?? this.isFree,
      isFeatured: isFeatured ?? this.isFeatured,
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
      requirements: requirements ?? this.requirements,
      targetAudience: targetAudience ?? this.targetAudience,
      enrollmentCount: enrollmentCount ?? this.enrollmentCount,
      completionCount: completionCount ?? this.completionCount,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      xpReward: xpReward ?? this.xpReward,
      badgeId: badgeId ?? this.badgeId,
      publishedAt: publishedAt ?? this.publishedAt,
      isActive: isActive ?? this.isActive,
      sessions: sessions ?? this.sessions,
      instructor: instructor ?? this.instructor,
    );
  }

  @override
  String toString() {
    return 'Program(id: $id, title: $title, lessons: $totalLessons)';
  }
}

enum ProgramPace {
  daily,
  flexible,
  scheduled;
}

enum ProgramDifficulty {
  beginner,
  intermediate,
  advanced,
  progressive;
}

ProgramPace _parseProgramPace(String? value) {
  if (value == null || value.isEmpty) return ProgramPace.daily;
  return ProgramPace.values.firstWhere(
    (pace) => pace.name == value,
    orElse: () => ProgramPace.daily,
  );
}

ProgramDifficulty _parseProgramDifficulty(String? value) {
  if (value == null || value.isEmpty) return ProgramDifficulty.beginner;
  return ProgramDifficulty.values.firstWhere(
    (difficulty) => difficulty.name == value,
    orElse: () => ProgramDifficulty.beginner,
  );
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
