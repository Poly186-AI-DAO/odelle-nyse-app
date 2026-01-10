import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user/user_profile.dart';
import '../../repositories/user_profile_repository.dart';
import '../../utils/logger.dart';
import '../repository_providers.dart';

/// State for user profile.
class UserProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const UserProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  UserProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel for user profile.
class UserProfileViewModel extends Notifier<UserProfileState> {
  static const String _tag = 'UserProfileViewModel';

  @override
  UserProfileState build() {
    return const UserProfileState();
  }

  UserProfileRepository get _repository =>
      ref.read(userProfileRepositoryProvider);

  Future<void> loadProfile(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.getProfile(id);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e, stackTrace) {
      Logger.error('Failed to load user profile',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final id = await _repository.saveProfile(profile);
      final updatedProfile = profile.id == null
          ? profile.copyWith(id: id)
          : profile;
      state = state.copyWith(profile: updatedProfile, isLoading: false);
    } catch (e, stackTrace) {
      Logger.error('Failed to save user profile',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteProfile(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteProfile(id);
      state = state.copyWith(profile: null, isLoading: false);
    } catch (e, stackTrace) {
      Logger.error('Failed to delete user profile',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider for user profile ViewModel.
final userProfileViewModelProvider =
    NotifierProvider<UserProfileViewModel, UserProfileState>(
  UserProfileViewModel.new,
);
