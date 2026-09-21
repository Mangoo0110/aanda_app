import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement_draft.dart';

abstract interface class SettlementRepo {
  /// Fetches unsettled costs split into in-range and outstanding groups.
  AsyncRequest<SettlementDraft> prepareSettlement({
    required String houseId,
    required DateTime fromDate,
    required DateTime toDate,
  });

  /// Calls the edge function to compute and optionally save a settlement.
  AsyncRequest<Settlement> computeSettlement({
    required String houseId,
    required DateTime fromDate,
    required DateTime toDate,
    required List<String> costIds,
    bool save = false,
    String? label,
  });

  /// Lists all finalised settlements for an account, newest first.
  AsyncRequest<List<Settlement>> getSettlements({required String houseId});
}
