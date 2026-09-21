import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class GetSprintStatsParams {
  const GetSprintStatsParams({
    required this.houseId,
    this.cycleId,
    required this.startDate,
    required this.endDate,
  });

  final String houseId;
  final String? cycleId;
  final DateTime startDate;
  final DateTime endDate;
}

final class GetSprintStats
    implements AsyncUsecase<Map<String, dynamic>, GetSprintStatsParams> {
  const GetSprintStats(this._repo);

  final HouseRepo _repo;

  @override
  AsyncRequest<Map<String, dynamic>> call(GetSprintStatsParams params) {
    return _repo.getSprintStats(
      houseId: params.houseId,
      cycleId: params.cycleId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
