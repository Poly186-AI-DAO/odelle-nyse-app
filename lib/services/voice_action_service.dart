import 'dart:convert';

import '../config/azure_ai_config.dart';
import '../database/app_database.dart';
import '../models/tracking/dose_log.dart';
import '../models/tracking/meal_log.dart';
import '../models/tracking/supplement.dart';
import '../utils/logger.dart';
import 'azure_agent_service.dart';
import 'user_context_service.dart';

/// VoiceActionService - Processes voice commands and executes actions
///
/// Flow:
/// 1. User speaks → Transcription
/// 2. Transcription → LLM (determine intent)
/// 3. LLM → Execute action (log dose, meal, etc.)
/// 4. Return confirmation for UI card
class VoiceActionService {
  static const String _tag = 'VoiceActionService';

  final AzureAgentService _agentService;
  final UserContextService _userContextService;
  final AppDatabase _database;

  VoiceActionService({
    required AzureAgentService agentService,
    required UserContextService userContextService,
    required AppDatabase database,
  })  : _agentService = agentService,
        _userContextService = userContextService,
        _database = database;

  /// Process a voice command and return an action result
  Future<ActionResult> processVoiceCommand(String transcription) async {
    Logger.info('Processing voice command: "$transcription"', tag: _tag);

    if (transcription.trim().isEmpty) {
      return ActionResult(
        success: false,
        type: ActionType.unknown,
        message: 'No command received',
      );
    }

    try {
      // Get supplements for context
      final supplements = await _database.getSupplements();
      final supplementNames = supplements.map((s) => s.name).join(', ');

      // Ask LLM to determine intent
      final intentResponse = await _agentService.complete(
        prompt: '''
User said: "$transcription"

Available supplements: $supplementNames

Determine the user's intent. Respond with JSON only:
{
  "intent": "log_supplement" | "log_meal" | "get_mantra" | "check_progress" | "unknown",
  "supplement_name": "name if logging supplement",
  "meal_description": "description if logging meal",
  "protein_estimate": number if meal,
  "calories_estimate": number if meal,
  "confidence": 0.0-1.0
}
''',
        systemPrompt:
            'You are an intent classifier. Respond only with valid JSON.',
        deployment: AzureAIDeployment.gpt5Chat,
        temperature: 0.3,
        maxTokens: 300,
      );

      final intent = jsonDecode(intentResponse) as Map<String, dynamic>;
      final intentType = intent['intent'] as String? ?? 'unknown';
      final confidence = (intent['confidence'] as num?)?.toDouble() ?? 0.5;

      Logger.info('Intent: $intentType (confidence: $confidence)', tag: _tag);

      // Execute based on intent
      switch (intentType) {
        case 'log_supplement':
          return await _logSupplement(
            intent['supplement_name'] as String?,
            supplements,
          );

        case 'log_meal':
          return await _logMeal(
            intent['meal_description'] as String?,
            intent['protein_estimate'] as int? ?? 0,
            intent['calories_estimate'] as int? ?? 0,
          );

        case 'get_mantra':
          return await _getRandomMantra();

        case 'check_progress':
          return await _checkProgress();

        default:
          return ActionResult(
            success: false,
            type: ActionType.unknown,
            message:
                "I didn't understand that. Try saying 'log my vitamins' or 'I ate some fruit'.",
          );
      }
    } catch (e, stack) {
      Logger.error('Failed to process voice command: $e',
          tag: _tag, error: e, stackTrace: stack);
      return ActionResult(
        success: false,
        type: ActionType.error,
        message: 'Something went wrong. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Log a supplement dose
  Future<ActionResult> _logSupplement(
    String? supplementName,
    List<Supplement> supplements,
  ) async {
    if (supplementName == null || supplementName.isEmpty) {
      return ActionResult(
        success: false,
        type: ActionType.logSupplement,
        message: 'Which supplement did you take?',
      );
    }

    // Find matching supplement
    final match = supplements.firstWhere(
      (s) => s.name.toLowerCase().contains(supplementName.toLowerCase()),
      orElse: () => supplements.first,
    );

    // Create dose log
    final doseLog = DoseLog(
      supplementId: match.id!,
      timestamp: DateTime.now(),
      amountMg: match.defaultDoseMg,
      unit: match.unit,
      source: DoseSource.manual,
      takenWithFood: match.takeWithFood,
      takenWithFat: match.takeWithFat,
    );

    await _database.insertDoseLog(doseLog);

    Logger.info('Logged dose: ${match.name}', tag: _tag);

    return ActionResult(
      success: true,
      type: ActionType.logSupplement,
      message: 'Logged ${match.name}',
      details: {
        'supplement': match.name,
        'dose': '${match.defaultDoseMg} ${match.unit ?? 'mg'}',
        'time': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log a meal
  Future<ActionResult> _logMeal(
    String? description,
    int proteinGrams,
    int calories,
  ) async {
    if (description == null || description.isEmpty) {
      return ActionResult(
        success: false,
        type: ActionType.logMeal,
        message: 'What did you eat?',
      );
    }

    // Estimate macros if not provided
    final protein =
        proteinGrams > 0 ? proteinGrams : _estimateProtein(description);
    final cals = calories > 0 ? calories : _estimateCalories(description);

    final mealLog = MealLog(
      timestamp: DateTime.now(),
      type: _guessMealType(),
      description: description,
      proteinGrams: protein,
      calories: cals,
      source: MealSource.voice,
    );

    await _database.insertMealLog(mealLog);

    Logger.info('Logged meal: $description', tag: _tag);

    return ActionResult(
      success: true,
      type: ActionType.logMeal,
      message: 'Logged: $description',
      details: {
        'meal': description,
        'protein': '${protein}g protein',
        'calories': '$cals cal',
        'time': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get a random mantra
  Future<ActionResult> _getRandomMantra() async {
    final mantra = await _database.getRandomMantra();

    if (mantra == null) {
      // Fall back to user context
      final mantras = _userContextService.allMantras;
      if (mantras.isEmpty) {
        return ActionResult(
          success: false,
          type: ActionType.getMantra,
          message: 'No mantras available',
        );
      }
      final randomMantra =
          mantras[(DateTime.now().millisecondsSinceEpoch % mantras.length)];
      return ActionResult(
        success: true,
        type: ActionType.getMantra,
        message: randomMantra,
      );
    }

    return ActionResult(
      success: true,
      type: ActionType.getMantra,
      message: mantra.text,
      details: {'category': mantra.category},
    );
  }

  /// Check today's progress
  Future<ActionResult> _checkProgress() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Get today's meals
    final meals =
        await _database.getMealLogs(startDate: todayStart, endDate: todayEnd);
    final totalProtein =
        meals.fold<int>(0, (sum, m) => sum + (m.proteinGrams ?? 0));
    final totalCalories =
        meals.fold<int>(0, (sum, m) => sum + (m.calories ?? 0));

    // Get today's doses
    final doses =
        await _database.getDoseLogs(startDate: todayStart, endDate: todayEnd);

    return ActionResult(
      success: true,
      type: ActionType.checkProgress,
      message: 'Today: ${totalProtein}g protein, ${doses.length} supplements',
      details: {
        'protein_consumed': totalProtein,
        'protein_target': 150,
        'calories': totalCalories,
        'supplements_taken': doses.length,
        'meals_logged': meals.length,
      },
    );
  }

  /// Guess meal type based on time of day
  MealType _guessMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) return MealType.breakfast;
    if (hour < 15) return MealType.lunch;
    if (hour < 18) return MealType.snack;
    return MealType.dinner;
  }

  /// Estimate protein from description
  int _estimateProtein(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('fruit') ||
        lower.contains('apple') ||
        lower.contains('banana')) {
      return 1;
    }
    if (lower.contains('yogurt') || lower.contains('greek')) return 15;
    if (lower.contains('egg')) return 6;
    if (lower.contains('chicken')) return 25;
    if (lower.contains('protein') || lower.contains('shake')) return 30;
    return 5; // Default guess
  }

  /// Estimate calories from description
  int _estimateCalories(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('fruit') || lower.contains('apple')) return 80;
    if (lower.contains('banana')) return 100;
    if (lower.contains('yogurt')) return 150;
    if (lower.contains('egg')) return 70;
    if (lower.contains('shake')) return 200;
    return 100; // Default guess
  }
}

/// Result of a voice action
class ActionResult {
  final bool success;
  final ActionType type;
  final String message;
  final Map<String, dynamic>? details;
  final String? error;

  const ActionResult({
    required this.success,
    required this.type,
    required this.message,
    this.details,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'type': type.name,
        'message': message,
        if (details != null) 'details': details,
        if (error != null) 'error': error,
      };
}

/// Types of actions
enum ActionType {
  logSupplement,
  logMeal,
  getMantra,
  checkProgress,
  unknown,
  error,
}
