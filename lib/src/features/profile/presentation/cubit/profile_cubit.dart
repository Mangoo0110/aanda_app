import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/profile/domain/entities/user_profile.dart';
import 'package:aanda/src/features/profile/domain/usecases/profile_usecases.dart';

part 'profile_state.dart';

final class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetUserProfile getUserProfile,
    required UpdateUserProfile updateUserProfile,
    required UploadProfileAvatar uploadProfileAvatar,
    required MarkProfileOnboarded markProfileOnboarded,
  })  : _getUserProfile = getUserProfile,
        _updateUserProfile = updateUserProfile,
        _uploadProfileAvatar = uploadProfileAvatar,
        _markProfileOnboarded = markProfileOnboarded,
        super(const ProfileState());

  final GetUserProfile _getUserProfile;
  final UpdateUserProfile _updateUserProfile;
  final UploadProfileAvatar _uploadProfileAvatar;
  final MarkProfileOnboarded _markProfileOnboarded;

  /// Loads the profile for the given [userId].
  Future<UserProfile?> loadProfile(String userId) async {
    if (state.isLoading) return state.profile;
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));

    final profile = await handleFutureRequest<UserProfile>(
      request: () => _getUserProfile(userId),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            status: ProfileStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
    );

    if (profile != null) {
      emit(state.copyWith(status: ProfileStatus.loaded, profile: profile));
    }
    return profile;
  }

  /// Updates profile attributes.
  Future<bool> updateProfile(UserProfile updated) async {
    emit(state.copyWith(status: ProfileStatus.updating, clearError: true));

    final result = await handleFutureRequest<UserProfile>(
      request: () => _updateUserProfile(updated),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            status: ProfileStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
    );

    if (result != null) {
      emit(state.copyWith(status: ProfileStatus.loaded, profile: result));
      return true;
    }
    return false;
  }

  /// Uploads user avatar image bytes and updates current profile.
  Future<String?> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String extension,
  }) async {
    emit(state.copyWith(isUploadingAvatar: true, clearError: true));

    final avatarUrl = await handleFutureRequest<String>(
      request: () => _uploadProfileAvatar(
        UploadAvatarParams(
          userId: userId,
          fileBytes: bytes,
          fileExtension: extension,
        ),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            isUploadingAvatar: false,
            errorMessage: failure.message,
          ),
        );
      },
    );

    emit(state.copyWith(isUploadingAvatar: false));

    if (avatarUrl != null && state.profile != null) {
      final updatedProfile = state.profile!.copyWith(avatarUrl: avatarUrl);
      await updateProfile(updatedProfile);
      return avatarUrl;
    }
    return avatarUrl;
  }

  /// Mark onboarding finished (user clicked skip or finished).
  Future<void> completeOnboarding(String userId) async {
    await handleFutureRequest<void>(
      request: () => _markProfileOnboarded(userId),
      debugger: ControllerDebugger(),
      onError: (_) {},
    );
    if (state.profile != null) {
      emit(
        state.copyWith(
          profile: state.profile!.copyWith(isOnboarded: true),
        ),
      );
    }
  }
}
