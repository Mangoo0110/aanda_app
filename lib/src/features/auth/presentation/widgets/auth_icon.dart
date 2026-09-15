import 'package:flutter/material.dart';
import 'package:aanda/src/core/theme/app_colors.dart';

class AuthIcon extends StatelessWidget {
  const AuthIcon({
    super.key,
    required this.icon,
    this.noBackground = false,
    this.size = 100,
    this.iconSize = 56,
    this.borderRadius = 32,
  });

  final IconData icon;
  final bool noBackground;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: noBackground ? Colors.transparent : colors.tileColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Icon(icon, color: colors.primaryColor, size: iconSize),
        ),
      ),
    );
  }
}
