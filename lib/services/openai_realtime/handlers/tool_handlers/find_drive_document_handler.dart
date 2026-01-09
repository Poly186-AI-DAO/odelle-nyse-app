import 'dart:developer' as developer;
import 'package:odelle_nyse/services/google_drive_service.dart';
import 'base_tool_handler.dart';

/// Handler for finding documents in Google Drive by title
class FindDriveDocumentHandler extends BaseToolHandler {
  @override
  String get toolName => 'find_drive_document';

  @override
  Future<Map<String, dynamic>> handle({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final result = await DriveClient().findDocumentByTitle(
        arguments['title'] as String,
      );

      if (result == null) {
        return createOutputEvent(
          callId: callId,
          output: {
            'success': false,
            'message': 'Document not found',
          },
        );
      }

      developer.log('Found Drive document',
          name: 'FindDriveDocumentHandler',
          error:
              'Document ID: ${result['id']}, Link: ${result['webViewLink']}');

      return createOutputEvent(
        callId: callId,
        output: {
          'success': true,
          'message': 'Document found successfully',
          'document': result,
        },
      );
    } catch (e) {
      developer.log('Error finding Drive document',
          name: 'FindDriveDocumentHandler', error: e.toString());
      rethrow;
    }
  }
}
