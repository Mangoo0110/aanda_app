import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/repo/settlement_repo.dart';

class RecordSettlementPaymentParams {
  const RecordSettlementPaymentParams({
    required this.settlementId,
    required this.userId,
    required this.amount,
    this.note,
  });

  final String settlementId;
  final String userId;
  final double amount;
  final String? note;
}

final class RecordSettlementPayment
    implements AsyncUsecase<Settlement, RecordSettlementPaymentParams> {
  const RecordSettlementPayment(this._repo);

  final SettlementRepo _repo;

  @override
  AsyncRequest<Settlement> call(RecordSettlementPaymentParams params) {
    return _repo.recordSettlementPayment(
      settlementId: params.settlementId,
      userId: params.userId,
      amount: params.amount,
      note: params.note,
    );
  }
}
