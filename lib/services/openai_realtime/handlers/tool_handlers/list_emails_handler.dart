import 'dart:developer' as developer;
import 'package:odelle_nyse/services/google_gmail_service.dart';

import 'base_tool_handler.dart';

/// Handler for listing recent emails from Gmail
class ListEmailsHandler extends BaseToolHandler {
  @override
  String get toolName => 'list_emails';

  @override
  Future<Map<String, dynamic>> handle({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final maxResults = arguments['max_results'] as int? ?? 20;
      final query = arguments['query'] as String?;

      final emails = await GmailClient().listRecentEmails(
        maxResults: maxResults,
        query: query,
      );

      developer.log('Listed emails',
          name: 'ListEmailsHandler',
          error: 'Count: ${emails.length}, Query: ${query ?? "none"}');

      return createOutputEvent(
        callId: callId,
        output: {
          'success': true,
          'message': 'Retrieved ${emails.length} emails',
          'emails': emails,
        },
      );
    } catch (e) {
      developer.log('Error listing emails',
          name: 'ListEmailsHandler', error: e.toString());
      rethrow;
    }
  }
}
