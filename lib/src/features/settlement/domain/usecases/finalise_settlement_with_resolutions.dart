import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/repo/settlement_repo.dart';

class FinaliseSettlementWithResolutionsParams {
  const FinaliseSettlementWithResolutionsParams({
    required this.settlementId,
    required this.resolutions,
  });

  final String settlementId;
  final List<MemberResolutionParams> resolutions;
}

final class FinaliseSettlementWithResolutions
    implements AsyncUsecase<Settlement, FinaliseSettlementWithResolutionsParams> {
  const FinaliseSettlementWithResolutions(this._repo);

  final SettlementRepo _repo;

  @override
  AsyncRequest<Settlement> call(FinaliseSettlementWithResolutionsParams params) {
    return _repo.finaliseSettlementWithResolutions(
      settlementId: params.settlementId,
      resolutions: params.resolutions,
    );
  }
}
