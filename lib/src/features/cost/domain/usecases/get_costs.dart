import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';

class GetCostsParams {
  const GetCostsParams({
    this.houseId,
    this.scope,
    this.startDate,
    this.endDate,
  });

  final String? houseId;
  final CostScope? scope;
  final DateTime? startDate;
  final DateTime? endDate;
}

final class GetCosts implements AsyncUsecase<List<Cost>, GetCostsParams> {
  const GetCosts(this._repo);
  final CostRepo _repo;

  @override
  AsyncRequest<List<Cost>> call(GetCostsParams params) => _repo.getCosts(
    houseId: params.houseId,
    scope: params.scope,
    startDate: params.startDate,
    endDate: params.endDate,
  );
}
