import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aanda/src/app/routing/app_routes.dart';

/// Reusable back button matching the clean minimal UI design.
///
/// Features a 40x40 rounded squircle container with a clean card surface,
/// a centered iOS-style chevron, and intelligent pop/fallback navigation.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.fallbackRoute,
    this.margin = const EdgeInsets.only(left: 16),
    this.size = 40,
    this.iconSize,
    this.icon = Icons.arrow_back_ios_new_rounded,
    this.backgroundColor,
    this.iconColor,
    this.shape = BoxShape.circle,
  });

  /// Optional custom callback. If omitted, attempts [context.pop()],
  /// then [fallbackRoute], then defaults to [AppRoutes.home].
  final VoidCallback? onPressed;

  /// Route to navigate to when [context.canPop()] is false. Defaults to [AppRoutes.home].
  final String? fallbackRoute;

  /// Margin around the button. Defaults to 16px left to align with screen body padding
  /// when used as [AppBar.leading].
  final EdgeInsetsGeometry margin;

  /// Button width and height. Defaults to 40.
  final double size;

  /// Back chevron or cancel icon size. Defaults to 16 for back chevron, 20 for others.
  final double? iconSize;

  /// Icon to display. Defaults to [Icons.arrow_back_ios_new_rounded].
  /// Can be set to [Icons.close_rounded] for modal / close dialogues.
  final IconData icon;

  /// Custom background color. Defaults to white (or dark surface in dark mode).
  final Color? backgroundColor;

  /// Custom icon color. Defaults to theme text color.
  final Color? iconColor;

  /// Button shape. Defaults to circular matching the clean-minimal UI.
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg =
        backgroundColor ?? (isDark ? const Color(0xFF2B2724) : Colors.white);
    final fg = iconColor ?? (isDark ? Colors.white : const Color(0xFF1B1D1F));

    return Padding(
      padding: margin,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: shape,
            borderRadius: shape == BoxShape.rectangle
                ? BorderRadius.circular(14)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: shape == BoxShape.circle
                ? const CircleBorder()
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                if (onPressed != null) {
                  onPressed!();
                } else if (context.canPop()) {
                  context.pop();
                } else if (fallbackRoute != null) {
                  context.go(fallbackRoute!);
                } else {
                  context.go(AppRoutes.home);
                }
              },
              child: Center(
                child: Icon(
                  icon,
                  size:
                      iconSize ??
                      (icon == Icons.arrow_back_ios_new_rounded ? 16 : 20),
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
