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

  @override
  Widget build(BuildContext context) {
    final raw = icon?.trim();
    final effectiveBg = backgroundColor ??
        CategoryColorHelper.getColorFor(
          icon: raw,
          name: categoryName,
        );

    final isCircle = shape == BoxShape.circle && borderRadius == null;
    final decoration = BoxDecoration(
      color: effectiveBg,
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isCircle
          ? null
          : BorderRadius.circular(borderRadius ?? (size * 0.26)),
    );

    if (raw == null || raw.isEmpty) {
      return _buildContainer(
        decoration: decoration,
        child: _buildEmoji(fallbackEmoji),
      );
    }

    // 1. Network URL with CachedNetworkImage
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final imageWidget = CachedNetworkImage(
        imageUrl: raw,
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
    if (raw.startsWith('/') || raw.startsWith('file://')) {
      final path =
          raw.startsWith('file://') ? raw.replaceFirst('file://', '') : raw;
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
    if (raw.startsWith('assets/')) {
      final imageWidget = Image.asset(
        raw,
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
      child: _buildEmoji(raw),
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
