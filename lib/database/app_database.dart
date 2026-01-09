import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/journal_entry.dart';
import '../models/protocol_entry.dart';
import '../models/character_stats.dart';
import '../models/mantra.dart';
import '../utils/logger.dart';

/// Local SQLite database for Odelle Nyse
/// Acts as primary data store (Room-equivalent for Flutter)
class AppDatabase {
  static const String _tag = 'AppDatabase';
  static const String _databaseName = 'odelle_nyse.db';
  static const int _databaseVersion = 1;

  static Database? _database;
  static final AppDatabase instance = AppDatabase._internal();

  AppDatabase._internal();

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    Logger.info('Initializing database', tag: _tag);

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    Logger.info('Creating database tables (version $version)', tag: _tag);

    // Journal entries table
    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        transcription TEXT NOT NULL,
        mood REAL,
        sentiment TEXT,
        tags TEXT
      )
    ''');

    // Protocol entries table
    await db.execute('''
      CREATE TABLE protocol_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Character stats table
    await db.execute('''
      CREATE TABLE character_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        strength REAL DEFAULT 0,
        intellect REAL DEFAULT 0,
        spirit REAL DEFAULT 0,
        sales REAL DEFAULT 0,
        total_xp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1
      )
    ''');

    // Mantras table
    await db.execute('''
      CREATE TABLE mantras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        category TEXT
      )
    ''');

    // Create indexes for faster queries
    await db.execute(
        'CREATE INDEX idx_journal_timestamp ON journal_entries(timestamp)');
    await db.execute(
        'CREATE INDEX idx_protocol_timestamp ON protocol_entries(timestamp)');
    await db
        .execute('CREATE INDEX idx_protocol_type ON protocol_entries(type)');

    // Seed default mantras
    await _seedMantras(db);

    Logger.info('Database tables created successfully', tag: _tag);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Logger.info('Upgrading database from $oldVersion to $newVersion',
        tag: _tag);
    // Future migrations go here
  }

  /// Seed default mantras
  Future<void> _seedMantras(Database db) async {
    for (final mantra in DefaultMantras.all) {
      await db.insert('mantras', mantra.toMap());
    }
    Logger.info('Seeded ${DefaultMantras.all.length} default mantras',
        tag: _tag);
  }

  // ===================
  // Journal Entry CRUD
  // ===================

  Future<int> insertJournalEntry(JournalEntry entry) async {
    final db = await database;
    final id = await db.insert('journal_entries', entry.toMap());
    Logger.info('Inserted journal entry: $id', tag: _tag);
    return id;
  }

  Future<List<JournalEntry>> getJournalEntries({
    int limit = 50,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'journal_entries',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  Future<JournalEntry?> getJournalEntry(int id) async {
    final db = await database;
    final maps = await db.query(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return JournalEntry.fromMap(maps.first);
  }

  Future<int> updateJournalEntry(JournalEntry entry) async {
    final db = await database;
    return await db.update(
      'journal_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteJournalEntry(int id) async {
    final db = await database;
    return await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ====================
  // Protocol Entry CRUD
  // ====================

  Future<int> insertProtocolEntry(ProtocolEntry entry) async {
    final db = await database;
    final id = await db.insert('protocol_entries', entry.toMap());
    Logger.info('Inserted protocol entry: ${entry.type.displayName}',
        tag: _tag);
    return id;
  }

  Future<List<ProtocolEntry>> getProtocolEntries({
    int limit = 50,
    int offset = 0,
    ProtocolType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (type != null) {
      whereClause += 'type = ?';
      whereArgs.add(type.name);
    }
    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'protocol_entries',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => ProtocolEntry.fromMap(map)).toList();
  }

  Future<List<ProtocolEntry>> getTodayProtocolEntries() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getProtocolEntries(startDate: startOfDay, endDate: endOfDay);
  }

  Future<int> deleteProtocolEntry(int id) async {
    final db = await database;
    return await db.delete(
      'protocol_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ====================
  // Character Stats CRUD
  // ====================

  Future<int> upsertCharacterStats(CharacterStats stats) async {
    final db = await database;
    final dateStr = stats.date.toIso8601String().split('T')[0];

    // Check if stats exist for this date
    final existing = await db.query(
      'character_stats',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'character_stats',
        stats.toMap(),
        where: 'date = ?',
        whereArgs: [dateStr],
      );
    } else {
      return await db.insert('character_stats', stats.toMap());
    }
  }

  Future<CharacterStats?> getCharacterStats(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];

    final maps = await db.query(
      'character_stats',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (maps.isEmpty) return null;
    return CharacterStats.fromMap(maps.first);
  }

  Future<CharacterStats> getTodayStats() async {
    final existing = await getCharacterStats(DateTime.now());
    return existing ?? CharacterStats.today();
  }

  // =============
  // Mantras CRUD
  // =============

  Future<int> insertMantra(Mantra mantra) async {
    final db = await database;
    return await db.insert('mantras', mantra.toMap());
  }

  Future<List<Mantra>> getMantras({bool activeOnly = true}) async {
    final db = await database;
    final maps = await db.query(
      'mantras',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Mantra.fromMap(map)).toList();
  }

  Future<Mantra?> getRandomMantra() async {
    final db = await database;
    final maps = await db.rawQuery(
        'SELECT * FROM mantras WHERE is_active = 1 ORDER BY RANDOM() LIMIT 1');
    if (maps.isEmpty) return null;
    return Mantra.fromMap(maps.first);
  }

  Future<int> updateMantra(Mantra mantra) async {
    final db = await database;
    return await db.update(
      'mantras',
      mantra.toMap(),
      where: 'id = ?',
      whereArgs: [mantra.id],
    );
  }

  Future<int> deleteMantra(int id) async {
    final db = await database;
    return await db.delete(
      'mantras',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =================
  // Utility Methods
  // =================

  /// Get count of entries for today (for streak calculation)
  Future<Map<ProtocolType, int>> getTodayCounts() async {
    final entries = await getTodayProtocolEntries();
    final counts = <ProtocolType, int>{};

    for (final type in ProtocolType.values) {
      counts[type] = entries.where((e) => e.type == type).length;
    }

    return counts;
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    Logger.info('Database closed', tag: _tag);
  }
}
