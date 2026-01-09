import 'base_tool.dart';

/// Tool for creating calendar events
class CreateCalendarEventTool implements BaseTool {
  @override
  String get type => 'function';

  @override
  String get name => 'create_calendar_event';

  @override
  String get description => 'Create a new event in Google Calendar.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'strict': true,
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Title of the calendar event',
          },
          'description': {
            'type': 'string',
            'description': 'Description of the calendar event',
          },
          'location': {
            'type': 'string',
            'description': 'Location of the event',
          },
          'start_time': {
            'type': 'string',
            'description': 'Start time of the event in ISO 8601 format',
          },
          'end_time': {
            'type': 'string',
            'description': 'End time of the event in ISO 8601 format',
          },
          'attendee_emails': {
            'type': 'array',
            'items': {
              'type': 'string',
              'description': 'Email address of an attendee',
            },
            'description': 'List of attendee email addresses',
          },
          'notify_attendees': {
            'type': 'boolean',
            'description': 'Whether to send email notifications to attendees',
          },
        },
        'required': [
          'title',
          'description',
          'location',
          'start_time',
          'end_time',
          'attendee_emails',
          'notify_attendees',
        ],
      };

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'description': description,
        'parameters': parameters,
      };
}
