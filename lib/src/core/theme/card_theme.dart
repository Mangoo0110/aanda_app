part of 'app_theme.dart';

class DCardTheme {
  DCardTheme._(); // Private constructor

  // Light CardTheme
  static CardThemeData lightCardTheme = CardThemeData(
    color: AppColors.light().surfaceColor,
    shadowColor: AppColors.light().shadowColor,
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    shape: RoundedRectangleBorder(
      borderRadius: AppSizes.bigRectangleTileRadius,
      side: BorderSide.none,
    ),
    clipBehavior: Clip.antiAlias,
    surfaceTintColor: Colors.transparent,
  );

  // Dark CardTheme
  static CardThemeData darkCardTheme = CardThemeData(
    color: AppColors.dark().tileColor,
    shadowColor: AppColors.dark().shadowColor,
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 0),
    shape: RoundedRectangleBorder(
      borderRadius: AppSizes.bigRectangleTileRadius,
      side: BorderSide.none,
    ),
    clipBehavior: Clip.antiAlias,
    surfaceTintColor: Colors.transparent,
  );
}
