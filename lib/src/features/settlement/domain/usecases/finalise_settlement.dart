import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/repo/settlement_repo.dart';

/// Alias for ComputeSettlement with save=true.
class FinaliseSettlementParams {
  const FinaliseSettlementParams({
    required this.houseId,
    required this.fromDate,
    required this.toDate,
    required this.includedCostIds,
    this.label,
  });

  final String houseId;
  final DateTime fromDate;
  final DateTime toDate;
  final List<String> includedCostIds;
  final String? label;
}

final class FinaliseSettlement
    implements AsyncUsecase<Settlement, FinaliseSettlementParams> {
  const FinaliseSettlement(this._repo);

  final SettlementRepo _repo;

  @override
  AsyncRequest<Settlement> call(FinaliseSettlementParams params) {
    return _repo.computeSettlement(
      houseId: params.houseId,
      fromDate: params.fromDate,
      toDate: params.toDate,
      costIds: params.includedCostIds,
      save: true,
      label: params.label,
    );
  }
}
