import 'dart:convert';
import 'package:odelle_nyse/services/google_auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail_api;

class GmailServiceException implements Exception {
  final String message;
  final dynamic originalError;

  GmailServiceException(this.message, [this.originalError]);

  @override
  String toString() =>
      'GmailServiceException: $message${originalError != null ? ' ($originalError)' : ''}';
}

class GmailClient {
  static gmail_api.GmailApi? _gmail;

  /// Gets the Gmail API instance, ensuring it's initialized first
  static Future<gmail_api.GmailApi> get gmail async {
    await _ensureInitialized();
    return _gmail!;
  }

  /// Ensures the Gmail API is initialized by checking if we have a valid instance
  /// or creating a new one using Google Sign In
  static Future<void> _ensureInitialized() async {
    if (_gmail == null) {
      final googleSignIn = GoogleSignIn(
        scopes: ['https://www.googleapis.com/auth/gmail.modify'],
      );
      final account = await googleSignIn.signInSilently();
      if (account == null) {
        throw GmailServiceException('Not signed in to Google');
      }
      final auth = await account.authentication;
      if (auth.accessToken == null) {
        throw GmailServiceException('Failed to get access token');
      }

      final headers = {
        'Authorization': 'Bearer ${auth.accessToken}',
        'Accept': 'application/json',
      };
      final client = GoogleAuthClient(headers);
      _gmail = gmail_api.GmailApi(client);
    }
  }

  /// Lists recent emails (without full content)
  Future<List<Map<String, String>>> listRecentEmails({
    int maxResults = 20,
    String? query,
  }) async {
    try {
      final gmailApi = await gmail;
      final response = await gmailApi.users.messages.list(
        'me',
        maxResults: maxResults,
        q: query,
      );

      final messages = response.messages ?? [];
      final List<Map<String, String>> emailList = [];

      for (var message in messages) {
        if (message.id == null) continue;

        final details = await gmailApi.users.messages.get(
          'me',
          message.id!,
          format: 'metadata',
          metadataHeaders: ['Subject', 'From', 'Date'],
        );

        final headers = details.payload?.headers ?? [];
        final Map<String, String> emailData = {
          'id': message.id!,
          'subject': headers
                  .firstWhere((h) => h.name == 'Subject',
                      orElse: () =>
                          gmail_api.MessagePartHeader()..value = '(no subject)')
                  .value ??
              '(no subject)',
          'from': headers
                  .firstWhere((h) => h.name == 'From',
                      orElse: () => gmail_api.MessagePartHeader()..value = '')
                  .value ??
              '',
          'date': headers
                  .firstWhere((h) => h.name == 'Date',
                      orElse: () => gmail_api.MessagePartHeader()..value = '')
                  .value ??
              '',
          'snippet': details.snippet ?? '',
        };

        emailList.add(emailData);
      }

      return emailList;
    } catch (e) {
      throw GmailServiceException('Failed to list emails', e);
    }
  }

  /// Reads a specific email's content
  Future<Map<String, dynamic>> readEmail(String emailId) async {
    try {
      final gmailApi = await gmail;
      final message = await gmailApi.users.messages.get(
        'me',
        emailId,
        format: 'full',
      );

      final headers = message.payload?.headers ?? [];
      final parts = message.payload?.parts ?? [];

      String content = '';

      // Extract content from parts
      for (var part in parts) {
        if (part.mimeType == 'text/plain' && part.body?.data != null) {
          content = _decodeBase64Url(part.body!.data!);
          break;
        }
      }

      // If no parts found, try body directly
      if (content.isEmpty && message.payload?.body?.data != null) {
        content = _decodeBase64Url(message.payload!.body!.data!);
      }

      return {
        'id': message.id ?? '',
        'threadId': message.threadId ?? '',
        'subject': headers
                .firstWhere((h) => h.name == 'Subject',
                    orElse: () =>
                        gmail_api.MessagePartHeader()..value = '(no subject)')
                .value ??
            '(no subject)',
        'from': headers
                .firstWhere((h) => h.name == 'From',
                    orElse: () => gmail_api.MessagePartHeader()..value = '')
                .value ??
            '',
        'to': headers
                .firstWhere((h) => h.name == 'To',
                    orElse: () => gmail_api.MessagePartHeader()..value = '')
                .value ??
            '',
        'date': headers
                .firstWhere((h) => h.name == 'Date',
                    orElse: () => gmail_api.MessagePartHeader()..value = '')
                .value ??
            '',
        'content': content,
      };
    } catch (e) {
      throw GmailServiceException('Failed to read email', e);
    }
  }

  /// Sends a new email
  Future<String> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
  }) async {
    try {
      final gmailApi = await gmail;

      final StringBuffer emailContent = StringBuffer()
        ..write('From: me\n')
        ..write('To: $to\n');

      if (cc != null) emailContent.write('Cc: $cc\n');
      if (bcc != null) emailContent.write('Bcc: $bcc\n');

      emailContent
        ..write('Subject: $subject\n')
        ..write('Content-Type: text/plain; charset=utf-8\n')
        ..write('\n')
        ..write(body);

      final encodedEmail = _base64UrlEncode(emailContent.toString());

      final message = await gmailApi.users.messages.send(
        gmail_api.Message(
          raw: encodedEmail,
        ),
        'me',
      );

      return message.id ?? '';
    } catch (e) {
      throw GmailServiceException('Failed to send email', e);
    }
  }

  /// Helper method to decode base64Url encoded strings
  String _decodeBase64Url(String input) {
    String output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw GmailServiceException('Invalid base64url length');
    }
    return String.fromCharCodes(base64Decode(output));
  }

  /// Helper method to encode strings to base64Url
  String _base64UrlEncode(String input) {
    return base64Url.encode(utf8.encode(input));
  }
}
