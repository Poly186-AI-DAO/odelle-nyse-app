import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../config/azure_ai_config.dart';
import '../utils/logger.dart';

/// Message role for chat completions
enum ChatRole { system, user, assistant, tool }

/// Content part for multimodal chat
class ChatContentPart {
  final String type;
  final String? text;
  final ChatImageUrl? imageUrl;

  const ChatContentPart({
    required this.type,
    this.text,
    this.imageUrl,
  });

  factory ChatContentPart.text(String text) =>
      ChatContentPart(type: 'text', text: text);

  factory ChatContentPart.imageUrl(String url, {String? detail}) =>
      ChatContentPart(
        type: 'image_url',
        imageUrl: ChatImageUrl(url: url, detail: detail),
      );

  Map<String, dynamic> toJson() {
    switch (type) {
      case 'image_url':
        return {
          'type': type,
          if (imageUrl != null) 'image_url': imageUrl!.toJson(),
        };
      case 'text':
      default:
        return {
          'type': type,
          if (text != null) 'text': text,
        };
    }
  }

  factory ChatContentPart.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'text';
    if (type == 'image_url') {
      return ChatContentPart(
        type: type,
        imageUrl: json['image_url'] != null
            ? ChatImageUrl.fromJson(json['image_url'] as Map<String, dynamic>)
            : null,
      );
    }
    return ChatContentPart(
      type: type,
      text: json['text'] as String?,
    );
  }
}

/// Image URL payload for multimodal chat
class ChatImageUrl {
  final String url;
  final String? detail;

  const ChatImageUrl({required this.url, this.detail});

  Map<String, dynamic> toJson() => {
        'url': url,
        if (detail != null) 'detail': detail,
      };

  factory ChatImageUrl.fromJson(Map<String, dynamic> json) {
    return ChatImageUrl(
      url: json['url'] as String? ?? '',
      detail: json['detail'] as String?,
    );
  }
}

/// A single message in the conversation
class ChatMessage {
  final ChatRole role;
  final String? content;
  final List<ChatContentPart>? contentParts;
  final String? name;
  final List<ToolCall>? toolCalls;
  final String? toolCallId;

  const ChatMessage({
    required this.role,
    this.content,
    this.contentParts,
    this.name,
    this.toolCalls,
    this.toolCallId,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'role': role.name,
    };

    if (contentParts != null) {
      json['content'] = contentParts!.map((part) => part.toJson()).toList();
    } else if (content != null) {
      json['content'] = content;
    }
    if (name != null) json['name'] = name;
    if (toolCallId != null) json['tool_call_id'] = toolCallId;
    if (toolCalls != null) {
      json['tool_calls'] = toolCalls!.map((tc) => tc.toJson()).toList();
    }

    return json;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final contentValue = json['content'];
    String? content;
    List<ChatContentPart>? contentParts;
    if (contentValue is String) {
      content = contentValue;
    } else if (contentValue is List) {
      contentParts = contentValue
          .whereType<Map<String, dynamic>>()
          .map(ChatContentPart.fromJson)
          .toList();
    }

    return ChatMessage(
      role: ChatRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => ChatRole.assistant,
      ),
      content: content,
      contentParts: contentParts,
      name: json['name'] as String?,
      toolCallId: json['tool_call_id'] as String?,
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List)
              .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  static ChatMessage system(String content) =>
      ChatMessage(role: ChatRole.system, content: content);

  static ChatMessage user(String content) =>
      ChatMessage(role: ChatRole.user, content: content);

  static ChatMessage userWithParts(List<ChatContentPart> parts) =>
      ChatMessage(role: ChatRole.user, contentParts: parts);

  static ChatMessage assistant(String content, {List<ToolCall>? toolCalls}) =>
      ChatMessage(
          role: ChatRole.assistant, content: content, toolCalls: toolCalls);

  static ChatMessage toolResult({
    required String toolCallId,
    required String content,
  }) =>
      ChatMessage(
          role: ChatRole.tool, toolCallId: toolCallId, content: content);
}

/// A tool call requested by the model
class ToolCall {
  final String id;
  final String type;
  final String functionName;
  final String arguments;

  const ToolCall({
    required this.id,
    required this.type,
    required this.functionName,
    required this.arguments,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'function': {
          'name': functionName,
          'arguments': arguments,
        },
      };

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    final function = json['function'] as Map<String, dynamic>;
    return ToolCall(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'function',
      functionName: function['name'] as String,
      arguments: function['arguments'] as String,
    );
  }

  Map<String, dynamic>? get parsedArguments {
    try {
      return jsonDecode(arguments) as Map<String, dynamic>;
    } catch (e) {
      Logger.warning('Failed to parse tool arguments: $e',
          tag: 'AzureAgentService');
      return null;
    }
  }
}

/// Tool definition for function calling
class ToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const ToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': parameters,
        },
      };
}

/// Response from chat completions
class ChatCompletionResponse {
  final String id;
  final String model;
  final ChatMessage message;
  final String? finishReason;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const ChatCompletionResponse({
    required this.id,
    required this.model,
    required this.message,
    this.finishReason,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  bool get hasToolCalls =>
      message.toolCalls != null && message.toolCalls!.isNotEmpty;

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    final choice = (json['choices'] as List).first as Map<String, dynamic>;
    final usage = json['usage'] as Map<String, dynamic>? ?? {};

    return ChatCompletionResponse(
      id: json['id'] as String,
      model: json['model'] as String,
      message: ChatMessage.fromJson(choice['message'] as Map<String, dynamic>),
      finishReason: choice['finish_reason'] as String?,
      promptTokens: usage['prompt_tokens'] as int? ?? 0,
      completionTokens: usage['completion_tokens'] as int? ?? 0,
      totalTokens: usage['total_tokens'] as int? ?? 0,
    );
  }
}

/// Streaming event types
enum StreamEventType {
  /// Content chunk (regular output)
  content,

  /// Reasoning/thinking content
  thinking,

  /// Tool call being executed
  toolCall,

  /// Tool call result received
  toolResult,

  /// Stream finished
  done,

  /// Usage statistics
  usage,

  /// Error occurred
  error,
}

/// A streaming event from chat completions
class StreamEvent {
  final StreamEventType type;
  final String? content;
  final String? finishReason;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final String? error;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final String? toolResult;

  const StreamEvent({
    required this.type,
    this.content,
    this.finishReason,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.error,
    this.toolName,
    this.toolArgs,
    this.toolResult,
  });

  factory StreamEvent.content(String content) => StreamEvent(
        type: StreamEventType.content,
        content: content,
      );

  factory StreamEvent.thinking(String content) => StreamEvent(
        type: StreamEventType.thinking,
        content: content,
      );

  factory StreamEvent.toolCall({
    required String name,
    Map<String, dynamic>? args,
  }) =>
      StreamEvent(
        type: StreamEventType.toolCall,
        toolName: name,
        toolArgs: args,
      );

  factory StreamEvent.toolResultEvent({
    required String name,
    required String result,
  }) =>
      StreamEvent(
        type: StreamEventType.toolResult,
        toolName: name,
        toolResult: result,
      );

  factory StreamEvent.done(String? finishReason) => StreamEvent(
        type: StreamEventType.done,
        finishReason: finishReason,
      );

  factory StreamEvent.usage({
    required int promptTokens,
    required int completionTokens,
    required int totalTokens,
  }) =>
      StreamEvent(
        type: StreamEventType.usage,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
      );

  factory StreamEvent.error(String message) => StreamEvent(
        type: StreamEventType.error,
        error: message,
      );
}

/// Callback type for executing tool calls
typedef ToolExecutor = Future<String> Function(
    String name, Map<String, dynamic>? args);

/// Azure OpenAI Agent Service for chat completions with tool calling
/// Runs entirely on-device, calling Azure directly
class AzureAgentService {
  static const String _tag = 'AzureAgentService';

  final http.Client _client;
  late final String _apiKey;
  late final String _endpoint;
  bool _isInitialized = false;

  AzureAgentService({http.Client? client}) : _client = client ?? http.Client() {
    _initialize();
  }

  void _initialize() {
    _apiKey = dotenv.env['AZURE_AI_FOUNDRY_KEY'] ?? '';
    _endpoint = dotenv.env['AZURE_AI_FOUNDRY_ENDPOINT'] ?? '';

    if (_apiKey.isEmpty || _endpoint.isEmpty) {
      Logger.error(
        'Azure AI Foundry key or endpoint not found in environment',
        tag: _tag,
      );
      return;
    }

    Logger.info('Azure Agent Service initialized', tag: _tag);
    _isInitialized = true;
  }

  bool get isInitialized => _isInitialized;

  /// Send a chat completion request
  /// [messages] - Conversation history
  /// [tools] - Available tools for the model to call
  /// [deployment] - Which model to use (defaults to GPT-5.2-chat)
  /// [temperature] - Sampling temperature (0-2)
  /// [maxTokens] - Maximum tokens in response
  Future<ChatCompletionResponse> chat({
    required List<ChatMessage> messages,
    List<ToolDefinition>? tools,
    AzureAIDeployment deployment = AzureAIDeployment.gpt5,
    double? temperature,
    int? maxTokens,
    String? responseFormat,
  }) async {
    if (!_isInitialized) {
      throw StateError('AzureAgentService not initialized');
    }

    final uri = AzureAIConfig.buildChatCompletionsUri(
      endpoint: _endpoint,
      deployment: deployment,
    );

    final body = <String, dynamic>{
      'messages': messages.map((m) => m.toJson()).toList(),
    };

    // Note: GPT-5 models (gpt-5-nano, gpt-5.2-chat, gpt-5.2) don't support temperature
    // Only default (1.0) is supported. Temperature param is ignored for these models.
    // Keep this code for future models that might support it.
    if (temperature != null &&
        deployment != AzureAIDeployment.gpt5Nano &&
        deployment != AzureAIDeployment.gpt5 &&
        deployment != AzureAIDeployment.gpt5Chat) {
      body['temperature'] = temperature;
    }

    if (tools != null && tools.isNotEmpty) {
      body['tools'] = tools.map((t) => t.toJson()).toList();
    }

    if (maxTokens != null) {
      // GPT-5 models use max_completion_tokens instead of max_tokens
      body['max_completion_tokens'] = maxTokens;
    }

    if (responseFormat == 'json') {
      body['response_format'] = {'type': 'json_object'};
    }

    Logger.info(
      'Sending chat request to ${deployment.deploymentName}',
      tag: _tag,
      data: {'messageCount': messages.length, 'toolCount': tools?.length ?? 0},
    );

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'api-key': _apiKey,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        Logger.error(
          'Chat request failed',
          tag: _tag,
          data: {'status': response.statusCode, 'body': response.body},
        );
        throw Exception(
          'Chat request failed: ${response.statusCode} - ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final result = ChatCompletionResponse.fromJson(json);

      Logger.info(
        'Chat response received',
        tag: _tag,
        data: {
          'finishReason': result.finishReason,
          'hasToolCalls': result.hasToolCalls,
          'tokens': result.totalTokens,
        },
      );

      return result;
    } catch (e, stackTrace) {
      Logger.error('Chat request error: $e', tag: _tag, data: {
        'stackTrace': stackTrace.toString(),
      });
      rethrow;
    }
  }

  /// Run an agent loop that handles tool calls automatically
  /// [messages] - Initial conversation
  /// [tools] - Available tools
  /// [executor] - Function to execute tool calls
  /// [maxIterations] - Maximum tool call iterations (prevents infinite loops)
  /// [deployment] - Which model to use
  Future<ChatCompletionResponse> runAgent({
    required List<ChatMessage> messages,
    required List<ToolDefinition> tools,
    required ToolExecutor executor,
    int maxIterations = 10,
    AzureAIDeployment deployment = AzureAIDeployment.gpt5,
    double? temperature,
  }) async {
    final conversationHistory = List<ChatMessage>.from(messages);
    ChatCompletionResponse response;
    int iterations = 0;

    while (iterations < maxIterations) {
      iterations++;

      response = await chat(
        messages: conversationHistory,
        tools: tools,
        deployment: deployment,
        temperature: temperature,
      );

      // If no tool calls, we're done
      if (!response.hasToolCalls) {
        Logger.info(
          'Agent completed after $iterations iterations',
          tag: _tag,
        );
        return response;
      }

      // Add assistant message with tool calls to history
      conversationHistory.add(response.message);

      // Execute each tool call and add results
      for (final toolCall in response.message.toolCalls!) {
        Logger.info(
          'Executing tool: ${toolCall.functionName}',
          tag: _tag,
          data: {'args': toolCall.parsedArguments},
        );

        try {
          final result = await executor(
            toolCall.functionName,
            toolCall.parsedArguments,
          );

          conversationHistory.add(ChatMessage.toolResult(
            toolCallId: toolCall.id,
            content: result,
          ));
        } catch (e) {
          Logger.error(
            'Tool execution failed: ${toolCall.functionName}',
            tag: _tag,
            error: e,
          );

          conversationHistory.add(ChatMessage.toolResult(
            toolCallId: toolCall.id,
            content: 'Error: $e',
          ));
        }
      }
    }

    Logger.warning(
      'Agent reached max iterations ($maxIterations)',
      tag: _tag,
    );

    // Return last response even if we hit max iterations
    return await chat(
      messages: conversationHistory,
      tools: tools,
      deployment: deployment,
      temperature: temperature,
    );
  }

  /// Run an agent loop that streams events including tool calls
  /// This allows the UI to show tool execution in real-time
  Stream<StreamEvent> runAgentStream({
    required List<ChatMessage> messages,
    required List<ToolDefinition> tools,
    required ToolExecutor executor,
    int maxIterations = 10,
    AzureAIDeployment deployment = AzureAIDeployment.gpt5,
    double? temperature,
  }) async* {
    final conversationHistory = List<ChatMessage>.from(messages);
    int iterations = 0;

    while (iterations < maxIterations) {
      iterations++;

      final response = await chat(
        messages: conversationHistory,
        tools: tools,
        deployment: deployment,
        temperature: temperature,
      );

      // If no tool calls, emit content and we're done
      if (!response.hasToolCalls) {
        if (response.message.content != null) {
          yield StreamEvent.content(response.message.content!);
        }
        Logger.info(
          'Agent stream completed after $iterations iterations',
          tag: _tag,
        );
        yield StreamEvent.done('stop');
        return;
      }

      // Add assistant message with tool calls to history
      conversationHistory.add(response.message);

      // Execute each tool call and emit events
      for (final toolCall in response.message.toolCalls!) {
        // Emit tool call event (UI shows "calling X...")
        yield StreamEvent.toolCall(
          name: toolCall.functionName,
          args: toolCall.parsedArguments,
        );

        Logger.info(
          'Executing tool: ${toolCall.functionName}',
          tag: _tag,
          data: {'args': toolCall.parsedArguments},
        );

        try {
          final result = await executor(
            toolCall.functionName,
            toolCall.parsedArguments,
          );

          // Emit tool result event
          yield StreamEvent.toolResultEvent(
            name: toolCall.functionName,
            result: result,
          );

          conversationHistory.add(ChatMessage.toolResult(
            toolCallId: toolCall.id,
            content: result,
          ));
        } catch (e) {
          Logger.error(
            'Tool execution failed: ${toolCall.functionName}',
            tag: _tag,
            error: e,
          );

          yield StreamEvent.toolResultEvent(
            name: toolCall.functionName,
            result: 'Error: $e',
          );

          conversationHistory.add(ChatMessage.toolResult(
            toolCallId: toolCall.id,
            content: 'Error: $e',
          ));
        }
      }
    }

    Logger.warning(
      'Agent stream reached max iterations ($maxIterations)',
      tag: _tag,
    );

    // Make final call to get response
    final finalResponse = await chat(
      messages: conversationHistory,
      tools: tools,
      deployment: deployment,
      temperature: temperature,
    );

    if (finalResponse.message.content != null) {
      yield StreamEvent.content(finalResponse.message.content!);
    }
    yield StreamEvent.done('max_iterations');
  }

  /// Quick helper for simple one-shot completions (no tools)
  /// Uses gpt-5 for quality outputs
  /// Set [responseFormat] to 'json' to force JSON output (no markdown wrapping)
  Future<String> complete({
    required String prompt,
    String? systemPrompt,
    AzureAIDeployment deployment = AzureAIDeployment.gpt5,
    double? temperature,
    int? maxTokens,
    String? responseFormat,
  }) async {
    final messages = <ChatMessage>[
      if (systemPrompt != null) ChatMessage.system(systemPrompt),
      ChatMessage.user(prompt),
    ];

    final response = await chat(
      messages: messages,
      deployment: deployment,
      temperature: temperature,
      maxTokens: maxTokens,
      responseFormat: responseFormat,
    );

    return response.message.content ?? '';
  }

  /// Helper to extract JSON from LLM responses that may be wrapped in markdown
  /// Use this for older models or when response_format isn't available
  static String extractJson(String response) {
    var clean = response.trim();
    // Strip markdown code fences if present
    if (clean.startsWith('```')) {
      clean = clean
          .replaceAll(RegExp(r'^```\w*\n?'), '')
          .replaceAll(RegExp(r'\n?```$'), '');
    }
    return clean.trim();
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
