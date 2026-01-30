import 'dart:convert';

import '../../database/app_database.dart';
import '../../models/habits/habit.dart';
import '../../models/habits/habit_log.dart';
import '../../models/journal_entry.dart';
import '../../models/mantra.dart';
import '../../models/mood/mood_entry.dart';
import '../../models/relationships/contact.dart';
import '../../models/smart_reminder.dart';
import '../../models/tracking/dose_log.dart';
import '../../models/tracking/meal_log.dart';
import '../../models/tracking/supplement.dart';
import '../../models/tracking/workout_log.dart';
import '../../models/wealth/wealth.dart';
import '../../services/azure_agent_service.dart';
import '../../services/azure_image_service.dart';
import '../../services/health_kit_service.dart';
import '../../services/smart_reminder_service.dart';
import '../../services/user_context_service.dart';
import '../../services/weather_service.dart';
import '../../utils/logger.dart';

/// ChatToolExecutor - Handles all AI agent tool definitions and execution
///
/// Separated from ChatViewModel to follow single responsibility principle.
/// Provides tools for:
/// - Body: workouts, meals, supplements, health data
/// - Mind: mood, meditation, journal
/// - Spirit: habits, mantras
/// - Bonds: contacts, relationships
/// - Wealth: bills, subscriptions, income
/// - Utilities: reminders, weather, images
class ChatToolExecutor {
  static const String _tag = 'ChatToolExecutor';

  final AppDatabase database;
  final UserContextService userContextService;
  final HealthKitService healthKitService;
  final SmartReminderService reminderService;
  final WeatherService weatherService;
  final AzureImageService imageService;

  ChatToolExecutor({
    required this.database,
    required this.userContextService,
    required this.healthKitService,
    required this.reminderService,
    required this.weatherService,
    required this.imageService,
  });

  /// Get all available tool definitions
  List<ToolDefinition> getTools() {
    return [
      ..._getBodyTools(),
      ..._getMindTools(),
      ..._getSpiritTools(),
      ..._getBondsTools(),
      ..._getWealthTools(),
      ..._getStatusTools(),
      ..._getKnowledgeTools(),
      ..._getCreativeTools(),
      ..._getReminderTools(),
      ..._getUtilityTools(),
    ];
  }

  /// Execute a tool by name
  Future<String> executeTool(String name, Map<String, dynamic>? args) async {
    Logger.info('Executing chat tool: $name', tag: _tag, data: args);
    final safeArgs = args ?? {};

    switch (name) {
      // Body tools
      case 'log_workout':
        return await _toolLogWorkout(safeArgs);
      case 'log_meal':
        return await _toolLogMeal(safeArgs);
      case 'log_supplement':
        return await _toolLogSupplement(safeArgs);
      case 'get_workouts':
        return await _toolGetWorkouts(safeArgs);
      case 'get_meals':
        return await _toolGetMeals(safeArgs);
      case 'get_health_data':
        return await _toolGetHealthData(safeArgs);
      // Mind tools
      case 'log_mood':
        return await _toolLogMood(safeArgs);
      case 'log_meditation':
        return await _toolLogMeditation(safeArgs);
      case 'add_journal_entry':
        return await _toolAddJournalEntry(safeArgs);
      case 'get_journal':
        return await _toolGetJournal(safeArgs);
      case 'get_mood_history':
        return await _toolGetMoodHistory(safeArgs);
      // Spirit tools
      case 'log_habit':
        return await _toolLogHabit(safeArgs);
      case 'add_mantra':
        return await _toolAddMantra(safeArgs);
      case 'create_habit':
        return await _toolCreateHabit(safeArgs);
      case 'get_habits':
        return await _toolGetHabits(safeArgs);
      case 'get_mantras':
        return await _toolGetMantras(safeArgs);
      // Bonds tools
      case 'add_contact':
        return await _toolAddContact(safeArgs);
      case 'get_contacts':
        return await _toolGetContacts(safeArgs);
      case 'log_interaction':
        return await _toolLogInteraction(safeArgs);
      case 'get_overdue_contacts':
        return await _toolGetOverdueContacts(safeArgs);
      // Wealth tools
      case 'add_bill':
        return await _toolAddBill(safeArgs);
      case 'add_subscription':
        return await _toolAddSubscription(safeArgs);
      case 'add_income':
        return await _toolAddIncome(safeArgs);
      case 'get_bills':
        return await _toolGetBills(safeArgs);
      case 'get_subscriptions':
        return await _toolGetSubscriptions(safeArgs);
      // Status tools
      case 'get_user_status':
        return await _toolGetUserStatus(safeArgs);
      case 'note_pattern':
        return await _toolNotePattern(safeArgs);
      // Knowledge tools
      case 'search_user_documents':
        return _toolSearchDocuments(safeArgs);
      // Creative tools
      case 'generate_image':
        return await _toolGenerateImage(safeArgs);
      // Reminder tools
      case 'create_reminder':
        return await _toolCreateReminder(safeArgs);
      case 'get_reminders':
        return await _toolGetReminders(safeArgs);
      case 'delete_reminder':
        return await _toolDeleteReminder(safeArgs);
      // Utility tools
      case 'get_weather':
        return await _toolGetWeather(safeArgs);
      default:
        return jsonEncode({'error': 'Unknown tool: $name'});
    }
  }

  // ===========================================================================
  // BODY TOOLS (Definitions)
  // ===========================================================================

  List<ToolDefinition> _getBodyTools() {
    return [
      ToolDefinition(
        name: 'log_workout',
        description:
            'Log a workout session. Use when user mentions completing a workout, gym session, run, yoga, etc.',
        parameters: {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description':
                  'Name of the workout (e.g., "Push Day", "Morning Run")',
            },
            'type': {
              'type': 'string',
              'enum': [
                'strength',
                'hypertrophy',
                'powerlifting',
                'cardio',
                'hiit',
                'flexibility',
                'yoga',
                'sports',
                'mixed'
              ],
              'description': 'Type of workout',
            },
            'duration_minutes': {
              'type': 'integer',
              'description': 'How long the workout lasted in minutes',
            },
            'perceived_effort': {
              'type': 'integer',
              'description': 'RPE (Rate of Perceived Exertion) 1-10',
            },
            'notes': {
              'type': 'string',
              'description': 'Any additional notes about the workout',
            },
          },
          'required': ['name'],
        },
      ),
      ToolDefinition(
        name: 'log_meal',
        description:
            'Log a meal or food intake. Use when user mentions eating, food, breakfast, lunch, dinner, snacks.',
        parameters: {
          'type': 'object',
          'properties': {
            'description': {
              'type': 'string',
              'description': 'What the user ate (e.g., "Chicken and rice")',
            },
            'type': {
              'type': 'string',
              'enum': [
                'breakfast',
                'lunch',
                'dinner',
                'snack',
                'preworkout',
                'postworkout',
                'other'
              ],
              'description': 'Type of meal',
            },
            'calories': {
              'type': 'integer',
              'description': 'Estimated calories (if known)',
            },
            'protein_grams': {
              'type': 'integer',
              'description': 'Estimated protein in grams (if known)',
            },
            'quality': {
              'type': 'string',
              'enum': ['poor', 'fair', 'good', 'excellent'],
              'description': 'Overall meal quality',
            },
          },
          'required': ['description'],
        },
      ),
      ToolDefinition(
        name: 'log_supplement',
        description:
            'Log a supplement dose taken. Use when user mentions taking supplements, vitamins, medications.',
        parameters: {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'Name of the supplement (e.g., "Vitamin D")',
            },
            'dosage': {
              'type': 'string',
              'description': 'Dosage taken (e.g., "5000 IU", "5g")',
            },
            'notes': {
              'type': 'string',
              'description': 'Any additional notes',
            },
          },
          'required': ['name'],
        },
      ),
      ToolDefinition(
        name: 'get_workouts',
        description:
            'Get recent workout history. Use when user asks about workout history or progress.',
        parameters: {
          'type': 'object',
          'properties': {
            'days': {
              'type': 'integer',
              'description': 'Number of days to look back (default: 7)',
            },
            'limit': {
              'type': 'integer',
              'description':
                  'Maximum number of workouts to return (default: 10)',
            },
          },
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'get_meals',
        description:
            'Get recent meal history. Use when user asks about what they ate or nutrition.',
        parameters: {
          'type': 'object',
          'properties': {
            'days': {
              'type': 'integer',
              'description': 'Number of days to look back (default: 7)',
            },
            'limit': {
              'type': 'integer',
              'description': 'Maximum number of meals to return (default: 20)',
            },
          },
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'get_health_data',
        description:
            'Get health data from HealthKit (Apple Health). Includes steps, heart rate, sleep, workouts.',
        parameters: {
          'type': 'object',
          'properties': {
            'type': {
              'type': 'string',
              'enum': ['summary', 'sleep', 'workouts', 'heart_rate', 'steps'],
              'description':
                  'Type of health data to retrieve (default: summary)',
            },
          },
          'required': [],
        },
      ),
    ];
  }

  // ===========================================================================
  // MIND TOOLS (Definitions)
  // ===========================================================================

  List<ToolDefinition> _getMindTools() {
    return [
      ToolDefinition(
        name: 'log_mood',
        description:
            'Log current mood or emotional state. Use when user shares how they\'re feeling.',
        parameters: {
          'type': 'object',
          'properties': {
            'mood': {
              'type': 'string',
              'enum': [
                'happy',
                'calm',
                'grateful',
                'energized',
                'focused',
                'confident',
                'excited',
                'peaceful',
                'neutral',
                'tired',
                'anxious',
                'sad',
                'frustrated',
                'stressed',
                'angry',
                'overwhelmed',
                'lonely',
                'bored'
              ],
              'description': 'The mood to log',
            },
            'intensity': {
              'type': 'integer',
              'description': 'Intensity 1-10 (default: 5)',
            },
            'notes': {
              'type': 'string',
              'description': 'Additional context',
            },
          },
          'required': ['mood'],
        },
      ),
      ToolDefinition(
        name: 'log_meditation',
        description: 'Log a meditation or mindfulness session.',
        parameters: {
          'type': 'object',
          'properties': {
            'duration_minutes': {
              'type': 'integer',
              'description': 'How long the session lasted',
            },
            'type': {
              'type': 'string',
              'enum': [
                'mindfulness',
                'breathing',
                'bodyScan',
                'lovingKindness',
                'visualization',
                'mantra',
                'transcendental',
                'yoga',
                'walking',
                'other'
              ],
              'description': 'Type of meditation',
            },
            'notes': {
              'type': 'string',
              'description': 'Any insights or notes',
            },
          },
          'required': ['duration_minutes'],
        },
      ),
      ToolDefinition(
        name: 'add_journal_entry',
        description:
            'Create a journal entry to capture thoughts or reflections.',
        parameters: {
          'type': 'object',
          'properties': {
            'content': {
              'type': 'string',
              'description': 'The journal entry content',
            },
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Tags for categorization',
            },
          },
          'required': ['content'],
        },
      ),
      ToolDefinition(
        name: 'get_journal',
        description:
            'Get recent journal entries. Use when user wants to review past reflections.',
        parameters: {
          'type': 'object',
          'properties': {
            'days': {
              'type': 'integer',
              'description': 'Number of days to look back (default: 7)',
            },
            'limit': {
              'type': 'integer',
              'description': 'Maximum entries to return (default: 10)',
            },
          },
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'get_mood_history',
        description: 'Get mood history to analyze patterns.',
        parameters: {
          'type': 'object',
          'properties': {
            'days': {
              'type': 'integer',
              'description': 'Number of days to look back (default: 7)',
            },
          },
          'required': [],
        },
      ),
    ];
  }

  // ===========================================================================
  // SPIRIT TOOLS (Definitions)
  // ===========================================================================

  List<ToolDefinition> _getSpiritTools() {
    return [
      ToolDefinition(
        name: 'log_habit',
        description:
            'Log completion of a habit. Use when user mentions completing a daily habit.',
        parameters: {
          'type': 'object',
          'properties': {
            'habit_name': {
              'type': 'string',
              'description': 'Name of the habit',
            },
            'completed': {
              'type': 'boolean',
              'description': 'Whether the habit was completed (default: true)',
            },
            'notes': {
              'type': 'string',
              'description': 'Any notes about the completion',
            },
          },
          'required': ['habit_name'],
        },
      ),
      ToolDefinition(
        name: 'create_habit',
        description:
            'Create a new habit to track. Use when user wants to start tracking a new habit.',
        parameters: {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description':
                  'Name of the habit (e.g., "Cold shower", "Read 30 minutes")',
            },
            'category': {
              'type': 'string',
              'enum': [
                'health',
                'fitness',
                'mindfulness',
                'productivity',
                'learning',
                'social',
                'custom'
              ],
              'description': 'Category of the habit',
            },
            'frequency': {
              'type': 'string',
              'enum': ['daily', 'weekdays', 'weekends', 'weekly', 'custom'],
              'description':
                  'How often the habit should be done (default: daily)',
            },
            'description': {
              'type': 'string',
              'description': 'Description of the habit',
            },
          },
          'required': ['title'],
        },
      ),
      ToolDefinition(
        name: 'add_mantra',
        description: 'Create a new mantra or affirmation.',
        parameters: {
          'type': 'object',
          'properties': {
            'text': {
              'type': 'string',
              'description': 'The mantra or affirmation text',
            },
            'category': {
              'type': 'string',
              'description':
                  'Category (e.g., "morning", "confidence", "abundance")',
            },
          },
          'required': ['text'],
        },
      ),
      ToolDefinition(
        name: 'get_habits',
        description: 'Get all tracked habits and their status.',
        parameters: {
          'type': 'object',
          'properties': {
            'include_completed_today': {
              'type': 'boolean',
              'description': 'Include whether each habit was completed today',
            },
          },
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'get_mantras',
        description: 'Get saved mantras and affirmations.',
        parameters: {
          'type': 'object',
          'properties': {
            'limit': {
              'type': 'integer',
              'description': 'Maximum mantras to return (default: 10)',
            },
          },
          'required': [],
        },
      ),
    ];
  }

  // ===========================================================================
  // BONDS TOOLS (Definitions) - Relationships/Contacts
  // ===========================================================================

  List<ToolDefinition> _getBondsTools() {
    return [
      ToolDefinition(
        name: 'add_contact',
        description:
            'Add a person to track for relationship maintenance. Use when user wants to track staying in touch with someone.',
        parameters: {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'Name of the person',
            },
            'relationship': {
              'type': 'string',
              'enum': [
                'family',
                'friend',
                'colleague',
                'mentor',
                'mentee',
                'partner',
                'client',
                'acquaintance',
                'other'
              ],
              'description': 'Type of relationship',
            },
            'contact_frequency_days': {
              'type': 'integer',
              'description': 'How often to reach out (in days, default: 30)',
            },
            'priority': {
              'type': 'integer',
              'description':
                  'Priority 1-5, where 5 is most important (default: 3)',
            },
            'notes': {
              'type': 'string',
              'description': 'Notes about the person',
            },
            'birthday': {
              'type': 'string',
              'description': 'Birthday in YYYY-MM-DD format (optional)',
            },
          },
          'required': ['name'],
        },
      ),
      ToolDefinition(
        name: 'get_contacts',
        description: 'Get contacts/relationships being tracked.',
        parameters: {
          'type': 'object',
          'properties': {
            'relationship': {
              'type': 'string',
              'enum': [
                'family',
                'friend',
                'colleague',
                'mentor',
                'mentee',
                'partner',
                'client',
                'acquaintance',
                'other'
              ],
              'description': 'Filter by relationship type',
            },
          },
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'log_interaction',
        description:
            'Log that user reached out to or connected with a contact.',
        parameters: {
          'type': 'object',
          'properties': {
            'contact_name': {
              'type': 'string',
              'description': 'Name of the contact',
            },
            'notes': {
              'type': 'string',
              'description': 'Notes about the interaction',
            },
          },
          'required': ['contact_name'],
        },
      ),
      ToolDefinition(
        name: 'get_overdue_contacts',
        description: 'Get contacts that are overdue for reaching out.',
        parameters: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),
    ];
  }

  // ===========================================================================
  // WEALTH TOOLS (Definitions)
  // ===========================================================================

  List<ToolDefinition> _getWealthTools() {
    return [
      ToolDefinition(
        name: 'add_bill',
        description:
            'Add a recurring bill to track (rent, utilities, insurance, etc.)',
        parameters: {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'Name of the bill (e.g., "Rent", "Electric")',
            },
            'amount': {
              'type': 'number',
              'description': 'Amount in dollars',
            },
            'due_day': {
              'type': 'integer',
              'description': 'Day of month when bill is due (1-31)',
            },
            'frequency': {
              'type': 'string',
              'enum': ['weekly', 'monthly', 'quarterly', 'yearly'],
              'description': 'How often the bill recurs',
            },
          },
          'required': ['name', 'amount'],
        },
      ),
      ToolDefinition(
        name: 'add_subscription',
        description:
            'Add a subscription to track (Netflix, gym, software, etc.)',
        parameters: {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'Name of the subscription',
            },
            'amount': {
              'type': 'number',
              'description': 'Amount in dollars',
            },
            'frequency': {
              'type': 'string',
              'enum': ['weekly', 'monthly', 'yearly'],
              'description': 'Billing frequency',
            },
          },
          'required': ['name', 'amount'],
        },
      ),
      ToolDefinition(
        name: 'add_income',
        description:
            'Add an income source to track (salary, freelance, investments, etc.)',
        parameters: {
          'type': 'object',
          'properties': {
            'source': {
              'type': 'string',
              'description': 'Name/source of income',
            },
            'amount': {
              'type': 'number',
              'description': 'Amount in dollars',
            },
            'frequency': {
              'type': 'string',
              'enum': ['weekly', 'biweekly', 'monthly', 'yearly', 'oneTime'],
              'description': 'How often this income is received',
            },
          },
          'required': ['source', 'amount'],
        },
      ),
      ToolDefinition(
        name: 'get_bills',
        description: 'Get tracked bills. Use when user asks about their bills.',
        parameters: {
          'type': 'object',
          'properties': {
            'upcoming_days': {
              'type': 'integer',
              'description': 'Filter to bills due in the next N days',
            },
          },
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'get_subscriptions',
        description: 'Get tracked subscriptions.',
        parameters: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),
    ];
  }

  // ===========================================================================
  // STATUS TOOLS (Definitions)
  // ===========================================================================

  List<ToolDefinition> _getStatusTools() {
    return [
      ToolDefinition(
        name: 'get_user_status',
        description:
            'Get comprehensive status across all domains: Body, Mind, Spirit, Wealth. '
            'Use this to gather context before giving advice.',
        parameters: {
          'type': 'object',
          'properties': {
            'domain': {
              'type': 'string',
              'enum': ['all', 'body', 'mind', 'spirit', 'wealth', 'bonds'],
              'description': 'Which domain to get status for (default: all)',
            },
          },
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'note_pattern',
        description:
            'Record a pattern or insight about the user for the psychograph. Use when user reveals something significant.',
        parameters: {
          'type': 'object',
          'properties': {
            'category': {
              'type': 'string',
              'enum': [
                'habit',
                'trigger',
                'preference',
                'breakthrough',
                'shadow',
                'strength'
              ],
              'description': 'Type of pattern observed',
            },
            'observation': {
              'type': 'string',
              'description': 'The pattern or insight observed',
            },
            'context': {
              'type': 'string',
              'description': 'What prompted this observation',
            },
          },
          'required': ['category', 'observation'],
        },
      ),
    ];
  }

  // ===========================================================================
  // KNOWLEDGE TOOLS (Definitions)
  // ===========================================================================

  List<ToolDefinition> _getKnowledgeTools() {
    return [
      ToolDefinition(
        name: 'search_user_documents',
        description:
            'Search the user\'s knowledge base documents. ALWAYS use when generating personalized content.',
        parameters: {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'Search query - keywords or phrases',
            },
            'document': {
              'type': 'string',
              'enum': [
                'whitepaper',
                'mantras',
                'prime',
                'architecture',
                'master_algorithm',
                'meta_awareness',
                'character_design',
              ],
              'description': 'Optional: specific document to search',
            },
          },
          'required': ['query'],
        },
      ),
    ];
  }

  // ===========================================================================
  // CREATIVE TOOLS (Definitions)
  // ===========================================================================

  List<ToolDefinition> _getCreativeTools() {
    return [
      ToolDefinition(
        name: 'generate_image',
        description:
            'Generate an image using FLUX.2-pro. Use when user asks for visualization, artwork, or images.',
        parameters: {
          'type': 'object',
          'properties': {
            'prompt': {
              'type': 'string',
              'description': 'Detailed description of the image to generate',
            },
            'size': {
              'type': 'string',
              'enum': ['square', 'portrait', 'landscape'],
              'description': 'Image aspect ratio (default: square)',
            },
          },
          'required': ['prompt'],
        },
      ),
    ];
  }

  // ===========================================================================
  // REMINDER TOOLS (Definitions)
  // ===========================================================================

  List<ToolDefinition> _getReminderTools() {
    return [
      ToolDefinition(
        name: 'create_reminder',
        description:
            'Create a reminder for the user. Use when user asks to be reminded about something.',
        parameters: {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'Title of the reminder',
            },
            'message': {
              'type': 'string',
              'description': 'Optional message/details',
            },
            'time': {
              'type': 'string',
              'description':
                  'When to remind (ISO 8601 format or relative like "in 30 minutes", "tomorrow at 9am")',
            },
            'type': {
              'type': 'string',
              'enum': [
                'water',
                'meal',
                'workout',
                'supplement',
                'habit',
                'meditation',
                'custom'
              ],
              'description': 'Type of reminder',
            },
            'repeat': {
              'type': 'string',
              'enum': ['none', 'daily', 'weekdays', 'weekends', 'weekly'],
              'description': 'Repeat pattern (default: none)',
            },
          },
          'required': ['title', 'time'],
        },
      ),
      ToolDefinition(
        name: 'get_reminders',
        description: 'Get upcoming reminders.',
        parameters: {
          'type': 'object',
          'properties': {
            'type': {
              'type': 'string',
              'enum': [
                'water',
                'meal',
                'workout',
                'supplement',
                'habit',
                'meditation',
                'custom'
              ],
              'description': 'Filter by reminder type',
            },
          },
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'delete_reminder',
        description: 'Delete a reminder.',
        parameters: {
          'type': 'object',
          'properties': {
            'id': {
              'type': 'integer',
              'description': 'ID of the reminder to delete',
            },
            'title': {
              'type': 'string',
              'description': 'Title of reminder to delete (if ID not known)',
            },
          },
          'required': [],
        },
      ),
    ];
  }

  // ===========================================================================
  // UTILITY TOOLS (Definitions)
  // ===========================================================================

  List<ToolDefinition> _getUtilityTools() {
    return [
      ToolDefinition(
        name: 'get_weather',
        description: 'Get current weather and forecast for user\'s location.',
        parameters: {
          'type': 'object',
          'properties': {
            'include_forecast': {
              'type': 'boolean',
              'description': 'Include multi-day forecast (default: true)',
            },
          },
          'required': [],
        },
      ),
    ];
  }

  // ===========================================================================
  // TOOL IMPLEMENTATIONS - Body
  // ===========================================================================

  Future<String> _toolLogWorkout(Map<String, dynamic> args) async {
    try {
      final name = args['name'] as String? ?? 'Workout';
      final typeStr = args['type'] as String? ?? 'mixed';
      final duration = args['duration_minutes'] as int? ?? 60;
      final effort = args['perceived_effort'] as int?;
      final notes = args['notes'] as String?;

      final type = WorkoutType.values.firstWhere(
        (t) => t.name.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => WorkoutType.mixed,
      );

      final workout = WorkoutLog(
        name: name,
        type: type,
        startTime: DateTime.now().subtract(Duration(minutes: duration)),
        endTime: DateTime.now(),
        durationMinutes: duration,
        perceivedEffort: effort,
        notes: notes,
      );

      final id = await database.insertWorkoutLog(workout);
      Logger.info('Logged workout via chat: $name (id: $id)', tag: _tag);

      return jsonEncode({
        'success': true,
        'id': id,
        'name': name,
        'type': type.name,
        'duration_minutes': duration,
        'message': 'Workout logged successfully',
      });
    } catch (e) {
      Logger.error('Failed to log workout', tag: _tag, error: e);
      return jsonEncode({'error': 'Failed to log workout: $e'});
    }
  }

  Future<String> _toolLogMeal(Map<String, dynamic> args) async {
    try {
      final description = args['description'] as String? ?? '';
      final typeStr = args['type'] as String? ?? 'other';
      final calories = args['calories'] as int?;
      final protein = args['protein_grams'] as int?;
      final qualityStr = args['quality'] as String?;

      final type = MealType.values.firstWhere(
        (t) => t.name.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => MealType.other,
      );

      MealQuality? quality;
      if (qualityStr != null) {
        quality = MealQuality.values.firstWhere(
          (q) => q.name.toLowerCase() == qualityStr.toLowerCase(),
          orElse: () => MealQuality.good,
        );
      }

      final meal = MealLog(
        description: description,
        type: type,
        timestamp: DateTime.now(),
        calories: calories,
        proteinGrams: protein,
        quality: quality,
      );

      final id = await database.insertMealLog(meal);
      Logger.info('Logged meal via chat: $description (id: $id)', tag: _tag);

      return jsonEncode({
        'success': true,
        'id': id,
        'description': description,
        'type': type.name,
        'message': 'Meal logged successfully',
      });
    } catch (e) {
      Logger.error('Failed to log meal', tag: _tag, error: e);
      return jsonEncode({'error': 'Failed to log meal: $e'});
    }
  }

  Future<String> _toolLogSupplement(Map<String, dynamic> args) async {
    try {
      final name = args['name'] as String? ?? '';
      final dosage = args['dosage'] as String? ?? '';
      final notes = args['notes'] as String?;

      // First check if supplement exists
      final supplements = await database.getSupplements();
      var supplement = supplements
          .where(
            (s) => s.name.toLowerCase() == name.toLowerCase(),
          )
          .firstOrNull;

      // Create supplement if it doesn't exist
      if (supplement == null) {
        final newSupp = Supplement(
          name: name,
          category: SupplementCategory.other,
          defaultDoseMg: _parseDosageToMg(dosage),
        );
        final suppId = await database.insertSupplement(newSupp);
        supplement = newSupp.copyWith(id: suppId);
      }

      // Log the dose
      final dose = DoseLog(
        supplementId: supplement.id!,
        amountMg: _parseDosageToMg(dosage),
        timestamp: DateTime.now(),
        notes: notes,
      );
      final id = await database.insertDoseLog(dose);

      return jsonEncode({
        'success': true,
        'id': id,
        'supplement': name,
        'dosage': dosage,
        'message': 'Supplement dose logged successfully',
      });
    } catch (e) {
      Logger.error('Failed to log supplement', tag: _tag, error: e);
      return jsonEncode({'error': 'Failed to log supplement: $e'});
    }
  }

  Future<String> _toolGetWorkouts(Map<String, dynamic> args) async {
    try {
      final days = args['days'] as int? ?? 7;
      final limit = args['limit'] as int? ?? 10;
      final startDate = DateTime.now().subtract(Duration(days: days));

      final workouts = await database.getWorkoutLogs(
        startDate: startDate,
        limit: limit,
      );

      return jsonEncode({
        'workouts': workouts
            .map((w) => {
                  'id': w.id,
                  'name': w.name ?? w.type.displayName,
                  'type': w.type.name,
                  'duration_minutes': w.durationMinutes,
                  'date': w.startTime.toIso8601String(),
                  'perceived_effort': w.perceivedEffort,
                })
            .toList(),
        'count': workouts.length,
        'days_searched': days,
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to get workouts: $e'});
    }
  }

  Future<String> _toolGetMeals(Map<String, dynamic> args) async {
    try {
      final days = args['days'] as int? ?? 7;
      final limit = args['limit'] as int? ?? 20;
      final startDate = DateTime.now().subtract(Duration(days: days));

      final meals = await database.getMealLogs(
        startDate: startDate,
        limit: limit,
      );

      return jsonEncode({
        'meals': meals
            .map((m) => {
                  'id': m.id,
                  'description': m.description,
                  'type': m.type.name,
                  'calories': m.calories,
                  'protein_grams': m.proteinGrams,
                  'date': m.timestamp.toIso8601String(),
                })
            .toList(),
        'count': meals.length,
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to get meals: $e'});
    }
  }

  Future<String> _toolGetHealthData(Map<String, dynamic> args) async {
    try {
      final type = args['type'] as String? ?? 'summary';

      switch (type) {
        case 'summary':
          final summary = await healthKitService.getTodaySummary();
          return jsonEncode({
            'date': summary.date.toIso8601String(),
            'steps': summary.steps,
            'active_calories': summary.activeCalories,
            'resting_heart_rate': summary.restingHeartRate,
            'average_heart_rate': summary.averageHeartRate,
            'mindful_minutes': summary.mindfulMinutes?.inMinutes,
            'workouts_count': summary.workouts.length,
          });
        case 'sleep':
          final sleep = await healthKitService.getLastNightSleep();
          if (sleep == null) {
            return jsonEncode({'message': 'No sleep data available'});
          }
          return jsonEncode({
            'total_hours': sleep.totalDuration.inMinutes / 60.0,
            'deep_sleep_hours': sleep.deepSleep?.inMinutes != null
                ? sleep.deepSleep!.inMinutes / 60.0
                : null,
            'rem_sleep_hours': sleep.remSleep?.inMinutes != null
                ? sleep.remSleep!.inMinutes / 60.0
                : null,
            'quality_score': sleep.qualityScore,
            'bed_time': sleep.bedTime?.toIso8601String(),
            'wake_time': sleep.wakeTime?.toIso8601String(),
          });
        case 'workouts':
          final workouts = await healthKitService.getTodayWorkouts();
          return jsonEncode({
            'workouts': workouts
                .map((w) => {
                      'type': w.type,
                      'duration_minutes': w.duration.inMinutes,
                      'calories_burned': w.caloriesBurned,
                      'start_time': w.startTime.toIso8601String(),
                    })
                .toList(),
          });
        case 'steps':
          final steps = await healthKitService.getSteps(DateTime.now());
          return jsonEncode({'steps_today': steps});
        case 'heart_rate':
          final resting = await healthKitService.getRestingHeartRate();
          return jsonEncode({'resting_heart_rate': resting});
        default:
          return jsonEncode({'error': 'Unknown health data type: $type'});
      }
    } catch (e) {
      return jsonEncode({'error': 'Failed to get health data: $e'});
    }
  }

  // ===========================================================================
  // TOOL IMPLEMENTATIONS - Mind
  // ===========================================================================

  Future<String> _toolLogMood(Map<String, dynamic> args) async {
    try {
      final moodStr = args['mood'] as String? ?? 'neutral';
      final intensity = args['intensity'] as int? ?? 5;
      final notes = args['notes'] as String?;

      final mood = MoodType.values.firstWhere(
        (m) => m.name.toLowerCase() == moodStr.toLowerCase(),
        orElse: () => MoodType.neutral,
      );

      final entry = MoodEntry(
        userId: 0, // Default user
        mood: mood,
        intensity: intensity.clamp(1, 10),
        timestamp: DateTime.now(),
        notes: notes,
      );

      final id = await database.insertMoodEntry(entry);
      return jsonEncode({
        'success': true,
        'id': id,
        'mood': mood.name,
        'intensity': intensity,
        'message': 'Mood logged successfully',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to log mood: $e'});
    }
  }

  Future<String> _toolLogMeditation(Map<String, dynamic> args) async {
    try {
      final duration = args['duration_minutes'] as int? ?? 10;
      final typeStr = args['type'] as String? ?? 'mindfulness';
      final notes = args['notes'] as String?;

      // Store as journal entry with meditation tag
      final entry = JournalEntry(
        transcription:
            notes ?? 'Meditation session: $duration minutes ($typeStr)',
        timestamp: DateTime.now(),
        tags: ['meditation', typeStr],
      );

      final id = await database.insertJournalEntry(entry);
      return jsonEncode({
        'success': true,
        'id': id,
        'duration_minutes': duration,
        'type': typeStr,
        'message': 'Meditation logged successfully',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to log meditation: $e'});
    }
  }

  Future<String> _toolAddJournalEntry(Map<String, dynamic> args) async {
    try {
      final content = args['content'] as String? ?? '';
      final tags = (args['tags'] as List?)?.cast<String>() ?? [];

      final entry = JournalEntry(
        transcription: content,
        timestamp: DateTime.now(),
        tags: tags,
      );

      final id = await database.insertJournalEntry(entry);
      return jsonEncode({
        'success': true,
        'id': id,
        'message': 'Journal entry saved',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to add journal entry: $e'});
    }
  }

  Future<String> _toolGetJournal(Map<String, dynamic> args) async {
    try {
      final days = args['days'] as int? ?? 7;
      final limit = args['limit'] as int? ?? 10;
      final startDate = DateTime.now().subtract(Duration(days: days));

      final entries = await database.getJournalEntries(
        startDate: startDate,
        limit: limit,
      );

      return jsonEncode({
        'entries': entries
            .map((e) => {
                  'id': e.id,
                  'content': e.transcription.length > 200
                      ? '${e.transcription.substring(0, 200)}...'
                      : e.transcription,
                  'tags': e.tags,
                  'date': e.timestamp.toIso8601String(),
                })
            .toList(),
        'count': entries.length,
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to get journal: $e'});
    }
  }

  Future<String> _toolGetMoodHistory(Map<String, dynamic> args) async {
    try {
      final days = args['days'] as int? ?? 7;
      final startDate = DateTime.now().subtract(Duration(days: days));

      final moods = await database.getMoodEntries(
        startDate: startDate,
        limit: 50,
      );

      // Calculate mood distribution
      final moodCounts = <String, int>{};
      for (final entry in moods) {
        moodCounts[entry.mood.name] = (moodCounts[entry.mood.name] ?? 0) + 1;
      }

      return jsonEncode({
        'entries': moods
            .map((m) => {
                  'mood': m.mood.name,
                  'intensity': m.intensity,
                  'date': m.timestamp.toIso8601String(),
                })
            .toList(),
        'mood_distribution': moodCounts,
        'total_entries': moods.length,
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to get mood history: $e'});
    }
  }

  // ===========================================================================
  // TOOL IMPLEMENTATIONS - Spirit
  // ===========================================================================

  Future<String> _toolLogHabit(Map<String, dynamic> args) async {
    try {
      final habitName = args['habit_name'] as String? ?? '';
      final completed = args['completed'] as bool? ?? true;
      final notes = args['notes'] as String?;

      // Find or create habit
      final habits = await database.getHabits();
      var habit = habits
          .where(
            (h) => h.title.toLowerCase() == habitName.toLowerCase(),
          )
          .firstOrNull;

      if (habit == null) {
        // Create the habit
        final newHabit = Habit(
          userId: 0,
          title: habitName,
          category: HabitCategory.custom,
        );
        final id = await database.insertHabit(newHabit);
        habit = newHabit.copyWith(id: id);
      }

      // Log the completion
      final log = HabitLog(
        habitId: habit.id!,
        date: DateTime.now(),
        isCompleted: completed,
        notes: notes,
      );
      final logId = await database.insertHabitLog(log);

      return jsonEncode({
        'success': true,
        'habit': habit.title,
        'completed': completed,
        'log_id': logId,
        'message': completed
            ? 'Nice! Habit marked as complete.'
            : 'Habit logged as not completed today.',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to log habit: $e'});
    }
  }

  Future<String> _toolCreateHabit(Map<String, dynamic> args) async {
    try {
      final title = args['title'] as String? ?? '';
      final categoryStr = args['category'] as String? ?? 'custom';
      final frequencyStr = args['frequency'] as String? ?? 'daily';
      final description = args['description'] as String?;

      final category = HabitCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == categoryStr.toLowerCase(),
        orElse: () => HabitCategory.custom,
      );

      final frequency = HabitFrequency.values.firstWhere(
        (f) => f.name.toLowerCase() == frequencyStr.toLowerCase(),
        orElse: () => HabitFrequency.daily,
      );

      final habit = Habit(
        userId: 0,
        title: title,
        description: description,
        category: category,
        frequency: frequency,
      );

      final id = await database.insertHabit(habit);
      return jsonEncode({
        'success': true,
        'id': id,
        'title': title,
        'category': category.name,
        'frequency': frequency.name,
        'message': 'Habit created successfully!',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to create habit: $e'});
    }
  }

  Future<String> _toolAddMantra(Map<String, dynamic> args) async {
    try {
      final text = args['text'] as String? ?? '';
      final category = args['category'] as String?;

      final mantra = Mantra(
        text: text,
        category: category,
      );

      final id = await database.insertMantra(mantra);
      return jsonEncode({
        'success': true,
        'id': id,
        'text': text,
        'message': 'Mantra saved!',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to add mantra: $e'});
    }
  }

  Future<String> _toolGetHabits(Map<String, dynamic> args) async {
    try {
      final includeStatus = args['include_completed_today'] as bool? ?? true;
      final habits = await database.getHabits();

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final habitData = <Map<String, dynamic>>[];
      for (final habit in habits) {
        Map<String, dynamic> data = {
          'id': habit.id,
          'title': habit.title,
          'category': habit.category.name,
          'frequency': habit.frequency.name,
        };

        if (includeStatus) {
          final logs = await database.getHabitLogs(
            habitId: habit.id,
            startDate: todayStart,
            endDate: todayEnd,
          );
          data['completed_today'] = logs.any((l) => l.isCompleted);
        }

        habitData.add(data);
      }

      return jsonEncode({
        'habits': habitData,
        'count': habits.length,
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to get habits: $e'});
    }
  }

  Future<String> _toolGetMantras(Map<String, dynamic> args) async {
    try {
      final limit = args['limit'] as int? ?? 10;
      final mantras = await database.getMantras();

      return jsonEncode({
        'mantras': mantras
            .take(limit)
            .map((m) => {
                  'id': m.id,
                  'text': m.text,
                  'category': m.category,
                })
            .toList(),
        'count': mantras.length,
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to get mantras: $e'});
    }
  }

  // ===========================================================================
  // TOOL IMPLEMENTATIONS - Bonds
  // ===========================================================================

  Future<String> _toolAddContact(Map<String, dynamic> args) async {
    try {
      final name = args['name'] as String? ?? '';
      final relationshipStr = args['relationship'] as String? ?? 'friend';
      final frequency = args['contact_frequency_days'] as int? ?? 30;
      final priority = args['priority'] as int? ?? 3;
      final notes = args['notes'] as String?;
      final birthdayStr = args['birthday'] as String?;

      final relationship = RelationshipType.values.firstWhere(
        (r) => r.name.toLowerCase() == relationshipStr.toLowerCase(),
        orElse: () => RelationshipType.friend,
      );

      DateTime? birthday;
      if (birthdayStr != null) {
        birthday = DateTime.tryParse(birthdayStr);
      }

      final contact = Contact(
        name: name,
        relationship: relationship,
        contactFrequencyDays: frequency,
        priority: priority.clamp(1, 5),
        notes: notes,
        birthday: birthday,
      );

      final id = await database.insertContact(contact);
      return jsonEncode({
        'success': true,
        'id': id,
        'name': name,
        'relationship': relationship.name,
        'message': 'Contact added! I\'ll help you stay in touch.',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to add contact: $e'});
    }
  }

  Future<String> _toolGetContacts(Map<String, dynamic> args) async {
    try {
      final relationshipStr = args['relationship'] as String?;

      List<Contact> contacts;
      if (relationshipStr != null) {
        final relationship = RelationshipType.values.firstWhere(
          (r) => r.name.toLowerCase() == relationshipStr.toLowerCase(),
          orElse: () => RelationshipType.friend,
        );
        contacts = await database.getContactsByRelationship(relationship);
      } else {
        contacts = await database.getContacts();
      }

      return jsonEncode({
        'contacts': contacts
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'relationship': c.relationship.name,
                  'priority': c.priority,
                  'days_since_contact': c.daysSinceContact,
                  'is_overdue': c.isOverdue,
                })
            .toList(),
        'count': contacts.length,
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to get contacts: $e'});
    }
  }

  Future<String> _toolLogInteraction(Map<String, dynamic> args) async {
    try {
      final contactName = args['contact_name'] as String? ?? '';

      // Find contact
      final contacts = await database.getContacts();
      final contact = contacts
          .where(
            (c) => c.name.toLowerCase().contains(contactName.toLowerCase()),
          )
          .firstOrNull;

      if (contact == null) {
        return jsonEncode({'error': 'Contact not found: $contactName'});
      }

      await database.updateContactLastContact(contact.id!, DateTime.now());
      return jsonEncode({
        'success': true,
        'contact': contact.name,
        'message': 'Great job staying connected with ${contact.name}!',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to log interaction: $e'});
    }
  }

  Future<String> _toolGetOverdueContacts(Map<String, dynamic> args) async {
    try {
      final contacts = await database.getOverdueContacts();

      return jsonEncode({
        'overdue_contacts': contacts
            .map((c) => {
                  'name': c.name,
                  'relationship': c.relationship.name,
                  'days_overdue': c.daysSinceContact != null
                      ? c.daysSinceContact! - c.contactFrequencyDays
                      : null,
                  'priority': c.priority,
                })
            .toList(),
        'count': contacts.length,
        'message': contacts.isEmpty
            ? 'No overdue contacts - you\'re doing great!'
            : '${contacts.length} contacts are overdue for reaching out.',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to get overdue contacts: $e'});
    }
  }

  // ===========================================================================
  // TOOL IMPLEMENTATIONS - Wealth
  // ===========================================================================

  Future<String> _toolAddBill(Map<String, dynamic> args) async {
    try {
      final name = args['name'] as String? ?? '';
      final amount = (args['amount'] as num?)?.toDouble() ?? 0;
      final dueDay = args['due_day'] as int?;
      final frequencyStr = args['frequency'] as String? ?? 'monthly';

      final frequency = _parseBillFrequency(frequencyStr);
      final category = _guessBillCategory(name);

      final bill = Bill(
        name: name,
        amount: amount,
        dueDay: dueDay ?? 1,
        frequency: frequency,
        category: category,
      );

      final id = await database.insertBill(bill);
      return jsonEncode({
        'success': true,
        'id': id,
        'name': name,
        'amount': amount,
        'message': 'Bill added!',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to add bill: $e'});
    }
  }

  Future<String> _toolAddSubscription(Map<String, dynamic> args) async {
    try {
      final name = args['name'] as String? ?? '';
      final amount = (args['amount'] as num?)?.toDouble() ?? 0;
      final frequencyStr = args['frequency'] as String? ?? 'monthly';

      final frequency = _parseSubscriptionFrequency(frequencyStr);
      final category = _guessSubscriptionCategory(name);

      final subscription = Subscription(
        name: name,
        amount: amount,
        frequency: frequency,
        category: category,
        startDate: DateTime.now(),
      );

      final id = await database.insertSubscription(subscription);
      return jsonEncode({
        'success': true,
        'id': id,
        'name': name,
        'amount': amount,
        'message': 'Subscription added!',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to add subscription: $e'});
    }
  }

  Future<String> _toolAddIncome(Map<String, dynamic> args) async {
    try {
      final source = args['source'] as String? ?? '';
      final amount = (args['amount'] as num?)?.toDouble() ?? 0;
      final frequencyStr = args['frequency'] as String? ?? 'monthly';

      final frequency = _parseIncomeFrequency(frequencyStr);
      final type = _guessIncomeType(source);

      final income = Income(
        source: source,
        amount: amount,
        frequency: frequency,
        type: type,
      );

      final id = await database.insertIncome(income);
      return jsonEncode({
        'success': true,
        'id': id,
        'source': source,
        'amount': amount,
        'message': 'Income added!',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to add income: $e'});
    }
  }

  Future<String> _toolGetBills(Map<String, dynamic> args) async {
    try {
      final upcomingDays = args['upcoming_days'] as int?;

      List<Bill> bills;
      if (upcomingDays != null) {
        bills = await database.getBillsDueSoon(upcomingDays);
      } else {
        bills = await database.getBills();
      }

      final totalMonthly = await database.getTotalMonthlyBills();

      return jsonEncode({
        'bills': bills
            .map((b) => {
                  'id': b.id,
                  'name': b.name,
                  'amount': b.amount,
                  'due_day': b.dueDay,
                  'frequency': b.frequency.name,
                  'category': b.category.name,
                })
            .toList(),
        'count': bills.length,
        'total_monthly': totalMonthly,
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to get bills: $e'});
    }
  }

  Future<String> _toolGetSubscriptions(Map<String, dynamic> args) async {
    try {
      final subscriptions = await database.getSubscriptions();
      final totalMonthly = await database.getTotalMonthlySubscriptions();

      return jsonEncode({
        'subscriptions': subscriptions
            .map((s) => {
                  'id': s.id,
                  'name': s.name,
                  'amount': s.amount,
                  'frequency': s.frequency.name,
                  'category': s.category.name,
                })
            .toList(),
        'count': subscriptions.length,
        'total_monthly': totalMonthly,
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to get subscriptions: $e'});
    }
  }

  // ===========================================================================
  // TOOL IMPLEMENTATIONS - Status
  // ===========================================================================

  Future<String> _toolGetUserStatus(Map<String, dynamic> args) async {
    final domain = args['domain'] as String? ?? 'all';

    try {
      final status = <String, dynamic>{};

      if (domain == 'all' || domain == 'body') {
        final recentWorkouts = await database.getWorkoutLogs(limit: 5);
        final recentMeals = await database.getMealLogs(limit: 5);

        status['body'] = {
          'recent_workouts': recentWorkouts
              .map((w) => {
                    'name': w.name ?? w.type.displayName,
                    'type': w.type.name,
                    'duration_minutes': w.durationMinutes,
                    'date': w.startTime.toIso8601String(),
                  })
              .toList(),
          'recent_meals': recentMeals
              .map((m) => {
                    'description': m.description,
                    'type': m.type.name,
                    'calories': m.calories,
                    'date': m.timestamp.toIso8601String(),
                  })
              .toList(),
        };
      }

      if (domain == 'all' || domain == 'mind') {
        final recentMoods = await database.getMoodEntries(limit: 5);
        status['mind'] = {
          'recent_moods': recentMoods
              .map((m) => {
                    'mood': m.mood.name,
                    'intensity': m.intensity,
                    'date': m.timestamp.toIso8601String(),
                  })
              .toList(),
          'current_mood':
              recentMoods.isNotEmpty ? recentMoods.first.mood.name : null,
        };
      }

      if (domain == 'all' || domain == 'spirit') {
        final habits = await database.getHabits();
        status['spirit'] = {
          'habits': habits
              .map((h) => {
                    'title': h.title,
                    'category': h.category.name,
                  })
              .toList(),
          'habit_count': habits.length,
        };
      }

      if (domain == 'all' || domain == 'bonds') {
        final overdueContacts = await database.getOverdueContacts();
        status['bonds'] = {
          'overdue_contacts': overdueContacts
              .map((c) => {
                    'name': c.name,
                    'relationship': c.relationship.name,
                  })
              .toList(),
          'overdue_count': overdueContacts.length,
        };
      }

      if (domain == 'all' || domain == 'wealth') {
        final totalBills = await database.getTotalMonthlyBills();
        final totalSubs = await database.getTotalMonthlySubscriptions();
        final totalIncome = await database.getTotalMonthlyIncome();

        status['wealth'] = {
          'monthly_bills': totalBills,
          'monthly_subscriptions': totalSubs,
          'monthly_income': totalIncome,
          'monthly_net': totalIncome - totalBills - totalSubs,
        };
      }

      return jsonEncode(status);
    } catch (e) {
      return jsonEncode({'error': 'Failed to get user status: $e'});
    }
  }

  Future<String> _toolNotePattern(Map<String, dynamic> args) async {
    try {
      final category = args['category'] as String? ?? 'habit';
      final observation = args['observation'] as String? ?? '';
      final context = args['context'] as String?;

      final pattern = PsychographPattern(
        category: category,
        observation: observation,
        context: context,
      );
      await database.insertPsychographPattern(pattern);

      return jsonEncode({
        'success': true,
        'category': category,
        'message': 'Pattern noted for psychograph',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to note pattern: $e'});
    }
  }

  // ===========================================================================
  // TOOL IMPLEMENTATIONS - Knowledge
  // ===========================================================================

  String _toolSearchDocuments(Map<String, dynamic> args) {
    final query = args['query'] as String? ?? '';
    final document = args['document'] as String?;

    if (query.isEmpty) {
      return jsonEncode({'error': 'Query is required'});
    }

    return userContextService.searchDocuments(query, documentName: document);
  }

  // ===========================================================================
  // TOOL IMPLEMENTATIONS - Creative
  // ===========================================================================

  Future<String> _toolGenerateImage(Map<String, dynamic> args) async {
    try {
      final prompt = args['prompt'] as String? ?? '';
      final sizeStr = args['size'] as String? ?? 'square';

      if (prompt.isEmpty) {
        return jsonEncode({'error': 'Prompt is required'});
      }

      ImageSize size;
      switch (sizeStr) {
        case 'portrait':
          size = ImageSize.portrait;
          break;
        case 'landscape':
          size = ImageSize.landscape;
          break;
        default:
          size = ImageSize.square;
      }

      final result = await imageService.generateImage(
        prompt: prompt,
        size: size,
      );

      // Result is returned if successful (throws on error)
      return jsonEncode({
        'success': true,
        'image_base64': result.imageData,
        'prompt': prompt,
        'message': 'Image generated successfully',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to generate image: $e'});
    }
  }

  // ===========================================================================
  // TOOL IMPLEMENTATIONS - Reminders
  // ===========================================================================

  Future<String> _toolCreateReminder(Map<String, dynamic> args) async {
    try {
      final title = args['title'] as String? ?? '';
      final message = args['message'] as String?;
      final timeStr = args['time'] as String? ?? '';
      final typeStr = args['type'] as String? ?? 'custom';
      final repeatStr = args['repeat'] as String? ?? 'none';

      // Parse time
      DateTime? scheduledTime = _parseReminderTime(timeStr);
      if (scheduledTime == null) {
        return jsonEncode({'error': 'Could not parse time: $timeStr'});
      }

      final type = ReminderType.values.firstWhere(
        (t) => t.name.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => ReminderType.custom,
      );

      final repeat = RepeatPattern.values.firstWhere(
        (r) => r.name.toLowerCase() == repeatStr.toLowerCase(),
        orElse: () => RepeatPattern.none,
      );

      final reminder = SmartReminder(
        type: type,
        title: title,
        message: message,
        scheduledTime: scheduledTime,
        repeatPattern: repeat,
        isSmart: true,
      );

      final id = await reminderService.createReminder(reminder);
      return jsonEncode({
        'success': true,
        'id': id,
        'title': title,
        'scheduled_time': scheduledTime.toIso8601String(),
        'message': 'Reminder set!',
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to create reminder: $e'});
    }
  }

  Future<String> _toolGetReminders(Map<String, dynamic> args) async {
    try {
      final typeStr = args['type'] as String?;

      List<SmartReminder> reminders;
      if (typeStr != null) {
        final type = ReminderType.values.firstWhere(
          (t) => t.name.toLowerCase() == typeStr.toLowerCase(),
          orElse: () => ReminderType.custom,
        );
        reminders = await reminderService.getRemindersByType(type);
      } else {
        reminders = await reminderService.getUpcomingReminders();
      }

      return jsonEncode({
        'reminders': reminders
            .map((r) => {
                  'id': r.id,
                  'title': r.title,
                  'type': r.type.name,
                  'scheduled_time': r.scheduledTime?.toIso8601String(),
                  'repeat': r.repeatPattern.name,
                })
            .toList(),
        'count': reminders.length,
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to get reminders: $e'});
    }
  }

  Future<String> _toolDeleteReminder(Map<String, dynamic> args) async {
    try {
      final id = args['id'] as int?;
      final title = args['title'] as String?;

      if (id != null) {
        await reminderService.deleteReminder(id);
        return jsonEncode({
          'success': true,
          'message': 'Reminder deleted',
        });
      } else if (title != null) {
        final reminders = await reminderService.getAllReminders();
        final match = reminders
            .where(
              (r) => r.title.toLowerCase().contains(title.toLowerCase()),
            )
            .firstOrNull;

        if (match != null && match.id != null) {
          await reminderService.deleteReminder(match.id!);
          return jsonEncode({
            'success': true,
            'message': 'Reminder "${match.title}" deleted',
          });
        }
        return jsonEncode({'error': 'Reminder not found: $title'});
      }

      return jsonEncode({'error': 'Provide id or title to delete reminder'});
    } catch (e) {
      return jsonEncode({'error': 'Failed to delete reminder: $e'});
    }
  }

  // ===========================================================================
  // TOOL IMPLEMENTATIONS - Utility
  // ===========================================================================

  Future<String> _toolGetWeather(Map<String, dynamic> args) async {
    try {
      final includeForecast = args['include_forecast'] as bool? ?? true;

      final current = await weatherService.getCurrentWeather();
      if (current == null) {
        return jsonEncode({'error': 'Could not get weather data'});
      }

      final result = <String, dynamic>{
        'current': {
          'temperature': current.temperature,
          'feels_like': current.feelsLike,
          'condition': current.condition,
          'humidity': current.humidity,
          'uv_index': current.uvIndex,
        },
      };

      if (includeForecast) {
        final forecast = await weatherService.getDailyForecast(days: 3);
        result['forecast'] = forecast
            .map((f) => {
                  'date': f.date.toIso8601String(),
                  'high': f.highTemp,
                  'low': f.lowTemp,
                  'condition': f.condition,
                })
            .toList();
      }

      return jsonEncode(result);
    } catch (e) {
      return jsonEncode({'error': 'Failed to get weather: $e'});
    }
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  double _parseDosageToMg(String dosage) {
    final cleaned = dosage.toLowerCase().replaceAll(RegExp(r'[^\d.]'), '');
    final value = double.tryParse(cleaned) ?? 0;

    if (dosage.toLowerCase().contains('g') &&
        !dosage.toLowerCase().contains('mg')) {
      return value * 1000; // Convert grams to mg
    }
    return value;
  }

  DateTime? _parseReminderTime(String timeStr) {
    // Try ISO 8601 first
    final parsed = DateTime.tryParse(timeStr);
    if (parsed != null) return parsed;

    final now = DateTime.now();
    final lower = timeStr.toLowerCase();

    // Handle relative times
    if (lower.contains('in ')) {
      final match = RegExp(r'in (\d+) (minute|hour|day)').firstMatch(lower);
      if (match != null) {
        final amount = int.parse(match.group(1)!);
        final unit = match.group(2)!;
        switch (unit) {
          case 'minute':
            return now.add(Duration(minutes: amount));
          case 'hour':
            return now.add(Duration(hours: amount));
          case 'day':
            return now.add(Duration(days: amount));
        }
      }
    }

    // Handle "tomorrow at X"
    if (lower.contains('tomorrow')) {
      final hourMatch =
          RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?').firstMatch(lower);
      if (hourMatch != null) {
        var hour = int.parse(hourMatch.group(1)!);
        final minute =
            hourMatch.group(2) != null ? int.parse(hourMatch.group(2)!) : 0;
        final ampm = hourMatch.group(3);

        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;

        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(
            tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
      }
    }

    // Handle "at X" for today
    if (lower.contains('at ')) {
      final hourMatch =
          RegExp(r'at (\d{1,2})(?::(\d{2}))?\s*(am|pm)?').firstMatch(lower);
      if (hourMatch != null) {
        var hour = int.parse(hourMatch.group(1)!);
        final minute =
            hourMatch.group(2) != null ? int.parse(hourMatch.group(2)!) : 0;
        final ampm = hourMatch.group(3);

        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;

        var result = DateTime(now.year, now.month, now.day, hour, minute);
        // If time has passed today, set for tomorrow
        if (result.isBefore(now)) {
          result = result.add(const Duration(days: 1));
        }
        return result;
      }
    }

    return null;
  }

  BillFrequency _parseBillFrequency(String value) {
    switch (value.toLowerCase()) {
      case 'weekly':
        return BillFrequency.weekly;
      case 'quarterly':
        return BillFrequency.quarterly;
      case 'yearly':
        return BillFrequency.yearly;
      default:
        return BillFrequency.monthly;
    }
  }

  SubscriptionFrequency _parseSubscriptionFrequency(String value) {
    switch (value.toLowerCase()) {
      case 'weekly':
        return SubscriptionFrequency.weekly;
      case 'yearly':
        return SubscriptionFrequency.yearly;
      default:
        return SubscriptionFrequency.monthly;
    }
  }

  IncomeFrequency _parseIncomeFrequency(String value) {
    switch (value.toLowerCase()) {
      case 'weekly':
        return IncomeFrequency.weekly;
      case 'biweekly':
        return IncomeFrequency.biweekly;
      case 'yearly':
        return IncomeFrequency.yearly;
      case 'onetime':
        return IncomeFrequency.oneTime;
      default:
        return IncomeFrequency.monthly;
    }
  }

  BillCategory _guessBillCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rent') || lower.contains('mortgage')) {
      return BillCategory.housing;
    }
    if (lower.contains('electric') ||
        lower.contains('gas') ||
        lower.contains('water') ||
        lower.contains('utilit')) {
      return BillCategory.utilities;
    }
    if (lower.contains('car') || lower.contains('auto')) {
      return BillCategory.transportation;
    }
    if (lower.contains('insurance')) {
      return BillCategory.insurance;
    }
    return BillCategory.other;
  }

  SubscriptionCategory _guessSubscriptionCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('netflix') ||
        lower.contains('hulu') ||
        lower.contains('disney') ||
        lower.contains('spotify')) {
      return SubscriptionCategory.entertainment;
    }
    if (lower.contains('gym') || lower.contains('fitness')) {
      return SubscriptionCategory.health;
    }
    if (lower.contains('cloud') ||
        lower.contains('notion') ||
        lower.contains('github')) {
      return SubscriptionCategory.software;
    }
    return SubscriptionCategory.other;
  }

  IncomeType _guessIncomeType(String source) {
    final lower = source.toLowerCase();
    if (lower.contains('salary') || lower.contains('job')) {
      return IncomeType.salary;
    }
    if (lower.contains('freelance') || lower.contains('contract')) {
      return IncomeType.freelance;
    }
    if (lower.contains('invest') || lower.contains('dividend')) {
      return IncomeType.investment;
    }
    return IncomeType.other;
  }
}
