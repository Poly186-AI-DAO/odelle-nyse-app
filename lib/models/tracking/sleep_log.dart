/// A sleep session log entry.
class SleepLog {
  final int? id;
  final DateTime bedTime;
  final DateTime? sleepTime;
  final DateTime? wakeTime;
  final DateTime? outOfBedTime;

  // Duration
  final int? totalMinutes;
  final int? timeToFallAsleepMinutes;
  final int? timesWoken;

  // Quality metrics
  final int? qualityRating; // 1-10
  final int? restfulnessRating; // 1-10

  // Sleep phases (from wearables)
  final int? deepSleepMinutes;
  final int? remSleepMinutes;
  final int? lightSleepMinutes;
  final int? awakeMinutes;

  // Factors
  final bool? alcoholConsumed;
  final bool? caffeineAfternoon;
  final bool? screenBeforeBed;
  final bool? exercisedToday;
  final int? stressLevel; // 1-10

  // Environment
  final int? roomTempF;
  final bool? darkRoom;
  final bool? whiteNoise;

  // For AI parsing
  final int? journalEntryId;

  final String? notes;
  final SleepSource source;

  SleepLog({
    this.id,
    required this.bedTime,
    this.sleepTime,
    this.wakeTime,
    this.outOfBedTime,
    this.totalMinutes,
    this.timeToFallAsleepMinutes,
    this.timesWoken,
    this.qualityRating,
    this.restfulnessRating,
    this.deepSleepMinutes,
    this.remSleepMinutes,
    this.lightSleepMinutes,
    this.awakeMinutes,
    this.alcoholConsumed,
    this.caffeineAfternoon,
    this.screenBeforeBed,
    this.exercisedToday,
    this.stressLevel,
    this.roomTempF,
    this.darkRoom,
    this.whiteNoise,
    this.journalEntryId,
    this.notes,
    this.source = SleepSource.manual,
  });

  /// Create from database map.
  factory SleepLog.fromMap(Map<String, dynamic> map) {
    return SleepLog(
      id: map['id'] as int?,
      bedTime: DateTime.parse(map['bed_time'] as String),
      sleepTime: map['sleep_time'] != null
          ? DateTime.parse(map['sleep_time'] as String)
          : null,
      wakeTime: map['wake_time'] != null
          ? DateTime.parse(map['wake_time'] as String)
          : null,
      outOfBedTime: map['out_of_bed_time'] != null
          ? DateTime.parse(map['out_of_bed_time'] as String)
          : null,
      totalMinutes: map['total_minutes'] as int?,
      timeToFallAsleepMinutes: map['time_to_fall_asleep_minutes'] as int?,
      timesWoken: map['times_woken'] as int?,
      qualityRating: map['quality_rating'] as int?,
      restfulnessRating: map['restfulness_rating'] as int?,
      deepSleepMinutes: map['deep_sleep_minutes'] as int?,
      remSleepMinutes: map['rem_sleep_minutes'] as int?,
      lightSleepMinutes: map['light_sleep_minutes'] as int?,
      awakeMinutes: map['awake_minutes'] as int?,
      alcoholConsumed: _parseOptionalBool(map['alcohol_consumed']),
      caffeineAfternoon: _parseOptionalBool(map['caffeine_afternoon']),
      screenBeforeBed: _parseOptionalBool(map['screen_before_bed']),
      exercisedToday: _parseOptionalBool(map['exercised_today']),
      stressLevel: map['stress_level'] as int?,
      roomTempF: map['room_temp_f'] as int?,
      darkRoom: _parseOptionalBool(map['dark_room']),
      whiteNoise: _parseOptionalBool(map['white_noise']),
      journalEntryId: map['journal_entry_id'] as int?,
      notes: map['notes'] as String?,
      source: _parseSleepSource(map['source'] as String?),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bed_time': bedTime.toIso8601String(),
      'sleep_time': sleepTime?.toIso8601String(),
      'wake_time': wakeTime?.toIso8601String(),
      'out_of_bed_time': outOfBedTime?.toIso8601String(),
      'total_minutes': totalMinutes,
      'time_to_fall_asleep_minutes': timeToFallAsleepMinutes,
      'times_woken': timesWoken,
      'quality_rating': qualityRating,
      'restfulness_rating': restfulnessRating,
      'deep_sleep_minutes': deepSleepMinutes,
      'rem_sleep_minutes': remSleepMinutes,
      'light_sleep_minutes': lightSleepMinutes,
      'awake_minutes': awakeMinutes,
      'alcohol_consumed': alcoholConsumed != null ? (alcoholConsumed! ? 1 : 0) : null,
      'caffeine_afternoon': caffeineAfternoon != null ? (caffeineAfternoon! ? 1 : 0) : null,
      'screen_before_bed': screenBeforeBed != null ? (screenBeforeBed! ? 1 : 0) : null,
      'exercised_today': exercisedToday != null ? (exercisedToday! ? 1 : 0) : null,
      'stress_level': stressLevel,
      'room_temp_f': roomTempF,
      'dark_room': darkRoom != null ? (darkRoom! ? 1 : 0) : null,
      'white_noise': whiteNoise != null ? (whiteNoise! ? 1 : 0) : null,
      'journal_entry_id': journalEntryId,
      'notes': notes,
      'source': source.name,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog.fromMap(json);
  }

  /// Copy with modifications.
  SleepLog copyWith({
    int? id,
    DateTime? bedTime,
    DateTime? sleepTime,
    DateTime? wakeTime,
    DateTime? outOfBedTime,
    int? totalMinutes,
    int? timeToFallAsleepMinutes,
    int? timesWoken,
    int? qualityRating,
    int? restfulnessRating,
    int? deepSleepMinutes,
    int? remSleepMinutes,
    int? lightSleepMinutes,
    int? awakeMinutes,
    bool? alcoholConsumed,
    bool? caffeineAfternoon,
    bool? screenBeforeBed,
    bool? exercisedToday,
    int? stressLevel,
    int? roomTempF,
    bool? darkRoom,
    bool? whiteNoise,
    int? journalEntryId,
    String? notes,
    SleepSource? source,
  }) {
    return SleepLog(
      id: id ?? this.id,
      bedTime: bedTime ?? this.bedTime,
      sleepTime: sleepTime ?? this.sleepTime,
      wakeTime: wakeTime ?? this.wakeTime,
      outOfBedTime: outOfBedTime ?? this.outOfBedTime,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      timeToFallAsleepMinutes: timeToFallAsleepMinutes ?? this.timeToFallAsleepMinutes,
      timesWoken: timesWoken ?? this.timesWoken,
      qualityRating: qualityRating ?? this.qualityRating,
      restfulnessRating: restfulnessRating ?? this.restfulnessRating,
      deepSleepMinutes: deepSleepMinutes ?? this.deepSleepMinutes,
      remSleepMinutes: remSleepMinutes ?? this.remSleepMinutes,
      lightSleepMinutes: lightSleepMinutes ?? this.lightSleepMinutes,
      awakeMinutes: awakeMinutes ?? this.awakeMinutes,
      alcoholConsumed: alcoholConsumed ?? this.alcoholConsumed,
      caffeineAfternoon: caffeineAfternoon ?? this.caffeineAfternoon,
      screenBeforeBed: screenBeforeBed ?? this.screenBeforeBed,
      exercisedToday: exercisedToday ?? this.exercisedToday,
      stressLevel: stressLevel ?? this.stressLevel,
      roomTempF: roomTempF ?? this.roomTempF,
      darkRoom: darkRoom ?? this.darkRoom,
      whiteNoise: whiteNoise ?? this.whiteNoise,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      notes: notes ?? this.notes,
      source: source ?? this.source,
    );
  }

  @override
  String toString() {
    return 'SleepLog(id: $id, bedTime: $bedTime, totalMinutes: $totalMinutes)';
  }
}

enum SleepSource {
  manual,
  voice,
  appleWatch,
  ouraRing,
  whoop,
  other;

  String get displayName {
    switch (this) {
      case manual:
        return 'Manual';
      case voice:
        return 'Voice';
      case appleWatch:
        return 'Apple Watch';
      case ouraRing:
        return 'Oura Ring';
      case whoop:
        return 'Whoop';
      case other:
        return 'Other';
    }
  }
}

SleepSource _parseSleepSource(String? value) {
  if (value == null || value.isEmpty) return SleepSource.manual;
  return SleepSource.values.firstWhere(
    (ss) => ss.name == value,
    orElse: () => SleepSource.manual,
  );
}

bool? _parseOptionalBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
  }
  return null;
}
