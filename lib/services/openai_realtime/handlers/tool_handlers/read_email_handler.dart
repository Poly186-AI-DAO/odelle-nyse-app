import 'dart:developer' as developer;
import 'package:odelle_nyse/services/google_gmail_service.dart';

import 'base_tool_handler.dart';

/// Handler for reading a specific email from Gmail
class ReadEmailHandler extends BaseToolHandler {
  @override
  String get toolName => 'read_email';

  @override
  Future<Map<String, dynamic>> handle({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final emailId = arguments['email_id'] as String;
      final email = await GmailClient().readEmail(emailId);

      developer.log('Read email',
          name: 'ReadEmailHandler', error: 'Email ID: $emailId');

      return createOutputEvent(
        callId: callId,
        output: {
          'success': true,
          'message': 'Email retrieved successfully',
          'email': email,
        },
      );
    } catch (e) {
      developer.log('Error reading email',
          name: 'ReadEmailHandler', error: e.toString());
      rethrow;
    }
  }
}
