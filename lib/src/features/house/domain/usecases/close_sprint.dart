import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class CloseSprintParams {
  const CloseSprintParams({required this.cycleId, this.closedAt});

  final String cycleId;
  final DateTime? closedAt;
}

final class CloseSprint implements AsyncUsecase<Sprint, CloseSprintParams> {
  const CloseSprint(this._repo);

  final HouseRepo _repo;

  @override
  AsyncRequest<Sprint> call(CloseSprintParams params) {
    return _repo.closeSprint(
      cycleId: params.cycleId,
      closedAt: params.closedAt,
    );
  }
}
