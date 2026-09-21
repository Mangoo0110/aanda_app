import 'package:aanda/src/features/cost/domain/entities/category_emoji.dart';

class CategoryEmojiModel extends CategoryEmoji {
  const CategoryEmojiModel({
    required super.id,
    required super.emoji,
    required super.name,
    super.category = 'general',
    super.assetUrl,
    super.localCachedPath,
    super.costNature = 'variable',
    super.isFood = false,
    super.color,
  });

  factory CategoryEmojiModel.fromJson(Map<String, dynamic> json) {
    return CategoryEmojiModel(
      id: json['id'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🏷️',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      assetUrl: json['asset_url'] as String?,
      localCachedPath: json['local_cached_path'] as String?,
      costNature: json['cost_nature'] as String? ?? 'variable',
      isFood: json['is_food'] as bool? ?? false,
      color: json['color'] as String?,
    );
  }

  factory CategoryEmojiModel.fromEntity(CategoryEmoji entity) {
    return CategoryEmojiModel(
      id: entity.id,
      emoji: entity.emoji,
      name: entity.name,
      category: entity.category,
      assetUrl: entity.assetUrl,
      localCachedPath: entity.localCachedPath,
      costNature: entity.costNature,
      isFood: entity.isFood,
      color: entity.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'name': name,
      'category': category,
      'cost_nature': costNature,
      'is_food': isFood,
      if (assetUrl != null) 'asset_url': assetUrl,
      if (localCachedPath != null) 'local_cached_path': localCachedPath,
      if (color != null) 'color': color,
    };
  }

  CategoryEmojiModel copyWith({
    String? id,
    String? emoji,
    String? name,
    String? category,
    String? assetUrl,
    String? localCachedPath,
    String? costNature,
    bool? isFood,
    String? color,
  }) {
    return CategoryEmojiModel(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      category: category ?? this.category,
      assetUrl: assetUrl ?? this.assetUrl,
      localCachedPath: localCachedPath ?? this.localCachedPath,
      costNature: costNature ?? this.costNature,
      isFood: isFood ?? this.isFood,
      color: color ?? this.color,
    );
  }
}
