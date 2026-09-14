import '../utils/extensions/textstyle_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import '../constants/app_sizes.dart';

part 'date_picker_theme.dart';
part 'app_button_themes.dart';
part 'floating_action_button_theme.dart';
part 'progress_indicator_theme.dart';
part 'app_bar_theme.dart';
part 'bottom_app_bar_theme.dart';
part 'bottom_navigation_bar_theme.dart';
part 'bottom_sheet_theme.dart';
part 'button_theme.dart';
part 'card_theme.dart';
part 'checkbox_theme.dart';
part 'divider_theme.dart';
part 'icon_theme.dart';
part 'input_decoration_theme.dart';
part 'switch_theme.dart';
part 'tab_bar_theme.dart';
part 'text_theme.dart';
part 'text_selection_theme.dart';
part 'slider_theme.dart';

class AppTheme {
  AppTheme();

  ThemeData get lightTheme {
    final colors = AppColors.light();

    return ThemeData(
      primaryColor: colors.primaryColor,
      primaryTextTheme: DTextTheme.lightTextTheme,
      textButtonTheme: AppButtonThemes.text(colors),
      primaryColorLight: colors.primaryColor,
      primaryColorDark: colors.primaryColor,
      splashColor: colors.splashColor,
      highlightColor: colors.splashColor,
      hoverColor: colors.splashColor,
      focusColor: colors.splashColor,
      shadowColor: colors.shadowColor,
      dividerColor: colors.dividerColor,
      cardColor: colors.backgroundColor,
      useMaterial3: true,
      fontFamily: 'Public Sans',
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: colors.primaryColor,
        onPrimary: colors.buttonContentColor,
        primaryContainer: colors.tileColor,
        onPrimaryContainer: colors.textColor,
        secondary: colors.primaryColor,
        onSecondary: colors.buttonContentColor,
        secondaryContainer: colors.tileColor,
        onSecondaryContainer: colors.textColor,
        error: colors.errorColor,
        onError: colors.buttonContentColor,
        surface: colors.backgroundColor,
        onSurface: colors.textColor,
        outline: colors.enabledBorderColor,
        shadow: colors.shadowColor,
      ),
      scaffoldBackgroundColor: colors.backgroundColor,
      textTheme: DTextTheme.lightTextTheme,
      textSelectionTheme: DTextSelectionTheme.lightTextSelectionTheme,
      switchTheme: SwitchThemes.lightSwitchTheme,
      appBarTheme: DAppBarTheme.lightAppBarTheme,
      bottomAppBarTheme: DBottomAppBarTheme.lightBottomAppBarTheme,
      inputDecorationTheme: DInputDecorationTheme.lightTheme,
      iconTheme: DIconTheme.lightIconTheme,
      buttonTheme: DButtonTheme.lightButtonTheme,
      bottomSheetTheme: DBottomSheetTheme.lightBottomSheetTheme,
      checkboxTheme: DCheckboxTheme.lightCheckboxTheme,
      cardTheme: DCardTheme.lightCardTheme,
      bottomNavigationBarTheme: DBottomNavigationBarThemes.lightBottomNavTheme,
      tabBarTheme: DTabBarTheme.lightTabBarTheme,
      listTileTheme: ListTileThemeData(
        iconColor: colors.iconColor,
        selectedColor: colors.primaryColor,
        selectedTileColor: colors.tileColor,
        tileColor: colors.backgroundColor,
      ),
      dividerTheme: DDividerTheme.lightDividerTheme,
      progressIndicatorTheme: ProgressIndicatorThemes.light,
      datePickerTheme: DatePickerThemes.lightTheme,
      elevatedButtonTheme: AppButtonThemes.elevated(colors),
      filledButtonTheme: AppButtonThemes.filled(colors),
      outlinedButtonTheme: AppButtonThemes.outlined(colors),
      iconButtonTheme: AppButtonThemes.icon(colors),
      floatingActionButtonTheme: FloatingActionButtonThemes.lightTheme,
      sliderTheme: AppSliderTheme.lightTheme,
    );
  }

  ThemeData get darkTheme {
    final colors = AppColors.dark();

    return ThemeData(
      primaryColor: colors.primaryColor,
      textButtonTheme: AppButtonThemes.text(colors),
      primaryTextTheme: DTextTheme.darkTextTheme,
      primaryColorLight: colors.primaryColor,
      primaryColorDark: colors.backgroundColor,
      splashColor: colors.splashColor,
      highlightColor: colors.primaryColor.withAlpha(80),
      hoverColor: colors.primaryColor.withAlpha(80),
      focusColor: colors.primaryColor.withAlpha(80),
      shadowColor: colors.shadowColor,
      dividerColor: colors.dividerColor,
      useMaterial3: true,
      fontFamily: 'Public Sans',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: colors.primaryColor,
        onPrimary: colors.buttonContentColor,
        primaryContainer: colors.tileColor,
        onPrimaryContainer: colors.textColor,
        secondary: colors.primaryColor,
        onSecondary: colors.buttonContentColor,
        secondaryContainer: colors.tileColor,
        onSecondaryContainer: colors.textColor,
        error: colors.errorColor,
        onError: colors.invertTextColor,
        surface: colors.backgroundColor,
        onSurface: colors.textColor,
        outline: colors.enabledBorderColor,
        shadow: colors.shadowColor,
      ),
      scaffoldBackgroundColor: colors.backgroundColor,
      textTheme: DTextTheme.darkTextTheme,
      switchTheme: SwitchThemes.darkSwitchTheme,
      appBarTheme: DAppBarTheme.darkAppBarTheme,
      bottomAppBarTheme: DBottomAppBarTheme.darkBottomAppBarTheme,
      inputDecorationTheme: DInputDecorationTheme.darkTheme,
      iconTheme: DIconTheme.darkIconTheme,
      textSelectionTheme: DTextSelectionTheme.darkTextSelectionTheme,
      buttonTheme: DButtonTheme.darkButtonTheme,
      bottomSheetTheme: DBottomSheetTheme.darkBottomSheetTheme,
      checkboxTheme: DCheckboxTheme.darkCheckboxTheme,
      cardTheme: DCardTheme.darkCardTheme,
      tabBarTheme: DTabBarTheme.darkTabBarTheme,
      bottomNavigationBarTheme: DBottomNavigationBarThemes.darkBottomNavTheme,
      dividerTheme: DDividerTheme.darkDividerTheme,
      listTileTheme: ListTileThemeData(
        iconColor: colors.iconColor,
        selectedColor: colors.primaryColor,
        selectedTileColor: colors.tileColor,
        tileColor: colors.backgroundColor,
      ),
      progressIndicatorTheme: ProgressIndicatorThemes.dark,
      datePickerTheme: DatePickerThemes.darkTheme,
      elevatedButtonTheme: AppButtonThemes.elevated(colors),
      filledButtonTheme: AppButtonThemes.filled(colors),
      outlinedButtonTheme: AppButtonThemes.outlined(colors),
      iconButtonTheme: AppButtonThemes.icon(colors),
      floatingActionButtonTheme: FloatingActionButtonThemes.darkTheme,
      sliderTheme: AppSliderTheme.darkTheme,
    );
  }
}
