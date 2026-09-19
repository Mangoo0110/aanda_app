import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/repo/settlement_repo.dart';

class GetCycleSettlementParams {
  const GetCycleSettlementParams({required this.cycleId});
  final String cycleId;
}

final class GetCycleSettlement
    implements AsyncUsecase<Settlement?, GetCycleSettlementParams> {
  const GetCycleSettlement(this._repo);

  final SettlementRepo _repo;

  @override
  AsyncRequest<Settlement?> call(GetCycleSettlementParams params) {
    return _repo.getCycleSettlement(cycleId: params.cycleId);
  }
}
