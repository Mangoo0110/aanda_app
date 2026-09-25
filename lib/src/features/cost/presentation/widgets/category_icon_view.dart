import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:aanda/src/features/cost/presentation/helpers/category_color_helper.dart';

class CategoryIconView extends StatelessWidget {
  const CategoryIconView({
    super.key,
    required this.icon,
    this.size = 38,
    this.color,
    this.backgroundColor,
    this.categoryName,
    this.fallbackEmoji = '🏷️',
    this.borderRadius,
    this.shape = BoxShape.circle,
  });

  final String? icon;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final String? categoryName;
  final String fallbackEmoji;
  final double? borderRadius;
  final BoxShape shape;

  static const Map<String, String> _presetAssetMap = {
    'food & dining': 'assets/images/categories/food.jpg',
    'groceries & bazar': 'assets/images/categories/grocery.jpg',
    'snacks & tea': 'assets/images/categories/snacks.jpg',
    'household supplies': 'assets/images/categories/supplies.jpg',
    'transport & fuel': 'assets/images/categories/transport.jpg',
    'rent & housing': 'assets/images/categories/rent.jpg',
    'electricity & current': 'assets/images/categories/electricity.jpg',
    'internet & wifi': 'assets/images/categories/wifi.jpg',
    'gas & cylinder': 'assets/images/categories/gas.jpg',
    'maid & cleaning': 'assets/images/categories/maid.jpg',
    'dining out & treats': 'assets/images/categories/dining.jpg',
    'food': 'assets/images/categories/food.jpg',
    'grocery': 'assets/images/categories/grocery.jpg',
    'groceries': 'assets/images/categories/grocery.jpg',
    'snacks': 'assets/images/categories/snacks.jpg',
    'supplies': 'assets/images/categories/supplies.jpg',
    'transport': 'assets/images/categories/transport.jpg',
    'rent': 'assets/images/categories/rent.jpg',
    'electricity': 'assets/images/categories/electricity.jpg',
    'wifi': 'assets/images/categories/wifi.jpg',
    'gas': 'assets/images/categories/gas.jpg',
    'maid': 'assets/images/categories/maid.jpg',
    'dining': 'assets/images/categories/dining.jpg',
    '🍳': 'assets/images/categories/food.jpg',
    '🛒': 'assets/images/categories/grocery.jpg',
    '☕': 'assets/images/categories/snacks.jpg',
    '🧴': 'assets/images/categories/supplies.jpg',
    '🚗': 'assets/images/categories/transport.jpg',
    '🏠': 'assets/images/categories/rent.jpg',
    '💡': 'assets/images/categories/electricity.jpg',
    '⚡': 'assets/images/categories/electricity.jpg',
    '📶': 'assets/images/categories/wifi.jpg',
    '⛽': 'assets/images/categories/gas.jpg',
    '🧹': 'assets/images/categories/maid.jpg',
    '🎬': 'assets/images/categories/dining.jpg',
  };

  @override
  Widget build(BuildContext context) {
    final raw = icon?.trim();
    final effectiveBg = backgroundColor ??
        CategoryColorHelper.getColorFor(
          icon: raw,
          name: categoryName,
        );

    final resolved = (raw != null &&
            (raw.startsWith('assets/') ||
                raw.startsWith('http://') ||
                raw.startsWith('https://') ||
                raw.startsWith('/') ||
                raw.startsWith('file://')))
        ? raw
        : (_presetAssetMap[raw] ??
            _presetAssetMap[categoryName?.toLowerCase().trim()] ??
            raw);

    final isCircle = shape == BoxShape.circle && borderRadius == null;
    final decoration = BoxDecoration(
      color: effectiveBg,
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isCircle
          ? null
          : BorderRadius.circular(borderRadius ?? (size * 0.26)),
    );

    if (resolved == null || resolved.isEmpty) {
      return _buildContainer(
        decoration: decoration,
        child: _buildEmoji(fallbackEmoji),
      );
    }

    // 1. Network URL with CachedNetworkImage
    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      final imageWidget = CachedNetworkImage(
        imageUrl: resolved,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: effectiveBg.withValues(alpha: 0.3),
          child: Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildEmoji(fallbackEmoji),
      );

      return Container(
        width: size,
        height: size,
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: isCircle
            ? ClipOval(child: imageWidget)
            : ClipRRect(
                borderRadius:
                    BorderRadius.circular(borderRadius ?? (size * 0.26)),
                child: imageWidget,
              ),
      );
    }

    // 2. Local File (e.g. user selected from gallery before upload)
    if (resolved.startsWith('/') || resolved.startsWith('file://')) {
      final path =
          resolved.startsWith('file://') ? resolved.replaceFirst('file://', '') : resolved;
      final file = File(path);
      final imageWidget = Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildEmoji(fallbackEmoji),
      );

      return Container(
        width: size,
        height: size,
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: isCircle
            ? ClipOval(child: imageWidget)
            : ClipRRect(
                borderRadius:
                    BorderRadius.circular(borderRadius ?? (size * 0.26)),
                child: imageWidget,
              ),
      );
    }

    // 3. Bundled Asset
    if (resolved.startsWith('assets/')) {
      final imageWidget = Image.asset(
        resolved,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildEmoji(fallbackEmoji),
      );

      return Container(
        width: size,
        height: size,
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: isCircle
            ? ClipOval(child: imageWidget)
            : ClipRRect(
                borderRadius:
                    BorderRadius.circular(borderRadius ?? (size * 0.26)),
                child: imageWidget,
              ),
      );
    }

    // 4. Emoji or short text
    return _buildContainer(
      decoration: decoration,
      child: _buildEmoji(resolved),
    );
  }

  Widget _buildContainer({
    required BoxDecoration decoration,
    required Widget child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildEmoji(String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size * 0.52,
          height: 1.1,
        ),
      ),
    );
  }
}
