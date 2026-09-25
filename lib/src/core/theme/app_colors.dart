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
    required this.positiveColor,
    required this.warningColor,
    required this.unsettledColor,
  });

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _darkPrimaryColor = Color(0xFF8B6EFF);
  static const Color _secondaryContainerColor = Color(0xFFEDE9FF);
  static const Color _darkSecondaryContainerColor = Color(0xFF1E1A2E);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _darkSurfaceColor = Color(0xFF1C1B1F);
  static const Color _backgroundColor = Color(0xFFFAF9F7);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _splashColor = Color(0x206C47FF);
  static const Color _hintBaseColor = Color(0xFF78716C);
  static const Color _iconBaseColor = _primaryColor;
  static const Color _darkIconBaseColor = _darkPrimaryColor;
  static const Color _bottomNavColor = Color(0xFFFFFFFF);
  static const Color _darkBottomNavColor = Color(0xFF1C1B1F);
  static const Color _unselectedLabelColor = Color(0xFF78716C);
  static const Color _unselectedTileColor = Color(0xFFF5F3EF);

  static final AppColors _lightInstance = AppColors._(
    textColor: const Color(0xFF141414),
    invertTextColor: Colors.white,
    grey: const Color(0xFF78716C),
    backgroundColor: _surfaceColor,
    tileColor: _secondaryContainerColor,
    softGrey: const Color(0xFFF5F3EF),
    iconColor: _iconBaseColor,
    buttonContentColor: Colors.white,
    activeButtonContentColor: Colors.white,
    inActiveButtonColor: _surfaceColor,
    inActiveButtonContentColor: _primaryColor,
    drawerColor: _surfaceColor,
    borderColor: Colors.transparent,
    popupBackgroundColor: _surfaceColor,
    popupContentColor: const Color(0xFF141414),
    dividerColor: const Color(0xFFEEEAE4),
    tabBarColor: _surfaceColor,
    shadowColor: const Color(0x0D000000),
    errorColor: _errorColor,
    bottomNavigationBarColor: _bottomNavColor,
    unselectedLabelColor: _unselectedLabelColor,
    hintColor: _hintBaseColor,
    labelColor: _hintBaseColor,
    enabledBorderColor: Colors.transparent,
    positiveColor: const Color(0xFF16A34A),
    warningColor: const Color(0xFFF59E0B),
    unsettledColor: const Color(0xFFEF4444),
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
    inActiveButtonContentColor: const Color(0xFFD4C8FF),
    drawerColor: _darkSurfaceColor,
    borderColor: Colors.transparent,
    popupBackgroundColor: const Color(0xFF221F1D),
    popupContentColor: const Color(0xFFF7F2EE),
    dividerColor: const Color(0xFF2D2A35),
    tabBarColor: _darkSurfaceColor,
    shadowColor: const Color(0x66000000),
    errorColor: const Color(0xFFF87171),
    bottomNavigationBarColor: _darkBottomNavColor,
    unselectedLabelColor: const Color(0xFFA39A93),
    hintColor: const Color(0xFFA39A93),
    labelColor: const Color(0xFFA39A93),
    enabledBorderColor: Colors.transparent,
    positiveColor: const Color(0xFF4ADE80),
    warningColor: const Color(0xFFFBBF24),
    unsettledColor: const Color(0xFFF87171),
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
  final Color positiveColor;
  final Color warningColor;
  final Color unsettledColor;

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
  Color get cardColor => surfaceColor;
  Color get textPrimaryColor => textColor;
  Color get textSecondaryColor => grey;
  Color get textPrimary => textColor;
  Color get textSecondary => grey;
  Color get chipColor => softGrey;
  Color get settledColor => positiveColor;
}
