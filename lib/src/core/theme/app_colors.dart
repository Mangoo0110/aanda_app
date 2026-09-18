import 'package:flutter/material.dart';

class AppColors {
  AppColors._({
    required this.textColor,
    required this.invertTextColor,
    required this.grey,
    required this.backgroundColor,
    required this.tileColor,
    required this.softGrey,
    required this.iconColor,
    required this.buttonContentColor,
    required this.activeButtonContentColor,
    required this.inActiveButtonColor,
    required this.inActiveButtonContentColor,
    required this.drawerColor,
    required this.borderColor,
    required this.popupBackgroundColor,
    required this.popupContentColor,
    required this.dividerColor,
    required this.tabBarColor,
    required this.shadowColor,
    required this.errorColor,
    required this.bottomNavigationBarColor,
    required this.unselectedLabelColor,
    required this.hintColor,
    required this.labelColor,
    required this.enabledBorderColor,
  });

  static const Color _primaryColor = Color(0xFFD85A38);
  static const Color _darkPrimaryColor = Color(0xFFF28B70);
  static const Color _secondaryContainerColor = Color(0xFFFDEEE8);
  static const Color _darkSecondaryContainerColor = Color(0xFF3B2822);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _darkSurfaceColor = Color(0xFF221F1D);
  static const Color _backgroundColor = Color(0xFFFFF7EE);
  static const Color _errorColor = Color(0xFFBA1A1A);
  static const Color _splashColor = Color(0x24D85A38);
  static const Color _hintBaseColor = Color(0xFF8C8D8E);
  static const Color _iconBaseColor = Color(0xFFD85A38);
  static const Color _darkIconBaseColor = Color(0xFFF28B70);
  static const Color _bottomNavColor = Color(0xFFFFFFFF);
  static const Color _darkBottomNavColor = Color(0xFF221F1D);
  static const Color _unselectedLabelColor = Color(0xFF8C8D8E);
  static const Color _unselectedTileColor = Color(0xFFFAF5EE);

  static final AppColors _lightInstance = AppColors._(
    textColor: const Color(0xFF1B1D1F),
    invertTextColor: Colors.white,
    grey: const Color(0xFF8C8D8E),
    backgroundColor: _surfaceColor,
    tileColor: _secondaryContainerColor,
    softGrey: const Color(0xFFFAF5EE),
    iconColor: _iconBaseColor,
    buttonContentColor: Colors.white,
    activeButtonContentColor: Colors.white,
    inActiveButtonColor: _surfaceColor,
    inActiveButtonContentColor: _primaryColor,
    drawerColor: _surfaceColor,
    borderColor: const Color(0xFFEFE8DE),
    popupBackgroundColor: _surfaceColor,
    popupContentColor: const Color(0xFF1B1D1F),
    dividerColor: const Color(0xFFF2ECE4),
    tabBarColor: _surfaceColor,
    shadowColor: const Color(0x14000000),
    errorColor: _errorColor,
    bottomNavigationBarColor: _bottomNavColor,
    unselectedLabelColor: _unselectedLabelColor,
    hintColor: _hintBaseColor,
    labelColor: _hintBaseColor,
    enabledBorderColor: const Color(0xFFEFE8DE),
  );

  static final AppColors _darkInstance = AppColors._(
    textColor: const Color(0xFFF7F2EE),
    invertTextColor: const Color(0xFF181514),
    grey: const Color(0xFFA39A93),
    backgroundColor: _darkSurfaceColor,
    tileColor: _darkSecondaryContainerColor,
    softGrey: const Color(0xFF2D2825),
    iconColor: _darkIconBaseColor,
    buttonContentColor: const Color(0xFF181514),
    activeButtonContentColor: const Color(0xFF181514),
    inActiveButtonColor: const Color(0xFF2D2825),
    inActiveButtonContentColor: const Color(0xFFE0C4BC),
    drawerColor: _darkSurfaceColor,
    borderColor: const Color(0xFF4A3E39),
    popupBackgroundColor: const Color(0xFF221F1D),
    popupContentColor: const Color(0xFFF7F2EE),
    dividerColor: const Color(0xFF332C29),
    tabBarColor: _darkSurfaceColor,
    shadowColor: const Color(0x66000000),
    errorColor: const Color(0xFFFFB4AB),
    bottomNavigationBarColor: _darkBottomNavColor,
    unselectedLabelColor: const Color(0xFFA39A93),
    hintColor: const Color(0xFFA39A93),
    labelColor: const Color(0xFFA39A93),
    enabledBorderColor: const Color(0xFF4A3E39),
  );

  factory AppColors.light() => _lightInstance;

  factory AppColors.dark() => _darkInstance;

  factory AppColors.context(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkInstance
        : _lightInstance;
  }

  final Color textColor;
  final Color invertTextColor;
  final Color grey;
  final Color backgroundColor;
  final Color tileColor;
  final Color softGrey;
  final Color iconColor;
  final Color buttonContentColor;
  final Color activeButtonContentColor;
  final Color inActiveButtonColor;
  final Color inActiveButtonContentColor;
  final Color drawerColor;
  final Color borderColor;
  final Color popupBackgroundColor;
  final Color popupContentColor;
  final Color dividerColor;
  final Color tabBarColor;
  final Color shadowColor;
  final Color errorColor;
  final Color bottomNavigationBarColor;
  final Color unselectedLabelColor;
  final Color hintColor;
  final Color labelColor;
  final Color enabledBorderColor;

  bool get _isDark => identical(this, _darkInstance);

  Color get primaryColor => _isDark ? _darkPrimaryColor : _primaryColor;
  Color get secondaryColor => tileColor;
  Color get surfaceColor => backgroundColor;
  Color get appBackgroundColor =>
      _isDark ? _darkSurfaceColor : _backgroundColor;
  Color get splashColor => _splashColor;
  Color get activeButtonColor => primaryColor;
  Color get buttonColor => primaryColor;
  Color get fillColor => backgroundColor;
  Color get focusedBorderColor => primaryColor;
  Color get unselectedTileColor => _unselectedTileColor;
}
