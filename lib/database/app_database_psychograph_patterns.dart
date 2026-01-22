part of 'app_database.dart';

/// A single psychograph pattern noted about the user.
class PsychographPattern {
  final int? id;
  final String category;
  final String observation;
  final String? context;
  final DateTime createdAt;

  PsychographPattern({
    this.id,
    required this.category,
    required this.observation,
    this.context,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category': category,
        'observation': observation,
        'context': context,
        'created_at': createdAt.toIso8601String(),
      };

  factory PsychographPattern.fromMap(Map<String, dynamic> map) {
    return PsychographPattern(
      id: map['id'] as int?,
      category: map['category'] as String? ?? 'unknown',
      observation: map['observation'] as String? ?? '',
      context: map['context'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Aggregated psychograph pattern info for summary views.
class PsychographPatternAggregate {
  final String category;
  final String observation;
  final int count;
  final DateTime lastSeen;

  const PsychographPatternAggregate({
    required this.category,
    required this.observation,
    required this.count,
    required this.lastSeen,
  });

  factory PsychographPatternAggregate.fromMap(Map<String, dynamic> map) {
    final countValue = map['count'];
    final count =
        countValue is int ? countValue : (countValue as num?)?.toInt() ?? 0;
    return PsychographPatternAggregate(
      category: map['category'] as String? ?? 'unknown',
      observation: map['observation'] as String? ?? '',
      count: count,
      lastSeen: DateTime.tryParse(map['last_seen'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// CRUD operations for psychograph patterns.
mixin PsychographPatternCrud on AppDatabaseBase {
  static const String _tag = 'PsychographPatternCrud';

  Future<int> insertPsychographPattern(PsychographPattern pattern) async {
    final db = await database;
    final id = await db.insert('psychograph_patterns', pattern.toMap());
    Logger.info('Inserted psychograph pattern: $id', tag: _tag);

    await queueSync(
      tableName: 'psychograph_patterns',
      rowId: id,
      operation: 'INSERT',
      data: pattern.toMap(),
    );

    return id;
  }

  Future<List<PsychographPattern>> getRecentPsychographPatterns({
    int limit = 10,
  }) async {
    final db = await database;
    final maps = await db.query(
      'psychograph_patterns',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map(PsychographPattern.fromMap).toList();
  }

  Future<List<PsychographPatternAggregate>> getTopPsychographPatterns({
    int limit = 10,
  }) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT category, observation, COUNT(*) as count, MAX(created_at) as last_seen
      FROM psychograph_patterns
      GROUP BY category, observation
      ORDER BY count DESC, last_seen DESC
      LIMIT ?
    ''', [limit]);
    return maps.map(PsychographPatternAggregate.fromMap).toList();
  }
}
