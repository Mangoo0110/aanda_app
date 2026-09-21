import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/repo/settlement_repo.dart';

class GetSettlementsParams {
  const GetSettlementsParams({required this.houseId});
  final String houseId;
}

final class GetSettlements
    implements AsyncUsecase<List<Settlement>, GetSettlementsParams> {
  const GetSettlements(this._repo);

  final SettlementRepo _repo;

  @override
  AsyncRequest<List<Settlement>> call(GetSettlementsParams params) {
    return _repo.getSettlements(houseId: params.houseId);
  }
}
