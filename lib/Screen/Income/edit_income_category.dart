import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/income_catehory_model.dart';

import '../../Provider/expense_category_proivder.dart';
import '../../const.dart';
import '../../model/expense_category_model.dart';
import '../Widgets/Constant Data/constant.dart';

class EditIncomeCategory extends StatefulWidget {
  const EditIncomeCategory(
      {Key? key,
      required this.listOfExpanseCategory,
      required this.incomeCategoryModel,
      required this.menuContext})
      : super(key: key);

  final List<IncomeCategoryModel> listOfExpanseCategory;
  final IncomeCategoryModel incomeCategoryModel;
  final BuildContext menuContext;

  @override
  State<EditIncomeCategory> createState() => _EditIncomeCategoryState();
}

class _EditIncomeCategoryState extends State<EditIncomeCategory> {
  String categoryDescription = '';
  String categoryName = '';

  String expenseKey = '';

  void getExpenseKey() async {
    final userId = await getUserID();
    await FirebaseDatabase.instance
        .ref(userId)
        .child('Income Category')
        .orderByKey()
        .get()
        .then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['categoryName'].toString() ==
            widget.incomeCategoryModel.categoryName) {
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
    categoryDescription = widget.incomeCategoryModel.categoryDescription;
    categoryName = widget.incomeCategoryModel.categoryName;
    getExpenseKey();
  }

  @override
  Widget build(BuildContext context) {
    List<String> names = [];
    for (var element in widget.listOfExpanseCategory) {
      names.add(element.categoryName.removeAllWhiteSpace().toLowerCase());
    }
    return Consumer(
      builder: (context, ref, child) {
        final theme = Theme.of(context);
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
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            lang.S.of(context).entercategoryName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          icon: const Icon(FeatherIcons.x, size: 22.0),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    thickness: 1.0,
                    color: kNeutral300,
                    height: 1,
                  ),
                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      lang.S.of(context).pleaseEnterValidData,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      initialValue: categoryName,
                      onChanged: (value) {
                        categoryName = value;
                      },
                      showCursor: true,
                      cursorColor: kTitleColor,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        labelText: lang.S.of(context).categoryName,
                        hintText: lang.S.of(context).entercategoryName,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      initialValue: categoryDescription,
                      onChanged: (value) {
                        categoryDescription = value;
                      },
                      showCursor: true,
                      cursorColor: kTitleColor,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        labelText: lang.S.of(context).description,
                        hintText: '${lang.S.of(context).addDescription}...',
                      ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => GoRouter.of(context).pop(),
                          child: Text(lang.S.of(context).cancel),
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
                          onPressed: () async {
                            ExpenseCategoryModel expenseCategory =
                                ExpenseCategoryModel(
                                    categoryName: categoryName,
                                    categoryDescription: categoryDescription);
                            if (categoryName != '' &&
                                    categoryName ==
                                        widget.incomeCategoryModel.categoryName
                                ? true
                                : !names.contains(categoryName
                                    .toLowerCase()
                                    .removeAllWhiteSpace())) {
                              setState(() async {
                                try {
                                  EasyLoading.show(
                                      status:
                                          '${lang.S.of(context).loading}...',
                                      dismissOnTap: false);
                                  final DatabaseReference
                                      productInformationRef = FirebaseDatabase
                                          .instance
                                          .ref()
                                          .child(await getUserID())
                                          .child('Income Category')
                                          .child(expenseKey);
                                  await productInformationRef
                                      .set(expenseCategory.toJson());
                                  EasyLoading.showSuccess(
                                      lang.S.of(context).editSuccessfully,
                                      duration:
                                          const Duration(milliseconds: 500));

                                  ///____provider_refresh____________________________________________
                                  // ignore: unused_result
                                  ref.refresh(incomeCategoryProvider);

                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    GoRouter.of(context).pop();
                                    // Navigator.pop(widget.menuContext);
                                  });
                                } catch (e) {
                                  EasyLoading.dismiss();
                                  //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                }
                              });
                            } else if (names.contains(categoryName
                                .toLowerCase()
                                .removeAllWhiteSpace())) {
                              EasyLoading.showError(
                                  lang.S.of(context).categoryNameAlreadyExists);
                            } else {
                              EasyLoading.showError(
                                  lang.S.of(context).enterCategoryName);
                            }
                          },
                          child: Text(lang.S.of(context).cancel),
                        ),
                      ),
                    ),
                  ]),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Container(
                  //       padding: const EdgeInsets.all(10.0),
                  //       decoration: BoxDecoration(
                  //         borderRadius: BorderRadius.circular(5.0),
                  //         color: Colors.red,
                  //       ),
                  //       width: 150,
                  //       child: Column(
                  //         children: [
                  //           Text(
                  //             lang.S.of(context).cancel,
                  //             style: kTextStyle.copyWith(color: kWhite),
                  //           ),
                  //         ],
                  //       ),
                  //     ).onTap(() {
                  //       GoRouter.of(context).pop();
                  //       // Navigator.pop(widget.menuContext);
                  //     }),
                  //     const SizedBox(width: 20),
                  //     Container(
                  //       padding: const EdgeInsets.all(10.0),
                  //       decoration: BoxDecoration(
                  //         borderRadius: BorderRadius.circular(5.0),
                  //         color: kGreenTextColor,
                  //       ),
                  //       width: 150,
                  //       child: Column(
                  //         children: [
                  //           Text(
                  //             lang.S.of(context).saveAndPublished,
                  //             style: kTextStyle.copyWith(color: kWhite),
                  //           ),
                  //         ],
                  //       ),
                  //     ).onTap(() {
                  //       ExpenseCategoryModel expenseCategory = ExpenseCategoryModel(categoryName: categoryName, categoryDescription: categoryDescription);
                  //       if (categoryName != '' && categoryName == widget.incomeCategoryModel.categoryName
                  //           ? true
                  //           : !names.contains(categoryName.toLowerCase().removeAllWhiteSpace())) {
                  //         setState(() async {
                  //           try {
                  //             EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                  //             final DatabaseReference productInformationRef =
                  //                 FirebaseDatabase.instance.ref().child(await getUserID()).child('Income Category').child(expenseKey);
                  //             await productInformationRef.set(expenseCategory.toJson());
                  //             EasyLoading.showSuccess(lang.S.of(context).editSuccessfully, duration: const Duration(milliseconds: 500));
                  //
                  //             ///____provider_refresh____________________________________________
                  //             ref.refresh(incomeCategoryProvider);
                  //
                  //             Future.delayed(const Duration(milliseconds: 100), () {
                  //               GoRouter.of(context).pop();
                  //               // Navigator.pop(widget.menuContext);
                  //             });
                  //           } catch (e) {
                  //             EasyLoading.dismiss();
                  //             //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  //           }
                  //         });
                  //       } else if (names.contains(categoryName.toLowerCase().removeAllWhiteSpace())) {
                  //         EasyLoading.showError(lang.S.of(context).categoryNameAlreadyExists);
                  //       } else {
                  //         EasyLoading.showError(lang.S.of(context).enterCategoryName);
                  //       }
                  //     }),
                  //   ],
                  // ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
