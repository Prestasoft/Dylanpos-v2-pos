// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:nb_utils/nb_utils.dart';
// import '../Provider/profile_provider.dart';
// import '../Screen/Widgets/Constant Data/constant.dart';
// import '../const.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart' as ri;
//
// import 'Screen/Home/home_screen.dart';
// import 'currency.dart';
// import 'model/personal_information_model.dart';
//
// class GlobalCurrency extends StatefulWidget {
//   const GlobalCurrency({super.key, required this.isDrawer});
//   final bool isDrawer;
//
//   @override
//   State<GlobalCurrency> createState() => _GlobalCurrencyState();
// }
//
// class _GlobalCurrencyState extends State<GlobalCurrency> {
//   String? dropdownCurrencyValue = '\$ (US Dollar)';
//   // String currency = '\$ (US Dollar)';
//
//   @override
//   void initState() {
//     super.initState();
//     setState(() {});
//     getCurrency();
//   }
//
//   Future<void> getCurrency() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? data = prefs.getString('currency');
//
//     if (data != null && data.isNotEmpty) {
//       for (var element in currencySymbols.keys) {
//         if (element.substring(0, 2).contains(data) || element.substring(0, 5).contains(data)) {
//           setState(() {
//             currency = data;
//             dropdownCurrencyValue = element;
//           });
//           break;
//         }
//       }
//     } else {
//       setState(() {
//         dropdownCurrencyValue = currencySymbols.keys.first[0];
//       });
//     }
//   }
//
//   Future<void> setCurrency(String currency) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('currency', currency);
//     await getCurrency(); // Refresh the currency state
//   }
//
//   final Map<String, String> currencySymbols = {
//     '\$ (US Dollar)': '\$',
//     "₹ (Rupee)": "₹",
//     "€ (Euro)": "€",
//     "₽ (Ruble)": "₽",
//     "£ (UK Pound)": "£",
//     '৳ (Taka)': '৳',
//     "R (Rial)": "R",
//     "؋ (Afghani)": "؋",
//     "Lek (Lek)": "Lek",
//     "د.ج (Algerian Dinar)": "د.ج",
//     "Kz (Kwanza)": "Kz",
//     "EC\$ (East Caribbean Dollar)": "EC\$",
//     "\$ (Argentine Peso)": "\$",
//     "֏ (Armenian Dram)": "֏",
//     "A\$ (Australian Dollar)": "A\$",
//     "₼ (Azerbaijani Manat)": "₼",
//     "B\$ (Bahamian Dollar)": "B\$",
//     ".د.ب (Bahraini Dinar)": ".د.ب",
//     "৳ (Bangladeshi Taka)": "৳",
//     "Bds\$ (Barbadian Dollar)": "Bds\$",
//     "Br (Belarusian Ruble)": "Br",
//     "BZ\$ (Belize Dollar)": "BZ\$",
//     "CFA (West African CFA franc)": "CFA",
//     "FCFA (West African franc)": "FCFA",
//     "Nu. (Bhutanese Ngultrum)": "Nu.",
//     "Bs. (Bolivian Boliviano)": "Bs.",
//     "KM (Bosnia and Herzegovina Convertible Mark)": "KM",
//     "P (Botswana Pula)": "P",
//     "R\$ (Brazilian Real)": "R\$",
//     "B\$ (Brunei Dollar)": "B\$",
//     "лв (Bulgarian Lev)": "лв",
//     "FBu (Burundian Franc)": "FBu",
//     "Esc (Cape Verdean Escudo)": "Esc",
//     "៛ (Cambodian Riel)": "៛",
//     "CFA F (Central African CFA franc)": "CFA F",
//     "CA\$ (Canadian Dollar)": "CA\$",
//     "\$ (Chilean Peso)": "\$",
//     "¥ (Chinese Yuan)": "¥",
//     "\$ (Colombian Peso)": "\$",
//     "CF (Comorian Franc)": "CF",
//     "FC (Congolese Franc)": "FC",
//     "₡ (Costa Rican Colón)": "₡",
//     "kn (Croatian Kuna)": "kn",
//     "CUP (Cuban Peso)": "CUP",
//     "Kč (Czech Koruna)": "Kč",
//     "kr (Danish Krone)": "kr",
//     "Fdj (Djiboutian Franc)": "Fdj",
//     "RD\$ (Dominican Peso)": "RD\$",
//     "US\$ (United States Dollar)": "US\$",
//     "\$ (United States Dollar)": "\$",
//     "E£ (Egyptian Pound)": "E£",
//     "Nfk (Eritrean Nakfa)": "Nfk",
//     "E (Swazi Lilangeni)": "E",
//     "Br (Ethiopian Birr)": "Br",
//     "FJ\$ (Fijian Dollar)": "FJ\$",
//     "D (Gambian Dalasi)": "D",
//     "₾ (Georgian Lari)": "₾",
//     "GH₵ (Ghanaian Cedi)": "GH₵",
//     "Q (Guatemalan Quetzal)": "Q",
//     "GNF (Guinean Franc)": "GNF",
//     "GY\$ (Guyanese Dollar)": "GY\$",
//     "G (Haitian Gourde)": "G",
//     "L (Honduran Lempira)": "L",
//     "Ft (Hungarian Forint)": "Ft",
//     "kr (Icelandic Króna)": "kr",
//     "₹ (Indian Rupee)": "₹",
//     "Rp (Indonesian Rupiah)": "Rp",
//     "﷼ (Iranian Rial)": "﷼",
//     "ع.د (Iraqi Dinar)": "ع.د",
//     "₪ (Israeli New Shekel)": "₪",
//     "J\$ (Jamaican Dollar)": "J\$",
//     "¥ (Japanese Yen)": "¥",
//     "د.ا (Jordanian Dinar)": "د.ا",
//     "₸ (Kazakhstani Tenge)": "₸",
//     "KSh (Kenyan Shilling)": "KSh",
//     "AU\$ (Australian Dollar)": "AU\$",
//     "د.ك (Kuwaiti Dinar)": "د.ك",
//     "som (Kyrgyzstani Som)": "som",
//     "₭ (Laotian Kip)": "₭",
//     "ل.ل (Lebanese Pound)": "ل.ل",
//     "L (Lesotho Loti)": "L",
//     "L\$ (Liberian Dollar)": "L\$",
//     "ل.د (Libyan Dinar)": "ل.د",
//     "CHF (Swiss Franc)": "CHF",
//     "Ar (Malagasy Ariary)": "Ar",
//     "MK (Malawian Kwacha)": "MK",
//     "RM (Malaysian Ringgit)": "RM",
//     "Rf (Maldivian Rufiyaa)": "Rf",
//     "Ouguiya (Mauritanian Ouguiya)": "Ouguiya",
//     "Rs (Mauritian Rupee)": "Rs",
//     "Mex\$ (Mexican Peso)": "Mex\$",
//     "lei (Moldovan Leu)": "lei",
//     "₮ (Mongolian Tugrik)": "₮",
//     "د.م. (Moroccan Dirham)": "د.م.",
//     "MT (Mozambican Metical)": "MT",
//     "K (Myanmar Kyat)": "K",
//     "N\$ (Namibian Dollar)": "N\$",
//     "रू (Nepalese Rupee)": "रू",
//     "NZ\$ (New Zealand Dollar)": "NZ\$",
//     "C\$ (Nicaraguan Córdoba)": "C\$",
//     "₦ (Nigerian Naira)": "₦",
//     "kr (Norwegian Krone)": "kr",
//     "﷼ (Omani Rial)": "﷼",
//     "PKR (Pakistani Rupee)": "PKR",
//     "₱ (Philippine Peso)": "₱",
//     "zł (Polish Złoty)": "zł",
//     "﷼ (Qatari Riyal)": "﷼",
//     "lei (Romanian Leu)": "lei",
//     "руб (Russian Ruble)": "руб",
//     "RF (Rwandan Franc)": "RF",
//     "₣ (Swiss Franc)": "₣",
//     "₲ (Paraguayan Guarani)": "₲",
//     "SR (Saudi Riyal)": "SR",
//     "د.س (Sudanese Pound)": "د.س",
//     "\$ (Singapore Dollar)": "\$",
//     "S (Solomon Islands Dollar)": "S",
//     "Sh (Somali Shilling)": "Sh",
//     "R (South African Rand)": "R",
//     "₩ (South Korean Won)": "₩",
//     "£ (British Pound)": "£",
//     "\$ (Sri Lankan Rupee)": "\$",
//     "L (Saint Helenian Pound)": "L",
//     "\$ (East Caribbean Dollar)": "\$",
//     "kr (Swedish Krona)": "kr",
//     "TJS (Tajikistani Somoni)": "TJS",
//     "TSh (Tanzanian Shilling)": "TSh",
//     "฿ (Thai Baht)": "฿",
//     "T (Tongan Paʻanga)": "T",
//     "TTD (Trinidad and Tobago Dollar)": "TTD",
//     "XAf (XAf Central Africa)": "XAf",
//   };
//
//   @override
//   Widget build(BuildContext context) {
//     return ri.Consumer(
//       builder: (context, ref, __) {
//         AsyncValue<PersonalInformationModel> userProfileDetails = ref.watch(profileDetailsProvider);
//         return userProfileDetails.when(data: (details) {
//           setCurrency(details.currency);
//           return SizedBox(
//             height: 40,
//             width: widget.isDrawer ? 125 : 152,
//             child: DropdownButtonFormField(
//               dropdownColor: Colors.white,
//               alignment: Alignment.center,
//               decoration: kInputDecoration.copyWith(
//                 contentPadding: const EdgeInsets.all(8),
//                 enabledBorder: const OutlineInputBorder(
//                   borderRadius: BorderRadius.all(Radius.circular(30.0)),
//                   borderSide: BorderSide(color: kNeutral400, width: 1),
//                 ),
//                 focusedBorder: const OutlineInputBorder(
//                   borderRadius: BorderRadius.all(Radius.circular(30.0)),
//                   borderSide: BorderSide(color: kNeutral400, width: 1),
//                 ),
//               ),
//               isExpanded: true,
//               padding: EdgeInsets.zero,
//               value: dropdownCurrencyValue,
//               icon: Icon(
//                 Icons.keyboard_arrow_down_rounded,
//                 color: widget.isDrawer ? Colors.white : const Color(0xFF585865),
//               ),
//               isDense: true,
//               items: currencySymbols.keys.map((String items) {
//                 return DropdownMenuItem(
//                   value: items,
//                   child: Text(
//                     items,
//                     style: kTextStyle.copyWith(color: widget.isDrawer ? Colors.white : kTitleColor, fontSize: 14.0, overflow: TextOverflow.ellipsis),
//                   ),
//                 );
//               }).toList(),
//               onChanged: (String? newValue) async {
//                 if (newValue != null && currencySymbols.containsKey(newValue)) {
//                   String newCurrencySymbol = currencySymbols[newValue]!;
//
//                   setState(() {
//                     dropdownCurrencyValue = newValue;
//                     currency = newCurrencySymbol;
//                   });
//
//                   final prefs = await SharedPreferences.getInstance();
//                   await prefs.setString('currency', newCurrencySymbol);
//
//                   final DatabaseReference personalInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Personal Information');
//                   await personalInformationRef.update({'currency': newCurrencySymbol});
//
//                   ref.invalidate(profileDetailsProvider);
//                   print("Updating currency to: $globalCurrency");
//                   Future.delayed(const Duration(milliseconds: 600)).then((value) => context.go('/dashboard'));
//                 }
//               },
//             ),
//           );
//         }, error: (error, stack) {
//           return Text(error.toString());
//         }, loading: () {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         });
//       },
//     );
//   }
// }
