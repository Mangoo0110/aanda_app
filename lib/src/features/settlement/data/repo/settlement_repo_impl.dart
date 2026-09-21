import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/async_handlers/response.dart';
import 'package:aanda/src/core/error_handler/error_handler.dart';
import 'package:aanda/src/features/settlement/data/datasources/settlement_remote_datasource.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement_draft.dart';
import 'package:aanda/src/features/settlement/domain/repo/settlement_repo.dart';

class SettlementRepoImpl with ErrorHandler implements SettlementRepo {
  const SettlementRepoImpl({required SettlementRemoteDatasource datasource})
    : _datasource = datasource;

  final SettlementRemoteDatasource _datasource;

  @override
  AsyncRequest<SettlementDraft> prepareSettlement({
    required String houseId,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final draft = await _datasource.fetchSettlementDraft(
          houseId: houseId,
          fromDate: fromDate,
          toDate: toDate,
        );
        return SuccessRepoCall(data: draft);
      },
    );
  }

  @override
  AsyncRequest<Settlement> computeSettlement({
    required String houseId,
    required DateTime fromDate,
    required DateTime toDate,
    required List<String> costIds,
    bool save = false,
    String? label,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final settlement = await _datasource.computeSettlement(
          houseId: houseId,
          fromDate: fromDate,
          toDate: toDate,
          costIds: costIds,
          save: save,
          label: label,
        );
        return SuccessRepoCall(data: settlement);
      },
    );
  }

  @override
  AsyncRequest<List<Settlement>> getSettlements({required String houseId}) {
    return asyncTryCatch(
      tryFunc: () async {
        final settlements =
            await _datasource.getSettlements(houseId: houseId);
        return SuccessRepoCall(data: settlements);
      },
    );
  }
}
