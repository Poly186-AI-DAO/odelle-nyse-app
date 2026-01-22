import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/tracking/meditation_log.dart';
import '../service_providers.dart';

class DailyMeditation {
  final String title;
  final String description;
  final int durationMinutes;
  final String type;
  final String? imagePath;
  final String? audioPath;

  const DailyMeditation({
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.type,
    this.imagePath,
    this.audioPath,
  });

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
  final String? error;

  const DailyContentState({
    required this.selectedDate,
    this.mantras = const [],
    this.meditations = const [],
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
  });

  DailyContentState copyWith({
    DateTime? selectedDate,
    List<String>? mantras,
    List<DailyMeditation>? meditations,
    bool? isLoading,
    bool? isGenerating,
    String? error,
  }) {
    return DailyContentState(
      selectedDate: selectedDate ?? this.selectedDate,
      mantras: mantras ?? this.mantras,
      meditations: meditations ?? this.meditations,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
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

    if (shouldGenerate || missingTypes.isNotEmpty || mantras.isEmpty) {
      state = state.copyWith(isGenerating: true);
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
    final rows = await db.query(
      'generation_queue',
      where: "type = ? AND status = 'completed' AND content_date = ?",
      whereArgs: ['mantras', dateKey],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) return [];

    final output = rows.first['output_data'] as String?;
    if (output == null || output.isEmpty) return [];

    try {
      final decoded = jsonDecode(output) as Map<String, dynamic>;
      final list = decoded['mantras'] as List?;
      if (list == null) return [];
      return list.map((m) => m.toString()).toList();
    } catch (_) {
      return [];
    }
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
        final duration =
            (decoded['duration_minutes'] as num?)?.toInt() ?? 10;
        final imagePath = decoded['imagePath']?.toString() ??
            row['image_path']?.toString();
        final audioPath = decoded['audioPath']?.toString() ??
            row['audio_path']?.toString();

        byType[type] = DailyMeditation(
          title: title,
          description: description,
          durationMinutes: duration,
          type: type,
          imagePath: imagePath,
          audioPath: audioPath,
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
}

final dailyContentViewModelProvider =
    NotifierProvider<DailyContentViewModel, DailyContentState>(
        DailyContentViewModel.new);
