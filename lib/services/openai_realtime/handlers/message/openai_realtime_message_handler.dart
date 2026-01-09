import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:developer' as developer;
import '../../models/openai/openai_response_models.dart';
import '../tool_handlers/base_tool_handler.dart';
import '../tool_handlers/create_calendar_event_handler.dart';
import '../tool_handlers/create_drive_document_handler.dart';
import '../tool_handlers/find_drive_document_handler.dart';
import '../tool_handlers/send_email_handler.dart';
import '../tool_handlers/list_emails_handler.dart';
import '../tool_handlers/read_email_handler.dart';

/// Callback for when a message is received
typedef OnMessage = void Function(Map<String, dynamic> message);

/// Callback for when a new response is created
typedef OnResponseCreated = void Function(OpenAIResponse response);

/// Callback for when a response is completed
typedef OnResponseDone = void Function(OpenAIResponse response);

/// Callback for when a conversation is created
typedef OnConversationCreated = void Function(ConversationCreatedEvent event);

/// Callback for when a conversation item is created
typedef OnConversationItemCreated = void Function(
    ConversationItemCreatedEvent event);

/// Callback for when a conversation item is truncated
typedef OnConversationItemTruncated = void Function(
    ConversationItemTruncatedEvent event);

/// Callback for when a conversation item is deleted
typedef OnConversationItemDeleted = void Function(
    ConversationItemDeletedEvent event);

/// Handles WebRTC message processing for OpenAI responses
class OpenAIRealtimeMessageHandler {
  final OnResponseCreated? onResponseCreated;
  final OnResponseDone? onResponseDone;
  final OnMessage? childHandler;
  final Future<void> Function(Map<String, dynamic>)? sendEvent;
  final OnConversationCreated? onConversationCreated;
  final OnConversationItemCreated? onConversationItemCreated;
  final OnConversationItemTruncated? onConversationItemTruncated;
  final OnConversationItemDeleted? onConversationItemDeleted;
  final String? userId;

  /// Map of tool names to their handlers
  final Map<String, BaseToolHandler> _toolHandlers = {
    'create_calendar_event': CreateCalendarEventHandler(),
    'create_drive_document': CreateDriveDocumentHandler(),
    'find_drive_document': FindDriveDocumentHandler(),
    'send_email': SendEmailHandler(),
    'list_emails': ListEmailsHandler(),
    'read_email': ReadEmailHandler(),
  };

  OpenAIRealtimeMessageHandler({
    this.userId,
    this.onResponseCreated,
    this.onResponseDone,
    this.childHandler,
    this.sendEvent,
    this.onConversationCreated,
    this.onConversationItemCreated,
    this.onConversationItemTruncated,
    this.onConversationItemDeleted,
  });

  /// Handles raw data channel messages
  Future<void> handleDataChannelMessage(RTCDataChannelMessage data) async {
    if (!data.isBinary && data.text.isNotEmpty) {
      try {
        final message = Map<String, dynamic>.from(jsonDecode(data.text));
        await handleMessage(message);
      } catch (e, stackTrace) {
        developer.log('Error parsing WebRTC message',
            name: 'OpenAIMessageHandler',
            error:
                'Error: $e\nStackTrace: $stackTrace\nRaw text: ${data.text}');
      }
    }
  }

  /// Handles parsed WebRTC messages
  Future<void> handleMessage(Map<String, dynamic> message) async {
    final type = message['type'] as String?;
    var handled = false;

    if (type == 'conversation.created' && onConversationCreated != null) {
      final event = ConversationCreatedEvent.fromJson(message);
      onConversationCreated!(event);
      developer.log('Handled conversation.created event',
          name: 'OpenAIMessageHandler');
      handled = true;
    } else if (type == 'conversation.item.created' &&
        onConversationItemCreated != null) {
      final event = ConversationItemCreatedEvent.fromJson(message);
      onConversationItemCreated!(event);
      developer.log('Handled conversation.item.created event',
          name: 'OpenAIMessageHandler');
      handled = true;
    } else if (type == 'conversation.item.truncated' &&
        onConversationItemTruncated != null) {
      final event = ConversationItemTruncatedEvent.fromJson(message);
      onConversationItemTruncated!(event);
      developer.log('Handled conversation.item.truncated event',
          name: 'OpenAIMessageHandler');
      handled = true;
    } else if (type == 'conversation.item.deleted' &&
        onConversationItemDeleted != null) {
      final event = ConversationItemDeletedEvent.fromJson(message);
      onConversationItemDeleted!(event);
      handled = true;
    } else if (type == 'response.created') {
      final response =
          OpenAIResponse.fromJson(message['response'] as Map<String, dynamic>);
      onResponseCreated?.call(response);
      handled = true;
    } else if (type == 'response.done') {
      final response = message['response'] as Map<String, dynamic>;
      final outputs = response['output'] as List<dynamic>;

      // Check if this is a function call response
      final functionCall = outputs.firstWhere(
        (output) => output['type'] == 'function_call',
        orElse: () => <String, dynamic>{},
      ) as Map<String, dynamic>?;

      if (functionCall != null) {
        handled = true;
        await _handleFunctionCall(
          name: functionCall['name'] as String,
          arguments: functionCall['arguments'] as String,
          callId: functionCall['call_id'] as String,
        );
      }

      onResponseDone?.call(OpenAIResponse.fromJson(response));
      handled = true;
    }

    // Always forward to child handlers, even if we handled it
    if (childHandler != null) {
      try {
        childHandler!(message);
        developer.log('Forwarded to child handler',
            name: 'OpenAIMessageHandler');
      } catch (e) {
        developer.log('Error in child handler',
            name: 'OpenAIMessageHandler',
            error: 'Error: $e\nMessage: ${jsonEncode(message)}');
      }
    }
  }

  /// Handles function calls from the LLM
  Future<void> _handleFunctionCall({
    required String name,
    required String arguments,
    required String callId,
  }) async {
    try {
      final parsedArguments = jsonDecode(arguments) as Map<String, dynamic>;

      developer.log('Processing function call',
          name: 'OpenAIMessageHandler',
          error: 'Name: $name, Arguments: ${jsonEncode(arguments)}');

      final handler = _toolHandlers[name];
      if (handler == null) {
        throw Exception('No handler found for function: $name');
      }

      final outputEvent = await handler.handle(
        arguments: parsedArguments,
        callId: callId,
      );

      if (sendEvent != null) {
        await sendEvent!(outputEvent);
        await sendEvent!({'type': 'response.create'});
      }

      // Forward function output to child handlers
      if (childHandler != null) {
        final outputMessage = {
          'type': 'function_call_output',
          'name': name,
          'result': outputEvent,
        };
        childHandler!(outputMessage);
      }
    } catch (e) {
      developer.log('Error handling function call',
          name: 'OpenAIMessageHandler', error: 'Error: $e');
      rethrow;
    }
  }
}
