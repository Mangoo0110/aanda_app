part of 'app_theme.dart';

class DTextTheme {
  DTextTheme._();

  // Light Theme Text Styles
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.bold,
      color: AppColors.light().textColor,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w600,
      color: AppColors.light().textColor,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.normal,
      color: AppColors.light().textColor,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.light().textColor,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.light().textColor,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.normal,
      color: AppColors.light().textColor,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.light().textColor,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.light().textColor,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.light().textColor,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.light().textColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.light().textColor,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.light().textColor,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: AppColors.light().textColor,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.light().textColor,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.normal,
      color: AppColors.light().textColor,
    ),
  );

  // Dark Theme Text Styles
  static TextTheme get darkTextTheme => TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.bold,
      color: AppColors.dark().textColor,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w600,
      color: AppColors.dark().textColor,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.normal,
      color: AppColors.dark().textColor,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.dark().textColor,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.dark().textColor,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.normal,
      color: AppColors.dark().textColor,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColors.dark().textColor,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.dark().textColor,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.dark().textColor,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.dark().textColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.dark().textColor,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.dark().textColor,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: AppColors.dark().textColor,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.dark().textColor,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.normal,
      color: AppColors.dark().textColor,
    ),
  );
}
