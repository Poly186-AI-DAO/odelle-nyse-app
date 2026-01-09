import 'base_tool.dart';

/// Tool for sending emails via Gmail
class SendEmailTool implements BaseTool {
  @override
  String get type => 'function';

  @override
  String get name => 'send_email';

  @override
  String get description => 'Send an email using Gmail.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'strict': true,
        'properties': {
          'to': {
            'type': 'string',
            'description': 'Email address of the recipient',
          },
          'subject': {
            'type': 'string',
            'description': 'Subject line of the email',
          },
          'body': {
            'type': 'string',
            'description': 'Content of the email',
          },
          'cc': {
            'type': 'string',
            'description': 'CC email addresses (comma-separated)',
          },
          'bcc': {
            'type': 'string',
            'description': 'BCC email addresses (comma-separated)',
          },
        },
        'required': [
          'to',
          'subject',
          'body',
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
