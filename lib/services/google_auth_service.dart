import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;

/// Custom AuthClient for Google APIs
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this.headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}

class GoogleAuthService {
  // Store scopes for persistence
  static const List<String> _requiredScopes = [
    'email',
    'https://www.googleapis.com/auth/calendar',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/gmail.modify',
  ];

  final GoogleSignIn _googleSignIn;

  GoogleAuthService() : _googleSignIn = GoogleSignIn(scopes: _requiredScopes);

  // Stream of Google auth state changes
  Stream<GoogleSignInAccount?> get authStateChanges =>
      _googleSignIn.onCurrentUserChanged;

  // Sign in with Google and authenticate with backend
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      return googleUser != null;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Check if the user has granted required permissions by making test API calls
  Future<Map<String, bool>> checkIntegrationPermissions() async {
    final Map<String, bool> permissions = {
      'calendar': false,
      'drive': false,
      'gmail': false,
    };

    try {
      final GoogleSignInAccount? currentUser =
          await _googleSignIn.signInSilently();

      if (currentUser == null) return permissions;

      try {
        final auth = await currentUser.authentication;
        if (auth.accessToken == null) return permissions;

        final headers = await _getAuthHeaders();
        if (headers == null) return permissions;

        // Test Calendar API
        try {
          final client = GoogleAuthClient(headers);
          final calendarApi = calendar.CalendarApi(client);
          await calendarApi.calendarList.list(maxResults: 1);
          permissions['calendar'] = true;
        } catch (e) {
          print('Calendar API test failed: $e');
        }

        // Test Drive API
        try {
          final client = GoogleAuthClient(headers);
          final driveApi = drive.DriveApi(client);
          await driveApi.files.list(pageSize: 1);
          permissions['drive'] = true;
        } catch (e) {
          print('Drive API test failed: $e');
        }

        // Test Gmail API
        try {
          final client = GoogleAuthClient(headers);
          final gmailApi = gmail.GmailApi(client);
          await gmailApi.users.labels.list('me');
          client.close();
          permissions['gmail'] = true;
        } catch (e) {
          print('Gmail API test failed: $e');
        }
      } catch (e) {
        print('Error verifying token: $e');
      }
    } catch (e) {
      print('Error checking permissions: $e');
    }

    return permissions;
  }

  /// Helper to get auth headers for API calls
  Future<Map<String, String>?> _getAuthHeaders() async {
    try {
      final GoogleSignInAccount? currentUser =
          await _googleSignIn.signInSilently();

      if (currentUser == null) return null;

      final auth = await currentUser.authentication;
      if (auth.accessToken == null) return null;

      return {
        'Authorization': 'Bearer ${auth.accessToken}',
        'Accept': 'application/json',
      };
    } catch (e) {
      print('Error getting auth headers: $e');
      return null;
    }
  }

  Future<bool> requestRequiredScopesPermission() async {
    try {
      // Request additional permissions
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error requesting calendar permissions: $e');
      return false;
    }
  }
}
