import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/tracking/meditation_log.dart';
import '../../services/daily_content_service.dart';
import '../../services/media_storage_service.dart';
import '../../utils/logger.dart';
import '../service_providers.dart';

class DailyMeditation {
  final String title;
  final String description;
  final int durationMinutes;
  final String type;
  final String? imagePath;
  final String? imageUrl; // Firebase Storage URL
  final String? audioPath;
  final String? audioUrl; // Firebase Storage URL

  const DailyMeditation({
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.type,
    this.imagePath,
    this.imageUrl,
    this.audioPath,
    this.audioUrl,
  });

  /// Get the effective audio path - downloads from Firebase if local doesn't exist
  Future<String?> getEffectiveAudioPath() async {
    // Check if local file exists
    if (audioPath != null && audioPath!.isNotEmpty) {
      final file = File(audioPath!);
      if (await file.exists()) {
        return audioPath;
      }
    }
    // Fallback to downloading from Firebase
    if (audioUrl != null && audioUrl!.isNotEmpty) {
      return MediaStorageService.instance.downloadAudio(audioUrl!);
    }
    return null;
  }

  /// Get the effective image path - downloads from Firebase if local doesn't exist
  Future<String?> getEffectiveImagePath() async {
    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (await file.exists()) {
        return imagePath;
      }
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return MediaStorageService.instance.getLocalPath(imageUrl!);
    }
    return null;
  }

  MeditationType get meditationType => _mapMeditationType(type);

  static MeditationType _mapMeditationType(String type) {
    switch (type) {
      case 'morning':
        return MeditationType.mindfulness;
      case 'focus':
        return MeditationType.breathing;
      case 'evening':
        return MeditationType.bodyScan;
      default:
        return MeditationType.mindfulness;
    }
  }
}

class DailyContentState {
  final DateTime selectedDate;
  final List<String> mantras;
  final List<DailyMeditation> meditations;
  final bool isLoading;
  final bool isGenerating;
  final bool
      pendingGeneration; // True when content needs to be generated but awaiting approval
  final Map<String, dynamic>? quotaInfo; // ElevenLabs quota info
  final String? error;

  const DailyContentState({
    required this.selectedDate,
    this.mantras = const [],
    this.meditations = const [],
    this.isLoading = false,
    this.isGenerating = false,
    this.pendingGeneration = false,
    this.quotaInfo,
    this.error,
  });

  DailyContentState copyWith({
    DateTime? selectedDate,
    List<String>? mantras,
    List<DailyMeditation>? meditations,
    bool? isLoading,
    bool? isGenerating,
    bool? pendingGeneration,
    Map<String, dynamic>? quotaInfo,
    String? error,
  }) {
    return DailyContentState(
      selectedDate: selectedDate ?? this.selectedDate,
      mantras: mantras ?? this.mantras,
      meditations: meditations ?? this.meditations,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      pendingGeneration: pendingGeneration ?? this.pendingGeneration,
      quotaInfo: quotaInfo ?? this.quotaInfo,
      error: error,
    );
  }
}

class DailyContentViewModel extends Notifier<DailyContentState> {
  static const List<String> _defaultMeditationTypes = [
    'morning',
    'focus',
    'evening',
  ];

  Timer? _midnightTimer;

  @override
  DailyContentState build() {
    final now = DateTime.now();
    _scheduleMidnightRefresh(now);
    ref.onDispose(() {
      _midnightTimer?.cancel();
    });

    Future.microtask(() => refreshForDate(now));
    return DailyContentState(selectedDate: now);
  }

  Future<void> refreshForDate(DateTime date) async {
    state = state.copyWith(selectedDate: date, isLoading: true, error: null);

    try {
      if (_isToday(date)) {
        await _ensureDailyContent();
      }

      await _loadFromDatabase(date);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _scheduleMidnightRefresh(DateTime now) {
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    _midnightTimer?.cancel();
    _midnightTimer = Timer(duration, () {
      refreshForDate(DateTime.now());
      _scheduleMidnightRefresh(DateTime.now());
    });
  }

  Future<void> _ensureDailyContent() async {
    final service = ref.read(dailyContentServiceProvider);
    final db = ref.read(databaseProvider);
    final dateKey = _dateKey(DateTime.now());

    final dbInstance = await db.database;
    final meditationRows = await _fetchMeditationRows(dbInstance, dateKey);
    final existingTypes = _extractMeditationTypes(meditationRows);
    final missingTypes = _defaultMeditationTypes
        .where((type) => !existingTypes.contains(type))
        .toList();

    final mantras = await _fetchMantras(dbInstance, dateKey);
    final shouldGenerate = await service.shouldGenerateForToday();

    final needsGeneration =
        shouldGenerate || missingTypes.isNotEmpty || mantras.isEmpty;

    if (needsGeneration) {
      // Check if auto-generation is enabled
      final prefs = await SharedPreferences.getInstance();
      final autoGenerate = prefs.getBool('autoGenerateMeditations') ?? false;

      if (autoGenerate) {
        // Auto-generate (user has opted in)
        await _performGeneration(
          service: service,
          shouldGenerate: shouldGenerate,
          mantras: mantras,
          missingTypes: missingTypes,
        );
      } else {
        // Mark as pending - require user approval
        // Fetch quota info to show user
        final quotaInfo = await service.checkQuota();
        state = state.copyWith(
          pendingGeneration: true,
          quotaInfo: quotaInfo,
        );
      }
    }
  }

  /// Manually trigger generation (called when user approves)
  Future<void> generateContent() async {
    final service = ref.read(dailyContentServiceProvider);
    final db = ref.read(databaseProvider);
    final dateKey = _dateKey(DateTime.now());

    final dbInstance = await db.database;
    final meditationRows = await _fetchMeditationRows(dbInstance, dateKey);
    final existingTypes = _extractMeditationTypes(meditationRows);
    final missingTypes = _defaultMeditationTypes
        .where((type) => !existingTypes.contains(type))
        .toList();

    final mantras = await _fetchMantras(dbInstance, dateKey);
    final shouldGenerate = await service.shouldGenerateForToday();

    await _performGeneration(
      service: service,
      shouldGenerate: shouldGenerate,
      mantras: mantras,
      missingTypes: missingTypes,
    );

    // Reload content after generation
    await _loadFromDatabase(state.selectedDate);
  }

  /// Internal method to perform the actual generation
  Future<void> _performGeneration({
    required DailyContentService service,
    required bool shouldGenerate,
    required List<String> mantras,
    required List<String> missingTypes,
  }) async {
    state = state.copyWith(isGenerating: true, pendingGeneration: false);
    try {
      if (shouldGenerate || mantras.isEmpty) {
        await service.generateDailyMantras(count: 4);
      }

      if (shouldGenerate || missingTypes.isNotEmpty) {
        await service.generateDailyMeditations(
          types: missingTypes.isEmpty ? _defaultMeditationTypes : missingTypes,
        );
      }

      await service.markGeneratedToday();
    } finally {
      state = state.copyWith(isGenerating: false);
    }
  }

  Future<void> _loadFromDatabase(DateTime date) async {
    final db = ref.read(databaseProvider);
    final dbInstance = await db.database;
    final dateKey = _dateKey(date);

    final meditationRows = await _fetchMeditationRows(dbInstance, dateKey);
    final mantras = await _fetchMantras(dbInstance, dateKey);

    final meditations = _parseMeditations(meditationRows);

    state = state.copyWith(
      mantras: mantras,
      meditations: meditations,
      isLoading: false,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMeditationRows(
    Database db,
    String dateKey,
  ) async {
    return db.query(
      'generation_queue',
      where: "type = ? AND status = 'completed' AND content_date = ?",
      whereArgs: ['meditation', dateKey],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<String>> _fetchMantras(Database db, String dateKey) async {
    // 1. Try today's generated mantras from generation_queue
    final rows = await db.query(
      'generation_queue',
      where: "type = ? AND status = 'completed' AND content_date = ?",
      whereArgs: ['mantras', dateKey],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    final parsed = _parseMantrasRows(rows);
    if (parsed.isNotEmpty) return parsed;

    // 2. Try most recent generated mantras from generation_queue
    final fallbackRows = await db.query(
      'generation_queue',
      where: "type = ? AND status = 'completed'",
      whereArgs: ['mantras'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    final fallbackParsed = _parseMantrasRows(fallbackRows);
    if (fallbackParsed.isNotEmpty) return fallbackParsed;

    // 3. Try mantras table (seeded by bootstrap from Princeps_Mantras.md)
    final appDb = ref.read(databaseProvider);
    final mantraRecords = await appDb.getMantras(activeOnly: true);
    if (mantraRecords.isNotEmpty) {
      // Shuffle and take 4 random mantras for variety
      final shuffled = List.of(mantraRecords)..shuffle();
      return shuffled.take(4).map((m) => m.text).toList();
    }

    // 4. Final fallback: seed mantras from service
    final service = ref.read(dailyContentServiceProvider);
    await service.initialize();
    if (service.mantras.isEmpty) return [];
    return service.mantras.take(4).toList();
  }

  List<String> _parseMantrasRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return [];
    final output = rows.first['output_data'] as String?;
    if (output == null || output.trim().isEmpty) return [];
    return _parseMantrasPayload(output);
  }

  List<String> _parseMantrasPayload(String output) {
    try {
      final decoded = jsonDecode(output);
      if (decoded is List) {
        return decoded.map((m) => m.toString()).toList();
      }
      if (decoded is Map<String, dynamic>) {
        final list = decoded['mantras'] as List?;
        if (list == null) return [];
        return list.map((m) => m.toString()).toList();
      }
      if (decoded is String && decoded.trim().isNotEmpty) {
        return [decoded.trim()];
      }
    } catch (_) {
      // Fall through to plaintext parsing below.
    }

    final lines = output
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^[-*•]\s*'), ''))
        .map((line) => line.replaceAll('"', '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return lines;
  }

  List<DailyMeditation> _parseMeditations(
    List<Map<String, dynamic>> rows,
  ) {
    final byType = <String, DailyMeditation>{};

    for (final row in rows) {
      final output = row['output_data'] as String?;
      if (output == null || output.isEmpty) continue;

      try {
        final decoded = jsonDecode(output) as Map<String, dynamic>;
        final type = _extractTypeFromRow(row, decoded);
        if (type == null || byType.containsKey(type)) continue;

        final title =
            decoded['title']?.toString() ?? _fallbackTitleForType(type);
        final description =
            decoded['description']?.toString() ?? _extractDescription(decoded);
        final duration = (decoded['duration_minutes'] as num?)?.toInt() ?? 10;
        final imagePath =
            decoded['imagePath']?.toString() ?? row['image_path']?.toString();
        final imageUrl = decoded['imageUrl']?.toString();
        final audioPath =
            decoded['audioPath']?.toString() ?? row['audio_path']?.toString();
        final audioUrl = decoded['audioUrl']?.toString();

        byType[type] = DailyMeditation(
          title: title,
          description: description,
          durationMinutes: duration,
          type: type,
          imagePath: imagePath,
          imageUrl: imageUrl,
          audioPath: audioPath,
          audioUrl: audioUrl,
        );
      } catch (_) {
        continue;
      }
    }

    final ordered = byType.values.toList()
      ..sort((a, b) => _typeOrder(a.type).compareTo(_typeOrder(b.type)));
    return ordered;
  }

  String? _extractTypeFromRow(
    Map<String, dynamic> row,
    Map<String, dynamic> decoded,
  ) {
    final type = decoded['type']?.toString();
    if (type != null && type.isNotEmpty) return type;

    final input = row['input_data'] as String?;
    if (input == null || input.isEmpty) return null;

    try {
      final decodedInput = jsonDecode(input) as Map<String, dynamic>;
      return decodedInput['type']?.toString();
    } catch (_) {
      return null;
    }
  }

  Set<String> _extractMeditationTypes(List<Map<String, dynamic>> rows) {
    final types = <String>{};
    for (final row in rows) {
      final output = row['output_data'] as String?;
      if (output == null || output.isEmpty) continue;

      try {
        final decoded = jsonDecode(output) as Map<String, dynamic>;
        final type = _extractTypeFromRow(row, decoded);
        if (type != null) {
          types.add(type);
        }
      } catch (_) {}
    }
    return types;
  }

  String _extractDescription(Map<String, dynamic> decoded) {
    final script = decoded['script']?.toString();
    if (script == null || script.isEmpty) return 'A guided meditation.';

    final cleaned = script.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= 140) return cleaned;
    return '${cleaned.substring(0, 140)}...';
  }

  String _fallbackTitleForType(String type) {
    switch (type) {
      case 'morning':
        return 'Morning Energy';
      case 'focus':
        return 'Focused Reset';
      case 'evening':
        return 'Evening Release';
      default:
        return 'Meditation';
    }
  }

  int _typeOrder(String type) {
    final index = _defaultMeditationTypes.indexOf(type);
    return index == -1 ? _defaultMeditationTypes.length : index;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _dateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Fetches all meditation history from the database (up to [limit] records).
  /// Returns a map grouped by date key (yyyy-MM-dd) for easy display.
  Future<Map<String, List<DailyMeditation>>> fetchMeditationHistory({
    int limit = 100,
  }) async {
    final dbInstance = await ref.read(databaseProvider).database;
    final rows = await dbInstance.query(
      'generation_queue',
      where: "type = ? AND status = 'completed'",
      whereArgs: ['meditation'],
      orderBy: 'content_date DESC, created_at DESC',
      limit: limit,
    );

    final grouped = <String, List<DailyMeditation>>{};

    Logger.debug('Fetching meditation history', tag: 'AudioDebug', data: {
      'rowCount': rows.length,
    });

    for (final row in rows) {
      final dateKey =
          row['content_date']?.toString() ?? _dateKey(DateTime.now());
      final output = row['output_data']?.toString();
      if (output == null || output.isEmpty) continue;

      try {
        final decoded = jsonDecode(output) as Map<String, dynamic>;
        final type = _extractTypeFromRow(row, decoded);
        final title = decoded['title']?.toString() ??
            _fallbackTitleForType(type ?? 'meditation');
        final description = _extractDescription(decoded);
        final audioPath =
            decoded['audioPath']?.toString() ?? row['audio_path']?.toString();
        final audioUrl = decoded['audioUrl']?.toString();
        final imagePath =
            decoded['imagePath']?.toString() ?? row['image_path']?.toString();
        final imageUrl = decoded['imageUrl']?.toString();
        final durationMin = (decoded['duration_minutes'] as num?)?.toInt() ??
            (decoded['durationMinutes'] as num?)?.toInt() ??
            5;

        Logger.debug('Parsed meditation from DB', tag: 'AudioDebug', data: {
          'title': title,
          'audioPath': audioPath,
          'rowAudioPath': row['audio_path'],
          'decodedAudioPath': decoded['audioPath'],
        });

        final meditation = DailyMeditation(
          title: title,
          description: description,
          durationMinutes: durationMin,
          type: type ?? 'meditation',
          audioPath: audioPath,
          audioUrl: audioUrl,
          imagePath: imagePath,
          imageUrl: imageUrl,
        );

        grouped.putIfAbsent(dateKey, () => []).add(meditation);
      } catch (_) {}
    }

    return grouped;
  }
}

final dailyContentViewModelProvider =
    NotifierProvider<DailyContentViewModel, DailyContentState>(
        DailyContentViewModel.new);
