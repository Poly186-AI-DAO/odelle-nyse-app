import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/journal_entry.dart';
import '../models/protocol_entry.dart';
import '../models/character_stats.dart';
import '../models/mantra.dart';
import '../models/user/user_profile.dart';
import '../models/tracking/supplement.dart';
import '../models/tracking/dose_log.dart';
import '../models/habits/habit.dart';
import '../models/habits/habit_log.dart';
import '../models/mood/mood_entry.dart';
import '../models/gamification/streak.dart';
import '../models/content/content_category.dart';
import '../models/content/instructor.dart';
import '../models/content/program.dart';
import '../models/content/session.dart';
import '../models/content/play_history.dart';
import '../models/content/favorite.dart';
import '../utils/logger.dart';

/// Local SQLite database for Odelle Nyse
/// Acts as primary data store (Room-equivalent for Flutter)
class AppDatabase {
  static const String _tag = 'AppDatabase';
  static const String _databaseName = 'odelle_nyse.db';
  static const int _databaseVersion = 3;

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

    await _createCoreTables(db);
    await _createPhase1Tables(db);
    await _createPhase2Tables(db);
    await _createIndexes(db);
    await _seedMantras(db);

    Logger.info('Database tables created successfully', tag: _tag);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Logger.info('Upgrading database from $oldVersion to $newVersion',
        tag: _tag);
    if (oldVersion < 2) {
      await _createPhase1Tables(db);
      await _createIndexes(db);
    }
    if (oldVersion < 3) {
      await _createPhase2Tables(db);
      await _createIndexes(db);
    }
  }

  Future<void> _createCoreTables(Database db) async {
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
  }

  Future<void> _createPhase1Tables(Database db) async {
    // User profiles
    await db.execute('''
      CREATE TABLE user_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT,
        name TEXT NOT NULL,
        email TEXT,
        avatar_url TEXT,
        avatar_local_path TEXT,
        level INTEGER DEFAULT 1,
        total_xp INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        title TEXT,
        timezone TEXT,
        uses_metric INTEGER DEFAULT 0,
        wake_up_time TEXT,
        bed_time TEXT,
        is_premium INTEGER DEFAULT 0,
        premium_expires_at TEXT,
        has_completed_onboarding INTEGER DEFAULT 0,
        goals TEXT,
        focus_areas TEXT,
        created_at TEXT NOT NULL,
        last_active_at TEXT
      )
    ''');

    // Supplements catalog
    await db.execute('''
      CREATE TABLE supplements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT,
        category TEXT NOT NULL,
        default_dose_mg REAL,
        unit TEXT DEFAULT 'mg',
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        take_with_food INTEGER DEFAULT 0,
        take_with_fat INTEGER DEFAULT 0,
        max_daily_mg REAL,
        preferred_times TEXT,
        interactions TEXT,
        image_url TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Dose logs
    await db.execute('''
      CREATE TABLE dose_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplement_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        amount_mg REAL NOT NULL,
        unit TEXT,
        source TEXT NOT NULL,
        taken_with_food INTEGER,
        taken_with_fat INTEGER,
        meal_context TEXT,
        journal_entry_id INTEGER,
        confidence REAL,
        notes TEXT,
        FOREIGN KEY (supplement_id) REFERENCES supplements(id),
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id)
      )
    ''');

    // Habits
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        emoji TEXT,
        color_hex TEXT,
        category TEXT NOT NULL,
        custom_category TEXT,
        frequency TEXT DEFAULT 'daily',
        days_of_week TEXT,
        times_per_day INTEGER,
        times_per_week INTEGER,
        reminder_time TEXT,
        reminder_enabled INTEGER DEFAULT 0,
        target_time TEXT,
        is_time_sensitive INTEGER DEFAULT 0,
        habit_type TEXT DEFAULT 'boolean',
        target_count INTEGER,
        target_minutes INTEGER,
        xp_per_completion INTEGER DEFAULT 10,
        created_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        is_archived INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id)
      )
    ''');

    // Habit logs
    await db.execute('''
      CREATE TABLE habit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed_at TEXT,
        is_completed INTEGER DEFAULT 0,
        count INTEGER,
        duration_minutes INTEGER,
        notes TEXT,
        status TEXT DEFAULT 'pending',
        journal_entry_id INTEGER,
        FOREIGN KEY (habit_id) REFERENCES habits(id),
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id)
      )
    ''');

    // Mood entries
    await db.execute('''
      CREATE TABLE mood_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        mood TEXT NOT NULL,
        intensity INTEGER,
        secondary_moods TEXT,
        factors TEXT,
        notes TEXT,
        check_in_type TEXT DEFAULT 'manual',
        linked_session_id INTEGER,
        linked_workout_id INTEGER,
        journal_entry_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id),
        FOREIGN KEY (linked_session_id) REFERENCES sessions(id),
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id)
      )
    ''');

    // Streaks
    await db.execute('''
      CREATE TABLE streaks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        streak_type TEXT NOT NULL,
        current_count INTEGER DEFAULT 0,
        streak_start_date TEXT,
        last_activity_date TEXT,
        longest_count INTEGER DEFAULT 0,
        longest_start_date TEXT,
        longest_end_date TEXT,
        total_active_days INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id)
      )
    ''');
  }

  Future<void> _createPhase2Tables(Database db) async {
    // Content categories
    await db.execute('''
      CREATE TABLE content_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        slug TEXT,
        description TEXT,
        icon_name TEXT,
        icon_url TEXT,
        color_hex TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        content_type TEXT NOT NULL,
        parent_category_id INTEGER,
        FOREIGN KEY (parent_category_id) REFERENCES content_categories(id)
      )
    ''');

    // Instructors
    await db.execute('''
      CREATE TABLE instructors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        title TEXT,
        bio TEXT,
        short_bio TEXT,
        avatar_url TEXT,
        cover_image_url TEXT,
        certifications TEXT,
        years_experience INTEGER,
        instagram_handle TEXT,
        website_url TEXT,
        sessions_count INTEGER DEFAULT 0,
        followers_count INTEGER DEFAULT 0,
        average_rating REAL,
        is_featured INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Programs
    await db.execute('''
      CREATE TABLE programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subtitle TEXT,
        short_description TEXT NOT NULL,
        long_description TEXT,
        thumbnail_url TEXT,
        cover_image_url TEXT,
        promo_video_url TEXT,
        total_lessons INTEGER NOT NULL,
        total_duration_minutes INTEGER NOT NULL,
        duration_days INTEGER NOT NULL,
        pace TEXT DEFAULT 'daily',
        category_id INTEGER,
        instructor_id INTEGER,
        difficulty TEXT DEFAULT 'beginner',
        is_free INTEGER DEFAULT 1,
        is_featured INTEGER DEFAULT 0,
        learning_outcomes TEXT,
        requirements TEXT,
        target_audience TEXT,
        enrollment_count INTEGER DEFAULT 0,
        completion_count INTEGER DEFAULT 0,
        average_rating REAL,
        rating_count INTEGER DEFAULT 0,
        xp_reward INTEGER DEFAULT 0,
        badge_id TEXT,
        published_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES content_categories(id),
        FOREIGN KEY (instructor_id) REFERENCES instructors(id)
      )
    ''');

    // Sessions
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subtitle TEXT,
        short_description TEXT NOT NULL,
        long_description TEXT,
        thumbnail_url TEXT,
        cover_image_url TEXT,
        audio_url TEXT,
        video_url TEXT,
        preview_url TEXT,
        duration_seconds INTEGER NOT NULL,
        duration_display TEXT NOT NULL,
        category_id INTEGER,
        instructor_id INTEGER,
        program_id INTEGER,
        lesson_number INTEGER,
        difficulty TEXT DEFAULT 'beginner',
        is_guided INTEGER DEFAULT 1,
        is_free INTEGER DEFAULT 1,
        is_featured INTEGER DEFAULT 0,
        is_downloadable INTEGER DEFAULT 0,
        tags TEXT,
        benefits TEXT,
        requirements TEXT,
        calorie_estimate INTEGER,
        target_mood TEXT,
        play_count INTEGER DEFAULT 0,
        completion_count INTEGER DEFAULT 0,
        average_rating REAL,
        rating_count INTEGER DEFAULT 0,
        published_at TEXT NOT NULL,
        updated_at TEXT,
        is_active INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES content_categories(id),
        FOREIGN KEY (instructor_id) REFERENCES instructors(id),
        FOREIGN KEY (program_id) REFERENCES programs(id)
      )
    ''');

    // Play history
    await db.execute('''
      CREATE TABLE play_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        session_id INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        progress_seconds INTEGER DEFAULT 0,
        completion_percentage REAL DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        device_type TEXT,
        was_offline INTEGER DEFAULT 0,
        pause_count INTEGER DEFAULT 0,
        total_seconds_played INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id),
        FOREIGN KEY (session_id) REFERENCES sessions(id)
      )
    ''');

    // Favorites
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        favorite_type TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id)
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_journal_timestamp ON journal_entries(timestamp)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_protocol_timestamp ON protocol_entries(timestamp)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_protocol_type ON protocol_entries(type)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_supplements_active ON supplements(is_active)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_dose_logs_timestamp ON dose_logs(timestamp)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_dose_logs_supplement ON dose_logs(supplement_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_habits_user ON habits(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON habit_logs(date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_habit_logs_habit ON habit_logs(habit_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_mood_entries_timestamp ON mood_entries(timestamp)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_mood_entries_user ON mood_entries(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_streaks_user_type ON streaks(user_id, streak_type)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_content_categories_type ON content_categories(content_type)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_instructors_active ON instructors(is_active)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sessions_category ON sessions(category_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sessions_program ON sessions(program_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sessions_instructor ON sessions(instructor_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_programs_category ON programs(category_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_programs_instructor ON programs(instructor_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_play_history_user ON play_history(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_play_history_session ON play_history(session_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_favorites_user_type ON favorites(user_id, favorite_type)');
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

  // ===================
  // User Profile CRUD
  // ===================

  Future<int> insertUserProfile(UserProfile profile) async {
    final db = await database;
    final id = await db.insert('user_profiles', profile.toMap());
    Logger.info('Inserted user profile: $id', tag: _tag);
    return id;
  }

  Future<UserProfile?> getUserProfile(int id) async {
    final db = await database;
    final maps = await db.query(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<List<UserProfile>> getUserProfiles({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'user_profiles',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => UserProfile.fromMap(map)).toList();
  }

  Future<int> updateUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.update(
      'user_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<int> deleteUserProfile(int id) async {
    final db = await database;
    return await db.delete(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===================
  // Supplements CRUD
  // ===================

  Future<int> insertSupplement(Supplement supplement) async {
    final db = await database;
    final id = await db.insert('supplements', supplement.toMap());
    Logger.info('Inserted supplement: $id', tag: _tag);
    return id;
  }

  Future<List<Supplement>> getSupplements({
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'supplements',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Supplement.fromMap(map)).toList();
  }

  Future<List<Supplement>> getActiveSupplements() async {
    return getSupplements();
  }

  Future<Supplement?> getSupplement(int id) async {
    final db = await database;
    final maps = await db.query(
      'supplements',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Supplement.fromMap(maps.first);
  }

  Future<int> updateSupplement(Supplement supplement) async {
    final db = await database;
    return await db.update(
      'supplements',
      supplement.toMap(),
      where: 'id = ?',
      whereArgs: [supplement.id],
    );
  }

  Future<int> deleteSupplement(int id) async {
    final db = await database;
    return await db.delete(
      'supplements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =================
  // Dose Logs CRUD
  // =================

  Future<int> insertDoseLog(DoseLog log) async {
    final db = await database;
    final id = await db.insert('dose_logs', log.toMap());
    Logger.info('Inserted dose log: $id', tag: _tag);
    return id;
  }

  Future<List<DoseLog>> getDoseLogs({
    int limit = 50,
    int offset = 0,
    int? supplementId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (supplementId != null) {
      whereClause += 'supplement_id = ?';
      whereArgs.add(supplementId);
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
      'dose_logs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => DoseLog.fromMap(map)).toList();
  }

  Future<DoseLog?> getDoseLog(int id) async {
    final db = await database;
    final maps = await db.query(
      'dose_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return DoseLog.fromMap(maps.first);
  }

  Future<int> updateDoseLog(DoseLog log) async {
    final db = await database;
    return await db.update(
      'dose_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteDoseLog(int id) async {
    final db = await database;
    return await db.delete(
      'dose_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =================
  // Habits CRUD
  // =================

  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    final id = await db.insert('habits', habit.toMap());
    Logger.info('Inserted habit: $id', tag: _tag);
    return id;
  }

  Future<List<Habit>> getHabits({
    int? userId,
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }
    if (activeOnly) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_active = 1 AND is_archived = 0';
    }

    final maps = await db.query(
      'habits',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'sort_order ASC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<Habit?> getHabit(int id) async {
    final db = await database;
    final maps = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =================
  // Habit Logs CRUD
  // =================

  Future<int> insertHabitLog(HabitLog log) async {
    final db = await database;
    final id = await db.insert('habit_logs', log.toMap());
    Logger.info('Inserted habit log: $id', tag: _tag);
    return id;
  }

  Future<List<HabitLog>> getHabitLogs({
    int? habitId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (habitId != null) {
      whereClause += 'habit_id = ?';
      whereArgs.add(habitId);
    }
    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date >= ?';
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }

    final maps = await db.query(
      'habit_logs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => HabitLog.fromMap(map)).toList();
  }

  Future<HabitLog?> getHabitLog(int id) async {
    final db = await database;
    final maps = await db.query(
      'habit_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return HabitLog.fromMap(maps.first);
  }

  Future<int> updateHabitLog(HabitLog log) async {
    final db = await database;
    return await db.update(
      'habit_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteHabitLog(int id) async {
    final db = await database;
    return await db.delete(
      'habit_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================
  // Mood Entries CRUD
  // ==================

  Future<int> insertMoodEntry(MoodEntry entry) async {
    final db = await database;
    final id = await db.insert('mood_entries', entry.toMap());
    Logger.info('Inserted mood entry: $id', tag: _tag);
    return id;
  }

  Future<List<MoodEntry>> getMoodEntries({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
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
      'mood_entries',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => MoodEntry.fromMap(map)).toList();
  }

  Future<MoodEntry?> getMoodEntry(int id) async {
    final db = await database;
    final maps = await db.query(
      'mood_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MoodEntry.fromMap(maps.first);
  }

  Future<int> updateMoodEntry(MoodEntry entry) async {
    final db = await database;
    return await db.update(
      'mood_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteMoodEntry(int id) async {
    final db = await database;
    return await db.delete(
      'mood_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==============
  // Streaks CRUD
  // ==============

  Future<int> insertStreak(Streak streak) async {
    final db = await database;
    final id = await db.insert('streaks', streak.toMap());
    Logger.info('Inserted streak: $id', tag: _tag);
    return id;
  }

  Future<List<Streak>> getStreaks({
    int? userId,
    StreakType? type,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }
    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'streak_type = ?';
      whereArgs.add(type.name);
    }

    final maps = await db.query(
      'streaks',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'last_activity_date DESC',
    );

    return maps.map((map) => Streak.fromMap(map)).toList();
  }

  Future<Streak?> getStreak(int id) async {
    final db = await database;
    final maps = await db.query(
      'streaks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Streak.fromMap(maps.first);
  }

  Future<int> updateStreak(Streak streak) async {
    final db = await database;
    return await db.update(
      'streaks',
      streak.toMap(),
      where: 'id = ?',
      whereArgs: [streak.id],
    );
  }

  Future<int> deleteStreak(int id) async {
    final db = await database;
    return await db.delete(
      'streaks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================
  // Content Categories CRUD
  // ========================

  Future<int> insertContentCategory(ContentCategory category) async {
    final db = await database;
    final id = await db.insert('content_categories', category.toMap());
    Logger.info('Inserted content category: $id', tag: _tag);
    return id;
  }

  Future<List<ContentCategory>> getContentCategories({
    bool activeOnly = true,
    ContentType? contentType,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (activeOnly) {
      whereClause += 'is_active = 1';
    }
    if (contentType != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'content_type = ?';
      whereArgs.add(contentType.name);
    }

    final maps = await db.query(
      'content_categories',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'sort_order ASC, name ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => ContentCategory.fromMap(map)).toList();
  }

  Future<ContentCategory?> getContentCategory(int id) async {
    final db = await database;
    final maps = await db.query(
      'content_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ContentCategory.fromMap(maps.first);
  }

  Future<int> updateContentCategory(ContentCategory category) async {
    final db = await database;
    return await db.update(
      'content_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteContentCategory(int id) async {
    final db = await database;
    return await db.delete(
      'content_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =================
  // Instructors CRUD
  // =================

  Future<int> insertInstructor(Instructor instructor) async {
    final db = await database;
    final id = await db.insert('instructors', instructor.toMap());
    Logger.info('Inserted instructor: $id', tag: _tag);
    return id;
  }

  Future<List<Instructor>> getInstructors({
    bool activeOnly = true,
    bool featuredOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (activeOnly) {
      whereClause += 'is_active = 1';
    }
    if (featuredOnly) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_featured = 1';
    }

    final maps = await db.query(
      'instructors',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Instructor.fromMap(map)).toList();
  }

  Future<Instructor?> getInstructor(int id) async {
    final db = await database;
    final maps = await db.query(
      'instructors',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Instructor.fromMap(maps.first);
  }

  Future<int> updateInstructor(Instructor instructor) async {
    final db = await database;
    return await db.update(
      'instructors',
      instructor.toMap(),
      where: 'id = ?',
      whereArgs: [instructor.id],
    );
  }

  Future<int> deleteInstructor(int id) async {
    final db = await database;
    return await db.delete(
      'instructors',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==============
  // Programs CRUD
  // ==============

  Future<int> insertProgram(Program program) async {
    final db = await database;
    final id = await db.insert('programs', program.toMap());
    Logger.info('Inserted program: $id', tag: _tag);
    return id;
  }

  Future<List<Program>> getPrograms({
    bool activeOnly = true,
    int? categoryId,
    int? instructorId,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (activeOnly) {
      whereClause += 'is_active = 1';
    }
    if (categoryId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category_id = ?';
      whereArgs.add(categoryId);
    }
    if (instructorId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'instructor_id = ?';
      whereArgs.add(instructorId);
    }

    final maps = await db.query(
      'programs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'published_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Program.fromMap(map)).toList();
  }

  Future<Program?> getProgram(int id) async {
    final db = await database;
    final maps = await db.query(
      'programs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Program.fromMap(maps.first);
  }

  Future<int> updateProgram(Program program) async {
    final db = await database;
    return await db.update(
      'programs',
      program.toMap(),
      where: 'id = ?',
      whereArgs: [program.id],
    );
  }

  Future<int> deleteProgram(int id) async {
    final db = await database;
    return await db.delete(
      'programs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==============
  // Sessions CRUD
  // ==============

  Future<int> insertSession(Session session) async {
    final db = await database;
    final id = await db.insert('sessions', session.toMap());
    Logger.info('Inserted session: $id', tag: _tag);
    return id;
  }

  Future<List<Session>> getSessions({
    bool activeOnly = true,
    bool featuredOnly = false,
    int? categoryId,
    int? programId,
    int? instructorId,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (activeOnly) {
      whereClause += 'is_active = 1';
    }
    if (featuredOnly) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_featured = 1';
    }
    if (categoryId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category_id = ?';
      whereArgs.add(categoryId);
    }
    if (programId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'program_id = ?';
      whereArgs.add(programId);
    }
    if (instructorId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'instructor_id = ?';
      whereArgs.add(instructorId);
    }

    final maps = await db.query(
      'sessions',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'published_at DESC, sort_order ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Session.fromMap(map)).toList();
  }

  Future<Session?> getSession(int id) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  Future<int> updateSession(Session session) async {
    final db = await database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================
  // Play History CRUD
  // ==================

  Future<int> insertPlayHistory(PlayHistory history) async {
    final db = await database;
    final id = await db.insert('play_history', history.toMap());
    Logger.info('Inserted play history: $id', tag: _tag);
    return id;
  }

  Future<List<PlayHistory>> getPlayHistory({
    int? userId,
    int? sessionId,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }
    if (sessionId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'session_id = ?';
      whereArgs.add(sessionId);
    }

    final maps = await db.query(
      'play_history',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'started_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => PlayHistory.fromMap(map)).toList();
  }

  Future<PlayHistory?> getPlayHistoryEntry(int id) async {
    final db = await database;
    final maps = await db.query(
      'play_history',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PlayHistory.fromMap(maps.first);
  }

  Future<int> updatePlayHistory(PlayHistory history) async {
    final db = await database;
    return await db.update(
      'play_history',
      history.toMap(),
      where: 'id = ?',
      whereArgs: [history.id],
    );
  }

  Future<int> deletePlayHistory(int id) async {
    final db = await database;
    return await db.delete(
      'play_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==============
  // Favorites CRUD
  // ==============

  Future<int> insertFavorite(Favorite favorite) async {
    final db = await database;
    final id = await db.insert('favorites', favorite.toMap());
    Logger.info('Inserted favorite: $id', tag: _tag);
    return id;
  }

  Future<List<Favorite>> getFavorites({
    int? userId,
    FavoriteType? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }
    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'favorite_type = ?';
      whereArgs.add(type.name);
    }

    final maps = await db.query(
      'favorites',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Favorite.fromMap(map)).toList();
  }

  Future<Favorite?> getFavorite(int id) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Favorite.fromMap(maps.first);
  }

  Future<int> updateFavorite(Favorite favorite) async {
    final db = await database;
    return await db.update(
      'favorites',
      favorite.toMap(),
      where: 'id = ?',
      whereArgs: [favorite.id],
    );
  }

  Future<int> deleteFavorite(int id) async {
    final db = await database;
    return await db.delete(
      'favorites',
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
