import 'package:aanda/src/features/cost/domain/entities/cost.dart';

/// Represents the un-finalised data gathered when the user starts a settlement:
/// the in-range costs and any outstanding (previously excluded) costs.
class SettlementDraft {
  const SettlementDraft({
    required this.houseId,
    required this.fromDate,
    required this.toDate,
    required this.inRangeCosts,
    required this.outstandingCosts,
  });

  final String houseId;
  final DateTime fromDate;
  final DateTime toDate;

  /// Costs whose purchase_date falls within [fromDate, toDate] and are unsettled.
  final List<Cost> inRangeCosts;

  /// Past costs (purchase_date < fromDate) that were never included in any
  /// prior settlement — i.e. costs with settlement_id IS NULL.
  final List<Cost> outstandingCosts;

  List<Cost> get allCosts => [...inRangeCosts, ...outstandingCosts];
}
