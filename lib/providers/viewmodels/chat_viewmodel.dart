import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/azure_ai_config.dart';
import '../../config/odelle_system_prompt.dart';
import '../../database/app_database.dart';
import '../../models/wealth/wealth.dart';
import '../../services/azure_agent_service.dart';
import '../../services/user_context_service.dart';
import '../../utils/logger.dart';
import '../service_providers.dart';

/// Represents a tool call made by the AI (for UI display)
class ToolCallInfo {
  final String name;
  final Map<String, dynamic>? args;
  final String? result;
  final bool isExecuting;

  const ToolCallInfo({
    required this.name,
    this.args,
    this.result,
    this.isExecuting = false,
  });

  ToolCallInfo copyWith({
    String? name,
    Map<String, dynamic>? args,
    String? result,
    bool? isExecuting,
  }) {
    return ToolCallInfo(
      name: name ?? this.name,
      args: args ?? this.args,
      result: result ?? this.result,
      isExecuting: isExecuting ?? this.isExecuting,
    );
  }
}

/// A message in the chat conversation (UI model)
class ChatMessageModel {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final bool isThinking;
  final String? thinkingContent;
  final String? imagePath;
  final Uint8List? pendingImageBytes; // For images not yet saved
  final List<ToolCallInfo>? toolCalls; // Tool calls made during response

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.isThinking = false,
    this.thinkingContent,
    this.imagePath,
    this.pendingImageBytes,
    this.toolCalls,
  });

  bool get hasImage => imagePath != null || pendingImageBytes != null;

  bool get hasToolCalls => toolCalls != null && toolCalls!.isNotEmpty;

  ChatMessageModel copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
    bool? isThinking,
    String? thinkingContent,
    String? imagePath,
    Uint8List? pendingImageBytes,
    List<ToolCallInfo>? toolCalls,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      isThinking: isThinking ?? this.isThinking,
      thinkingContent: thinkingContent ?? this.thinkingContent,
      imagePath: imagePath ?? this.imagePath,
      pendingImageBytes: pendingImageBytes ?? this.pendingImageBytes,
      toolCalls: toolCalls ?? this.toolCalls,
    );
  }
}

/// State for the chat screen
class ChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final String? conversationId;
  final Uint8List? pendingImage;
  final String? pendingImageMimeType;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
    this.conversationId,
    this.pendingImage,
    this.pendingImageMimeType,
  });

  bool get hasPendingImage => pendingImage != null;

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    String? conversationId,
    Uint8List? pendingImage,
    String? pendingImageMimeType,
    bool clearPendingImage = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
      conversationId: conversationId ?? this.conversationId,
      pendingImage:
          clearPendingImage ? null : (pendingImage ?? this.pendingImage),
      pendingImageMimeType: clearPendingImage
          ? null
          : (pendingImageMimeType ?? this.pendingImageMimeType),
    );
  }
}

/// ChatViewModel - Manages chat conversation with the AI
/// Features:
/// - Persists messages to SQLite
/// - Continues last conversation
/// - Properly awaits initialization before first message
/// - Image attachment support
class ChatViewModel extends Notifier<ChatState> {
  static const String _tag = 'ChatViewModel';
  static const _uuid = Uuid();

  AzureAgentService get _agentService => ref.read(azureAgentServiceProvider);
  UserContextService get _userContextService =>
      ref.read(userContextServiceProvider);
  AppDatabase get _database => ref.read(databaseProvider);

  // Conversation history for LLM context (includes system prompt)
  final List<ChatMessage> _conversationHistory = [];

  @override
  ChatState build() {
    // Start async initialization
    _initialize();
    return const ChatState(
      messages: [],
      isInitialized: false,
    );
  }

  /// Initialize conversation - load from DB or start fresh
  Future<void> _initialize() async {
    try {
      Logger.info('Initializing ChatViewModel...', tag: _tag);

      // Load user context first (must complete before we can chat)
      await _userContextService.loadContext();

      // Try to load most recent conversation
      final recentConversation = await _database.getMostRecentConversation();

      if (recentConversation != null) {
        // Load existing conversation
        await _loadConversation(recentConversation.id);
      } else {
        // Start fresh conversation
        await _startNewConversation();
      }

      state = state.copyWith(isInitialized: true);
      Logger.info('ChatViewModel initialized', tag: _tag);
    } catch (e, stack) {
      Logger.error('Failed to initialize ChatViewModel: $e',
          tag: _tag, error: e, stackTrace: stack);
      state = state.copyWith(
        isInitialized: true,
        error: 'Failed to load conversation',
      );
    }
  }

  /// Load an existing conversation from the database
  Future<void> _loadConversation(String conversationId) async {
    Logger.info('Loading conversation: $conversationId', tag: _tag);

    final messages = await _database.getChatMessages(conversationId);

    // Convert DB records to UI models, clearing stale image paths.
    final uiMessages = <ChatMessageModel>[];
    for (final message in messages) {
      if (message.role == 'system') continue;

      String? imagePath = message.imagePath;
      if (imagePath != null) {
        final imageFile = File(imagePath);
        final exists = await imageFile.exists();
        if (!exists) {
          imagePath = null;
          if (message.id != null) {
            await _database.updateChatMessageImagePath(message.id!, null);
          }
        }
      }

      uiMessages.add(ChatMessageModel(
        id: message.id?.toString() ?? _uuid.v4(),
        content: message.content,
        isUser: message.role == 'user',
        timestamp: message.timestamp,
        imagePath: imagePath,
      ));
    }

    // Rebuild LLM conversation history
    _conversationHistory.clear();
    final systemPrompt = await _buildSystemPrompt();
    _conversationHistory.add(ChatMessage.system(systemPrompt));
    for (final message in messages) {
      if (message.role == 'user') {
        _conversationHistory.add(ChatMessage.user(message.content));
      } else if (message.role == 'assistant') {
        _conversationHistory.add(ChatMessage.assistant(message.content));
      }
    }

    state = state.copyWith(
      messages: uiMessages,
      conversationId: conversationId,
    );
  }

  /// Start a new conversation
  Future<void> _startNewConversation() async {
    final conversationId = _uuid.v4();
    final now = DateTime.now();

    // Create conversation in DB
    await _database.createConversation(ChatConversation(
      id: conversationId,
      title: 'Note to Self',
      createdAt: now,
      lastMessageAt: now,
      messageCount: 0,
    ));

    // Initialize LLM history with system prompt
    _conversationHistory.clear();
    final systemPrompt = await _buildSystemPrompt();
    _conversationHistory.add(ChatMessage.system(systemPrompt));

    state = state.copyWith(
      messages: [],
      conversationId: conversationId,
    );

    Logger.info('Started new conversation: $conversationId', tag: _tag);
  }

  /// Build the system prompt with user context
  Future<String> _buildSystemPrompt() async {
    final psychographMemory = await _buildPsychographMemorySection();
    final referenceDocs = _userContextService.getReferenceDocs();
    return '''
${OdelleSystemPrompt.chatMode}

---

## ACTIVE MODE: DIGITAL TWIN CONSCIOUSNESS

You are in proactive agent mode. You have tools. USE THEM.

TOOL USE PHILOSOPHY:
─────────────────────────────────────────
• Don't just discuss — ACT when you can
• Don't ask "should I add this?" — just add it and confirm
• Check data before advising (use get_user_status)
• Update the world model when user shares new info
• If in doubt, use a tool to gather context first

WHEN TO USE TOOLS:
─────────────────────────────────────────
• User mentions money/bills/subscriptions → add_bill, add_subscription, add_income
• User mentions workouts/exercise → log or suggest workout
• User mentions food/eating → estimate and track
• User asks "how am I doing?" → get_user_status first, then respond
• User shares something new about themselves → note_pattern

IMAGE ANALYSIS:
─────────────────────────────────────────
When images are attached, analyze deeply:
• Food photos → Estimate macros (protein, carbs, fat, calories)
• Gym selfies → Note the energy, celebrate the action
• Screenshots → Extract actionable data, offer to track
• Environment → Read the context (home, work, travel)

RESPONSE STYLE:
─────────────────────────────────────────
• Brief and punchy (1-2 paragraphs max)
• Direct — no filler, no over-validation
• Action-oriented — what's the next move?
• Don't greet every time. Just continue.

---

## USER CONTEXT (YOUR WORLD MODEL)
${_userContextService.getQuickContext()}

$referenceDocs

$psychographMemory
''';
  }

  Future<String> _buildPsychographMemorySection() async {
    const limit = 5;
    try {
      final topPatterns =
          await _database.getTopPsychographPatterns(limit: limit);
      final recentPatterns =
          await _database.getRecentPsychographPatterns(limit: limit);

      if (topPatterns.isEmpty && recentPatterns.isEmpty) {
        return '## PSYCHOGRAPH MEMORY\n- No stored patterns yet.';
      }

      final buffer = StringBuffer();
      buffer.writeln('## PSYCHOGRAPH MEMORY');
      if (topPatterns.isNotEmpty) {
        buffer.writeln('Top patterns:');
        for (final pattern in topPatterns) {
          buffer.writeln(
              '- [${pattern.category}] ${_normalizeMemoryText(pattern.observation)} (count: ${pattern.count}, last_seen: ${pattern.lastSeen.toIso8601String()})');
        }
      }
      if (recentPatterns.isNotEmpty) {
        buffer.writeln('Recent patterns:');
        for (final pattern in recentPatterns) {
          final context = _normalizeMemoryText(pattern.context);
          final contextSuffix =
              context.isNotEmpty ? ' (context: $context)' : '';
          buffer.writeln(
              '- [${pattern.category}] ${_normalizeMemoryText(pattern.observation)}$contextSuffix');
        }
      }
      return buffer.toString().trimRight();
    } catch (e) {
      Logger.warning('Failed to load psychograph patterns: $e', tag: _tag);
      return '## PSYCHOGRAPH MEMORY\n- Unable to load stored patterns.';
    }
  }

  String _normalizeMemoryText(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Get all available tools (expanded beyond just wealth)
  List<ToolDefinition> _getTools() {
    return [
      // Wealth/Finance tools
      ..._getWealthTools(),
      // Status/Query tools
      ..._getStatusTools(),
      // Future: Body tracking, Mind tracking, Spirit tracking
    ];
  }

  /// Get tool definitions for wealth tracking
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
              'description':
                  'Name of the bill (e.g., "Rent", "Electric", "Car Insurance")',
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
              'description':
                  'Name of the subscription (e.g., "Netflix", "Gym", "Notion")',
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
              'description':
                  'Name/source of income (e.g., "Salary", "Freelance", "Dividends")',
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
    ];
  }

  /// Get tool definitions for status queries (proactive context gathering)
  List<ToolDefinition> _getStatusTools() {
    return [
      ToolDefinition(
        name: 'get_user_status',
        description:
            'Get current status of user\'s tracking data: bills total, subscriptions, income, and financial health. Use this to gather context before giving advice.',
        parameters: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),
      ToolDefinition(
        name: 'note_pattern',
        description:
            'Record a pattern or insight about the user for the psychograph. Use when user reveals something significant about themselves (habits, triggers, preferences, breakthroughs).',
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

  /// Execute a tool call
  Future<String> _executeTool(String name, Map<String, dynamic>? args) async {
    Logger.info('Executing chat tool: $name', tag: _tag, data: args);
    final safeArgs = args ?? {};

    switch (name) {
      case 'add_bill':
        return await _toolAddBill(safeArgs);
      case 'add_subscription':
        return await _toolAddSubscription(safeArgs);
      case 'add_income':
        return await _toolAddIncome(safeArgs);
      case 'get_user_status':
        return await _toolGetUserStatus();
      case 'note_pattern':
        return await _toolNotePattern(safeArgs);
      default:
        return jsonEncode({'error': 'Unknown tool: $name'});
    }
  }

  /// Get user's current status across all tracked domains
  Future<String> _toolGetUserStatus() async {
    try {
      final bills = await _database.getBills();
      final subscriptions = await _database.getSubscriptions();
      final incomes = await _database.getIncomes();

      // Calculate monthly amounts based on frequency
      double billsToMonthly(Bill b) {
        switch (b.frequency) {
          case BillFrequency.weekly:
            return b.amount * 4.33;
          case BillFrequency.biweekly:
            return b.amount * 2.17;
          case BillFrequency.monthly:
            return b.amount;
          case BillFrequency.quarterly:
            return b.amount / 3;
          case BillFrequency.yearly:
            return b.amount / 12;
          case BillFrequency.custom:
            return b.amount; // Assume monthly for custom
        }
      }

      double subsToMonthly(Subscription s) {
        switch (s.frequency) {
          case SubscriptionFrequency.weekly:
            return s.amount * 4.33;
          case SubscriptionFrequency.monthly:
            return s.amount;
          case SubscriptionFrequency.quarterly:
            return s.amount / 3;
          case SubscriptionFrequency.yearly:
            return s.amount / 12;
        }
      }

      final totalBills =
          bills.fold<double>(0, (sum, b) => sum + billsToMonthly(b));
      final totalSubs =
          subscriptions.fold<double>(0, (sum, s) => sum + subsToMonthly(s));
      final totalIncome =
          incomes.fold<double>(0, (sum, i) => sum + i.monthlyAmount);

      final status = {
        'bills': {
          'count': bills.length,
          'monthly_total': totalBills,
          'items': bills
              .take(5)
              .map((b) => {'name': b.name, 'amount': b.amount})
              .toList(),
        },
        'subscriptions': {
          'count': subscriptions.length,
          'monthly_total': totalSubs,
          'items': subscriptions
              .take(5)
              .map((s) => {'name': s.name, 'amount': s.amount})
              .toList(),
        },
        'income': {
          'count': incomes.length,
          'monthly_total': totalIncome,
          'items': incomes
              .take(5)
              .map((i) => {'source': i.source, 'amount': i.amount})
              .toList(),
        },
        'financial_summary': {
          'monthly_income': totalIncome,
          'monthly_expenses': totalBills + totalSubs,
          'monthly_surplus': totalIncome - totalBills - totalSubs,
        },
      };

      return jsonEncode({'success': true, 'status': status});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// Note a pattern for the user's psychograph
  Future<String> _toolNotePattern(Map<String, dynamic> args) async {
    final category = args['category'] as String?;
    final observation = args['observation'] as String?;
    final context = args['context'] as String?;

    if (category == null || observation == null) {
      return jsonEncode(
          {'success': false, 'error': 'Missing category or observation'});
    }

    final timestamp = DateTime.now();
    try {
      final id = await _database.insertPsychographPattern(
        PsychographPattern(
          category: category,
          observation: observation,
          context: context,
          createdAt: timestamp,
        ),
      );
      Logger.info('Psychograph pattern noted', tag: _tag, data: {
        'id': id,
        'category': category,
        'observation': observation,
        'context': context,
        'timestamp': timestamp.toIso8601String(),
      });

      return jsonEncode({
        'success': true,
        'id': id,
        'message': 'Pattern recorded: [$category] $observation',
        'note': 'This updates my world model of the user.'
      });
    } catch (e) {
      Logger.warning('Failed to save psychograph pattern: $e', tag: _tag);
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  Future<String> _toolAddBill(Map<String, dynamic> args) async {
    final name = args['name'] as String?;
    final amount = (args['amount'] as num?)?.toDouble();
    final dueDay = args['due_day'] as int? ?? 1;
    final frequencyStr = args['frequency'] as String? ?? 'monthly';

    if (name == null || amount == null) {
      return jsonEncode({'success': false, 'error': 'Missing name or amount'});
    }

    final frequency = _parseBillFrequency(frequencyStr);
    final bill = Bill(
      name: name,
      amount: amount,
      frequency: frequency,
      dueDay: dueDay.clamp(1, 31),
      category: _guessBillCategory(name),
      isActive: true,
    );

    await _database.insertBill(bill);
    Logger.info('Added bill via chat: $name', tag: _tag);

    return jsonEncode({
      'success': true,
      'name': name,
      'amount': amount,
      'dueDay': dueDay,
      'frequency': frequencyStr,
    });
  }

  Future<String> _toolAddSubscription(Map<String, dynamic> args) async {
    final name = args['name'] as String?;
    final amount = (args['amount'] as num?)?.toDouble();
    final frequencyStr = args['frequency'] as String? ?? 'monthly';

    if (name == null || amount == null) {
      return jsonEncode({'success': false, 'error': 'Missing name or amount'});
    }

    final frequency = _parseSubscriptionFrequency(frequencyStr);
    final subscription = Subscription(
      name: name,
      amount: amount,
      frequency: frequency,
      startDate: DateTime.now(),
      category: _guessSubscriptionCategory(name),
      isActive: true,
    );

    await _database.insertSubscription(subscription);
    Logger.info('Added subscription via chat: $name', tag: _tag);

    return jsonEncode({
      'success': true,
      'name': name,
      'amount': amount,
      'frequency': frequencyStr,
    });
  }

  Future<String> _toolAddIncome(Map<String, dynamic> args) async {
    final source = args['source'] as String?;
    final amount = (args['amount'] as num?)?.toDouble();
    final frequencyStr = args['frequency'] as String? ?? 'monthly';

    if (source == null || amount == null) {
      return jsonEncode(
          {'success': false, 'error': 'Missing source or amount'});
    }

    final frequency = _parseIncomeFrequency(frequencyStr);
    final income = Income(
      source: source,
      amount: amount,
      frequency: frequency,
      type: _guessIncomeType(source),
      isActive: true,
      isRecurring: frequency != IncomeFrequency.oneTime,
    );

    await _database.insertIncome(income);
    Logger.info('Added income via chat: $source', tag: _tag);

    return jsonEncode({
      'success': true,
      'source': source,
      'amount': amount,
      'frequency': frequencyStr,
    });
  }

  // ===================
  // Wealth Helpers
  // ===================

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
    if (lower.contains('rent') || lower.contains('mortgage'))
      return BillCategory.housing;
    if (lower.contains('electric') ||
        lower.contains('gas') ||
        lower.contains('water') ||
        lower.contains('utilit')) return BillCategory.utilities;
    if (lower.contains('car') || lower.contains('auto'))
      return BillCategory.transportation;
    if (lower.contains('insurance')) return BillCategory.insurance;
    if (lower.contains('phone') || lower.contains('internet'))
      return BillCategory.utilities;
    return BillCategory.other;
  }

  SubscriptionCategory _guessSubscriptionCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('netflix') ||
        lower.contains('hulu') ||
        lower.contains('disney') ||
        lower.contains('spotify')) return SubscriptionCategory.entertainment;
    if (lower.contains('gym') || lower.contains('fitness'))
      return SubscriptionCategory.health;
    if (lower.contains('cloud') ||
        lower.contains('notion') ||
        lower.contains('github')) return SubscriptionCategory.software;
    if (lower.contains('news') || lower.contains('times'))
      return SubscriptionCategory.news;
    return SubscriptionCategory.other;
  }

  IncomeType _guessIncomeType(String source) {
    final lower = source.toLowerCase();
    if (lower.contains('salary') || lower.contains('job'))
      return IncomeType.salary;
    if (lower.contains('freelance') || lower.contains('contract'))
      return IncomeType.freelance;
    if (lower.contains('invest') || lower.contains('dividend'))
      return IncomeType.investment;
    if (lower.contains('side') || lower.contains('gig')) return IncomeType.side;
    if (lower.contains('rent') || lower.contains('property'))
      return IncomeType.rental;
    return IncomeType.other;
  }

  /// Check if message might benefit from tool use (proactive agent mode)
  /// Expanded beyond just wealth tracking to include body/mind/spirit tracking
  bool _mightBeActionRequest(String text) {
    final lower = text.toLowerCase();

    // Wealth/Finance keywords
    final wealthKeywords = [
      'add bill',
      'track bill',
      'new bill',
      'add subscription',
      'track subscription',
      'new subscription',
      'add income',
      'track income',
      'new income',
      'rent',
      'mortgage',
      'electric',
      'utilities',
      'netflix',
      'spotify',
      'gym membership',
      'salary',
      'freelance',
      'paycheck',
      r'\$',
      'dollars',
      'per month',
      'monthly',
      'due on',
      'spending',
      'budget',
      'expenses',
      'bills',
    ];

    // Body tracking keywords (workouts, meals, sleep)
    final bodyKeywords = [
      'workout',
      'gym',
      'training',
      'exercise',
      'ate',
      'eating',
      'food',
      'meal',
      'protein',
      'macros',
      'calories',
      'sleep',
      'slept',
      'tired',
      'exhausted',
      'energy',
      'weight',
      'weigh',
      'pounds',
      'kg',
      'skipped',
      'missed',
      'rest day',
      'supplement',
      'creatine',
      'vitamin',
    ];

    // Mind tracking keywords (goals, tasks, focus)
    final mindKeywords = [
      'goal',
      'target',
      'progress',
      'tracking',
      'task',
      'todo',
      'reminder',
      'schedule',
      'focus',
      'distracted',
      'productive',
      'procrastinat',
      'plan',
      'planning',
      'week ahead',
      'experiment',
      'testing',
      'trying',
    ];

    // Spirit tracking keywords (mood, meditation, reflection)
    final spiritKeywords = [
      'meditat',
      'mindful',
      'breath',
      'feeling',
      'feel',
      'mood',
      'stress',
      'anxious',
      'calm',
      'grateful',
      'gratitude',
      'journal',
      'mantra',
      'affirmation',
      'reflect',
      'thinking about',
      'processing',
    ];

    // State queries that benefit from data lookup
    final stateQueries = [
      'how am i doing',
      'how\'s my',
      'what\'s my',
      'show me',
      'check my',
      'status',
      'this week',
      'today',
      'yesterday',
      'on track',
      'progress',
    ];

    final allKeywords = [
      ...wealthKeywords,
      ...bodyKeywords,
      ...mindKeywords,
      ...spiritKeywords,
      ...stateQueries,
    ];

    return allKeywords.any((kw) => lower.contains(kw));
  }

  /// Set a pending image to be attached to the next message
  void setPendingImage(Uint8List bytes, String mimeType) {
    state = state.copyWith(
      pendingImage: bytes,
      pendingImageMimeType: mimeType,
    );
  }

  /// Clear the pending image
  void clearPendingImage() {
    state = state.copyWith(clearPendingImage: true);
  }

  /// Send a message and get AI response
  Future<void> sendMessage(String text,
      {Uint8List? imageBytes, String? imageMimeType}) async {
    // Use pending image if no direct image provided
    final actualImageBytes = imageBytes ?? state.pendingImage;
    final actualMimeType = imageMimeType ?? state.pendingImageMimeType;

    if (text.trim().isEmpty && actualImageBytes == null) return;

    // Wait for initialization if not ready
    if (!state.isInitialized) {
      Logger.warning('Chat not initialized yet, waiting...', tag: _tag);
      for (var i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (state.isInitialized) break;
      }
      if (!state.isInitialized) {
        state = state.copyWith(error: 'Chat not ready, please try again');
        return;
      }
    }

    final conversationId = state.conversationId;
    if (conversationId == null) {
      state = state.copyWith(error: 'No active conversation');
      return;
    }

    final now = DateTime.now();
    final userMessageId = _uuid.v4();

    // Save image to local storage if provided
    String? savedImagePath;
    if (actualImageBytes != null) {
      savedImagePath = await _saveImageLocally(
          actualImageBytes, userMessageId, actualMimeType ?? 'image/jpeg');
    }

    final userMessage = ChatMessageModel(
      id: userMessageId,
      content: text.isNotEmpty ? text : '📷 Image',
      isUser: true,
      timestamp: now,
      imagePath: savedImagePath,
      pendingImageBytes: actualImageBytes,
    );

    // Add user message to state and clear pending image
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
      clearPendingImage: true,
    );

    // Build message parts for LLM
    final userParts = <ChatContentPart>[];
    if (text.isNotEmpty) {
      userParts.add(ChatContentPart.text(text));
    }
    if (actualImageBytes != null) {
      final mimeType = actualMimeType ?? 'image/jpeg';
      final base64Data = base64Encode(actualImageBytes);
      final dataUrl = 'data:$mimeType;base64,$base64Data';
      userParts.add(ChatContentPart.imageUrl(dataUrl));
      if (text.isEmpty) {
        userParts.insert(
            0, ChatContentPart.text('What do you see in this image?'));
      }
    }

    // Add to conversation history
    if (userParts.length == 1 && userParts.first.text != null) {
      _conversationHistory.add(ChatMessage.user(userParts.first.text!));
    } else {
      _conversationHistory.add(ChatMessage.userWithParts(userParts));
    }

    // Save user message to DB
    await _database.insertChatMessage(ChatMessageRecord(
      conversationId: conversationId,
      role: 'user',
      content: text.isNotEmpty ? text : '📷 Image',
      timestamp: now,
      imagePath: savedImagePath,
    ));

    // Create loading placeholder for AI response
    final aiMessageId = _uuid.v4();
    final loadingMessage = ChatMessageModel(
      id: aiMessageId,
      content: '',
      isUser: false,
      timestamp: now,
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, loadingMessage],
    );

    try {
      final logText = text.isNotEmpty ? text : '[image]';
      Logger.info(
          'Sending message: "${logText.substring(0, logText.length.clamp(0, 50))}..."',
          tag: _tag);

      String aiContent;
      final toolCallsList = <ToolCallInfo>[];

      // Check if this might benefit from proactive tool use
      if (text.isNotEmpty && _mightBeActionRequest(text)) {
        // Use streaming agent mode with all available tools
        Logger.info('Using proactive streaming agent mode with tools',
            tag: _tag);

        final stream = _agentService.runAgentStream(
          messages: _conversationHistory,
          tools: _getTools(),
          executor: _executeTool,
          maxIterations: 5,
          deployment: AzureAIDeployment.gpt5,
        );

        final contentBuffer = StringBuffer();

        await for (final event in stream) {
          switch (event.type) {
            case StreamEventType.toolCall:
              // Add tool call to list (shows as "calling...")
              if (event.toolName != null) {
                toolCallsList.add(ToolCallInfo(
                  name: event.toolName!,
                  args: event.toolArgs,
                  isExecuting: true,
                ));
                _updateStreamingMessage(
                  aiMessageId,
                  content: contentBuffer.toString(),
                  toolCalls: List.from(toolCallsList),
                );
              }
              break;

            case StreamEventType.toolResult:
              // Update the tool call with result
              if (event.toolName != null) {
                final idx = toolCallsList.lastIndexWhere(
                    (t) => t.name == event.toolName && t.isExecuting);
                if (idx >= 0) {
                  toolCallsList[idx] = toolCallsList[idx].copyWith(
                    result: event.toolResult,
                    isExecuting: false,
                  );
                  _updateStreamingMessage(
                    aiMessageId,
                    content: contentBuffer.toString(),
                    toolCalls: List.from(toolCallsList),
                  );
                }
              }
              break;

            case StreamEventType.content:
              if (event.content != null) {
                contentBuffer.write(event.content);
                _updateStreamingMessage(
                  aiMessageId,
                  content: contentBuffer.toString(),
                  toolCalls: List.from(toolCallsList),
                );
              }
              break;

            case StreamEventType.thinking:
              // Agent mode typically doesn't emit thinking, but handle it
              break;

            case StreamEventType.done:
              Logger.info('Agent stream completed: ${event.finishReason}',
                  tag: _tag);
              break;

            case StreamEventType.usage:
              break;

            case StreamEventType.error:
              throw Exception(event.error ?? 'Unknown agent error');
          }
        }

        aiContent = contentBuffer.isNotEmpty
            ? contentBuffer.toString()
            : "Done! I've updated your records.";

        // Finalize the message
        _updateStreamingMessage(
          aiMessageId,
          content: aiContent,
          toolCalls: toolCallsList.isNotEmpty ? toolCallsList : null,
          isLoading: false,
        );
      } else {
        // Use streaming API for regular conversation
        final stream = _agentService.chatStream(
          messages: _conversationHistory,
          deployment: AzureAIDeployment.gpt5,
        );

        final contentBuffer = StringBuffer();
        final thinkingBuffer = StringBuffer();

        await for (final event in stream) {
          switch (event.type) {
            case StreamEventType.thinking:
              // Handle thinking/reasoning tokens
              if (event.content != null) {
                thinkingBuffer.write(event.content);
                _updateStreamingMessage(
                  aiMessageId,
                  content: contentBuffer.toString(),
                  thinkingContent: thinkingBuffer.toString(),
                  isThinking: true,
                );
              }
              break;

            case StreamEventType.content:
              // Handle regular content tokens
              if (event.content != null) {
                contentBuffer.write(event.content);
                _updateStreamingMessage(
                  aiMessageId,
                  content: contentBuffer.toString(),
                  thinkingContent: thinkingBuffer.isNotEmpty
                      ? thinkingBuffer.toString()
                      : null,
                  isThinking: false,
                );
              }
              break;

            case StreamEventType.toolCall:
            case StreamEventType.toolResult:
              // Not used in regular streaming mode (only agent mode)
              break;

            case StreamEventType.done:
              // Stream finished
              Logger.info('Stream completed: ${event.finishReason}', tag: _tag);
              break;

            case StreamEventType.usage:
              // Token usage stats
              Logger.debug(
                'Token usage: prompt=${event.promptTokens}, completion=${event.completionTokens}, total=${event.totalTokens}',
                tag: _tag,
              );
              break;

            case StreamEventType.error:
              throw Exception(event.error ?? 'Unknown streaming error');
          }
        }

        aiContent = contentBuffer.isNotEmpty
            ? contentBuffer.toString()
            : "I'm here for you.";

        // Finalize the message (remove loading state)
        _updateStreamingMessage(
          aiMessageId,
          content: aiContent,
          thinkingContent:
              thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null,
          isThinking: false,
          isLoading: false,
        );
      }

      final aiTimestamp = DateTime.now();

      // Add to conversation history
      _conversationHistory.add(ChatMessage.assistant(aiContent));

      // Save AI response to DB
      await _database.insertChatMessage(ChatMessageRecord(
        conversationId: conversationId,
        role: 'assistant',
        content: aiContent,
        timestamp: aiTimestamp,
      ));

      // Update timestamp on the message
      _updateStreamingMessage(
        aiMessageId,
        timestamp: aiTimestamp,
      );

      state = state.copyWith(isLoading: false);

      Logger.info(
          'Received response: "${aiContent.substring(0, aiContent.length.clamp(0, 50))}..."',
          tag: _tag);
    } catch (e, stack) {
      Logger.error('Chat error: $e', tag: _tag, error: e, stackTrace: stack);

      // Remove loading message
      final updatedMessages = [...state.messages];
      updatedMessages.removeLast();

      final errorMsg = e.toString().contains('Exception:')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Failed to get response. Please try again.';

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        error: errorMsg,
      );
    }
  }

  /// Save image to local app storage
  Future<String?> _saveImageLocally(
      Uint8List bytes, String messageId, String mimeType) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final chatImagesDir = Directory(path.join(appDir.path, 'chat_images'));
      if (!await chatImagesDir.exists()) {
        await chatImagesDir.create(recursive: true);
      }

      final extension = mimeType.contains('png') ? 'png' : 'jpg';
      final filePath = path.join(chatImagesDir.path, '$messageId.$extension');
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      Logger.debug('Saved chat image: $filePath', tag: _tag);
      return filePath;
    } catch (e) {
      Logger.error('Failed to save chat image: $e', tag: _tag);
      return null;
    }
  }

  /// Update a streaming message in place
  void _updateStreamingMessage(
    String messageId, {
    String? content,
    String? thinkingContent,
    bool? isThinking,
    bool? isLoading,
    DateTime? timestamp,
    List<ToolCallInfo>? toolCalls,
  }) {
    final messages = [...state.messages];
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    messages[index] = messages[index].copyWith(
      content: content,
      thinkingContent: thinkingContent,
      isThinking: isThinking,
      isLoading: isLoading ?? messages[index].isLoading,
      timestamp: timestamp,
      toolCalls: toolCalls ?? messages[index].toolCalls,
    );

    state = state.copyWith(messages: messages);
  }

  /// Clear conversation and start fresh
  Future<void> clearConversation() async {
    final currentId = state.conversationId;
    if (currentId != null) {
      await _database.deleteConversation(currentId);
    }

    _conversationHistory.clear();
    await _startNewConversation();

    state = state.copyWith(
      messages: [],
      isLoading: false,
      error: null,
      clearPendingImage: true,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for ChatViewModel
final chatViewModelProvider =
    NotifierProvider<ChatViewModel, ChatState>(ChatViewModel.new);
