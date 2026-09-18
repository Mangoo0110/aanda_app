part of 'app_theme.dart';

class DAppBarTheme {
  DAppBarTheme._(); // Private constructor

  // Light AppBarTheme
  static AppBarTheme lightAppBarTheme = AppBarTheme(
    backgroundColor: AppColors.light().appBackgroundColor,
    foregroundColor: AppColors.light().textColor,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarColor: AppColors.light().appBackgroundColor,
      statusBarIconBrightness: Brightness.dark,
    ),
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: 12,
    iconTheme: IconThemeData(color: AppColors.light().textColor, size: 24),
    actionsIconTheme: IconThemeData(
      color: AppColors.light().textColor,
      size: 18,
    ),
    toolbarTextStyle: TextStyle(color: AppColors.light().textColor),
    titleTextStyle: TextStyle(
      color: AppColors.light().textColor,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    centerTitle: false,
  );

  // Dark AppBarTheme
  static AppBarTheme darkAppBarTheme = AppBarTheme(
    backgroundColor: AppColors.dark().backgroundColor,
    foregroundColor: AppColors.dark().textColor,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarColor: AppColors.dark().backgroundColor,
      statusBarIconBrightness: Brightness.light,
    ),
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: 12,
    iconTheme: IconThemeData(color: AppColors.dark().textColor, size: 24),
    actionsIconTheme: IconThemeData(
      color: AppColors.dark().textColor,
      size: 18,
    ),
    toolbarTextStyle: TextStyle(color: AppColors.dark().textColor),
    titleTextStyle: TextStyle(
      color: AppColors.dark().textColor,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    centerTitle: false,
  );

  static AppBarTheme getAppBarTheme(Brightness brightness) {
    return brightness == Brightness.light ? lightAppBarTheme : darkAppBarTheme;
  }
}
