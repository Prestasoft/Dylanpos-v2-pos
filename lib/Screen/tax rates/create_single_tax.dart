import 'dart:convert';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Screen/tax%20rates/tax_model.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';

//____________________________________________________AddSingleTax_______________________
class CreateSingleTaxPopUp extends StatefulWidget {
  const CreateSingleTaxPopUp({super.key, required this.listOfTax});

  final List<TaxModel> listOfTax;

  @override
  State<CreateSingleTaxPopUp> createState() => _CreateSingleTaxPopUpState();
}

class _CreateSingleTaxPopUpState extends State<CreateSingleTaxPopUp> {
  String name = '';
  num rate = 0;
  String id = DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    List<String> names = [];
    for (var element in widget.listOfTax) {
      names.add(element.name.removeAllWhiteSpace().toLowerCase());
    }
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //___________________________________Tax Rates______________________________
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      lang.S.of(context).addNewTax,
                      //Add New Tax',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
            ),
            const Divider(
              thickness: 1,
              color: kNeutral300,
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${lang.S.of(context).name}*', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    onChanged: (value) {
                      name = value;
                    },
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: lang.S.of(context).enterName,
                    ),
                    onSaved: (value) {},
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    lang.S.of(context).taxRate,
                    //'Tax rate',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    onChanged: (value) {
                      rate = double.parse(value);
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: lang.S.of(context).enterTaxRate,
                    ),
                    onSaved: (value) {},
                  ),
                  const SizedBox(height: 6.0),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(450, 48)),
                onPressed: () async {
                  if (name != '' && !names.contains(name.toLowerCase().removeAllWhiteSpace())) {
                    TaxModel tax = TaxModel(name: name, taxRate: rate, id: id.toString());
                    try {
                      EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                      final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Tax List');
                      await productInformationRef.push().set(tax.toJson());
                      EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully, duration: const Duration(milliseconds: 500));

                      ///____provider_refresh____________________________________________
                      ref.refresh(taxProvider);

                      Future.delayed(const Duration(milliseconds: 100), () {
                        context.pop();
                      });
                    } catch (e) {
                      EasyLoading.dismiss();
                      //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  } else if (names.contains(name.toLowerCase().removeAllWhiteSpace())) {
                    EasyLoading.showError(lang.S.of(context).alreadyExists);
                  } else {
                    EasyLoading.showError(lang.S.of(context).enterName);
                  }
                },
                child: Text(
                  lang.S.of(context).save,
                  //'Save',
                  style: kTextStyle.copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 6)
          ],
        );
      },
    );
  }
}

//____________________________________________________EditSingleTax_______________________

class EditSingleTaxPopUp extends StatefulWidget {
  const EditSingleTaxPopUp({
    super.key,
    required this.taxList,
    required this.taxModel,
    required this.groupTaxList,
  });

  final List<TaxModel> taxList;
  final List<GroupTaxModel> groupTaxList;
  final TaxModel taxModel;

  @override
  State<EditSingleTaxPopUp> createState() => _EditSingleTaxTaxState();
}

class _EditSingleTaxTaxState extends State<EditSingleTaxPopUp> {
  String name = '';
  num rate = 0;
  String taxKey = '';

  void getTaxKey() async {
    final userId = await getUserID();
    await FirebaseDatabase.instance.ref(userId).child('Tax List').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['name'].toString() == widget.taxModel.name) {
          taxKey = element.key.toString();
        }
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    name = widget.taxModel.name;
    rate = widget.taxModel.taxRate;
    getTaxKey();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    List<String> names = [];
    for (var element in widget.taxList) {
      names.add(element.name.removeAllWhiteSpace().toLowerCase());
    }
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final groupTax = ref.watch(groupTaxProvider);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //___________________________________Tax Rates______________________________
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      lang.S.of(context).editTax,
                      // 'Edit Tax',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: kNeutral300,
            ),

            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${lang.S.of(context).name}*', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    initialValue: name,
                    onChanged: (value) {
                      name = value;
                    },
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: lang.S.of(context).enterName,
                    ),
                    onSaved: (value) {},
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    lang.S.of(context).taxRate,
                    // 'Tax rate',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    initialValue: rate.toString(),
                    onChanged: (value) {
                      rate = double.parse(value);
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: lang.S.of(context).enterTaxRate,
                    ),
                    onSaved: (value) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(450, 48)),
                onPressed: () {
                  TaxModel tax = TaxModel(taxRate: rate, id: widget.taxModel.id, name: name);
                  if (name != '' && name == widget.taxModel.name ? true : !names.contains(name.toLowerCase().removeAllWhiteSpace())) {
                    setState(() async {
                      try {
                        EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                        final DatabaseReference taxInfoRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Tax List').child(taxKey);
                        await taxInfoRef.set(tax.toJson());
                        EasyLoading.showSuccess(lang.S.of(context).editSuccessfully, duration: const Duration(milliseconds: 500));

                        ///____provider_refresh____________________________________________
                        ref.refresh(taxProvider);
                        ref.refresh(groupTaxProvider);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          context.pop();
                        });
                      } catch (e) {
                        EasyLoading.dismiss();
                        //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    });
                  } else if (names.contains(name.toLowerCase().removeAllWhiteSpace())) {
                    EasyLoading.showError(lang.S.of(context).nameAlreadyExists);
                  } else {
                    EasyLoading.showError(lang.S.of(context).nameCantBeEmpty);
                  }
                },
                child: Text(
                  lang.S.of(context).update,
                  // 'Update',
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}

//____________________________________________________EditSingleTax_______________________
