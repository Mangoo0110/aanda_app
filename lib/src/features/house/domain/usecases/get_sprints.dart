import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

final class GetSprints implements AsyncUsecase<List<Sprint>, String> {
  const GetSprints(this._repo);

  final HouseRepo _repo;

  @override
  AsyncRequest<List<Sprint>> call(String houseId) {
    return _repo.getSprints(houseId: houseId);
  }
}
