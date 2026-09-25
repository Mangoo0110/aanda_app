import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class UploadHouseAvatarParams {
  const UploadHouseAvatarParams({
    required this.houseId,
    required this.fileBytes,
    required this.fileExtension,
  });

  final String houseId;
  final List<int> fileBytes;
  final String fileExtension;
}

class UploadHouseAvatar implements AsyncUsecase<String, UploadHouseAvatarParams> {
  const UploadHouseAvatar({required HouseRepo repo}) : _repo = repo;

  final HouseRepo _repo;

  @override
  AsyncRequest<String> call(UploadHouseAvatarParams params) {
    return _repo.uploadHouseAvatar(
      houseId: params.houseId,
      fileBytes: params.fileBytes,
      fileExtension: params.fileExtension,
    );
  }
}
