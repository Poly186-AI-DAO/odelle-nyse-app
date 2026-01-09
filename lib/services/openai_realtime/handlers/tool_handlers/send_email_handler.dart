import 'dart:developer' as developer;
import 'package:odelle_nyse/services/google_gmail_service.dart';

import 'base_tool_handler.dart';

/// Handler for sending emails via Gmail
class SendEmailHandler extends BaseToolHandler {
  @override
  String get toolName => 'send_email';

  @override
  Future<Map<String, dynamic>> handle({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final emailId = await GmailClient().sendEmail(
        to: arguments['to'] as String,
        subject: arguments['subject'] as String,
        body: arguments['body'] as String,
        cc: arguments['cc'] as String?,
        bcc: arguments['bcc'] as String?,
      );

      developer.log('Sent email',
          name: 'SendEmailHandler', error: 'Email ID: $emailId');

      return createOutputEvent(
        callId: callId,
        output: {
          'success': true,
          'message': 'Email sent successfully',
          'emailId': emailId,
        },
      );
    } catch (e) {
      developer.log('Error sending email',
          name: 'SendEmailHandler', error: e.toString());
      rethrow;
    }
  }
}
