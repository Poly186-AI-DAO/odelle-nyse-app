import 'dart:developer' as developer;
import 'package:googleapis/calendar/v3.dart';
import 'package:odelle_nyse/services/google_calendar_service.dart';
import 'base_tool_handler.dart';

/// Handler for creating calendar events
class CreateCalendarEventHandler extends BaseToolHandler {
  @override
  String get toolName => 'create_calendar_event';

  @override
  Future<Map<String, dynamic>> handle({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      // Convert attendee emails to EventAttendee objects
      final List<EventAttendee> attendees =
          (arguments['attendee_emails'] as List<dynamic>)
              .map((email) => EventAttendee(email: email as String))
              .toList();

      // Create the calendar event
      final result = await CalendarClient().insert(
        title: arguments['title'] as String,
        description: arguments['description'] as String,
        location: arguments['location'] as String,
        attendeeEmailList: attendees,
        shouldNotifyAttendees: arguments['notify_attendees'] as bool,
        startTime: DateTime.parse(arguments['start_time'] as String),
        endTime: DateTime.parse(arguments['end_time'] as String),
      );

      developer.log('Created calendar event',
          name: 'CreateCalendarEventHandler',
          error: 'Event ID: ${result['id']}, Link: ${result['link']}');

      return createOutputEvent(
        callId: callId,
        output: {
          'success': true,
          'message': 'Calendar event created successfully',
          'event': result,
        },
      );
    } catch (e) {
      developer.log('Error creating calendar event',
          name: 'CreateCalendarEventHandler', error: e.toString());
      rethrow;
    }
  }
}
