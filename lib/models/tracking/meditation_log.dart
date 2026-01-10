import 'dart:convert';

/// A meditation session log entry.
class MeditationLog {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final MeditationType type;
  final MeditationSource source;

  // Session details
  final String? technique;
  final String? guidedBy;
  final String? audioTrackName;

  // Environment
  final String? location;
  final bool timerUsed;
  final bool guidedSession;

  // Subjective experience
  final int? focusQuality; // 1-10
  final int? calmBefore; // 1-10
  final int? calmAfter; // 1-10
  final int? distractionLevel; // 1-10
  final List<String>? insights;

  // For trends
  final int? heartRateStart;
  final int? heartRateEnd;
  final int? hrvBefore;
  final int? hrvAfter;

  // For AI parsing
  final int? journalEntryId;

  final String? notes;

  MeditationLog({
    this.id,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.type = MeditationType.mindfulness,
    this.source = MeditationSource.manual,
    this.technique,
    this.guidedBy,
    this.audioTrackName,
    this.location,
    this.timerUsed = false,
    this.guidedSession = false,
    this.focusQuality,
    this.calmBefore,
    this.calmAfter,
    this.distractionLevel,
    this.insights,
    this.heartRateStart,
    this.heartRateEnd,
    this.hrvBefore,
    this.hrvAfter,
    this.journalEntryId,
    this.notes,
  });

  /// Create from database map.
  factory MeditationLog.fromMap(Map<String, dynamic> map) {
    return MeditationLog(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      durationMinutes: (map['duration_minutes'] as int?) ?? 0,
      type: _parseMeditationType(map['type'] as String?),
      source: _parseMeditationSource(map['source'] as String?),
      technique: map['technique'] as String?,
      guidedBy: map['guided_by'] as String?,
      audioTrackName: map['audio_track_name'] as String?,
      location: map['location'] as String?,
      timerUsed: _parseBool(map['timer_used']),
      guidedSession: _parseBool(map['guided_session']),
      focusQuality: map['focus_quality'] as int?,
      calmBefore: map['calm_before'] as int?,
      calmAfter: map['calm_after'] as int?,
      distractionLevel: map['distraction_level'] as int?,
      insights: _parseStringList(map['insights']),
      heartRateStart: map['heart_rate_start'] as int?,
      heartRateEnd: map['heart_rate_end'] as int?,
      hrvBefore: map['hrv_before'] as int?,
      hrvAfter: map['hrv_after'] as int?,
      journalEntryId: map['journal_entry_id'] as int?,
      notes: map['notes'] as String?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'type': type.name,
      'source': source.name,
      'technique': technique,
      'guided_by': guidedBy,
      'audio_track_name': audioTrackName,
      'location': location,
      'timer_used': timerUsed ? 1 : 0,
      'guided_session': guidedSession ? 1 : 0,
      'focus_quality': focusQuality,
      'calm_before': calmBefore,
      'calm_after': calmAfter,
      'distraction_level': distractionLevel,
      'insights': insights != null ? jsonEncode(insights) : null,
      'heart_rate_start': heartRateStart,
      'heart_rate_end': heartRateEnd,
      'hrv_before': hrvBefore,
      'hrv_after': hrvAfter,
      'journal_entry_id': journalEntryId,
      'notes': notes,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory MeditationLog.fromJson(Map<String, dynamic> json) {
    return MeditationLog.fromMap(json);
  }

  /// Copy with modifications.
  MeditationLog copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    MeditationType? type,
    MeditationSource? source,
    String? technique,
    String? guidedBy,
    String? audioTrackName,
    String? location,
    bool? timerUsed,
    bool? guidedSession,
    int? focusQuality,
    int? calmBefore,
    int? calmAfter,
    int? distractionLevel,
    List<String>? insights,
    int? heartRateStart,
    int? heartRateEnd,
    int? hrvBefore,
    int? hrvAfter,
    int? journalEntryId,
    String? notes,
  }) {
    return MeditationLog(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      source: source ?? this.source,
      technique: technique ?? this.technique,
      guidedBy: guidedBy ?? this.guidedBy,
      audioTrackName: audioTrackName ?? this.audioTrackName,
      location: location ?? this.location,
      timerUsed: timerUsed ?? this.timerUsed,
      guidedSession: guidedSession ?? this.guidedSession,
      focusQuality: focusQuality ?? this.focusQuality,
      calmBefore: calmBefore ?? this.calmBefore,
      calmAfter: calmAfter ?? this.calmAfter,
      distractionLevel: distractionLevel ?? this.distractionLevel,
      insights: insights ?? this.insights,
      heartRateStart: heartRateStart ?? this.heartRateStart,
      heartRateEnd: heartRateEnd ?? this.heartRateEnd,
      hrvBefore: hrvBefore ?? this.hrvBefore,
      hrvAfter: hrvAfter ?? this.hrvAfter,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'MeditationLog(id: $id, type: ${type.name}, duration: $durationMinutes min)';
  }
}

enum MeditationType {
  mindfulness,
  breathing,
  bodyScan,
  lovingKindness,
  visualization,
  mantra,
  transcendental,
  yoga,
  walking,
  movement,
  other;

  String get displayName {
    switch (this) {
      case mindfulness:
        return 'Mindfulness';
      case breathing:
        return 'Breathing';
      case bodyScan:
        return 'Body Scan';
      case lovingKindness:
        return 'Loving Kindness';
      case visualization:
        return 'Visualization';
      case mantra:
        return 'Mantra';
      case transcendental:
        return 'Transcendental';
      case yoga:
        return 'Yoga';
      case walking:
        return 'Walking';
      case movement:
        return 'Movement';
      case other:
        return 'Other';
    }
  }
}

enum MeditationSource {
  manual,
  voice,
  appSync,
  timer;

  String get displayName {
    switch (this) {
      case manual:
        return 'Manual';
      case voice:
        return 'Voice';
      case appSync:
        return 'App Sync';
      case timer:
        return 'Timer';
    }
  }
}

MeditationType _parseMeditationType(String? value) {
  if (value == null || value.isEmpty) return MeditationType.mindfulness;
  return MeditationType.values.firstWhere(
    (mt) => mt.name == value,
    orElse: () => MeditationType.mindfulness,
  );
}

MeditationSource _parseMeditationSource(String? value) {
  if (value == null || value.isEmpty) return MeditationSource.manual;
  return MeditationSource.values.firstWhere(
    (ms) => ms.name == value,
    orElse: () => MeditationSource.manual,
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
