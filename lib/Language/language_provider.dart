import 'dart:ui';

import 'package:flutter/foundation.dart';

class LanguageChangeProvider with ChangeNotifier {
  Locale _currentLocale = const Locale("es");

  Locale get currentLocale => _currentLocale;

  void changeLocale(String locale) {
    _currentLocale = Locale(locale);
    // print(_currentLocale);
    notifyListeners();
  }
}
