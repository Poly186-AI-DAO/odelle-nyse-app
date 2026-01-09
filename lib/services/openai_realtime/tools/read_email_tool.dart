import 'base_tool.dart';

/// Tool for reading a specific email from Gmail
class ReadEmailTool implements BaseTool {
  @override
  String get type => 'function';

  @override
  String get name => 'read_email';

  @override
  String get description =>
      'Read the full content of a specific email by its ID.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'strict': true,
        'properties': {
          'email_id': {
            'type': 'string',
            'description': 'ID of the email to read',
          },
        },
        'required': ['email_id'],
      };

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'description': description,
        'parameters': parameters,
      };
}
