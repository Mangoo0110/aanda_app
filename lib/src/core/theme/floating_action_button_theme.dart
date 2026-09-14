part of 'app_theme.dart';

class FloatingActionButtonThemes {
  static FloatingActionButtonThemeData lightTheme =
      FloatingActionButtonThemeData(
        backgroundColor: AppColors.light().primaryColor,
        foregroundColor: AppColors.light().buttonContentColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2.0,
        iconSize: AppSizes.largeIconSize,
      );

  static FloatingActionButtonThemeData darkTheme =
      FloatingActionButtonThemeData(
        backgroundColor: AppColors.dark().primaryColor,
        foregroundColor: AppColors.dark().buttonContentColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2.0,
        iconSize: AppSizes.largeIconSize,
      );
}
