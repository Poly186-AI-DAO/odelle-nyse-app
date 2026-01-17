import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_profile_repository.dart';
import '../repositories/journal_repository.dart';
import '../repositories/dose_repository.dart';
import '../repositories/habit_repository.dart';
import '../repositories/mood_repository.dart';
import '../repositories/streak_repository.dart';
import '../repositories/meal_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/wealth_repository.dart';
import '../repositories/bonds_repository.dart';
import 'service_providers.dart';

/// Repository providers
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return UserProfileRepository(db);
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return JournalRepository(db);
});

final doseRepositoryProvider = Provider<DoseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DoseRepository(db);
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return HabitRepository(db);
});

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return MoodRepository(db);
});

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return StreakRepository(db);
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return MealRepository(db);
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkoutRepository(db);
});

final wealthRepositoryProvider = Provider<WealthRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WealthRepository(db);
});

final bondsRepositoryProvider = Provider<BondsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BondsRepository(db);
});

