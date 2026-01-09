import 'base_tool.dart';

/// Tool for listing recent emails from Gmail
class ListEmailsTool implements BaseTool {
  @override
  String get type => 'function';

  @override
  String get name => 'list_emails';

  @override
  String get description => 'List recent emails from Gmail inbox.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'strict': true,
        'properties': {
          'max_results': {
            'type': 'integer',
            'description': 'Maximum number of emails to return (default: 5)',
            'minimum': 1,
            'maximum': 15,
          },
          'query': {
            'type': 'string',
            'description': 'Search query to filter emails (optional)',
          },
        },
        'required': [],
      };

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'description': description,
        'parameters': parameters,
      };
}
