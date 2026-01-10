import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gamification/streak.dart';
import '../../repositories/streak_repository.dart';
import '../../utils/logger.dart';
import '../repository_providers.dart';

/// State for streak tracking.
class StreakState {
  final List<Streak> streaks;
  final bool isLoading;
  final String? error;

  const StreakState({
    this.streaks = const [],
    this.isLoading = false,
    this.error,
  });

  StreakState copyWith({
    List<Streak>? streaks,
    bool? isLoading,
    String? error,
  }) {
    return StreakState(
      streaks: streaks ?? this.streaks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel for streak tracking.
class StreakViewModel extends Notifier<StreakState> {
  static const String _tag = 'StreakViewModel';

  @override
  StreakState build() {
    return const StreakState();
  }

  StreakRepository get _repository => ref.read(streakRepositoryProvider);

  Future<void> load({
    int? userId,
    StreakType? type,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final streaks = await _repository.getStreaks(userId: userId, type: type);
      state = state.copyWith(streaks: streaks, isLoading: false);
    } catch (e, stackTrace) {
      Logger.error('Failed to load streaks',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveStreak(Streak streak) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.saveStreak(streak);
      await load(userId: streak.userId);
    } catch (e, stackTrace) {
      Logger.error('Failed to save streak',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteStreak(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteStreak(id);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to delete streak',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider for streak ViewModel.
final streakViewModelProvider = NotifierProvider<StreakViewModel, StreakState>(
  StreakViewModel.new,
);
