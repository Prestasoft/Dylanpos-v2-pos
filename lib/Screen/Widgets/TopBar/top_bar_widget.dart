// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flag/flag_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:flutter_feather_icons/flutter_feather_icons.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart' as ri;
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:nb_utils/nb_utils.dart';
// import 'package:provider/provider.dart';
// import 'package:restart_app/restart_app.dart';
// import 'package:salespro_admin/Screen/Authentication/log_in.dart';
// import 'package:salespro_admin/model/personal_information_model.dart';
// import '../../../Language/language_provider.dart';
// import '../../../Provider/profile_provider.dart';
// import '../../../const.dart';
// import '../../../currency.dart';
// import '../../Authentication/profile_setup.dart';
// import '../../Authentication/tablet_profile_set_up.dart';
// import '../../Home/home_screen.dart';
// import '../../Inventory Sales/inventory_sales.dart';
// import '../../POS Sale/pos_sale.dart';
// import '../../Product/product.dart';
// import '../../Purchase List/purchase_list.dart';
// import '../Constant Data/constant.dart';
// import 'package:salespro_admin/generated/l10n.dart' as lang;
//
// class TopBar extends StatefulWidget {
//   const TopBar({
//     super.key,
//   });
//
//   @override
//   State<TopBar> createState() => _TopBarState();
// }
//
// class _TopBarState extends State<TopBar> {
//   final ScrollController mainSideScroller = ScrollController();
//
//   List<String> baseFlagsCode = [
//     'US',
//     'ES',
//     'IN',
//     'SA',
//     'FR',
//     'BD',
//     'TR',
//     'CN',
//     'JP',
//     'RO',
//     'DE',
//     'VN',
//     'IT',
//     'TH',
//     'PT',
//     'IL',
//     'PL',
//     'HU',
//     'FI',
//     'KR',
//     'MY',
//     'ID',
//     'UA',
//     'BA',
//     'GR',
//     'NL',
//     'Pk',
//     'LK',
//     'IR',
//     'RS',
//     'KH',
//     'LA',
//     'RU',
//     'IN',
//     'IN',
//     'IN',
//     'ZA',
//     'CZ',
//     'SE',
//     'SK',
//     'TZ',
//     'AL',
//     'DK',
//     'AZ',
//     'KZ',
//     'HR',
//     'NP'
//   ];
//   List<String> countryList = [
//     'English',
//     'Spanish',
//     'Hindi',
//     'Arabic',
//     'France',
//     'Bengali',
//     'Turkish',
//     'Chinese',
//     'Japanese',
//     'Romanian',
//     'Germany',
//     'Vietnamese',
//     'Italian',
//     'Thai',
//     'Portuguese',
//     'Hebrew',
//     'Polish',
//     'Hungarian',
//     'Finland',
//     'Korean',
//     'Malay',
//     'Indonesian',
//     'Ukrainian',
//     'Bosnian',
//     'Greek',
//     'Dutch',
//     'Urdu',
//     'Sinhala',
//     'Persian',
//     'Serbian',
//     'Khmer',
//     'Lao',
//     'Russian',
//     'Kannada',
//     'Marathi',
//     'Tamil',
//     'Afrikaans',
//     'Czech',
//     'Swedish',
//     'Slovak',
//     'Swahili',
//     'Albanian',
//     'Danish',
//     'Azerbaijani',
//     'Kazakh',
//     'Croatian',
//     'Nepali'
//   ];
//
//   String selectedCountry = 'English';
//   String countryCode = 'en';
//
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
//   Future<void> changeLanguage(String code) async {
//     countryCode = code;
//     final DatabaseReference personalInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Personal Information');
//     final prefs = await SharedPreferences.getInstance();
//     context.read<LanguageChangeProvider>().changeLocale(code);
//     // setLanguage(selectedCountry);
//     // setLocale(countryCode);
//     prefs.setString('languageName', selectedCountry);
//     prefs.setString('currentLocale', code);
//     // personalInformationRef.update({'language': selectedCountry});
//     // personalInformationRef.update({'currentLocale': countryCode});
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
// //______________________________________currency___________
//   getCurrency() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? data = prefs.getString('currency');
//
//     if (!data.isEmptyOrNull) {
//       for (var element in items) {
//         if (element.substring(0, 2).contains(data!) || element.substring(0, 5).contains(data!)) {
//           setState(() {
//             currency = data;
//             dropdownValue = element;
//           });
//           break;
//         }
//       }
//     } else {
//       setState(() {
//         dropdownValue = items[0];
//       });
//     }
//   }
//
//   setCurrency(String currency) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('currency', currency);
//     getCurrency();
//   }
//
//   bool isFirstTime = true;
//
//   int i = 0;
//
//   @override
//   void initState() {
//     final User? user = FirebaseAuth.instance.currentUser;
//     if (user?.uid == null) {
//       Restart.restartApp();
//     }
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 70.0,
//       width: double.infinity,
//       decoration: const BoxDecoration(
//         color: kWhite,
//       ),
//       child: ri.Consumer(builder: (context, ref, __) {
//         AsyncValue<PersonalInformationModel> userProfileDetails = ref.watch(profileDetailsProvider);
//
//         return Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           // mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(width: 30.0),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
//
//                 backgroundColor: const Color(0xFF8424FF),
//                 // side: const BorderSide(color: kBorderColorTextField, width: 1),
//                 textStyle: kTextStyle.copyWith(color: kWhite),
//                 surfaceTintColor: const Color(0xFF8424FF).withOpacity(0.5),
//                 shadowColor: const Color(0xFF8424FF).withOpacity(0.1),
//               ),
//               onPressed: () {
//                 Navigator.pushNamed(context, '/pos-sales');
//               },
//               child: Row(
//                 children: [
//                   const Icon(Icons.add_rounded, color: kWhite),
//                   Text(
//                     'Pos',
//                     style: kTextStyle.copyWith(color: kWhite, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 16.0),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
//                 backgroundColor: kWhite,
//                 side: const BorderSide(color: kMainColor, width: 1),
//                 textStyle: kTextStyle.copyWith(color: kWhite),
//                 surfaceTintColor: lightGreyColor,
//                 shadowColor: lightGreyColor.withOpacity(0.1),
//               ),
//               onPressed: () {
//                 Navigator.pushNamed(context, '/inventory-sales');
//               },
//               child: Row(
//                 children: [
//                   const Icon(Icons.add_rounded, color: kMainColor),
//                   Text(
//                     'Inventory',
//                     style: kTextStyle.copyWith(color: kMainColor, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 30.0),
//             userProfileDetails.when(data: (details) {
//               setCurrency(details.currency);
//               setLanguage(details.language);
//               i == 0 ? changeLanguage(details.currentLocale) : null;
//               i++;
//               // setLocale(details.currentLocale);
//
//               //  isFirstTime = false;
//               return SizedBox(
//                 width: 180,
//                 child: Text(
//                   isSubUser ? '${details.companyName ?? ''} [$constSubUserTitle]' : details.companyName ?? '',
//                   overflow: TextOverflow.ellipsis,
//                   maxLines: 1,
//                   style: GoogleFonts.poppins(
//                     fontSize: context.width() < 900 ? 25 : context.width() * 0.018,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               );
//             }, error: (e, stack) {
//               return Text(e.toString());
//             }, loading: () {
//               return const Text('');
//             }),
//             const Spacer(),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
//                 backgroundColor: kWhite,
//                 side: const BorderSide(color: Color(0xFFFF2525), width: 1),
//                 textStyle: kTextStyle.copyWith(color: const Color(0xFFFF2525)),
//                 surfaceTintColor: kWhite,
//                 shadowColor: const Color(0xFFFF2525).withOpacity(0.1),
//                 foregroundColor: const Color(0xFFFF2525).withOpacity(0.1),
//               ),
//               onPressed: () {
//                 Navigator.pushNamed(context, Product.route);
//               },
//               child: Row(
//                 children: [
//                   const Icon(Icons.add_rounded, color: Color(0xFFFF2525)),
//                   Text(
//                     'Product',
//                     style: kTextStyle.copyWith(color: Color(0xFFFF2525), fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 10.0),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
//                 backgroundColor: kWhite,
//                 side: const BorderSide(color: Color(0xFF15CD75), width: 1),
//                 textStyle: kTextStyle.copyWith(color: const Color(0xFF15CD75)),
//                 surfaceTintColor: kWhite,
//                 shadowColor: const Color(0xFF15CD75).withOpacity(0.1),
//                 foregroundColor: const Color(0xFF15CD75).withOpacity(0.1),
//               ),
//               onPressed: () {
//                 Navigator.pushNamed(context, PurchaseList.route);
//               },
//               child: Row(
//                 children: [
//                   const Icon(Icons.add_rounded, color: Color(0xFF15CD75)),
//                   Text(
//                     'Purchase',
//                     style: kTextStyle.copyWith(color: Color(0xFF15CD75), fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 10.0),
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(30.0),
//                   color: Colors.white,
//                   border: Border.all(color: const Color(0xFF828282).withOpacity(0.3)),
//                 ),
//                 padding: const EdgeInsets.fromLTRB(13.0, 5.0, 13.0, 5.0),
//                 child: Theme(
//                   data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
//                   child: DropdownButton(
//                     underline: const SizedBox(),
//                     dropdownColor: Colors.white,
//                     focusColor: kbgColor,
//                     alignment: Alignment.center,
//                     isExpanded: true,
//                     style: const TextStyle(overflow: TextOverflow.ellipsis),
//                     value: selectedCountry,
//                     items: List.generate(
//                         countryList.length,
//                         (index) => DropdownMenuItem(
//                               onTap: () async {
//                                 final prefs = await SharedPreferences.getInstance();
//                                 final DatabaseReference personalInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Personal Information');
//                                 personalInformationRef.update({'language': selectedCountry});
//
//                                 setState(
//                                   () {
//                                     selectedCountry = countryList[index];
//                                     setLanguage(selectedCountry);
//                                     switch (selectedCountry) {
//                                       case 'English':
//                                         changeLanguage("en");
//                                         break;
//                                       case 'Swahili':
//                                         changeLanguage("sw");
//                                         break;
//                                       case 'Arabic':
//                                         changeLanguage("ar");
//                                         break;
//                                       case 'Spanish':
//                                         changeLanguage("es");
//                                         break;
//                                       case 'Hindi':
//                                         changeLanguage("hi");
//                                         break;
//                                       case 'France':
//                                         changeLanguage("fr");
//                                         break;
//                                       case 'Bengali':
//                                         changeLanguage("bn");
//                                         break;
//                                       case 'Turkish':
//                                         changeLanguage("tr");
//                                         break;
//                                       case 'Chinese':
//                                         changeLanguage("zh");
//                                         break;
//                                       case 'Japanese':
//                                         changeLanguage("ja");
//                                         break;
//                                       case 'Romanian':
//                                         changeLanguage("ro");
//                                         break;
//                                       case 'Germany':
//                                         changeLanguage("de");
//                                         break;
//                                       case 'Vietnamese':
//                                         changeLanguage("vi");
//                                         break;
//                                       case 'Italian':
//                                         changeLanguage("it");
//                                         break;
//                                       case 'Thai':
//                                         changeLanguage("th");
//                                         break;
//                                       case 'Portuguese':
//                                         changeLanguage("pt");
//                                         break;
//                                       case 'Hebrew':
//                                         changeLanguage("he");
//                                         break;
//                                       case 'Polish':
//                                         changeLanguage("pl");
//                                         break;
//                                       case 'Hungarian':
//                                         changeLanguage("hu");
//                                         break;
//                                       case 'Finland':
//                                         changeLanguage("fi");
//                                         break;
//                                       case 'Korean':
//                                         changeLanguage("ko");
//                                         break;
//                                       case 'Malay':
//                                         changeLanguage("ms");
//                                         break;
//                                       case 'Indonesian':
//                                         changeLanguage("id");
//                                         break;
//                                       case 'Ukrainian':
//                                         changeLanguage("uk");
//                                         break;
//                                       case 'Bosnian':
//                                         changeLanguage("bs");
//                                         break;
//                                       case 'Greek':
//                                         changeLanguage("el");
//                                         break;
//                                       case 'Dutch':
//                                         changeLanguage("nl");
//                                         break;
//                                       case 'Urdu':
//                                         changeLanguage("ur");
//                                         break;
//                                       case 'Sinhala':
//                                         changeLanguage("si");
//                                         break;
//                                       case 'Persian':
//                                         changeLanguage("fa");
//                                         break;
//                                       case 'Serbian':
//                                         changeLanguage("sr");
//                                         break;
//                                       case 'Khmer':
//                                         changeLanguage("km");
//                                         break;
//                                       case 'Lao':
//                                         changeLanguage("lo");
//                                         break;
//                                       case 'Russian':
//                                         changeLanguage("ru");
//                                         break;
//                                       case 'Kannada':
//                                         changeLanguage("kn");
//                                         break;
//                                       case 'Marathi':
//                                         changeLanguage("mr");
//                                         break;
//                                       case 'Tamil':
//                                         changeLanguage("ta");
//                                         break;
//                                       case 'Afrikaans':
//                                         changeLanguage("af");
//                                         break;
//                                       case 'Czech':
//                                         changeLanguage("cs");
//                                         break;
//                                       case 'Swedish':
//                                         changeLanguage("sv");
//                                         break;
//                                       case 'Slovak':
//                                         changeLanguage("sk");
//                                         break;
//                                       case 'Burmese':
//                                         changeLanguage("my");
//                                         break;
//                                       case 'Albanian':
//                                         changeLanguage("sq");
//                                         break;
//                                       case 'Danish':
//                                         changeLanguage("da");
//                                         break;
//                                       case 'Azerbaijani':
//                                         changeLanguage("az");
//                                         break;
//                                       case 'Kazakh':
//                                         changeLanguage("kk");
//                                         break;
//                                       case 'Croatian':
//                                         changeLanguage("hr");
//                                         break;
//                                       case 'Nepali':
//                                         changeLanguage("ne");
//                                         break;
//                                       default:
//                                         changeLanguage("en");
//                                     }
//                                     // saveDataOnLocal(key: 'savedLanguage', type: 'string', value: selectedCountry);
//                                   },
//                                 );
//                                 personalInformationRef.update({'currentLocale': countryCode});
//                               },
//                               value: countryList[index],
//                               child: InkWell(
//                                 child: Row(
//                                   children: [
//                                     Flag.fromString(
//                                       baseFlagsCode[index],
//                                       height: 15,
//                                       width: 20,
//                                     ),
//                                     const SizedBox(width: 5),
//                                     Flexible(
//                                       child: Text(
//                                         countryList[index],
//                                         style: const TextStyle(fontSize: 14, overflow: TextOverflow.ellipsis),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             )),
//                     onChanged: (value) {
//                       setState(() async {
//                         selectedCountry = value.toString();
//                         ref.refresh(profileDetailsProvider);
//                         Future.delayed(Duration(milliseconds: 600)).then((value) => Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const MtHomeScreen(),
//                               ),
//                             )); // Update selectedCountry here
//                       });
//                     },
//                     icon: const Icon(
//                       Icons.keyboard_arrow_down_rounded,
//                       color: Color(0xFF585865),
//                     ),
//                     isDense: true,
//                     padding: EdgeInsets.zero,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10.0),
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(30.0),
//                   color: Colors.white,
//                   border: Border.all(color: const Color(0xFF828282).withOpacity(0.3)),
//                 ),
//                 padding: const EdgeInsets.fromLTRB(13.0, 5.0, 13.0, 5.0),
//                 child: Theme(
//                   data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
//                   child: DropdownButton(
//                     dropdownColor: Colors.white,
//                     alignment: Alignment.center,
//                     isExpanded: true,
//                     padding: EdgeInsets.zero,
//                     underline: const SizedBox(),
//                     value: dropdownValue,
//                     icon: const Icon(
//                       Icons.keyboard_arrow_down_rounded,
//                       color: Color(0xFF585865),
//                     ),
//                     isDense: true,
//                     items: items.map((String items) {
//                       return DropdownMenuItem(
//                         value: items,
//                         child: Text(
//                           items,
//                           style: kTextStyle.copyWith(color: kTitleColor, fontSize: 14.0, overflow: TextOverflow.ellipsis),
//                         ),
//                       );
//                     }).toList(),
//                     onChanged: (String? newValue) async {
//                       final prefs = await SharedPreferences.getInstance();
//
//                       // Use a map for currency symbols
//                       final currencySymbols = {
//                         '\$ (US Dollar)': '\$',
//                         '₹ (Rupee)': '₹',
//                         '€ (Euro)': '€',
//                         '₽ (Ruble)': '₽',
//                         '£ (UK Pound)': '£',
//                         '৳ (Taka)': '৳',
//                         'R (Rial)': 'R',
//                         '؋ (Afghani)': '؋',
//                         'Lek (Lek)': 'Lek',
//                         'د.ج (Algerian Dinar)': 'د.ج',
//                         'Kz (Kwanza)': 'Kz',
//                         'EC\$ (East Caribbean Dollar)': 'EC\$',
//                         '\$ (Argentine Peso)': '\$',
//                         '֏ (Armenian Dram)': '֏',
//                         'A\$ (Australian Dollar)': 'A\$',
//                         '₼ (Azerbaijani Manat)': '₼',
//                         'B\$ (Bahamian Dollar)': 'B\$',
//                         '.د.ب (Bahraini Dinar)': '.د.ب',
//                         'Bds\$ (Barbadian Dollar)': 'Bds\$',
//                         'Br (Belarusian Ruble)': 'Br',
//                         'BZ\$ (Belize Dollar)': 'BZ\$',
//                         'CFA (West African CFA franc)': 'CFA',
//                         'FCFA (West African CFA franc)': 'FCFA',
//                         'Nu. (Bhutanese Ngultrum)': 'Nu.',
//                         'Bs. (Bolivian Boliviano)': 'Bs.',
//                         'KM (Bosnia and Herzegovina Convertible Mark)': 'KM',
//                         'P (Botswana Pula)': 'P',
//                         'R\$ (Brazilian Real)': 'R\$',
//                         'B\$ (Brunei Dollar)': 'B\$',
//                         'лв (Bulgarian Lev)': 'лв',
//                         'FBu (Burundian Franc)': 'FBu',
//                         'Esc (Cape Verdean Escudo)': 'Esc',
//                         '៛ (Cambodian Riel)': '៛',
//                         'CFA F (Central African CFA franc)': 'CFA F',
//                         'CA\$ (Canadian Dollar)': 'CA\$',
//                         '\$ (Chilean Peso)': '\$',
//                         '¥ (Chinese Yuan)': '¥',
//                         '\$ (Colombian Peso)': '\$',
//                         'CF (Comorian Franc)': 'CF',
//                         'FC (Congolese Franc)': 'FC',
//                         '₡ (Costa Rican Colón)': '₡',
//                         'kn (Croatian Kuna)': 'kn',
//                         'CUP (Cuban Peso)': 'CUP',
//                         'Kč (Czech Koruna)': 'Kč',
//                         'kr (Danish Krone)': 'kr',
//                         'Fdj (Djiboutian Franc)': 'Fdj',
//                         'RD\$ (Dominican Peso)': 'RD\$',
//                         'US\$ (United States Dollar)': 'US\$',
//                         '\$ (United States Dollar)': '\$',
//                         'E£ (Egyptian Pound)': 'E£',
//                         'Nfk (Eritrean Nakfa)': 'Nfk',
//                         'E (Swazi Lilangeni)': 'E',
//                         'Br (Ethiopian Birr)': 'Br',
//                         'FJ\$ (Fijian Dollar)': 'FJ\$',
//                         'D (Gambian Dalasi)': 'D',
//                         '₾ (Georgian Lari)': '₾',
//                         'GH₵ (Ghanaian Cedi)': 'GH₵',
//                         'Q (Guatemalan Quetzal)': 'Q',
//                         'GNF (Guinean Franc)': 'GNF',
//                         'GY\$ (Guyanese Dollar)': 'GY\$',
//                         'G (Haitian Gourde)': 'G',
//                         'L (Honduran Lempira)': 'L',
//                         'Ft (Hungarian Forint)': 'Ft',
//                         'kr (Icelandic Króna)': 'kr',
//                         'Rp (Indonesian Rupiah)': 'Rp',
//                         '﷼ (Iranian Rial)': '﷼',
//                         'ع.د (Iraqi Dinar)': 'ع.د',
//                         '₪ (Israeli New Shekel)': '₪',
//                         'J\$ (Jamaican Dollar)': 'J\$',
//                         '¥ (Japanese Yen)': '¥',
//                         'د.ا (Jordanian Dinar)': 'د.ا',
//                         '₸ (Kazakhstani Tenge)': '₸',
//                         'KSh (Kenyan Shilling)': 'KSh',
//                         'AU\$ (Australian Dollar)': 'AU\$',
//                         'د.ك (Kuwaiti Dinar)': 'د.ك',
//                         'som (Kyrgyzstani Som)': 'som',
//                         '₭ (Laotian Kip)': '₭',
//                         'ل.ل (Lebanese Pound)': 'ل.ل',
//                         'L (Lesotho Loti)': 'L',
//                         'L\$ (Liberian Dollar)': 'L\$',
//                         'ل.د (Libyan Dinar)': 'ل.د',
//                         'CHF (Swiss Franc)': 'CHF',
//                         'Ar (Malagasy Ariary)': 'Ar',
//                         'MK (Malawian Kwacha)': 'MK',
//                         'RM (Malaysian Ringgit)': 'RM',
//                         'Rf (Maldivian Rufiyaa)': 'Rf',
//                         'Ouguiya (Mauritanian Ouguiya)': 'Ouguiya',
//                         'Rs (Mauritian Rupee)': 'Rs',
//                         'Mex\$ (Mexican Peso)': 'Mex\$',
//                         'lei (Moldovan Leu)': 'lei',
//                         '₮ (Mongolian Tugrik)': '₮',
//                         'د.م. (Moroccan Dirham)': 'د.م.',
//                         'MT (Mozambican Metical)': 'MT',
//                         'K (Myanmar Kyat)': 'K',
//                         'N\$ (Namibian Dollar)': 'N\$',
//                         'रू (Nepalese Rupee)': 'रू',
//                         'NZ\$ (New Zealand Dollar)': 'NZ\$',
//                         'C\$ (Nicaraguan Córdoba)': 'C\$',
//                         '₦ (Nigerian Naira)': '₦',
//                         'kr (Norwegian Krone)': 'kr',
//                         '﷼ (Omani Rial)': '﷼',
//                         'PKR (Pakistani Rupee)': 'PKR',
//                         '₱ (Philippine Peso)': '₱',
//                         'zł (Polish Złoty)': 'zł',
//                         '﷼ (Qatari Riyal)': '﷼',
//                         'lei (Romanian Leu)': 'lei',
//                         'руб (Russian Ruble)': 'руб',
//                         'RF (Rwandan Franc)': 'RF',
//                         '₣ (Swiss Franc)': '₣',
//                         '₲ (Paraguayan Guarani)': '₲',
//                         'SR (Saudi Riyal)': 'SR',
//                         'د.س (Sudanese Pound)': 'د.س',
//                         '\$ (Singapore Dollar)': '\$',
//                         'S (Solomon Islands Dollar)': 'S',
//                         'Sh (Somali Shilling)': 'Sh',
//                         'R (South African Rand)': 'R',
//                         '₩ (South Korean Won)': '₩',
//                         '£ (British Pound)': '£',
//                         '\$ (Sri Lankan Rupee)': '\$',
//                         'L (Saint Helenian Pound)': 'L',
//                         '\$ (East Caribbean Dollar)': '\$',
//                         'kr (Swedish Krona)': 'kr',
//                         'TJS (Tajikistani Somoni)': 'TJS',
//                         'TSh (Tanzanian Shilling)': 'TSh',
//                         '฿ (Thai Baht)': '฿',
//                         'T (Tongan Paʻanga)': 'T',
//                         'TTD (Trinidad and Tobago Dollar)': 'TTD',
//                         'XAf (XAf Central Africa)': 'XAF',
//                         // Add more currencies as needed
//                       };
//
//                       if (currencySymbols.containsKey(newValue)) {
//                         print(currencySymbols[newValue]!);
//                         currency = currencySymbols[newValue]!;
//                         await prefs.setString('currency', currency);
//                         final DatabaseReference personalInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Personal Information');
//                         await personalInformationRef.update({'currency': currency});
//                         // ref.refresh(profileDetailsProvider);
//                       } else {
//                         // Set a default currency if newValue is not found in the map
//                         currency = "\$";
//                         await prefs.setString('currency', currency);
//                       }
//
//                       setState(() {
//                         ref.refresh(profileDetailsProvider);
//                         Future.delayed(Duration(milliseconds: 400)).then((value) => dropdownValue = newValue.toString());
//
//                         ref.refresh(profileDetailsProvider);
//                         Future.delayed(Duration(milliseconds: 600)).then((value) => Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const MtHomeScreen(),
//                               ),
//                             ));
//                       });
//                     },
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10.0),
//             userProfileDetails.when(data: (details) {
//               return Theme(
//                 data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
//                 child: PopupMenuButton(
//                   surfaceTintColor: Colors.white,
//                   padding: EdgeInsets.zero,
//                   position: PopupMenuPosition.under,
//                   icon: Container(
//                     height: 70,
//                     width: 70,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF2DB0F6).withOpacity(0.1),
//                       shape: BoxShape.rectangle,
//                     ),
//                     child: const Icon(Icons.settings, color: Color(0xFF2DB0F6), size: 30.0),
//                   ),
//                   itemBuilder: (BuildContext bc) => [
//                     PopupMenuItem(
//                       child: GestureDetector(
//                         onTap: () {
//                           isSubUser ? null : ProfileUpdate(personalInformationModel: details).launch(context);
//                         },
//                         child: Row(
//                           children: [
//                             const Icon(Icons.manage_accounts_sharp, size: 18.0, color: kTitleColor),
//                             const SizedBox(width: 4.0),
//                             Text(
//                               isSubUser ? '${details.companyName}[$constSubUserTitle]' : lang.S.of(context).prof,
//                               style: kTextStyle.copyWith(color: kTitleColor),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     PopupMenuItem(
//                       child: GestureDetector(
//                         onTap: () async {
//                           await FirebaseAuth.instance.signOut();
//                           EasyLoading.showSuccess('Successfully Logged Out');
//                           Navigator.of(context).pushAndRemoveUntil(
//                             MaterialPageRoute(builder: (context) => const EmailLogIn()),
//                             (route) => false,
//                           );
//                           // const EmailLogIn().launch(context);
//                         },
//                         child: Row(
//                           children: [
//                             const Icon(FeatherIcons.logOut, size: 18.0, color: kTitleColor),
//                             const SizedBox(width: 4.0),
//                             Text(
//                               lang.S.of(context).logOut,
//                               style: kTextStyle.copyWith(color: kTitleColor),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }, error: (e, stack) {
//               return Center(
//                 child: Text(e.toString()),
//               );
//             }, loading: () {
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//             }),
//           ],
//         );
//       }),
//     );
//   }
// }
//
// class TopBarTablate extends StatelessWidget {
//   const TopBarTablate({
//     Key? key,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ri.Consumer(
//       builder: (_, ref, __) {
//         ri.AsyncValue<PersonalInformationModel> userProfileDetails = ref.watch(profileDetailsProvider);
//         return Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             // Container(
//             //   padding: const EdgeInsets.all(10.0),
//             //   decoration: BoxDecoration(
//             //     borderRadius: BorderRadius.circular(30.0),
//             //     color: kBlueTextColor,
//             //   ),
//             //   child: Row(
//             //     mainAxisSize: MainAxisSize.min,
//             //     children: [
//             //       const Icon(FeatherIcons.plus, color: kWhiteTextColor, size: 16.0),
//             //       const SizedBox(width: 5.0),
//             //       Text(
//             //         'Stock',
//             //         style: kTextStyle.copyWith(color: kWhiteTextColor),
//             //       ),
//             //     ],
//             //   ),
//             // ).onTap(
//             //       () => Navigator.pushNamed(context, SaleReports.route, arguments: 'Stock Report'),
//             // ),
//             const SizedBox(
//               width: 8.0,
//             ),
//             Container(
//               padding: const EdgeInsets.all(10.0),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(30.0),
//                 color: kRedTextColor,
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(FeatherIcons.plus, color: kWhite, size: 16.0),
//                   const SizedBox(width: 5.0),
//                   Text(
//                     lang.S.of(context).dueList,
//                     style: kTextStyle.copyWith(color: kWhite),
//                   ),
//                 ],
//               ),
//             ),
//             //     .onTap(
//             //   () => Navigator.pushNamed(context, TabletSaleReport.route, arguments: 'Due'),
//             // ),
//             const SizedBox(
//               width: 8.0,
//             ),
//             Container(
//               padding: const EdgeInsets.all(10.0),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(30.0),
//                 border: Border.all(color: kYellowColor),
//                 color: kWhite,
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(FeatherIcons.plus, color: kYellowColor, size: 16.0),
//                   const SizedBox(width: 5.0),
//                   Text(
//                     lang.S.of(context).reports,
//                     style: kTextStyle.copyWith(color: kYellowColor),
//                   ),
//                 ],
//               ),
//             ),
//             //         .onTap(
//             //   () => Navigator.pushNamed(context, TabletSaleReport.route),
//             // ),
//             const SizedBox(
//               width: 8.0,
//             ),
//             Container(
//               padding: const EdgeInsets.all(10.0),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(30.0),
//                 color: kRedTextColor,
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(FeatherIcons.plus, color: kWhite, size: 16.0),
//                   const SizedBox(width: 5.0),
//                   Text(
//                     lang.S.of(context).sale,
//                     style: kTextStyle.copyWith(color: kWhite),
//                   ),
//                 ],
//               ),
//             ),
//             //           .onTap(
//             //   () => Navigator.pushNamed(context, TabletPosSale.route),
//             // ),
//             const SizedBox(
//               width: 8.0,
//             ),
//             Container(
//               padding: const EdgeInsets.all(10.0),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(30.0),
//                 color: kGreenTextColor,
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(FeatherIcons.plus, color: kWhite, size: 16.0),
//                   const SizedBox(width: 5.0),
//                   Text(
//                     lang.S.of(context).purchase,
//                     style: kTextStyle.copyWith(color: kWhite),
//                   ),
//                 ],
//               ),
//             ),
//             //     .onTap(
//             //   () => Navigator.pushNamed(context, TabletPurchase.route),
//             // ),
//             const SizedBox(
//               width: 8.0,
//             ),
//             // Container(
//             //   padding: const EdgeInsets.all(10.0),
//             //   decoration: BoxDecoration(
//             //     borderRadius: BorderRadius.circular(30.0),
//             //     border: Border.all(color: kBlueTextColor),
//             //     color: kWhiteTextColor,
//             //   ),
//             //   child: Row(
//             //     mainAxisSize: MainAxisSize.min,
//             //     children: [
//             //       const Icon(FeatherIcons.plus, color: kBlueTextColor, size: 16.0),
//             //       const SizedBox(width: 5.0),
//             //       Text(
//             //         'Add More',
//             //         style: kTextStyle.copyWith(color: kBlueTextColor),
//             //       ),
//             //     ],
//             //   ),
//             // ),
//             // const Padding(
//             //   padding: EdgeInsets.all(8.0),
//             //   child: Icon(
//             //     FeatherIcons.bell,
//             //     color: kTitleColor,
//             //   ),
//             // ),
//             userProfileDetails.when(data: (details) {
//               return GestureDetector(
//                 onTap: () {
//                   TabletProfileSetUp(
//                     personalInformationModel: details,
//                   ).launch(context);
//                 },
//                 child: Container(
//                   height: 40,
//                   width: 40,
//                   decoration: BoxDecoration(
//                     image: DecorationImage(image: NetworkImage(details.pictureUrl), fit: BoxFit.cover),
//                     borderRadius: BorderRadius.circular(50),
//                   ),
//                 ),
//               );
//             }, error: (e, stack) {
//               return Center(
//                 child: Text(e.toString()),
//               );
//             }, loading: () {
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//             }),
//           ],
//         );
//       },
//     );
//   }
// }
