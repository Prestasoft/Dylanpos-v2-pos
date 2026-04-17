import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Provider de tema claro/oscuro exclusivo para pantallas de "Mi Panel" (empleados).
///
/// Persiste la preferencia en SharedPreferences bajo la clave [_prefKey].
/// El sistema principal (admin) no se ve afectado — siempre usa su tema propio.
class TaskThemeProvider with ChangeNotifier {
  static const _prefKey = 'task_panel_dark_mode';

  bool _isDark = false;
  bool get isDark => _isDark;

  TaskThemeProvider() {
    _isDark = getBoolAsync(_prefKey, defaultValue: false);
  }

  void toggle() {
    _isDark = !_isDark;
    setValue(_prefKey, _isDark);
    notifyListeners();
  }
}
