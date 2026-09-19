import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class CreateSprintParams {
  const CreateSprintParams({
    required this.houseId,
    required this.label,
    required this.startDate,
    this.endDate, // null = open cycle; set only when admin closes it
  });

  final String houseId;
  final String label;
  final DateTime startDate;
  final DateTime? endDate;
}

final class CreateSprint implements AsyncUsecase<Sprint, CreateSprintParams> {
  const CreateSprint(this._repo);

  final HouseRepo _repo;

  @override
  AsyncRequest<Sprint> call(CreateSprintParams params) {
    return _repo.createSprint(
      houseId: params.houseId,
      label: params.label,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
