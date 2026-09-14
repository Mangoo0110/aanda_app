part of 'app_theme.dart';

enum AppButtonVisualState { enabled, disabled, processing }

class AppButtonThemes {
  AppButtonThemes._();

  static ElevatedButtonThemeData elevated(AppColors colors) {
    return ElevatedButtonThemeData(style: AppButtonStyles.elevated(colors));
  }

  static FilledButtonThemeData filled(AppColors colors) {
    return FilledButtonThemeData(style: AppButtonStyles.filled(colors));
  }

  static OutlinedButtonThemeData outlined(AppColors colors) {
    return OutlinedButtonThemeData(style: AppButtonStyles.outlined(colors));
  }

  static TextButtonThemeData text(AppColors colors) {
    return TextButtonThemeData(style: AppButtonStyles.text(colors));
  }

  static IconButtonThemeData icon(AppColors colors) {
    return IconButtonThemeData(style: AppButtonStyles.icon(colors));
  }
}

class AppButtonStyles {
  AppButtonStyles._();

  static ButtonStyle elevated(
    AppColors colors, {
    AppButtonVisualState visualState = AppButtonVisualState.enabled,
  }) {
    return _baseStyle(colors).copyWith(
      elevation: WidgetStateProperty.resolveWith((states) {
        if (_isInactive(states, visualState)) return 0;
        if (states.contains(WidgetState.pressed)) return 0;
        return 0;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (_isDisabled(states, visualState)) return colors.softGrey;
        if (_isProcessing(visualState)) {
          return colors.primaryColor.withAlpha(190);
        }
        if (states.contains(WidgetState.pressed)) {
          return colors.primaryColor.withAlpha(220);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return colors.primaryColor.withAlpha(235);
        }
        return colors.primaryColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (_isDisabled(states, visualState)) return colors.grey;
        return colors.buttonContentColor;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (_isInactive(states, visualState)) return Colors.transparent;
        if (states.contains(WidgetState.pressed)) {
          return colors.buttonContentColor.withAlpha(20);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return colors.buttonContentColor.withAlpha(12);
        }
        return null;
      }),
    );
  }

  static ButtonStyle filled(
    AppColors colors, {
    AppButtonVisualState visualState = AppButtonVisualState.enabled,
  }) {
    return elevated(colors, visualState: visualState);
  }

  static ButtonStyle outlined(
    AppColors colors, {
    AppButtonVisualState visualState = AppButtonVisualState.enabled,
  }) {
    return _baseStyle(colors).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (_isDisabled(states, visualState)) return colors.softGrey;
        if (_isProcessing(visualState)) {
          return colors.tileColor.withAlpha(180);
        }
        if (states.contains(WidgetState.pressed)) return colors.tileColor;
        return colors.backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (_isDisabled(states, visualState)) return colors.grey;
        return colors.primaryColor;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (_isDisabled(states, visualState)) {
          return BorderSide(color: colors.softGrey);
        }
        if (_isProcessing(visualState)) {
          return BorderSide(color: colors.primaryColor.withAlpha(120));
        }
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.focused)) {
          return BorderSide(color: colors.primaryColor, width: 1.4);
        }
        return BorderSide(color: colors.enabledBorderColor);
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (_isInactive(states, visualState)) return Colors.transparent;
        if (states.contains(WidgetState.pressed)) {
          return colors.primaryColor.withAlpha(18);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return colors.primaryColor.withAlpha(12);
        }
        return null;
      }),
    );
  }

  static ButtonStyle text(
    AppColors colors, {
    AppButtonVisualState visualState = AppButtonVisualState.enabled,
  }) {
    return _baseStyle(colors).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(44, 36)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (_isInactive(states, visualState)) return Colors.transparent;
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.focused)) {
          return colors.tileColor;
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (_isDisabled(states, visualState)) return colors.grey;
        if (_isProcessing(visualState)) {
          return colors.primaryColor.withAlpha(170);
        }
        return colors.primaryColor;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (_isInactive(states, visualState)) return Colors.transparent;
        return colors.primaryColor.withAlpha(12);
      }),
    );
  }

  static ButtonStyle icon(
    AppColors colors, {
    AppButtonVisualState visualState = AppButtonVisualState.enabled,
  }) {
    return IconButton.styleFrom(
      fixedSize: const Size.square(40),
      shape: const CircleBorder(),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (_isDisabled(states, visualState)) return Colors.transparent;
        if (_isProcessing(visualState)) return colors.tileColor.withAlpha(180);
        if (states.contains(WidgetState.selected)) return colors.tileColor;
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.focused)) {
          return colors.tileColor;
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (_isDisabled(states, visualState)) return colors.grey;
        if (_isProcessing(visualState)) {
          return colors.primaryColor.withAlpha(170);
        }
        if (states.contains(WidgetState.selected)) return colors.primaryColor;
        return colors.textColor;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (_isInactive(states, visualState)) return Colors.transparent;
        return colors.primaryColor.withAlpha(12);
      }),
    );
  }

  static ButtonStyle _baseStyle(AppColors colors) {
    return ButtonStyle(
      animationDuration: const Duration(milliseconds: 140),
      minimumSize: const WidgetStatePropertyAll(
        Size.fromHeight(AppSizes.smallButtonHeight),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppSizes.maxCircularRadius),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
  }

  static bool _isDisabled(
    Set<WidgetState> states,
    AppButtonVisualState visualState,
  ) {
    return visualState == AppButtonVisualState.disabled ||
        states.contains(WidgetState.disabled);
  }

  static bool _isProcessing(AppButtonVisualState visualState) {
    return visualState == AppButtonVisualState.processing;
  }

  static bool _isInactive(
    Set<WidgetState> states,
    AppButtonVisualState visualState,
  ) {
    return _isDisabled(states, visualState) || _isProcessing(visualState);
  }
}
