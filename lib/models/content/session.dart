import 'dart:convert';
import 'content_category.dart';
import 'instructor.dart';
import 'program.dart';

/// A single meditation session, yoga class, or workout.
class Session {
  final int? id;
  final String title;
  final String? subtitle;
  final String shortDescription;
  final String? longDescription;

  // Media
  final String? thumbnailUrl;
  final String? coverImageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final String? previewUrl;

  // Duration
  final int durationSeconds;
  final String durationDisplay;

  // Classification
  final int categoryId;
  final int? instructorId;
  final int? programId;
  final int? lessonNumber;

  // Attributes
  final SessionDifficulty difficulty;
  final bool isGuided;
  final bool isFree;
  final bool isFeatured;
  final bool isDownloadable;

  // Tags & Benefits
  final List<String> tags;
  final List<String>? benefits;
  final List<String>? requirements;

  // Estimated outcomes
  final int? calorieEstimate;
  final String? targetMood;

  // Stats
  final int playCount;
  final int completionCount;
  final double? averageRating;
  final int ratingCount;

  // Metadata
  final DateTime publishedAt;
  final DateTime? updatedAt;
  final bool isActive;
  final int sortOrder;

  // Relationships (loaded separately)
  ContentCategory? category;
  Instructor? instructor;
  Program? program;

  Session({
    this.id,
    required this.title,
    this.subtitle,
    required this.shortDescription,
    this.longDescription,
    this.thumbnailUrl,
    this.coverImageUrl,
    this.audioUrl,
    this.videoUrl,
    this.previewUrl,
    required this.durationSeconds,
    required this.durationDisplay,
    required this.categoryId,
    this.instructorId,
    this.programId,
    this.lessonNumber,
    this.difficulty = SessionDifficulty.beginner,
    this.isGuided = true,
    this.isFree = true,
    this.isFeatured = false,
    this.isDownloadable = false,
    List<String>? tags,
    this.benefits,
    this.requirements,
    this.calorieEstimate,
    this.targetMood,
    this.playCount = 0,
    this.completionCount = 0,
    this.averageRating,
    this.ratingCount = 0,
    DateTime? publishedAt,
    this.updatedAt,
    this.isActive = true,
    this.sortOrder = 0,
    this.category,
    this.instructor,
    this.program,
  })  : tags = tags ?? const [],
        publishedAt = publishedAt ?? DateTime.now();

  /// Create from database map.
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      subtitle: map['subtitle'] as String?,
      shortDescription: (map['short_description'] as String?) ?? '',
      longDescription: map['long_description'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      coverImageUrl: map['cover_image_url'] as String?,
      audioUrl: map['audio_url'] as String?,
      videoUrl: map['video_url'] as String?,
      previewUrl: map['preview_url'] as String?,
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      durationDisplay: (map['duration_display'] as String?) ?? '',
      categoryId: (map['category_id'] as int?) ?? 0,
      instructorId: map['instructor_id'] as int?,
      programId: map['program_id'] as int?,
      lessonNumber: map['lesson_number'] as int?,
      difficulty: _parseSessionDifficulty(map['difficulty'] as String?),
      isGuided: _parseBool(map['is_guided'], defaultValue: true),
      isFree: _parseBool(map['is_free'], defaultValue: true),
      isFeatured: _parseBool(map['is_featured']),
      isDownloadable: _parseBool(map['is_downloadable']),
      tags: _parseStringList(map['tags']) ?? const [],
      benefits: _parseStringList(map['benefits']),
      requirements: _parseStringList(map['requirements']),
      calorieEstimate: map['calorie_estimate'] as int?,
      targetMood: map['target_mood'] as String?,
      playCount: (map['play_count'] as int?) ?? 0,
      completionCount: (map['completion_count'] as int?) ?? 0,
      averageRating: (map['average_rating'] as num?)?.toDouble(),
      ratingCount: (map['rating_count'] as int?) ?? 0,
      publishedAt: DateTime.parse(map['published_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isActive: _parseBool(map['is_active'], defaultValue: true),
      sortOrder: (map['sort_order'] as int?) ?? 0,
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
      'audio_url': audioUrl,
      'video_url': videoUrl,
      'preview_url': previewUrl,
      'duration_seconds': durationSeconds,
      'duration_display': durationDisplay,
      'category_id': categoryId,
      'instructor_id': instructorId,
      'program_id': programId,
      'lesson_number': lessonNumber,
      'difficulty': difficulty.name,
      'is_guided': isGuided ? 1 : 0,
      'is_free': isFree ? 1 : 0,
      'is_featured': isFeatured ? 1 : 0,
      'is_downloadable': isDownloadable ? 1 : 0,
      'tags': _encodeStringList(tags),
      'benefits': _encodeStringList(benefits),
      'requirements': _encodeStringList(requirements),
      'calorie_estimate': calorieEstimate,
      'target_mood': targetMood,
      'play_count': playCount,
      'completion_count': completionCount,
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'published_at': publishedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session.fromMap(json);
  }

  /// Copy with modifications.
  Session copyWith({
    int? id,
    String? title,
    String? subtitle,
    String? shortDescription,
    String? longDescription,
    String? thumbnailUrl,
    String? coverImageUrl,
    String? audioUrl,
    String? videoUrl,
    String? previewUrl,
    int? durationSeconds,
    String? durationDisplay,
    int? categoryId,
    int? instructorId,
    int? programId,
    int? lessonNumber,
    SessionDifficulty? difficulty,
    bool? isGuided,
    bool? isFree,
    bool? isFeatured,
    bool? isDownloadable,
    List<String>? tags,
    List<String>? benefits,
    List<String>? requirements,
    int? calorieEstimate,
    String? targetMood,
    int? playCount,
    int? completionCount,
    double? averageRating,
    int? ratingCount,
    DateTime? publishedAt,
    DateTime? updatedAt,
    bool? isActive,
    int? sortOrder,
    ContentCategory? category,
    Instructor? instructor,
    Program? program,
  }) {
    return Session(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      durationDisplay: durationDisplay ?? this.durationDisplay,
      categoryId: categoryId ?? this.categoryId,
      instructorId: instructorId ?? this.instructorId,
      programId: programId ?? this.programId,
      lessonNumber: lessonNumber ?? this.lessonNumber,
      difficulty: difficulty ?? this.difficulty,
      isGuided: isGuided ?? this.isGuided,
      isFree: isFree ?? this.isFree,
      isFeatured: isFeatured ?? this.isFeatured,
      isDownloadable: isDownloadable ?? this.isDownloadable,
      tags: tags ?? this.tags,
      benefits: benefits ?? this.benefits,
      requirements: requirements ?? this.requirements,
      calorieEstimate: calorieEstimate ?? this.calorieEstimate,
      targetMood: targetMood ?? this.targetMood,
      playCount: playCount ?? this.playCount,
      completionCount: completionCount ?? this.completionCount,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      category: category ?? this.category,
      instructor: instructor ?? this.instructor,
      program: program ?? this.program,
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, title: $title, duration: $durationDisplay)';
  }
}

enum SessionDifficulty {
  beginner,
  intermediate,
  advanced,
  allLevels;

  String get displayName {
    switch (this) {
      case SessionDifficulty.beginner:
        return 'Beginner';
      case SessionDifficulty.intermediate:
        return 'Intermediate';
      case SessionDifficulty.advanced:
        return 'Advanced';
      case SessionDifficulty.allLevels:
        return 'All Levels';
    }
  }
}

SessionDifficulty _parseSessionDifficulty(String? value) {
  if (value == null || value.isEmpty) return SessionDifficulty.beginner;
  return SessionDifficulty.values.firstWhere(
    (difficulty) => difficulty.name == value,
    orElse: () => SessionDifficulty.beginner,
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
