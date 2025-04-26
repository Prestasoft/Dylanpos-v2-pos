import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/WareHouse/warehouse_model.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';

class EditWarehouse extends StatefulWidget {
  const EditWarehouse({Key? key, required this.listOfWarehouse, required this.warehouseModel, required this.menuContext}) : super(key: key);

  final List<WareHouseModel> listOfWarehouse;
  final WareHouseModel warehouseModel;
  final BuildContext menuContext;

  @override
  State<EditWarehouse> createState() => _EditWarehouseState();
}

class _EditWarehouseState extends State<EditWarehouse> {
  String warehouseAddress = '';
  String houseName = '';

  String expenseKey = '';

  void getExpenseKey() async {
    final userId = await getUserID();
    await FirebaseDatabase.instance.ref(userId).child('Warehouse List').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['warehouseName'].toString() == widget.warehouseModel.warehouseName) {
          expenseKey = element.key.toString();
        }
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
    warehouseAddress = widget.warehouseModel.warehouseAddress;
    houseName = widget.warehouseModel.warehouseName;
    getExpenseKey();
  }

  @override
  Widget build(BuildContext context) {
    List<String> names = [];
    for (var element in widget.listOfWarehouse) {
      names.add(element.warehouseName.removeAllWhiteSpace().toLowerCase());
    }
    return Consumer(
      builder: (context, ref, child) {
        final theme = Theme.of(context);
        final screenWidth = MediaQuery.of(context).size.width;
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            color: kWhite,
          ),
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            lang.S.of(context).entercategoryName,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: IconButton(
                            onPressed: () {
                              GoRouter.of(context).pop();
                            },
                            icon: const Icon(
                              FeatherIcons.x,
                              color: kTitleColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    thickness: 1.0,
                    color: kGreyTextColor.withValues(alpha: 0.2),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.S.of(context).pleaseEnterValidData,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          initialValue: houseName,
                          onChanged: (value) {
                            houseName = value;
                          },
                          showCursor: true,
                          cursorColor: kTitleColor,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            labelText: lang.S.of(context).categoryName,
                            hintText: lang.S.of(context).entercategoryName,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          initialValue: warehouseAddress,
                          onChanged: (value) {
                            warehouseAddress = value;
                          },
                          showCursor: true,
                          cursorColor: kTitleColor,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            labelText: lang.S.of(context).description,
                            hintText: '${lang.S.of(context).addDescription}...',
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveGridRow(children: [
                    ResponsiveGridCol(
                      xs: 12,
                      md: 6,
                      lg: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ElevatedButton(
                          onPressed: () {
                            GoRouter.of(context).pop();
                            // Navigator.pop(widget.menuContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Column(
                            children: [
                              Text(
                                lang.S.of(context).cancel,
                                style: kTextStyle.copyWith(color: kWhite),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ResponsiveGridCol(
                      xs: 12,
                      md: 6,
                      lg: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ElevatedButton(
                          onPressed: () {
                            WareHouseModel warehouse = WareHouseModel(warehouseName: houseName, warehouseAddress: warehouseAddress, id: widget.warehouseModel.id);
                            if (houseName != '' && houseName == widget.warehouseModel.warehouseName ? true : !names.contains(houseName.toLowerCase().removeAllWhiteSpace())) {
                              setState(() async {
                                try {
                                  EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                                  final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Warehouse List').child(expenseKey);
                                  await productInformationRef.set(warehouse.toJson());
                                  EasyLoading.showSuccess(lang.S.of(context).editSuccessfully, duration: const Duration(milliseconds: 500));

                                  ///____provider_refresh____________________________________________
                                  ref.refresh(warehouseProvider);

                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    GoRouter.of(context).pop();
                                    // Navigator.pop(widget.menuContext);
                                  });
                                } catch (e) {
                                  EasyLoading.dismiss();
                                  //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                }
                              });
                            } else if (names.contains(houseName.toLowerCase().removeAllWhiteSpace())) {
                              // EasyLoading.showError('Warehouse  Already Exists');
                              EasyLoading.showError(lang.S.of(context).warehouseAlreadyExists);
                            } else {
                              //EasyLoading.showError('Name can\'t be empty');
                              EasyLoading.showError(lang.S.of(context).nameCantBeEmpty);
                            }
                          },
                          child: Column(
                            children: [
                              Text(
                                lang.S.of(context).saveAndPublished,
                                style: kTextStyle.copyWith(color: kWhite),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
