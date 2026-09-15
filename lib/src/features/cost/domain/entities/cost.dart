import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_type.dart';

class Cost {
  const Cost({
    required this.id,
    required this.name,
    required this.amount,
    required this.costType,
    required this.costScope,
    required this.paidBy,
    required this.purchaseDate,
    required this.createdAt,
    this.payerName,
    this.houseId,
    this.cycleId,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.note,
  });

  final String id;
  final String name;
  final double amount;
  final CostType costType;
  final CostScope costScope;
  final String paidBy;
  final String? payerName;
  final String? houseId;
  final String? cycleId;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final DateTime purchaseDate;
  final String? note;
  final DateTime createdAt;

  bool get isPersonal => costScope == CostScope.personal;
  bool get isShared => costScope == CostScope.shared;
}
