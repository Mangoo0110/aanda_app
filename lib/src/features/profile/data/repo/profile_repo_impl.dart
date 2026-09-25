import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/async_handlers/response.dart';
import 'package:aanda/src/core/error_handler/error_handler.dart';
import 'package:aanda/src/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:aanda/src/features/profile/domain/entities/user_profile.dart';
import 'package:aanda/src/features/profile/domain/repo/profile_repo.dart';

class ProfileRepoImpl with ErrorHandler implements ProfileRepo {
  ProfileRepoImpl({required ProfileRemoteDatasource datasource})
    : _datasource = datasource;

  final ProfileRemoteDatasource _datasource;

  @override
  AsyncRequest<UserProfile> getProfile({required String userId}) {
    return asyncTryCatch(
      tryFunc: () async {
        final map = await _datasource.getProfile(userId);
        return SuccessRepoCall(data: UserProfile.fromMap(map));
      },
    );
  }

  @override
  AsyncRequest<UserProfile> updateProfile({required UserProfile profile}) {
    return asyncTryCatch(
      tryFunc: () async {
        final map = await _datasource.updateProfile(profile);
        return SuccessRepoCall(data: UserProfile.fromMap(map));
      },
    );
  }

  @override
  AsyncRequest<String> uploadAvatar({
    required String userId,
    required List<int> fileBytes,
    required String fileExtension,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final publicUrl = await _datasource.uploadAvatar(
          userId: userId,
          fileBytes: fileBytes,
          fileExtension: fileExtension,
        );
        return SuccessRepoCall(data: publicUrl);
      },
    );
  }

  @override
  AsyncRequest<void> markOnboarded({required String userId}) {
    return asyncTryCatch(
      tryFunc: () async {
        await _datasource.markOnboarded(userId);
        return const SuccessRepoCall(data: null);
      },
    );
  }
}
