part of 'app_theme.dart';

class DTabBarTheme {
  DTabBarTheme._(); // Private constructor

  // Light TabBarTheme
  static TabBarThemeData lightTabBarTheme = TabBarThemeData(
    indicatorSize: TabBarIndicatorSize.tab,
    indicatorColor: AppColors.light().textColor,
    dividerColor: AppColors.light().softGrey,
    labelColor: AppColors.light().textColor,
    unselectedLabelColor: AppColors.light().grey,
    labelStyle: const TextStyle(
      fontSize: 13,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: const TextStyle(
      fontSize: 13,
      fontFamily: "Poppins",
      fontWeight: FontWeight.normal,
    ),
  );

  // Dark TabBarTheme
  static TabBarThemeData darkTabBarTheme = TabBarThemeData(
    indicatorSize: TabBarIndicatorSize.tab,
    indicatorColor: AppColors.dark().textColor,
    dividerColor: AppColors.dark().softGrey,
    labelColor: AppColors.dark().textColor,
    unselectedLabelColor: AppColors.dark().grey,
    labelStyle: const TextStyle(
      fontSize: 13,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: const TextStyle(
      fontSize: 13,
      fontFamily: "Poppins",
      fontWeight: FontWeight.normal,
    ),
  );
}
