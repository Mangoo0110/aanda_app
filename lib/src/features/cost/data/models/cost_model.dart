import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_type.dart';

class CostModel extends Cost {
  const CostModel({
    required super.id,
    required super.name,
    required super.amount,
    required super.costType,
    required super.costScope,
    required super.paidBy,
    required super.purchaseDate,
    required super.createdAt,
    super.payerName,
    super.houseId,
    super.cycleId,
    super.categoryId,
    super.categoryName,
    super.categoryIcon,
    super.note,
  });

  factory CostModel.fromJson(Map<String, dynamic> json) {
    // Resolve joined profile
    final profile = json['profiles'] as Map<String, dynamic>?;
    final payerName = profile != null
        ? (profile['full_name'] as String?)?.isNotEmpty == true
            ? profile['full_name'] as String
            : profile['username'] as String?
        : null;

    // Resolve joined category or match predefined category
    final category = json['cost_categories'] as Map<String, dynamic>?;
    final categoryId = json['category_id'] as String?;
    String? categoryName = category?['name'] as String?;
    String? categoryIcon = category?['icon'] as String?;

    if (categoryName == null && categoryId != null) {
      final matchedPredefined = CostCategory.predefinedCategories.where(
        (c) => c.id == categoryId,
      ).firstOrNull;
      if (matchedPredefined != null) {
        categoryName = matchedPredefined.name;
        categoryIcon = matchedPredefined.icon;
      }
    }

    return CostModel(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      costType: CostTypeX.fromString(json['cost_type'] as String),
      costScope: CostScopeX.fromString(json['cost_scope'] as String),
      paidBy: json['paid_by'] as String,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      payerName: payerName,
      houseId: json['house_id'] as String?,
      cycleId: json['cycle_id'] as String?,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'cost_type': costType.name,
    'cost_scope': costScope.name,
    'paid_by': paidBy,
    'purchase_date':
        '${purchaseDate.year.toString().padLeft(4, '0')}-'
        '${purchaseDate.month.toString().padLeft(2, '0')}-'
        '${purchaseDate.day.toString().padLeft(2, '0')}',
    'created_at': createdAt.toIso8601String(),
    if (houseId != null) 'house_id': houseId,
    if (cycleId != null) 'cycle_id': cycleId,
    if (categoryId != null && !categoryId!.startsWith('predefined_'))
      'category_id': categoryId,
    if (note != null) 'note': note,
  };
}
