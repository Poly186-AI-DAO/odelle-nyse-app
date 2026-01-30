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
import '../../services/azure_agent_service.dart';
import '../../services/azure_image_service.dart';
import '../../services/health_kit_service.dart';
import '../../services/smart_reminder_service.dart';
import '../../services/user_context_service.dart';
import '../../services/weather_service.dart';
import '../../utils/logger.dart';
import '../service_providers.dart';
import 'chat_tool_executor.dart';

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
/// - Full tool access: Body, Mind, Spirit, Wealth, Bonds tracking
class ChatViewModel extends Notifier<ChatState> {
  static const String _tag = 'ChatViewModel';
  static const _uuid = Uuid();

  AzureAgentService get _agentService => ref.read(azureAgentServiceProvider);
  UserContextService get _userContextService =>
      ref.read(userContextServiceProvider);
  HealthKitService get _healthKitService => ref.read(healthKitServiceProvider);
  SmartReminderService get _reminderService =>
      ref.read(smartReminderServiceProvider);
  WeatherService get _weatherService => ref.read(weatherServiceProvider);
  AppDatabase get _database => ref.read(databaseProvider);

  // Image service for generating images
  late final AzureImageService _imageService;

  // Tool executor for handling all tool calls
  late final ChatToolExecutor _toolExecutor;

  // Conversation history for LLM context (includes system prompt)
  final List<ChatMessage> _conversationHistory = [];

  @override
  ChatState build() {
    _imageService = AzureImageService();
    _toolExecutor = ChatToolExecutor(
      database: _database,
      userContextService: _userContextService,
      healthKitService: _healthKitService,
      reminderService: _reminderService,
      weatherService: _weatherService,
      imageService: _imageService,
    );
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

  /// Build the system prompt for chat mode.
  /// Uses getEssentialContext() which includes character design (for images),
  /// identity, mission, and sample mantras (~15KB, ~4k tokens).
  /// AI can use search_user_documents tool for deeper context when needed.
  Future<String> _buildSystemPrompt() async {
    final psychographMemory = await _buildPsychographMemorySection();
    // Essential context includes character design + identity + sample mantras
    final userContext = _userContextService.getEssentialContext();
    // Fetch live HealthKit data
    final healthContext = await _buildHealthKitContext();
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

KNOWLEDGE BASE SEARCH (CRITICAL):
─────────────────────────────────────────
You have access to bundled documents via search_user_documents. ALWAYS USE THIS:
• When creating meditation scripts → search mantras + whitepaper
• When generating affirmations → search mantras
• When creating images/visuals → search character_design
• When discussing philosophy → search prime + master_algorithm
• When explaining the protocol → search whitepaper + architecture
• Available docs: whitepaper, mantras, prime, architecture, master_algorithm, meta_awareness, character_design

IMAGE ANALYSIS:
─────────────────────────────────────────
When images are attached, analyze deeply:
• Food photos → Estimate macros (protein, carbs, fat, calories)
• Gym selfies → Note the energy, celebrate the action
• Screenshots → Extract actionable data, offer to track
• Environment → Read the context (home, work, travel)

IMAGE GENERATION:
─────────────────────────────────────────
When generating images of the user:
• ALWAYS use the CHARACTER DESIGN section below for physical description
• Include: 6'3" athletic build, deeply melanated skin, metallic-white box braids
• Include tattoos: Poincaré disk + DNA on left arm, Eyes of Horus + Ankh on back
• Reference outfit archetypes from character design as appropriate

RESPONSE STYLE:
─────────────────────────────────────────
• Brief and punchy (1-2 paragraphs max)
• Direct — no filler, no over-validation
• Action-oriented — what's the next move?
• Don't greet every time. Just continue.

---

## USER CONTEXT (YOUR WORLD MODEL)
$userContext

$healthContext

$psychographMemory
''';
  }

  /// Build live HealthKit context for the LLM
  Future<String> _buildHealthKitContext() async {
    final buffer = StringBuffer();
    buffer.writeln('## CURRENT HEALTH DATA (Live from HealthKit)');

    try {
      final authorized = await _healthKitService.requestAuthorization();
      if (!authorized) {
        buffer.writeln('- HealthKit not authorized');
        return buffer.toString();
      }

      final now = DateTime.now();

      // Fetch all data in parallel
      final results = await Future.wait([
        _healthKitService.getLatestWeight(),
        _healthKitService.getLatestHeight(),
        _healthKitService.getLatestBodyFat(),
        _healthKitService.getSteps(now),
        _healthKitService.getActiveCalories(now),
        _healthKitService.getLastNightSleep(),
        _healthKitService.getRestingHeartRate(),
      ]);

      final weightKg = results[0] as double?;
      final heightM = results[1] as double?;
      final bodyFatHK = results[2] as double?;
      final steps = results[3] as int;
      final activeCals = results[4] as double;
      final sleep = results[5] as SleepData?;
      final restingHR = results[6] as int?;

      // Convert units
      final weightLbs = weightKg != null ? weightKg * 2.20462 : null;
      final heightInches = heightM != null ? heightM * 39.3701 : null;

      // Calculate BMI
      double? bmi;
      if (weightKg != null && heightM != null && heightM > 0) {
        bmi = weightKg / (heightM * heightM);
      }

      // Use Navy calculator for body fat if not available from HealthKit
      double? bodyFat = bodyFatHK;
      String bodyFatSource = 'HealthKit';
      if (bodyFat == null && heightInches != null && weightLbs != null) {
        // Navy formula fallback requires waist/neck - we don't have it
        // Just note it's unavailable
        bodyFatSource = 'Not available (no smart scale data)';
      }

      buffer.writeln('');
      buffer.writeln('### Body Measurements');
      buffer.writeln(
          '- Weight: ${weightLbs?.toStringAsFixed(1) ?? "Unknown"} lbs (${weightKg?.toStringAsFixed(1) ?? "?"} kg)');
      buffer.writeln(
          '- Height: ${heightInches != null ? _formatHeight(heightInches) : "Unknown"}');
      buffer.writeln(
          '- BMI: ${bmi?.toStringAsFixed(1) ?? "Unknown"}${_getBMICategory(bmi)}');
      buffer.writeln(
          '- Body Fat: ${bodyFat?.toStringAsFixed(1) ?? bodyFatSource}${bodyFat != null ? "%" : ""}');

      buffer.writeln('');
      buffer.writeln('### Today\'s Activity');
      buffer.writeln('- Steps: $steps');
      buffer.writeln('- Active Calories: ${activeCals.toInt()} kcal');
      buffer.writeln('- Resting Heart Rate: ${restingHR ?? "Unknown"} bpm');

      buffer.writeln('');
      buffer.writeln('### Last Night\'s Sleep');
      if (sleep != null) {
        final hours = sleep.totalDuration.inHours;
        final mins = sleep.totalDuration.inMinutes % 60;
        buffer.writeln('- Duration: ${hours}h ${mins}m');
        buffer.writeln('- Quality Score: ${sleep.qualityScore}/100');
        if (sleep.deepSleep != null) {
          buffer.writeln(
              '- Deep Sleep: ${sleep.deepSleep!.inHours}h ${sleep.deepSleep!.inMinutes % 60}m');
        }
      } else {
        buffer.writeln('- No sleep data recorded');
      }
    } catch (e) {
      Logger.warning('Failed to fetch HealthKit data for context: $e',
          tag: _tag);
      buffer.writeln('- Error fetching health data');
    }

    return buffer.toString();
  }

  /// Format height in feet and inches
  String _formatHeight(double inches) {
    final feet = (inches / 12).floor();
    final remainingInches = (inches % 12).round();
    return "$feet'$remainingInches\" (${(inches * 2.54).toStringAsFixed(1)} cm)";
  }

  /// Get BMI category
  String _getBMICategory(double? bmi) {
    if (bmi == null) return '';
    if (bmi < 18.5) return ' (Underweight)';
    if (bmi < 25) return ' (Normal)';
    if (bmi < 30) return ' (Overweight)';
    return ' (Obese)';
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

      // ALWAYS use streaming agent mode with tools
      // The AI should act, not just talk - gather context, update records, learn
      Logger.info('Using streaming agent mode with tools', tag: _tag);

      final stream = _agentService.runAgentStream(
        messages: _conversationHistory,
        tools: _toolExecutor.getTools(),
        executor: _toolExecutor.executeTool,
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

      aiContent =
          contentBuffer.isNotEmpty ? contentBuffer.toString() : "I'm here.";

      // Finalize the message
      _updateStreamingMessage(
        aiMessageId,
        content: aiContent,
        toolCalls: toolCallsList.isNotEmpty ? toolCallsList : null,
        isLoading: false,
      );

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
