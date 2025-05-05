import 'package:firebase_database/firebase_database.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as ri;
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';

import '../Language/language_provider.dart';
import '../Provider/profile_provider.dart';
import '../Screen/Widgets/Constant Data/constant.dart';
import '../const.dart';

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

  Future<void> changeLanguage(String country) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await getUserID();
    final personalInformationRef = FirebaseDatabase.instance
        .ref()
        .child(userId)
        .child('Personal Information');

    selectedCountry = country;
    countryCode = getLanguageCode(country);

    await prefs.setString('languageName', selectedCountry);
    await prefs.setString('currentLocale', countryCode);

    context.read<LanguageChangeProvider>().changeLocale(countryCode);

    await personalInformationRef.update({
      'language': selectedCountry,
      'currentLocale': countryCode,
    });

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

// import 'package:firebase_database/firebase_database.dart';
// import 'package:flag/flag_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart' as fr; // Aliasing flutter_riverpod
// import 'package:nb_utils/nb_utils.dart';
// import 'package:provider/provider.dart';
//
// import '../Language/language_provider.dart';
// import '../Provider/profile_provider.dart';
// import '../Screen/Widgets/Constant Data/constant.dart';
// import '../const.dart';
//
// class GlobalLanguage extends StatefulWidget {
//   const GlobalLanguage({super.key, required this.isDrawer});
//   final bool isDrawer;
//
//   @override
//   State<GlobalLanguage> createState() => _GlobalLanguageState();
// }
//
// class _GlobalLanguageState extends State<GlobalLanguage> {
//   getData() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? data = prefs.getString('languageName');
//
//     if (!data.isEmptyOrNull) {
//       for (var element in countryList) {
//         if (element.contains(data!)) {
//           setState(() {
//             selectedCountry = element;
//           });
//           break;
//         }
//       }
//     } else {
//       setState(() {
//         selectedCountry = countryList[0];
//       });
//     }
//   }
//
//   //--------------------language-------------------------------
//   List<String> baseFlagsCode = ['US', 'ES', 'IN', 'SA', 'FR', 'BD', 'TR', 'CN', 'JP', 'RO', 'DE', 'VN', 'IT', 'TH', 'PT', 'IL', 'PL', 'HU', 'FI', 'KR', 'MY', 'ID', 'UA', 'BA', 'GR', 'NL', 'Pk', 'LK', 'IR', 'RS', 'KH', 'LA', 'RU', 'IN', 'IN', 'IN', 'ZA', 'CZ', 'SE', 'SK', 'TZ', 'AL', 'DK', 'AZ', 'KZ', 'HR', 'NP'];
//   List<String> countryList = ['English', 'Spanish', 'Hindi', 'Arabic', 'France', 'Bengali', 'Turkish', 'Chinese', 'Japanese', 'Romanian', 'Germany', 'Vietnamese', 'Italian', 'Thai', 'Portuguese', 'Hebrew', 'Polish', 'Hungarian', 'Finland', 'Korean', 'Malay', 'Indonesian', 'Ukrainian', 'Bosnian', 'Greek', 'Dutch', 'Urdu', 'Sinhala', 'Persian', 'Serbian', 'Khmer', 'Lao', 'Russian', 'Kannada', 'Marathi', 'Tamil', 'Afrikaans', 'Czech', 'Swedish', 'Slovak', 'Swahili', 'Albanian', 'Danish', 'Azerbaijani', 'Kazakh', 'Croatian', 'Nepali'];
//
//   String selectedCountry = 'Spanish';
//   String countryCode = 'es';
//
//   Future<void> changeLanguage(String code) async {
//     countryCode = code;
//     final DatabaseReference personalInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Personal Information');
//     final prefs = await SharedPreferences.getInstance();
//     context.read<LanguageChangeProvider>().changeLocale(code);
//     prefs.setString('languageName', selectedCountry);
//     prefs.setString('currentLocale', code);
//     setState(() {});
//   }
//
//   String? dropdownValue = '\$ (US Dollar)';
//
//   setLanguage(String language) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('languageName', language);
//     getData();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return fr.Consumer(builder: (context, ref, __) {
//       return SizedBox(
//         height: 40,
//         width: widget.isDrawer ? 125 : 152,
//         child: DropdownButtonFormField(
//           dropdownColor: widget.isDrawer == true ? kChartColor : Colors.white,
//           alignment: Alignment.center,
//           decoration: kInputDecoration.copyWith(
//             contentPadding: const EdgeInsets.all(8),
//             enabledBorder: const OutlineInputBorder(
//               borderRadius: BorderRadius.all(Radius.circular(30.0)),
//               borderSide: BorderSide(color: kNeutral400, width: 1),
//             ),
//             focusedBorder: const OutlineInputBorder(
//               borderRadius: BorderRadius.all(Radius.circular(30.0)),
//               borderSide: BorderSide(color: kNeutral400, width: 1),
//             ),
//           ),
//           isExpanded: true,
//           value: selectedCountry,
//           items: List.generate(
//               countryList.length,
//                   (index) => DropdownMenuItem(
//                 onTap: () async {
//                   final prefs = await SharedPreferences.getInstance();
//                   final DatabaseReference personalInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Personal Information');
//                   personalInformationRef.update({'language': selectedCountry});
//
//                   setState(() {
//                     selectedCountry = countryList[index];
//                     setLanguage(selectedCountry);
//                     switch (selectedCountry) {
//                       case 'English':
//                         changeLanguage("en");
//                         break;
//                       case 'Swahili':
//                         changeLanguage("sw");
//                         break;
//                       case 'Arabic':
//                         changeLanguage("ar");
//                         break;
//                       case 'Spanish':
//                         changeLanguage("es");
//                         break;
//                       case 'Hindi':
//                         changeLanguage("hi");
//                         break;
//                       case 'France':
//                         changeLanguage("fr");
//                         break;
//                       case 'Bengali':
//                         changeLanguage("bn");
//                         break;
//                       case 'Turkish':
//                         changeLanguage("tr");
//                         break;
//                       case 'Chinese':
//                         changeLanguage("zh");
//                         break;
//                       case 'Japanese':
//                         changeLanguage("ja");
//                         break;
//                       case 'Romanian':
//                         changeLanguage("ro");
//                         break;
//                       case 'Germany':
//                         changeLanguage("de");
//                         break;
//                       case 'Vietnamese':
//                         changeLanguage("vi");
//                         break;
//                       case 'Italian':
//                         changeLanguage("it");
//                         break;
//                       case 'Thai':
//                         changeLanguage("th");
//                         break;
//                       case 'Portuguese':
//                         changeLanguage("pt");
//                         break;
//                       case 'Hebrew':
//                         changeLanguage("he");
//                         break;
//                       case 'Polish':
//                         changeLanguage("pl");
//                         break;
//                       case 'Hungarian':
//                         changeLanguage("hu");
//                         break;
//                       case 'Finland':
//                         changeLanguage("fi");
//                         break;
//                       case 'Korean':
//                         changeLanguage("ko");
//                         break;
//                       case 'Malay':
//                         changeLanguage("ms");
//                         break;
//                       case 'Indonesian':
//                         changeLanguage("id");
//                         break;
//                       case 'Ukrainian':
//                         changeLanguage("uk");
//                         break;
//                       case 'Bosnian':
//                         changeLanguage("bs");
//                         break;
//                       case 'Greek':
//                         changeLanguage("el");
//                         break;
//                       case 'Dutch':
//                         changeLanguage("nl");
//                         break;
//                       case 'Urdu':
//                         changeLanguage("ur");
//                         break;
//                       case 'Sinhala':
//                         changeLanguage("si");
//                         break;
//                       case 'Persian':
//                         changeLanguage("fa");
//                         break;
//                       case 'Serbian':
//                         changeLanguage("sr");
//                         break;
//                       case 'Khmer':
//                         changeLanguage("km");
//                         break;
//                       case 'Lao':
//                         changeLanguage("lo");
//                         break;
//                       case 'Russian':
//                         changeLanguage("ru");
//                         break;
//                       case 'Kannada':
//                         changeLanguage("kn");
//                         break;
//                       case 'Marathi':
//                         changeLanguage("mr");
//                         break;
//                       case 'Tamil':
//                         changeLanguage("ta");
//                         break;
//                       case 'Afrikaans':
//                         changeLanguage("af");
//                         break;
//                       case 'Czech':
//                         changeLanguage("cs");
//                         break;
//                       case 'Swedish':
//                         changeLanguage("sv");
//                         break;
//                       case 'Slovak':
//                         changeLanguage("sk");
//                         break;
//                       case 'Burmese':
//                         changeLanguage("my");
//                         break;
//                       case 'Albanian':
//                         changeLanguage("sq");
//                         break;
//                       case 'Danish':
//                         changeLanguage("da");
//                         break;
//                       case 'Azerbaijani':
//                         changeLanguage("az");
//                         break;
//                       case 'Kazakh':
//                         changeLanguage("kk");
//                         break;
//                       case 'Croatian':
//                         changeLanguage("hr");
//                         break;
//                       case 'Nepali':
//                         changeLanguage("ne");
//                         break;
//                       default:
//                         changeLanguage("en");
//                     }
//                   });
//                   personalInformationRef.update({'currentLocale': countryCode});
//                 },
//                 value: countryList[index],
//                 child: InkWell(
//                   child: Row(
//                     children: [
//                       Flag.fromString(
//                         baseFlagsCode[index],
//                         height: 15,
//                         width: 20,
//                       ),
//                       const SizedBox(width: 5),
//                       Flexible(
//                         child: Text(
//                           countryList[index],
//                           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                             overflow: TextOverflow.ellipsis,
//                             color: widget.isDrawer == true ? Colors.white : Colors.black,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )),
//           onChanged: (value) {
//             setState(() async {
//               selectedCountry = value.toString();
//               ref.refresh(profileDetailsProvider);
//             });
//           },
//           icon: Icon(
//             Icons.keyboard_arrow_down_rounded,
//             color: widget.isDrawer ? Colors.white : const Color(0xFF585865),
//           ),
//           isDense: true,
//           padding: EdgeInsets.zero,
//         ),
//       );
//     });
//   }
// }
