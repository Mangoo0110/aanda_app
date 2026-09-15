import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/repo/settlement_repo.dart';

class ComputeSettlementParams {
  const ComputeSettlementParams({
    required this.cycleId,
    this.calculationDate,
    this.save = false,
  });

  final String cycleId;
  final DateTime? calculationDate;
  final bool save;
}

final class ComputeSettlement
    implements AsyncUsecase<Settlement, ComputeSettlementParams> {
  const ComputeSettlement(this._repo);

  final SettlementRepo _repo;

  @override
  AsyncRequest<Settlement> call(ComputeSettlementParams params) {
    return _repo.computeSettlement(
      cycleId: params.cycleId,
      calculationDate: params.calculationDate,
      save: params.save,
    );
  }
}
