import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/async_handlers/response.dart';
import 'package:aanda/src/core/error_handler/error_handler.dart';
import 'package:aanda/src/features/settlement/data/datasources/settlement_remote_datasource.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/repo/settlement_repo.dart';

class SettlementRepoImpl with ErrorHandler implements SettlementRepo {
  const SettlementRepoImpl({required SettlementRemoteDatasource datasource})
    : _datasource = datasource;

  final SettlementRemoteDatasource _datasource;

  @override
  AsyncRequest<Settlement> computeSettlement({
    required String cycleId,
    DateTime? calculationDate,
    bool save = false,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final settlement = await _datasource.computeSettlement(
          cycleId: cycleId,
          calculationDate: calculationDate,
          save: save,
        );
        return SuccessRepoCall(data: settlement);
      },
    );
  }
}
