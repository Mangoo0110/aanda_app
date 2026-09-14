part of 'app_theme.dart';

class ProgressIndicatorThemes {
  static ProgressIndicatorThemeData light = ProgressIndicatorThemeData(
    color: AppColors.light().primaryColor,
    linearTrackColor: AppColors.light().tileColor,
    circularTrackColor: AppColors.light().tileColor,
  );

  static ProgressIndicatorThemeData dark = ProgressIndicatorThemeData(
    color: AppColors.dark().primaryColor,
    linearTrackColor: AppColors.dark().tileColor,
    circularTrackColor: AppColors.dark().tileColor,
  );
}
