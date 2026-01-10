import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/habits/habit.dart';
import '../../models/habits/habit_log.dart';
import '../../repositories/habit_repository.dart';
import '../../utils/logger.dart';
import '../repository_providers.dart';

/// State for habit tracking.
class HabitState {
  final List<Habit> habits;
  final List<HabitLog> logs;
  final bool isLoading;
  final String? error;

  const HabitState({
    this.habits = const [],
    this.logs = const [],
    this.isLoading = false,
    this.error,
  });

  HabitState copyWith({
    List<Habit>? habits,
    List<HabitLog>? logs,
    bool? isLoading,
    String? error,
  }) {
    return HabitState(
      habits: habits ?? this.habits,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel for habit tracking.
class HabitViewModel extends Notifier<HabitState> {
  static const String _tag = 'HabitViewModel';

  @override
  HabitState build() {
    return const HabitState();
  }

  HabitRepository get _repository => ref.read(habitRepositoryProvider);

  Future<void> load({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    bool activeOnly = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final habits =
          await _repository.getHabits(userId: userId, activeOnly: activeOnly);
      final logs =
          await _repository.getHabitLogs(startDate: startDate, endDate: endDate);
      state = state.copyWith(habits: habits, logs: logs, isLoading: false);
    } catch (e, stackTrace) {
      Logger.error('Failed to load habit data',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createHabit(Habit habit) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createHabit(habit);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to create habit',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateHabit(Habit habit) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateHabit(habit);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to update habit',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteHabit(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteHabit(id);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to delete habit',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logHabit({
    required int habitId,
    required DateTime date,
    bool isCompleted = true,
    int? count,
    int? durationMinutes,
    String? notes,
    HabitLogStatus status = HabitLogStatus.completed,
    DateTime? completedAt,
    int? journalEntryId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.logHabit(
        habitId: habitId,
        date: date,
        isCompleted: isCompleted,
        count: count,
        durationMinutes: durationMinutes,
        notes: notes,
        status: status,
        completedAt: completedAt,
        journalEntryId: journalEntryId,
      );
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to log habit',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider for habit ViewModel.
final habitViewModelProvider = NotifierProvider<HabitViewModel, HabitState>(
  HabitViewModel.new,
);
