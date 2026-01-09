import 'base_tool.dart';

/// Tool for finding documents in Google Drive by title
class FindDriveDocumentTool implements BaseTool {
  @override
  String get type => 'function';

  @override
  String get name => 'find_drive_document';

  @override
  String get description =>
      'Find a document in Google Drive by its exact title.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'strict': true,
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Exact title of the document to find',
          },
        },
        'required': ['title'],
      };

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'description': description,
        'parameters': parameters,
      };
}
