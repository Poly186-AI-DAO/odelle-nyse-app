/// Tracks a user's progress through a program (course enrollment).
class ProgramEnrollment {
  final int? id;
  final int userId;
  final int programId;
  final DateTime enrolledAt;
  final DateTime? completedAt;

  // Progress
  final int lessonsCompleted;
  final int currentLessonNumber;
  final DateTime? lastActivityAt;
  final double completionPercentage;

  // Status
  final EnrollmentStatus status;

  // Gamification
  final int xpEarned;
  final bool badgeAwarded;

  // Loaded separately
  final List<LessonProgress>? lessonProgress;

  ProgramEnrollment({
    this.id,
    required this.userId,
    required this.programId,
    required this.enrolledAt,
    this.completedAt,
    this.lessonsCompleted = 0,
    this.currentLessonNumber = 1,
    this.lastActivityAt,
    this.completionPercentage = 0,
    this.status = EnrollmentStatus.active,
    this.xpEarned = 0,
    this.badgeAwarded = false,
    this.lessonProgress,
  });

  /// Create from database map.
  factory ProgramEnrollment.fromMap(Map<String, dynamic> map) {
    return ProgramEnrollment(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      programId: (map['program_id'] as int?) ?? 0,
      enrolledAt: DateTime.parse(map['enrolled_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      lessonsCompleted: (map['lessons_completed'] as int?) ?? 0,
      currentLessonNumber: (map['current_lesson_number'] as int?) ?? 1,
      lastActivityAt: map['last_activity_at'] != null
          ? DateTime.parse(map['last_activity_at'] as String)
          : null,
      completionPercentage:
          (map['completion_percentage'] as num?)?.toDouble() ?? 0,
      status: _parseEnrollmentStatus(map['status'] as String?),
      xpEarned: (map['xp_earned'] as int?) ?? 0,
      badgeAwarded: _parseBool(map['badge_awarded']),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'program_id': programId,
      'enrolled_at': enrolledAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'lessons_completed': lessonsCompleted,
      'current_lesson_number': currentLessonNumber,
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'completion_percentage': completionPercentage,
      'status': status.name,
      'xp_earned': xpEarned,
      'badge_awarded': badgeAwarded ? 1 : 0,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory ProgramEnrollment.fromJson(Map<String, dynamic> json) {
    return ProgramEnrollment.fromMap(json);
  }

  /// Copy with modifications.
  ProgramEnrollment copyWith({
    int? id,
    int? userId,
    int? programId,
    DateTime? enrolledAt,
    DateTime? completedAt,
    int? lessonsCompleted,
    int? currentLessonNumber,
    DateTime? lastActivityAt,
    double? completionPercentage,
    EnrollmentStatus? status,
    int? xpEarned,
    bool? badgeAwarded,
    List<LessonProgress>? lessonProgress,
  }) {
    return ProgramEnrollment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      programId: programId ?? this.programId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      completedAt: completedAt ?? this.completedAt,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      currentLessonNumber: currentLessonNumber ?? this.currentLessonNumber,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      status: status ?? this.status,
      xpEarned: xpEarned ?? this.xpEarned,
      badgeAwarded: badgeAwarded ?? this.badgeAwarded,
      lessonProgress: lessonProgress ?? this.lessonProgress,
    );
  }

  @override
  String toString() {
    return 'ProgramEnrollment(id: $id, programId: $programId, status: ${status.name})';
  }
}

/// Progress on individual lessons within a program.
class LessonProgress {
  final int? id;
  final int enrollmentId;
  final int sessionId;
  final int lessonNumber;
  final bool isCompleted;
  final DateTime? completedAt;
  final int? durationWatched;

  LessonProgress({
    this.id,
    required this.enrollmentId,
    required this.sessionId,
    required this.lessonNumber,
    this.isCompleted = false,
    this.completedAt,
    this.durationWatched,
  });

  /// Create from database map.
  factory LessonProgress.fromMap(Map<String, dynamic> map) {
    return LessonProgress(
      id: map['id'] as int?,
      enrollmentId: (map['enrollment_id'] as int?) ?? 0,
      sessionId: (map['session_id'] as int?) ?? 0,
      lessonNumber: (map['lesson_number'] as int?) ?? 0,
      isCompleted: _parseBool(map['is_completed']),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      durationWatched: map['duration_watched'] as int?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'enrollment_id': enrollmentId,
      'session_id': sessionId,
      'lesson_number': lessonNumber,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'duration_watched': durationWatched,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress.fromMap(json);
  }

  /// Copy with modifications.
  LessonProgress copyWith({
    int? id,
    int? enrollmentId,
    int? sessionId,
    int? lessonNumber,
    bool? isCompleted,
    DateTime? completedAt,
    int? durationWatched,
  }) {
    return LessonProgress(
      id: id ?? this.id,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      sessionId: sessionId ?? this.sessionId,
      lessonNumber: lessonNumber ?? this.lessonNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      durationWatched: durationWatched ?? this.durationWatched,
    );
  }

  @override
  String toString() {
    return 'LessonProgress(id: $id, lessonNumber: $lessonNumber, isCompleted: $isCompleted)';
  }
}

enum EnrollmentStatus {
  active,
  completed,
  paused,
  abandoned;

  String get displayName {
    switch (this) {
      case active:
        return 'Active';
      case completed:
        return 'Completed';
      case paused:
        return 'Paused';
      case abandoned:
        return 'Abandoned';
    }
  }
}

EnrollmentStatus _parseEnrollmentStatus(String? value) {
  if (value == null || value.isEmpty) return EnrollmentStatus.active;
  return EnrollmentStatus.values.firstWhere(
    (es) => es.name == value,
    orElse: () => EnrollmentStatus.active,
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
