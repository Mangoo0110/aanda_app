import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class AppThemeCubit extends Cubit<ThemeMode> {
  AppThemeCubit() : super(ThemeMode.light);

  void toggle() {
    emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
