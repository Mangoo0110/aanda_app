import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement_draft.dart';
import 'package:aanda/src/features/settlement/domain/repo/settlement_repo.dart';

class PrepareSettlementParams {
  const PrepareSettlementParams({
    required this.houseId,
    required this.fromDate,
    required this.toDate,
  });

  final String houseId;
  final DateTime fromDate;
  final DateTime toDate;
}

final class PrepareSettlement
    implements AsyncUsecase<SettlementDraft, PrepareSettlementParams> {
  const PrepareSettlement(this._repo);

  final SettlementRepo _repo;

  @override
  AsyncRequest<SettlementDraft> call(PrepareSettlementParams params) {
    return _repo.prepareSettlement(
      houseId: params.houseId,
      fromDate: params.fromDate,
      toDate: params.toDate,
    );
  }
}
