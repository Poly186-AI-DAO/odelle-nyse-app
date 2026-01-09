import 'base_tool.dart';

/// Tool for creating documents in Google Drive
class CreateDriveDocumentTool implements BaseTool {
  @override
  String get type => 'function';

  @override
  String get name => 'create_drive_document';

  @override
  String get description => 'Create a new document in Google Drive.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'strict': true,
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Title of the document',
          },
          'content': {
            'type': 'string',
            'description': 'Content of the document',
          },
          'folder_id': {
            'type': 'string',
            'description':
                'Optional ID of the folder to create the document in',
          },
        },
        'required': [
          'title',
          'content',
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
