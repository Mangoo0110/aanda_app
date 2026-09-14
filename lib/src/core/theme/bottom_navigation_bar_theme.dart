part of 'app_theme.dart';

class DBottomNavigationBarThemes {
  DBottomNavigationBarThemes._(); // Private constructor

  // Light BottomNavigationBarTheme
  static BottomNavigationBarThemeData lightBottomNavTheme =
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.light().bottomNavigationBarColor,
        selectedItemColor: AppColors.light().primaryColor,
        unselectedItemColor: AppColors.light().unselectedLabelColor,
        selectedIconTheme: IconThemeData(
          color: AppColors.light().primaryColor,
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: AppColors.light().unselectedLabelColor,
          size: 28,
        ),
        selectedLabelStyle: TextStyle(
          fontFamily: 'Public Sans',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.light().primaryColor,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Public Sans',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0.0,
        type: BottomNavigationBarType.fixed,
      );

  // Dark BottomNavigationBarTheme
  static BottomNavigationBarThemeData darkBottomNavTheme =
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.dark().bottomNavigationBarColor,
        selectedItemColor: AppColors.dark().primaryColor,
        unselectedItemColor: AppColors.dark().unselectedLabelColor,
        selectedIconTheme: IconThemeData(
          color: AppColors.dark().primaryColor,
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: AppColors.dark().unselectedLabelColor,
          size: 28,
        ),
        selectedLabelStyle: TextStyle(
          fontFamily: 'Public Sans',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.dark().primaryColor,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Public Sans',
          fontSize: 10,
          fontWeight: FontWeight.normal,
          color: AppColors.dark().unselectedLabelColor,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0.0,
        type: BottomNavigationBarType.fixed,
      );
}
