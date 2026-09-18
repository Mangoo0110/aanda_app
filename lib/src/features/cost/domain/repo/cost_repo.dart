import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_type.dart';

class CreateCostData {
  const CreateCostData({
    required this.name,
    required this.amount,
    required this.costType,
    required this.costScope,
    required this.purchaseDate,
    this.houseId,
    this.cycleId,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.note,
    this.paidBy,
  });

  final String name;
  final double amount;
  final CostType costType;
  final CostScope costScope;
  final DateTime purchaseDate;
  final String? houseId;
  final String? cycleId;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? note;
  final String? paidBy;
}

class UpdateCostData {
  const UpdateCostData({
    required this.id,
    required this.name,
    required this.amount,
    required this.costType,
    required this.costScope,
    required this.purchaseDate,
    this.houseId,
    this.cycleId,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.note,
    this.paidBy,
  });

  final String id;
  final String name;
  final double amount;
  final CostType costType;
  final CostScope costScope;
  final DateTime purchaseDate;
  final String? houseId;
  final String? cycleId;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? note;
  final String? paidBy;
}

abstract interface class CostRepo {
  /// Fetches costs with optional filters for house, scope (personal vs shared), and date range.
  AsyncRequest<List<Cost>> getCosts({
    String? houseId,
    CostScope? scope,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Adds a new cost entry.
  AsyncRequest<Cost> addCost(CreateCostData data);

  /// Updates an existing cost entry.
  AsyncRequest<Cost> updateCost(UpdateCostData data);

  /// Deletes a cost entry by id.
  AsyncRequest<void> deleteCost({required String costId});

  /// Fetches available categories (predefined + custom for [houseId]).
  AsyncRequest<List<CostCategory>> getCategories({String? houseId});

  /// Creates a new custom cost category preset.
  AsyncRequest<CostCategory> createCategory(CreateCostCategoryData data);
}

class CreateCostCategoryData {
  const CreateCostCategoryData({
    required this.name,
    required this.icon,
    this.isFood = false,
    this.houseId,
    this.defaultAmount,
    this.costNature = 'fixed',
  });

  final String name;
  final String icon;
  final bool isFood;
  final String? houseId;
  final double? defaultAmount;
  final String costNature;
}
