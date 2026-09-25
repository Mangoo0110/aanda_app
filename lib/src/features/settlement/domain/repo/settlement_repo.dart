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
    String? status,
    String? label,
  });

  /// Records a payment towards a published settlement statement.
  AsyncRequest<Settlement> recordSettlementPayment({
    required String settlementId,
    required String userId,
    required double amount,
    String? note,
  });

  /// Finalises a settlement with explicit per-member balance resolutions.
  AsyncRequest<Settlement> finaliseSettlementWithResolutions({
    required String settlementId,
    required List<MemberResolutionParams> resolutions,
  });

  /// Gets the currently open published settlement statement if one exists.
  AsyncRequest<Settlement?> getPublishedSettlement({required String houseId});

  /// Lists all finalised settlements for an account, newest first.
  AsyncRequest<List<Settlement>> getSettlements({required String houseId});
}

