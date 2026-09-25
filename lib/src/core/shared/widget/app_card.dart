import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final radius = borderRadius ?? BorderRadius.circular(16);
    final border = borderColor != null
        ? Border.all(color: borderColor!, width: 1)
        : null;
    final bg = backgroundColor ?? colors.surfaceColor;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: border,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: cardContent,
        ),
      );
    }

    if (margin != null) {
      cardContent = Padding(padding: margin!, child: cardContent);
    }

    return cardContent;
  }
}
