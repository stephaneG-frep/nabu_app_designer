import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.light;

  AppThemeMode get mode => _mode;

  ThemeData get theme => AppTheme.byMode(_mode);

  void setMode(AppThemeMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
  }
}
