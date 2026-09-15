import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';

class CostCategoryModel extends CostCategory {
  const CostCategoryModel({
    required super.id,
    required super.name,
    super.icon,
    super.isFood,
    super.houseId,
  });

  factory CostCategoryModel.fromJson(Map<String, dynamic> json) {
    return CostCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      isFood: (json['is_food'] as bool?) ?? false,
      houseId: json['house_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'is_food': isFood,
    if (houseId != null) 'house_id': houseId,
  };
}
