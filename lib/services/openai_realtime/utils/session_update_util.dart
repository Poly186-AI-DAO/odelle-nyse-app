import 'dart:developer' as developer;
import '../tools/create_calendar_event_tool.dart';
import '../tools/create_drive_document_tool.dart';
import '../tools/find_drive_document_tool.dart';
import '../tools/send_email_tool.dart';
import '../tools/list_emails_tool.dart';
import '../tools/read_email_tool.dart';

/// Utility class for handling OpenAI session updates
class SessionUpdateUtil {
  /// List of available tools for the session
  static final _tools = [
    CreateCalendarEventTool(),
    CreateDriveDocumentTool(),
    FindDriveDocumentTool(),
    SendEmailTool(),
    ListEmailsTool(),
    ReadEmailTool(),
  ];

  /// Creates a session update event with tools and other configurations
  static Map<String, dynamic> createSessionUpdateEvent() {
    final eventId = DateTime.now().millisecondsSinceEpoch.toString();
    final updateEvent = {
      'event_id': eventId,
      'type': 'session.update',
      'session': {
        'input_audio_transcription': {
          'model': 'whisper-1',
        },
        'max_response_output_tokens': 4096,
        'tools': _tools.map((tool) => tool.toJson()).toList(),
        'tool_choice': 'auto',
      }
    };

    developer.log('Created session update event',
        name: 'SessionUpdateUtil',
        error: 'Event ID: $eventId, Event: ${updateEvent.toString()}');

    return updateEvent;
  }
}
