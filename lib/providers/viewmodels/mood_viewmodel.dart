import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mood/mood_entry.dart';
import '../../models/mood/mood_trend.dart';
import '../../repositories/mood_repository.dart';
import '../../utils/logger.dart';
import '../repository_providers.dart';

/// State for mood tracking.
class MoodState {
  final List<MoodEntry> entries;
  final MoodTrend? trend;
  final bool isLoading;
  final String? error;

  const MoodState({
    this.entries = const [],
    this.trend,
    this.isLoading = false,
    this.error,
  });

  MoodState copyWith({
    List<MoodEntry>? entries,
    MoodTrend? trend,
    bool? isLoading,
    String? error,
  }) {
    return MoodState(
      entries: entries ?? this.entries,
      trend: trend ?? this.trend,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel for mood tracking.
class MoodViewModel extends Notifier<MoodState> {
  static const String _tag = 'MoodViewModel';

  @override
  MoodState build() {
    return const MoodState();
  }

  MoodRepository get _repository => ref.read(moodRepositoryProvider);

  Future<void> load({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    TrendPeriod period = TrendPeriod.month,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final entries = await _repository.getMoodEntries(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      MoodTrend? trend;
      if (entries.isNotEmpty) {
        DateTime earliest = entries.first.timestamp;
        DateTime latest = entries.first.timestamp;
        for (final entry in entries) {
          if (entry.timestamp.isBefore(earliest)) {
            earliest = entry.timestamp;
          }
          if (entry.timestamp.isAfter(latest)) {
            latest = entry.timestamp;
          }
        }
        final resolvedStart = startDate ?? earliest;
        final resolvedEnd = endDate ?? latest;
        trend = MoodTrend.fromEntries(
          startDate: resolvedStart,
          endDate: resolvedEnd,
          period: period,
          entries: entries,
        );
      }

      state = state.copyWith(
        entries: entries,
        trend: trend,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to load mood entries',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logMood(MoodEntry entry) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.logMood(entry);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to log mood entry',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateMood(MoodEntry entry) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateMood(entry);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to update mood entry',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteMood(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteMood(id);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to delete mood entry',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider for mood ViewModel.
final moodViewModelProvider = NotifierProvider<MoodViewModel, MoodState>(
  MoodViewModel.new,
);
