import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';

abstract interface class SettlementRepo {
  AsyncRequest<Settlement> computeSettlement({
    required String cycleId,
    DateTime? calculationDate,
    bool save = false,
  });

  AsyncRequest<Settlement?> getCycleSettlement({required String cycleId});
}
