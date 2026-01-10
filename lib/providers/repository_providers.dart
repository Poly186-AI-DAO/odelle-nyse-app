import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_profile_repository.dart';
import '../repositories/dose_repository.dart';
import '../repositories/habit_repository.dart';
import '../repositories/mood_repository.dart';
import '../repositories/streak_repository.dart';
import 'service_providers.dart';

/// Repository providers
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return UserProfileRepository(db);
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
