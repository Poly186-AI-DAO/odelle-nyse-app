import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// Service for storing and retrieving media files (audio, images) from Firebase Storage.
/// Provides local caching for offline access and faster playback.
class MediaStorageService {
  static const String _tag = 'MediaStorageService';
  static MediaStorageService? _instance;

  final FirebaseStorage _storage;

  MediaStorageService._() : _storage = FirebaseStorage.instance;

  static MediaStorageService get instance {
    _instance ??= MediaStorageService._();
    return _instance!;
  }

  // ============================================================
  // UPLOAD METHODS
  // ============================================================

  /// Upload meditation audio to Firebase Storage.
  /// Returns the download URL on success, null on failure.
  /// Also saves locally for offline access.
  Future<String?> uploadMeditationAudio({
    required String filename,
    required List<int> audioBytes,
    required String meditationType,
    required String contentDate,
  }) async {
    try {
      final path =
          'meditations/audio/$contentDate/${meditationType}_$filename.mp3';

      // Upload to Firebase Storage
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: 'audio/mpeg',
        customMetadata: {
          'type': meditationType,
          'contentDate': contentDate,
          'generatedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putData(Uint8List.fromList(audioBytes), metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        Logger.debug('Upload progress: ${(progress * 100).toStringAsFixed(1)}%',
            tag: _tag);
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      Logger.info('Uploaded meditation audio to Firebase Storage',
          tag: _tag, data: {'path': path, 'size': audioBytes.length});

      // Also save locally for offline access
      await _saveLocalCache(path, Uint8List.fromList(audioBytes));

      return downloadUrl;
    } catch (e) {
      Logger.error('Failed to upload meditation audio: $e', tag: _tag);
      return null;
    }
  }

  /// Upload meditation image to Firebase Storage.
  /// Returns the download URL on success, null on failure.
  Future<String?> uploadMeditationImage({
    required String filename,
    required List<int> imageBytes,
    required String meditationType,
    required String contentDate,
  }) async {
    try {
      final path =
          'meditations/images/$contentDate/${meditationType}_$filename.png';

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'type': meditationType,
          'contentDate': contentDate,
        },
      );

      await ref.putData(Uint8List.fromList(imageBytes), metadata);
      final downloadUrl = await ref.getDownloadURL();

      Logger.info('Uploaded meditation image to Firebase Storage',
          tag: _tag, data: {'path': path});

      await _saveLocalCache(path, Uint8List.fromList(imageBytes));

      return downloadUrl;
    } catch (e) {
      Logger.error('Failed to upload meditation image: $e', tag: _tag);
      return null;
    }
  }

  // ============================================================
  // DOWNLOAD METHODS
  // ============================================================

  /// Get local file path for a Firebase Storage URL.
  /// Downloads if not cached locally.
  /// Returns local file path on success, null on failure.
  Future<String?> getLocalPath(String firebaseUrl) async {
    try {
      // Extract storage path from URL
      final ref = _storage.refFromURL(firebaseUrl);
      final storagePath = ref.fullPath;

      // Check local cache first
      final localPath = await _getLocalCachePath(storagePath);
      final localFile = File(localPath);

      if (await localFile.exists()) {
        Logger.debug('Using cached file: $localPath', tag: _tag);
        return localPath;
      }

      // Download from Firebase
      Logger.info('Downloading from Firebase: $storagePath', tag: _tag);
      final bytes = await ref.getData();

      if (bytes == null) {
        Logger.warning('Downloaded file is empty', tag: _tag);
        return null;
      }

      // Save to local cache
      await _saveLocalCache(storagePath, bytes);

      return localPath;
    } catch (e) {
      Logger.error('Failed to get local path for $firebaseUrl: $e', tag: _tag);
      return null;
    }
  }

  /// Download audio file from Firebase URL to local storage.
  /// Returns local file path on success, null on failure.
  Future<String?> downloadAudio(String firebaseUrl) async {
    return getLocalPath(firebaseUrl);
  }

  // ============================================================
  // CACHE MANAGEMENT
  // ============================================================

  Future<String> _getLocalCachePath(String storagePath) async {
    final dir = await getApplicationDocumentsDirectory();
    // Sanitize path for local filesystem
    final safePath = storagePath.replaceAll('/', '_').replaceAll(' ', '_');
    return '${dir.path}/media_cache/$safePath';
  }

  Future<void> _saveLocalCache(String storagePath, Uint8List bytes) async {
    try {
      final localPath = await _getLocalCachePath(storagePath);
      final file = File(localPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      Logger.debug('Saved to local cache: $localPath', tag: _tag);
    } catch (e) {
      Logger.warning('Failed to save local cache: $e', tag: _tag);
    }
  }

  /// Clear old cached files (older than specified days)
  Future<void> clearOldCache({int olderThanDays = 30}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/media_cache');

      if (!await cacheDir.exists()) return;

      final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));

      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entity.delete();
            Logger.debug('Deleted old cache file: ${entity.path}', tag: _tag);
          }
        }
      }
    } catch (e) {
      Logger.warning('Failed to clear old cache: $e', tag: _tag);
    }
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/media_cache');

      if (!await cacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================
  // MIGRATION: Upload existing local files to Firebase
  // ============================================================

  /// Upload a local audio file to Firebase Storage.
  /// Used for migrating existing local-only files to cloud.
  Future<String?> uploadLocalFileToFirebase({
    required String localPath,
    required String meditationType,
    required String contentDate,
  }) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        Logger.warning('Local file not found for upload: $localPath',
            tag: _tag);
        return null;
      }

      final bytes = await file.readAsBytes();
      final filename = localPath.split('/').last.replaceAll('.mp3', '');

      return uploadMeditationAudio(
        filename: filename,
        audioBytes: bytes,
        meditationType: meditationType,
        contentDate: contentDate,
      );
    } catch (e) {
      Logger.error('Failed to upload local file: $e', tag: _tag);
      return null;
    }
  }
}
