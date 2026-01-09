import 'package:odelle_nyse/services/google_auth_service.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CalendarServiceException implements Exception {
  final String message;
  final dynamic originalError;

  CalendarServiceException(this.message, [this.originalError]);

  @override
  String toString() =>
      'CalendarServiceException: $message${originalError != null ? ' ($originalError)' : ''}';
}

class CalendarClient {
  static CalendarApi? _calendar;

  /// Ensures the Calendar API is initialized by checking if we have a valid instance
  /// or creating a new one using Google Sign In
  static Future<void> _ensureInitialized() async {
    if (_calendar == null) {
      final googleSignIn = GoogleSignIn(
        scopes: ['https://www.googleapis.com/auth/calendar'],
      );
      final account = await googleSignIn.signInSilently();
      if (account == null) {
        throw CalendarServiceException('Not signed in to Google');
      }
      final auth = await account.authentication;
      if (auth.accessToken == null) {
        throw CalendarServiceException('Failed to get access token');
      }

      final headers = {
        'Authorization': 'Bearer ${auth.accessToken}',
        'Accept': 'application/json',
      };
      final client = GoogleAuthClient(headers);
      _calendar = CalendarApi(client);
    }
  }

  /// Creates a new calendar event and returns the event details
  Future<Map<String, String>> insert({
    required String title,
    required String description,
    required String location,
    required List<EventAttendee> attendeeEmailList,
    required bool shouldNotifyAttendees,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      await _ensureInitialized();

      const String calendarId = "primary";
      // Convert times to local timezone string in IANA format
      final String localTimeZone = DateTime.now().timeZoneName;

      final Event event = Event(
        summary: title,
        description: description,
        attendees: attendeeEmailList,
        location: location,
        start: EventDateTime(
          dateTime: startTime,
          timeZone: localTimeZone,
        ),
        end: EventDateTime(
          dateTime: endTime,
          timeZone: localTimeZone,
        ),
      );

      final Event createdEvent = await _calendar!.events.insert(
        event,
        calendarId,
        sendUpdates: shouldNotifyAttendees ? "all" : "none",
      );

      return {
        'id': createdEvent.id ?? '',
        'link': createdEvent.htmlLink ?? '',
        'status': createdEvent.status ?? '',
        'summary': createdEvent.summary ?? '',
        'start': createdEvent.start?.dateTime?.toIso8601String() ?? '',
        'end': createdEvent.end?.dateTime?.toIso8601String() ?? '',
      };
    } catch (e) {
      throw CalendarServiceException('Failed to create calendar event', e);
    }
  }

  /// Deletes a calendar event
  Future<void> delete(String eventId) async {
    try {
      await _ensureInitialized();

      await _calendar!.events.delete('primary', eventId);
    } catch (e) {
      throw CalendarServiceException('Failed to delete calendar event', e);
    }
  }

  /// Lists upcoming calendar events
  Future<List<Event>> listUpcoming({int maxResults = 10}) async {
    try {
      await _ensureInitialized();

      // Get local timezone
      final String localTimeZone = DateTime.now().timeZoneName;

      final events = await _calendar!.events.list(
        'primary',
        maxResults: maxResults,
        timeMin: DateTime.now().toUtc(),
        timeZone: localTimeZone, // Ensure results are in local timezone
        orderBy: 'startTime',
        singleEvents: true,
      );

      return events.items ?? [];
    } catch (e) {
      throw CalendarServiceException('Failed to list calendar events', e);
    }
  }
}
