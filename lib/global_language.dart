// global_language.dart - Migrado a PostgreSQL API
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as ri;
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';

import '../Language/language_provider.dart';
import '../Provider/profile_provider.dart';
import '../Screen/Widgets/Constant Data/constant.dart';
import 'services/api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

class GlobalLanguage extends StatefulWidget {
  const GlobalLanguage({super.key, required this.isDrawer});
  final bool isDrawer;

  @override
  State<GlobalLanguage> createState() => _GlobalLanguageState();
}

class _GlobalLanguageState extends State<GlobalLanguage> {
  List<String> baseFlagsCode = ['ES', 'US'];
  List<String> countryList = ['Spanish', 'English'];

  String selectedCountry = 'Spanish';
  String countryCode = 'es';

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('languageName');

    if (!data.isEmptyOrNull) {
      if (countryList.contains(data)) {
        setState(() {
          selectedCountry = data!;
          countryCode = getLanguageCode(selectedCountry);
        });
      }
    } else {
      setState(() {
        selectedCountry = countryList[0];
        countryCode = getLanguageCode(selectedCountry);
      });
    }
  }

  /// Cambiar idioma - Usa PostgreSQL API
  Future<void> changeLanguage(String country) async {
    final prefs = await SharedPreferences.getInstance();

    selectedCountry = country;
    countryCode = getLanguageCode(country);

    await prefs.setString('languageName', selectedCountry);
    await prefs.setString('currentLocale', countryCode);

    context.read<LanguageChangeProvider>().changeLocale(countryCode);

    // Actualizar preferencia de idioma en PostgreSQL API
    try {
      await _apiService.put('settings/personal-information', {
        'language': selectedCountry,
        'currentLocale': countryCode,
      });
    } catch (e) {
      // Error silencioso - el cambio local ya se aplicó
      debugPrint('Error guardando preferencia de idioma: $e');
    }

    setState(() {});
  }

  String getLanguageCode(String language) {
    switch (language) {
      case 'English':
        return 'en';
      case 'Spanish':
        return 'es';
      default:
        return 'en';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ri.Consumer(builder: (context, ref, __) {
      return SizedBox(
        height: 40,
        width: widget.isDrawer ? 125 : 152,
        child: DropdownButtonFormField<String>(
          dropdownColor: widget.isDrawer ? kChartColor : Colors.white,
          alignment: Alignment.center,
          decoration: kInputDecoration.copyWith(
            contentPadding: const EdgeInsets.all(8),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
              borderSide: BorderSide(color: kNeutral400, width: 1),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
              borderSide: BorderSide(color: kNeutral400, width: 1),
            ),
          ),
          isExpanded: true,
          value: selectedCountry,
          items: List.generate(
            countryList.length,
            (index) => DropdownMenuItem<String>(
              value: countryList[index],
              child: Row(
                children: [
                  Flag.fromString(
                    baseFlagsCode[index],
                    height: 15,
                    width: 20,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      countryList[index],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            overflow: TextOverflow.ellipsis,
                            color:
                                widget.isDrawer ? Colors.white : Colors.black,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          onChanged: (value) async {
            if (value != null) {
              await changeLanguage(value);
              final _ = ref.refresh(profileDetailsProvider);
            }
          },
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: widget.isDrawer ? Colors.white : const Color(0xFF585865),
          ),
          isDense: true,
          padding: EdgeInsets.zero,
        ),
      );
    });
  }
}
