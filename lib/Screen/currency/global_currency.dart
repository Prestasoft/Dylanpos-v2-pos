import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as ri;
import 'package:provider/provider.dart';

import '../../../Screen/Widgets/Constant Data/constant.dart';
import '../../Provider/profile_provider.dart';
import '../../const.dart';
import '../../model/personal_information_model.dart';
import 'currency_list.dart';
import 'currency_provider.dart';

class GlobalCurrency extends StatefulWidget {
  const GlobalCurrency({super.key, required this.isDrawer});
  final bool isDrawer;

  @override
  State<GlobalCurrency> createState() => _GlobalCurrencyState();
}

class _GlobalCurrencyState extends State<GlobalCurrency> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CurrencyProvider>(context, listen: false).getCurrency();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return ri.Consumer(
      builder: (context, ref, watch) {
        ri.AsyncValue<PersonalInformationModel> userProfileDetails = ref.watch(profileDetailsProvider);
        return userProfileDetails.when(data: (data) {
          return SizedBox(
            height: 40,
            width: widget.isDrawer ? 125 : 152,
            child: DropdownButtonFormField<String>(
              dropdownColor: widget.isDrawer == true ? kChartColor : Colors.white,
              alignment: Alignment.center,
              decoration: kInputDecoration.copyWith(
                contentPadding: const EdgeInsets.all(8),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  borderSide: BorderSide(color: kNeutral300, width: 1),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  borderSide: BorderSide(color: kNeutral300, width: 1),
                ),
              ),
              isExpanded: true,
              padding: EdgeInsets.zero,
              value: currencyProvider.dropdownCurrencyValue,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: widget.isDrawer ? Colors.white : const Color(0xFF585865),
              ),
              isDense: true,
              items: currencySymbols.keys.map((String items) {
                return DropdownMenuItem<String>(
                  value: items,
                  child: Text(
                    items,
                    style: kTextStyle.copyWith(color: widget.isDrawer ? Colors.white : kTitleColor, fontSize: 14.0, overflow: TextOverflow.ellipsis),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) async {
                if (newValue != null && currencySymbols.containsKey(newValue)) {
                  String newCurrencySymbol = currencySymbols[newValue]!;
                  await currencyProvider.setCurrency(newCurrencySymbol);
                  final DatabaseReference personalInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Personal Information');
                  await personalInformationRef.update({'currency': newCurrencySymbol});
                  print("Updating currency to: ${currencyProvider.currency}");
                  // Future.delayed(const Duration(milliseconds: 600)).then((value) => context.go('/dashboard'));
                }
              },
            ),
          );
        }, error: (e, stack) {
          return Text(e.toString());
        }, loading: () {
          return CircularProgressIndicator();
        });
      },
    );
  }
}
