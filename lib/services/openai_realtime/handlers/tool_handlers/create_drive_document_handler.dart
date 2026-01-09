import 'dart:developer' as developer;
import 'package:odelle_nyse/services/google_drive_service.dart';
import 'base_tool_handler.dart';

/// Handler for creating documents in Google Drive
class CreateDriveDocumentHandler extends BaseToolHandler {
  @override
  String get toolName => 'create_drive_document';

  @override
  Future<Map<String, dynamic>> handle({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final result = await DriveClient().createDocument(
        title: arguments['title'] as String,
        content: arguments['content'] as String,
        folderId: arguments['folder_id'] as String?,
      );

      developer.log('Created Drive document',
          name: 'CreateDriveDocumentHandler',
          error:
              'Document ID: ${result['id']}, Link: ${result['webViewLink']}');

      return createOutputEvent(
        callId: callId,
        output: {
          'success': true,
          'message': 'Document created successfully',
          'document': result,
        },
      );
    } catch (e) {
      developer.log('Error creating Drive document',
          name: 'CreateDriveDocumentHandler', error: e.toString());
      rethrow;
    }
  }
}
