import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/profile/domain/entities/user_profile.dart';
import 'package:aanda/src/features/profile/domain/repo/profile_repo.dart';

final class GetUserProfile implements AsyncUsecase<UserProfile, String> {
  const GetUserProfile(this._repo);
  final ProfileRepo _repo;

  @override
  AsyncRequest<UserProfile> call(String userId) {
    return _repo.getProfile(userId: userId);
  }
}

final class UpdateUserProfile implements AsyncUsecase<UserProfile, UserProfile> {
  const UpdateUserProfile(this._repo);
  final ProfileRepo _repo;

  @override
  AsyncRequest<UserProfile> call(UserProfile profile) {
    return _repo.updateProfile(profile: profile);
  }
}

final class UploadAvatarParams {
  const UploadAvatarParams({
    required this.userId,
    required this.fileBytes,
    required this.fileExtension,
  });

  final String userId;
  final List<int> fileBytes;
  final String fileExtension;
}

final class UploadProfileAvatar
    implements AsyncUsecase<String, UploadAvatarParams> {
  const UploadProfileAvatar(this._repo);
  final ProfileRepo _repo;

  @override
  AsyncRequest<String> call(UploadAvatarParams params) {
    return _repo.uploadAvatar(
      userId: params.userId,
      fileBytes: params.fileBytes,
      fileExtension: params.fileExtension,
    );
  }
}

final class MarkProfileOnboarded implements AsyncUsecase<void, String> {
  const MarkProfileOnboarded(this._repo);
  final ProfileRepo _repo;

  @override
  AsyncRequest<void> call(String userId) {
    return _repo.markOnboarded(userId: userId);
  }
}
