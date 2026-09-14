part of 'app_theme.dart';

class DDividerTheme {
  DDividerTheme._(); // Private constructor

  // Light DividerThemeData
  static DividerThemeData lightDividerTheme = DividerThemeData(
    color:
        AppColors.light().dividerColor, // Assuming you have this color defined
    thickness: 1.0, // Define the thickness of the divider
    indent: 0.0, // Full-width dividers by default
    endIndent: 0.0, // Full-width dividers by default
  );

  // Dark DividerThemeData
  static DividerThemeData darkDividerTheme = DividerThemeData(
    color:
        AppColors.dark().dividerColor, // Assuming you have this color defined
    thickness: 1.0, // Define the thickness of the divider
    indent: 0.0, // Full-width dividers by default
    endIndent: 0.0, // Full-width dividers by default
  );
}
