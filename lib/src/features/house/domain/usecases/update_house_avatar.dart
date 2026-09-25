import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class UpdateHouseAvatarParams {
  const UpdateHouseAvatarParams({
    required this.houseId,
    required this.avatarUrl,
  });

  final String houseId;
  final String avatarUrl;
}

class UpdateHouseAvatar implements AsyncUsecase<void, UpdateHouseAvatarParams> {
  const UpdateHouseAvatar({required HouseRepo repo}) : _repo = repo;

  final HouseRepo _repo;

  @override
  AsyncRequest<void> call(UpdateHouseAvatarParams params) {
    return _repo.updateHouseAvatar(
      houseId: params.houseId,
      avatarUrl: params.avatarUrl,
    );
  }
}
