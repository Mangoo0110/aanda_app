part of 'app_theme.dart';

class DInputDecorationTheme {
  DInputDecorationTheme._(); // Private constructor

  // Light InputDecorationTheme
  static InputDecorationTheme lightTheme = InputDecorationTheme(
    filled: true,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    prefixIconConstraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    fillColor: AppColors.light().backgroundColor,
    focusColor: AppColors.light().textColor,
    hoverColor: AppColors.light().textColor,
    hintStyle: TextStyle(color: AppColors.light().hintColor),
    labelStyle: TextStyle(color: AppColors.light().labelColor),
    outlineBorder: BorderSide(color: AppColors.light().textColor),
    floatingLabelStyle: TextStyle(color: AppColors.light().primaryColor),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.light().enabledBorderColor),
      borderRadius: AppSizes.textFieldBorderRadius,
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.light().enabledBorderColor),
      borderRadius: AppSizes.textFieldBorderRadius,
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.light().focusedBorderColor,
        width: 1.5,
      ),
      borderRadius: AppSizes.textFieldBorderRadius,
    ),
  );

  // Dark InputDecorationTheme
  static InputDecorationTheme darkTheme = InputDecorationTheme(
    filled: true,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    prefixIconConstraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    fillColor: AppColors.dark().backgroundColor,
    focusColor: AppColors.dark().textColor,
    hoverColor: AppColors.dark().textColor,
    hintStyle: TextStyle(color: AppColors.dark().hintColor),
    labelStyle: TextStyle(color: AppColors.dark().labelColor),
    outlineBorder: BorderSide(color: AppColors.dark().textColor),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.dark().enabledBorderColor),
      borderRadius: AppSizes.textFieldBorderRadius,
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.dark().enabledBorderColor),
      borderRadius: AppSizes.textFieldBorderRadius,
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.dark().focusedBorderColor,
        width: 1.5,
      ),
      borderRadius: AppSizes.textFieldBorderRadius,
    ),
  );
}
