import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:z_speed/core/theme/dark_mode.dart';
import 'package:z_speed/core/theme/light_mode.dart';

@injectable
class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(lightMode);

  bool get isDarkMode => state == darkMode;
  
  // Exposes theme mode for MaterialApp
  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    if (state == lightMode) {
      emit(darkMode);
    } else {
      emit(lightMode);
    }
  }

  void setTheme(ThemeData theme) {
    emit(theme);
  }
}
