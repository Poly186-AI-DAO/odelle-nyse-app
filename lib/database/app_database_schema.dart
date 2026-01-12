part of 'app_database.dart';

mixin AppDatabaseSchema {
  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    Logger.info('Creating database tables (version $version)',
        tag: AppDatabase._tag);

    await _createCoreTables(db);
    await _createPhase1Tables(db);
    await _createHealthTables(db);
    await _createTrainingTables(db);
    await _createIndexes(db);
    await _seedMantras(db);

    Logger.info('Database tables created successfully', tag: AppDatabase._tag);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Logger.info('Upgrading database from $oldVersion to $newVersion',
        tag: AppDatabase._tag);
    if (oldVersion < 2) {
      await _createPhase1Tables(db);
      await _createIndexes(db);
    }
    if (oldVersion < 4) {
      await _createHealthTables(db);
      await _createIndexes(db);
    }
    if (oldVersion < 5) {
      await _dropLegacyContentTables(db);
    }
    if (oldVersion < 6) {
      await _createTrainingTables(db);
      await _createIndexes(db);
    }
    if (oldVersion < 7) {
      await _addGenerationQueueColumns(db);
      await _createGenerationQueueIndexes(db);
    }
  }

  /// Drop legacy content tables no longer in use
  Future<void> _dropLegacyContentTables(Database db) async {
    Logger.info('Dropping legacy content tables', tag: AppDatabase._tag);

    const legacyTables = [
      'daily_content',
      'content_cache',
      'content_themes',
    ];

    for (final table in legacyTables) {
      try {
        await db.execute('DROP TABLE IF EXISTS $table');
        Logger.info('Dropped legacy table: $table', tag: AppDatabase._tag);
      } catch (e) {
        Logger.warning('Could not drop table $table: $e', tag: AppDatabase._tag);
      }
    }

    Logger.info('Legacy content tables cleanup complete', tag: AppDatabase._tag);
  }

  /// Create health data tables for caching HealthKit data
  Future<void> _createHealthTables(Database db) async {
    Logger.info('Creating health data tables', tag: AppDatabase._tag);

    // Daily health summary cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_daily_summary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        steps INTEGER DEFAULT 0,
        active_calories REAL DEFAULT 0,
        basal_calories REAL DEFAULT 0,
        resting_heart_rate INTEGER,
        average_heart_rate INTEGER,
        exercise_minutes INTEGER DEFAULT 0,
        distance_meters REAL DEFAULT 0,
        flights_climbed INTEGER DEFAULT 0,
        water_liters REAL DEFAULT 0,
        mindful_minutes INTEGER DEFAULT 0,
        weight_kg REAL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Sleep data cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_sleep_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        bed_time TEXT,
        wake_time TEXT,
        total_minutes INTEGER,
        deep_sleep_minutes INTEGER,
        rem_sleep_minutes INTEGER,
        light_sleep_minutes INTEGER,
        awake_minutes INTEGER,
        quality_score INTEGER,
        source TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // Workout cache (from HealthKit)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_workout (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        healthkit_uuid TEXT UNIQUE,
        workout_type TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        calories_burned REAL,
        distance_meters REAL,
        steps INTEGER,
        source_name TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // Heart rate samples (optional, for detailed HR tracking)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_heart_rate (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        value INTEGER NOT NULL,
        source TEXT
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_health_daily_date ON health_daily_summary(date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_health_sleep_date ON health_sleep_log(date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_health_workout_start ON health_workout(start_time)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_health_hr_timestamp ON health_heart_rate(timestamp)');
  }

  /// Create training, exercise, meal, and reminder tables
  Future<void> _createTrainingTables(Database db) async {
    Logger.info('Creating training and exercise tables', tag: AppDatabase._tag);

    // Training programs (mesocycles) - e.g., "12-Week Strength Block"
    await db.execute('''
      CREATE TABLE IF NOT EXISTS training_programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        goal TEXT,
        duration_weeks INTEGER,
        start_date TEXT,
        end_date TEXT,
        status TEXT DEFAULT 'active',
        split_type TEXT,
        days_per_week INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Training blocks (microcycles) - e.g., "Week 3 - Volume Phase"
    await db.execute('''
      CREATE TABLE IF NOT EXISTS training_blocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_id INTEGER,
        name TEXT NOT NULL,
        week_number INTEGER,
        phase TEXT,
        intensity_percent REAL,
        volume_modifier REAL DEFAULT 1.0,
        is_deload INTEGER DEFAULT 0,
        notes TEXT,
        start_date TEXT,
        end_date TEXT,
        FOREIGN KEY (program_id) REFERENCES training_programs(id)
      )
    ''');

    // Exercise types (catalog) - the exercise library
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercise_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        category TEXT NOT NULL,
        primary_muscle TEXT NOT NULL,
        secondary_muscles TEXT,
        equipment TEXT,
        instructions TEXT,
        video_url TEXT,
        image_url TEXT,
        image_local_path TEXT,
        level TEXT,
        force TEXT,
        mechanic TEXT,
        is_compound INTEGER DEFAULT 0,
        is_custom INTEGER DEFAULT 0,
        is_generated INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Workout logs (our logged workouts, not HealthKit)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_id INTEGER,
        block_id INTEGER,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_minutes INTEGER,
        type TEXT NOT NULL,
        name TEXT,
        notes TEXT,
        source TEXT DEFAULT 'manual',
        location_name TEXT,
        latitude REAL,
        longitude REAL,
        calories_burned INTEGER,
        avg_heart_rate INTEGER,
        max_heart_rate INTEGER,
        perceived_effort INTEGER,
        energy_level INTEGER,
        mood TEXT,
        journal_entry_id INTEGER,
        FOREIGN KEY (program_id) REFERENCES training_programs(id),
        FOREIGN KEY (block_id) REFERENCES training_blocks(id),
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id)
      )
    ''');

    // Exercise sets (individual sets within a workout)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercise_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        exercise_type_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER,
        weight REAL,
        weight_unit TEXT DEFAULT 'lbs',
        duration_seconds INTEGER,
        distance_meters REAL,
        rpe INTEGER,
        is_warmup INTEGER DEFAULT 0,
        is_dropset INTEGER DEFAULT 0,
        is_failure INTEGER DEFAULT 0,
        rest_seconds INTEGER,
        notes TEXT,
        FOREIGN KEY (workout_id) REFERENCES workout_logs(id),
        FOREIGN KEY (exercise_type_id) REFERENCES exercise_types(id)
      )
    ''');

    // Personal records
    await db.execute('''
      CREATE TABLE IF NOT EXISTS personal_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_type_id INTEGER NOT NULL,
        record_type TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT,
        achieved_at TEXT NOT NULL,
        workout_id INTEGER,
        notes TEXT,
        FOREIGN KEY (exercise_type_id) REFERENCES exercise_types(id),
        FOREIGN KEY (workout_id) REFERENCES workout_logs(id)
      )
    ''');

    // Meal logs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        source TEXT DEFAULT 'manual',
        calories INTEGER,
        protein_grams INTEGER,
        carbs_grams INTEGER,
        fat_grams INTEGER,
        fiber_grams INTEGER,
        protein_level TEXT,
        quality TEXT,
        location TEXT,
        homemade INTEGER DEFAULT 0,
        meal_prepped INTEGER DEFAULT 0,
        photo_path TEXT,
        journal_entry_id INTEGER,
        confidence REAL,
        notes TEXT,
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id)
      )
    ''');

    // Smart reminders (water, eating, workout timing, etc.)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS smart_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT,
        scheduled_time TEXT,
        repeat_pattern TEXT,
        is_enabled INTEGER DEFAULT 1,
        is_smart INTEGER DEFAULT 1,
        priority INTEGER DEFAULT 0,
        context_data TEXT,
        last_triggered_at TEXT,
        last_dismissed_at TEXT,
        snooze_until TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Generation queue (for incremental content generation)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS generation_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        priority INTEGER DEFAULT 0,
        input_data TEXT,
        output_data TEXT,
        content_date TEXT,
        image_path TEXT,
        audio_path TEXT,
        error TEXT,
        attempts INTEGER DEFAULT 0,
        max_attempts INTEGER DEFAULT 3,
        created_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT
      )
    ''');

    // Create indexes for new tables
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_training_programs_status ON training_programs(status)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_training_blocks_program ON training_blocks(program_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_exercise_types_category ON exercise_types(category)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_exercise_types_muscle ON exercise_types(primary_muscle)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_workout_logs_start ON workout_logs(start_time)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_workout_logs_program ON workout_logs(program_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_exercise_sets_workout ON exercise_sets(workout_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_exercise_sets_type ON exercise_sets(exercise_type_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meal_logs_timestamp ON meal_logs(timestamp)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_smart_reminders_time ON smart_reminders(scheduled_time)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_smart_reminders_enabled ON smart_reminders(is_enabled)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_generation_queue_status ON generation_queue(status)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_generation_queue_type_date ON generation_queue(type, content_date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_generation_queue_date ON generation_queue(content_date)');

    Logger.info('Training tables created successfully', tag: AppDatabase._tag);
  }

  Future<void> _addGenerationQueueColumns(Database db) async {
    Logger.info('Ensuring generation_queue columns exist', tag: AppDatabase._tag);

    const columns = [
      'content_date TEXT',
      'image_path TEXT',
      'audio_path TEXT',
    ];

    for (final column in columns) {
      try {
        await db.execute('ALTER TABLE generation_queue ADD COLUMN $column');
      } catch (e) {
        Logger.debug('Generation queue column exists or failed: $column',
            tag: AppDatabase._tag, data: {'error': e.toString()});
      }
    }
  }

  Future<void> _createGenerationQueueIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_generation_queue_type_date ON generation_queue(type, content_date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_generation_queue_date ON generation_queue(content_date)');
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_user ON habits(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON habit_logs(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_logs_habit ON habit_logs(habit_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_mood_entries_timestamp ON mood_entries(timestamp)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_mood_entries_user ON mood_entries(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_streaks_user_type ON streaks(user_id, streak_type)');
  }

  /// Seed default mantras
  Future<void> _seedMantras(Database db) async {
    for (final mantra in DefaultMantras.all) {
      await db.insert('mantras', mantra.toMap());
    }
    Logger.info('Seeded ${DefaultMantras.all.length} default mantras',
        tag: AppDatabase._tag);
  }
}
