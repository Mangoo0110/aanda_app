import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

final class GetMyHouses implements AsyncUsecase<List<House>, NoParams> {
  const GetMyHouses(this._repo);
  final HouseRepo _repo;

  @override
  AsyncRequest<List<House>> call(NoParams params) => _repo.getMyHouses();
}
