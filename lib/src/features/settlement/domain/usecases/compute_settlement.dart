import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/repo/settlement_repo.dart';

class ComputeSettlementParams {
  const ComputeSettlementParams({
    required this.houseId,
    required this.fromDate,
    required this.toDate,
    required this.costIds,
    this.save = false,
    this.status,
    this.label,
  });

  final String houseId;
  final DateTime fromDate;
  final DateTime toDate;
  final List<String> costIds;
  final bool save;
  final String? status;
  final String? label;
}

final class ComputeSettlement
    implements AsyncUsecase<Settlement, ComputeSettlementParams> {
  const ComputeSettlement(this._repo);

  final SettlementRepo _repo;

  @override
  AsyncRequest<Settlement> call(ComputeSettlementParams params) {
    return _repo.computeSettlement(
      houseId: params.houseId,
      fromDate: params.fromDate,
      toDate: params.toDate,
      costIds: params.costIds,
      save: params.save,
      status: params.status,
      label: params.label,
    );
  }
}
