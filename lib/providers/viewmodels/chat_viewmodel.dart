import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/azure_ai_config.dart';
import '../../config/odelle_system_prompt.dart';
import '../../services/azure_agent_service.dart';
import '../../services/user_context_service.dart';
import '../../utils/logger.dart';
import '../service_providers.dart';

/// A message in the chat conversation
class ChatMessageModel {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessageModel copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// State for the chat screen
class ChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ChatViewModel - Manages chat conversation with the AI
class ChatViewModel extends Notifier<ChatState> {
  static const String _tag = 'ChatViewModel';

  AzureAgentService get _agentService => ref.read(azureAgentServiceProvider);
  UserContextService get _userContextService =>
      ref.read(userContextServiceProvider);

  // Conversation history for context
  final List<ChatMessage> _conversationHistory = [];

  @override
  ChatState build() {
    // Initialize conversation context (no greeting - let user start)
    _initializeConversation();
    return const ChatState(
      messages: [],
    );
  }

  /// Initialize conversation with system context
  Future<void> _initializeConversation() async {
    await _userContextService.loadContext();

    // Digital Twin concept - Odelle is a reflection of the user's clearest self
    final systemPrompt = '''
${OdelleSystemPrompt.conversationMode}

---

## MODE: NOTE TO SELF (DIGITAL TWIN)
This is "Note to Self" mode - the user is essentially talking to their digital twin.
You are the clearest, wisest version of them - the part that sees patterns, 
remembers the protocols, and holds space for growth.

Think of yourself as:
- Their internal dialogue made external
- The voice that reminds them of their own wisdom
- A mirror that reflects back what they already know

Keep responses:
- Brief and punchy (1-2 short paragraphs)
- Direct - no filler, no over-validation
- Grounded in THEIR values, goals, and frameworks
- Like texting yourself a reminder

Don't greet them. Just respond to what they say.

---

## USER CONTEXT (WHO YOU ARE)
${_userContextService.getQuickContext()}
''';

    _conversationHistory.add(ChatMessage.system(systemPrompt));
  }

  /// Send a message and get AI response
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Add user message
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    // Add to conversation history
    _conversationHistory.add(ChatMessage.user(text));

    // Create loading placeholder for AI response
    final loadingMessage = ChatMessageModel(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, loadingMessage],
    );

    try {
      Logger.info('Sending message: "$text"', tag: _tag);

      // Get AI response (GPT-5 doesn't support temperature, uses default 1.0)
      final response = await _agentService.chat(
        messages: _conversationHistory,
        deployment: AzureAIDeployment.gpt5Chat,
        maxTokens: 500,
      );

      final aiContent = response.message.content ?? "I'm here for you.";

      // Add to conversation history
      _conversationHistory.add(ChatMessage.assistant(aiContent));

      // Replace loading message with actual response
      final aiMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiContent,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final updatedMessages = [...state.messages];
      updatedMessages.removeLast(); // Remove loading
      updatedMessages.add(aiMessage);

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
      );

      Logger.info(
          'Received response: "${aiContent.substring(0, aiContent.length.clamp(0, 50))}..."',
          tag: _tag);
    } catch (e, stack) {
      Logger.error('Chat error: $e', tag: _tag, error: e, stackTrace: stack);
      Logger.error('Stack trace: $stack', tag: _tag);

      // Remove loading message and show error
      final updatedMessages = [...state.messages];
      updatedMessages.removeLast();

      // Show more detailed error for debugging
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

  /// Clear conversation and start fresh
  void clearConversation() {
    _conversationHistory.clear();
    _initializeConversation();

    state = const ChatState(
      messages: [],
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
