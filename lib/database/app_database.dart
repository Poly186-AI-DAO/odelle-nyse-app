import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/journal_entry.dart';
import '../models/protocol_entry.dart';
import '../models/character_stats.dart';
import '../models/mantra.dart';
import '../models/user/user_profile.dart';
import '../models/tracking/supplement.dart';
import '../models/tracking/dose_log.dart';
import '../models/tracking/meal_log.dart';
import '../models/tracking/workout_log.dart';
import '../models/habits/habit.dart';
import '../models/habits/habit_log.dart';
import '../models/mood/mood_entry.dart';
import '../models/gamification/streak.dart';
import '../models/wealth/wealth.dart';
import '../models/relationships/relationships.dart';
import '../utils/logger.dart';

part 'app_database_schema.dart';
part 'app_database_journal.dart';
part 'app_database_protocol.dart';
part 'app_database_character_stats.dart';
part 'app_database_mantras.dart';
part 'app_database_user_profiles.dart';
part 'app_database_supplements.dart';
part 'app_database_dose_logs.dart';
part 'app_database_meal_logs.dart';
part 'app_database_workout_logs.dart';
part 'app_database_habits.dart';
part 'app_database_habit_logs.dart';
part 'app_database_mood_entries.dart';
part 'app_database_streaks.dart';
part 'app_database_bills.dart';
part 'app_database_subscriptions.dart';
part 'app_database_incomes.dart';
part 'app_database_contacts.dart';
part 'app_database_interactions.dart';
part 'app_database_utils.dart';

abstract class AppDatabaseBase {
  Future<Database> get database;
  Future<List<ProtocolEntry>> getTodayProtocolEntries();
}

/// Local SQLite database for Odelle Nyse
/// Acts as primary data store (Room-equivalent for Flutter)
class AppDatabase extends AppDatabaseBase
    with
        AppDatabaseSchema,
        JournalEntryCrud,
        ProtocolEntryCrud,
        CharacterStatsCrud,
        MantraCrud,
        UserProfileCrud,
        SupplementCrud,
        DoseLogCrud,
        MealLogCrud,
        WorkoutLogCrud,
        HabitCrud,
        HabitLogCrud,
        MoodEntryCrud,
        StreakCrud,
        BillCrud,
        SubscriptionCrud,
        IncomeCrud,
        ContactCrud,
        InteractionCrud,
        AppDatabaseUtils {
  static const String _tag = 'AppDatabase';
  static const String _databaseName = 'odelle_nyse.db';
  static const int _databaseVersion = 8; // v8: Wealth + Bonds pillars

  static Database? _database;
  static final AppDatabase instance = AppDatabase._internal();

  AppDatabase._internal();

  /// Get database instance (lazy initialization)
  @override
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

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    Logger.info('Database closed', tag: _tag);
  }
}
