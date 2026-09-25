part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, loaded, updating, failure }

final class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.isUploadingAvatar = false,
  });

  final ProfileStatus status;
  final UserProfile? profile;
  final String? errorMessage;
  final bool isUploadingAvatar;

  bool get isLoading => status == ProfileStatus.loading;
  bool get isUpdating => status == ProfileStatus.updating;
  bool get isLoaded => status == ProfileStatus.loaded && profile != null;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    String? errorMessage,
    bool clearError = false,
    bool? isUploadingAvatar,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
    );
  }
}
