import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'currency_list.dart';

class CurrencyProvider with ChangeNotifier {
  String? _currency = 'RD\$'; // Initialize with the default currency symbol
  String? _dropdownCurrencyValue = 'RD\$ (Dominican Peso)';

  String? get currency => _currency;
  String? get dropdownCurrencyValue => _dropdownCurrencyValue;

  Future<void> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('currency');

    if (data != null && data.isNotEmpty) {
      for (var element in currencySymbols.keys) {
        if (element.substring(0, 2).contains(data) || element.substring(0, 5).contains(data)) {
          _currency = data;
          _dropdownCurrencyValue = element;
          notifyListeners();
          break;
        }
      }
    } else {
      _currency = '\$'; // Default currency
      _dropdownCurrencyValue = currencySymbols.keys.first;
      notifyListeners();
    }
  }

  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    _currency = currency;
    notifyListeners();
    await getCurrency(); // Refresh the currency state
  }
}
