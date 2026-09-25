part of 'app_theme.dart';

class FloatingActionButtonThemes {
  static FloatingActionButtonThemeData lightTheme =
      const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF141414),
        foregroundColor: Colors.white,
        shape: CircleBorder(),
        elevation: 4.0,
        iconSize: 26,
      );

  static FloatingActionButtonThemeData darkTheme =
      const FloatingActionButtonThemeData(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF141414),
        shape: CircleBorder(),
        elevation: 4.0,
        iconSize: 26,
      );
}
