part of 'app_theme.dart';

class DCardTheme {
  DCardTheme._(); // Private constructor

  // Light CardTheme
  static CardThemeData lightCardTheme = CardThemeData(
    color: AppColors.light().backgroundColor,
    shadowColor: AppColors.light().shadowColor,
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    shape: RoundedRectangleBorder(
      borderRadius: AppSizes.bigRectangleTileRadius,
      side: BorderSide(color: AppColors.light().dividerColor),
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
      side: BorderSide(color: AppColors.dark().dividerColor),
    ),
    clipBehavior: Clip.antiAlias,
    surfaceTintColor: Colors.transparent,
  );
}
