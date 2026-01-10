/// Tracks when a user plays/watches a session.
class PlayHistory {
  final int? id;
  final int userId;
  final int sessionId;
  final DateTime startedAt;
  final DateTime? endedAt;

  // Progress
  final int progressSeconds;
  final double completionPercentage;
  final bool isCompleted;

  // Context
  final String? deviceType;
  final bool wasOffline;

  // For analytics
  final int? pauseCount;
  final int? totalSecondsPlayed;

  PlayHistory({
    this.id,
    required this.userId,
    required this.sessionId,
    required this.startedAt,
    this.endedAt,
    this.progressSeconds = 0,
    this.completionPercentage = 0,
    this.isCompleted = false,
    this.deviceType,
    this.wasOffline = false,
    this.pauseCount,
    this.totalSecondsPlayed,
  });

  /// Create from database map.
  factory PlayHistory.fromMap(Map<String, dynamic> map) {
    return PlayHistory(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      sessionId: (map['session_id'] as int?) ?? 0,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      progressSeconds: (map['progress_seconds'] as int?) ?? 0,
      completionPercentage:
          (map['completion_percentage'] as num?)?.toDouble() ?? 0,
      isCompleted: _parseBool(map['is_completed']),
      deviceType: map['device_type'] as String?,
      wasOffline: _parseBool(map['was_offline']),
      pauseCount: map['pause_count'] as int?,
      totalSecondsPlayed: map['total_seconds_played'] as int?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'progress_seconds': progressSeconds,
      'completion_percentage': completionPercentage,
      'is_completed': isCompleted ? 1 : 0,
      'device_type': deviceType,
      'was_offline': wasOffline ? 1 : 0,
      'pause_count': pauseCount,
      'total_seconds_played': totalSecondsPlayed,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory PlayHistory.fromJson(Map<String, dynamic> json) {
    return PlayHistory.fromMap(json);
  }

  /// Copy with modifications.
  PlayHistory copyWith({
    int? id,
    int? userId,
    int? sessionId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? progressSeconds,
    double? completionPercentage,
    bool? isCompleted,
    String? deviceType,
    bool? wasOffline,
    int? pauseCount,
    int? totalSecondsPlayed,
  }) {
    return PlayHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      progressSeconds: progressSeconds ?? this.progressSeconds,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      isCompleted: isCompleted ?? this.isCompleted,
      deviceType: deviceType ?? this.deviceType,
      wasOffline: wasOffline ?? this.wasOffline,
      pauseCount: pauseCount ?? this.pauseCount,
      totalSecondsPlayed: totalSecondsPlayed ?? this.totalSecondsPlayed,
    );
  }

  @override
  String toString() {
    return 'PlayHistory(id: $id, sessionId: $sessionId, progress: $progressSeconds)';
  }
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
