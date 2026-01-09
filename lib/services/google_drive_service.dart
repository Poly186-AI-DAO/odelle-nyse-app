import 'package:googleapis/drive/v3.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_auth_service.dart';

class DriveServiceException implements Exception {
  final String message;
  final dynamic originalError;

  DriveServiceException(this.message, [this.originalError]);

  @override
  String toString() =>
      'DriveServiceException: $message${originalError != null ? ' ($originalError)' : ''}';
}

class DriveClient {
  static DriveApi? _drive;

  /// Ensures the Drive API is initialized by checking if we have a valid instance
  /// or creating a new one using Google Sign In
  static Future<void> _ensureInitialized() async {
    if (_drive == null) {
      final googleSignIn = GoogleSignIn(
        scopes: ['https://www.googleapis.com/auth/drive.file'],
      );
      final account = await googleSignIn.signInSilently();
      if (account == null) {
        throw DriveServiceException('Not signed in to Google');
      }
      final auth = await account.authentication;
      if (auth.accessToken == null) {
        throw DriveServiceException('Failed to get access token');
      }

      final headers = {
        'Authorization': 'Bearer ${auth.accessToken}',
        'Accept': 'application/json',
      };
      final client = GoogleAuthClient(headers);
      _drive = DriveApi(client);
    }
  }

  /// Creates a new document in Google Drive
  Future<Map<String, String>> createDocument({
    required String title,
    required String content,
    String? folderId,
  }) async {
    try {
      await _ensureInitialized();

      // Create file metadata
      final file = File()
        ..name = title
        ..mimeType = 'application/vnd.google-apps.document';

      // Upload the file
      final result = await _drive!.files.create(
        file,
        uploadMedia: Media(
          Stream.value(content.codeUnits),
          content.length,
          contentType: 'text/plain',
        ),
      );

      if (result.id == null) {
        throw DriveServiceException(
            'Failed to create document: No ID returned');
      }

      return {
        'id': result.id!,
        'name': result.name ?? title,
        'webViewLink': result.webViewLink ?? '',
        'webContentLink': result.webContentLink ?? '',
      };
    } catch (e) {
      throw DriveServiceException('Failed to create document', e);
    }
  }

  /// Lists documents in Google Drive
  Future<List<Map<String, String>>> listDocuments({
    int maxResults = 10,
    String? folderId,
    String? query,
  }) async {
    try {
      await _ensureInitialized();

      // Build query string
      String queryString = "mimeType = 'application/vnd.google-apps.document'";
      if (folderId != null) {
        queryString += " and '$folderId' in parents";
      }
      if (query != null) {
        queryString += " and name contains '$query'";
      }

      final result = await _drive!.files.list(
        q: queryString,
        pageSize: maxResults,
        spaces: 'drive',
        $fields:
            'files(id, name, webViewLink, webContentLink, createdTime, modifiedTime)',
      );

      return (result.files ?? [])
          .map((file) => {
                'id': file.id ?? '',
                'name': file.name ?? '',
                'webViewLink': file.webViewLink ?? '',
                'webContentLink': file.webContentLink ?? '',
                'createdTime': file.createdTime?.toIso8601String() ?? '',
                'modifiedTime': file.modifiedTime?.toIso8601String() ?? '',
              })
          .toList();
    } catch (e) {
      throw DriveServiceException('Failed to list documents', e);
    }
  }

  /// Reads a document from Google Drive
  Future<String> readDocument(String fileId) async {
    try {
      await _ensureInitialized();

      final media = await _drive!.files.get(
        fileId,
        downloadOptions: DownloadOptions.fullMedia,
      ) as Media;

      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }

      return String.fromCharCodes(dataStore);
    } catch (e) {
      throw DriveServiceException('Failed to read document', e);
    }
  }

  /// Updates a document in Google Drive
  Future<Map<String, String>> updateDocument({
    required String fileId,
    required String content,
    String? newTitle,
  }) async {
    try {
      await _ensureInitialized();

      // Update metadata if title is provided
      File? metadata;
      if (newTitle != null) {
        metadata = File()..name = newTitle;
      }

      // Update the file
      final result = await _drive!.files.update(
        metadata ?? File(),
        fileId,
        uploadMedia: Media(
          Stream.value(content.codeUnits),
          content.length,
          contentType: 'text/plain',
        ),
      );

      return {
        'id': result.id ?? fileId,
        'name': result.name ?? newTitle ?? '',
        'webViewLink': result.webViewLink ?? '',
        'webContentLink': result.webContentLink ?? '',
      };
    } catch (e) {
      throw DriveServiceException('Failed to update document', e);
    }
  }

  /// Deletes a document from Google Drive
  Future<void> deleteDocument(String fileId) async {
    try {
      await _ensureInitialized();

      await _drive!.files.delete(fileId);
    } catch (e) {
      throw DriveServiceException('Failed to delete document', e);
    }
  }

  /// Finds a document by its exact title and returns both metadata and content
  /// Returns null if no document is found with the exact title
  Future<Map<String, dynamic>?> findDocumentByTitle(String title) async {
    try {
      await _ensureInitialized();

      // Use exact title match in query
      String queryString =
          "mimeType = 'application/vnd.google-apps.document' and name = '$title'";

      final result = await _drive!.files.list(
        q: queryString,
        pageSize: 1, // We only need one result since title should be unique
        spaces: 'drive',
        $fields:
            'files(id, name, webViewLink, webContentLink, createdTime, modifiedTime)',
      );

      if (result.files == null || result.files!.isEmpty) {
        return null;
      }

      final file = result.files!.first;
      final fileId = file.id;
      if (fileId == null) {
        throw DriveServiceException('File found but has no ID');
      }

      // Get the document content
      final content = await readDocument(fileId);

      return {
        'id': fileId,
        'name': file.name ?? '',
        'webViewLink': file.webViewLink ?? '',
        'webContentLink': file.webContentLink ?? '',
        'createdTime': file.createdTime?.toIso8601String() ?? '',
        'modifiedTime': file.modifiedTime?.toIso8601String() ?? '',
        'content': content,
      };
    } catch (e) {
      throw DriveServiceException('Failed to find document by title', e);
    }
  }
}
