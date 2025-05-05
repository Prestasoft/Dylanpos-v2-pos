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
import '../../Provider/expense_category_proivder.dart';
import '../../const.dart';
import '../../model/expense_category_model.dart';
import '../Widgets/Constant Data/constant.dart';

class EditCategory extends StatefulWidget {
  const EditCategory(
      {Key? key,
      required this.listOfExpanseCategory,
      required this.expenseCategoryModel,
      required this.menuContext})
      : super(key: key);

  final List<ExpenseCategoryModel> listOfExpanseCategory;
  final ExpenseCategoryModel expenseCategoryModel;
  final BuildContext menuContext;

  @override
  State<EditCategory> createState() => _EditCategoryState();
}

class _EditCategoryState extends State<EditCategory> {
  String categoryDescription = '';
  String categoryName = '';

  String expenseKey = '';

  void getExpenseKey() async {
    await FirebaseDatabase.instance
        .ref(await getUserID())
        .child('Expense Category')
        .orderByKey()
        .get()
        .then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['categoryName'].toString() ==
            widget.expenseCategoryModel.categoryName) {
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
    categoryDescription = widget.expenseCategoryModel.categoryDescription;
    categoryName = widget.expenseCategoryModel.categoryName;
    getExpenseKey();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<String> names = [];
    for (var element in widget.listOfExpanseCategory) {
      names.add(element.categoryName.removeAllWhiteSpace().toLowerCase());
    }
    return Consumer(
      builder: (context, ref, child) {
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
                            lang.S.of(context).enterExpanseCategory,
                            style: kTextStyle.copyWith(
                                color: kTitleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 21.0),
                          ),
                        ),
                        IconButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          icon: const Icon(FeatherIcons.x, size: 22.0),
                        )
                      ],
                    ),
                  ),
                  const Divider(
                    thickness: 1.0,
                    color: kNeutral300,
                    height: 1,
                  ),

                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.S.of(context).pleaseEnterValidData,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        TextFormField(
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
                        const SizedBox(height: 20.0),
                        TextFormField(
                          initialValue: categoryDescription,
                          onChanged: (value) {
                            categoryDescription = value;
                          },
                          showCursor: true,
                          cursorColor: kTitleColor,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            labelText: lang.S.of(context).description,
                            hintText: lang.S.of(context).addDescription,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
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
                          child: Text(
                            lang.S.of(context).cancel,
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
                            ExpenseCategoryModel expenseCategory =
                                ExpenseCategoryModel(
                                    categoryName: categoryName,
                                    categoryDescription: categoryDescription);
                            if (categoryName != '' &&
                                    categoryName ==
                                        widget.expenseCategoryModel.categoryName
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
                                          .child('Expense Category')
                                          .child(expenseKey);
                                  await productInformationRef
                                      .set(expenseCategory.toJson());
                                  EasyLoading.showSuccess(
                                      lang.S.of(context).editSuccessfully,
                                      duration:
                                          const Duration(milliseconds: 500));

                                  ///____provider_refresh____________________________________________
                                  // ignore: unused_result
                                  ref.refresh(expenseCategoryProvider);

                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    GoRouter.of(context)
                                        .pop(widget.menuContext);
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
                              //EasyLoading.showError('Category Name Already Exists');
                              EasyLoading.showError(
                                  lang.S.of(context).categoryNameAlreadyExists);
                            } else {
                              EasyLoading.showError(
                                  lang.S.of(context).enterCategoryName);
                            }
                          },
                          child: Text(
                            lang.S.of(context).saveAndPublish,
                          ),
                        ),
                      ),
                    ),
                  ]),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     ElevatedButton(
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: Colors.red,
                  //       ),
                  //       onPressed: ()=>GoRouter.of(context).pop(),
                  //       child: Text(
                  //         lang.S.of(context).cancel,
                  //       ),
                  //     ),
                  //     const SizedBox(width: 20),
                  //     ElevatedButton(
                  //       onPressed: (){
                  //         ExpenseCategoryModel expenseCategory = ExpenseCategoryModel(categoryName: categoryName, categoryDescription: categoryDescription);
                  //         if (categoryName != '' && categoryName == widget.expenseCategoryModel.categoryName
                  //             ? true
                  //             : !names.contains(categoryName.toLowerCase().removeAllWhiteSpace())) {
                  //           setState(() async {
                  //             try {
                  //               EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                  //               final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Expense Category').child(expenseKey);
                  //               await productInformationRef.set(expenseCategory.toJson());
                  //               EasyLoading.showSuccess(lang.S.of(context).editSuccessfully, duration: const Duration(milliseconds: 500));
                  //
                  //               ///____provider_refresh____________________________________________
                  //               ref.refresh(expenseCategoryProvider);
                  //
                  //               Future.delayed(const Duration(milliseconds: 100), () {
                  //                 GoRouter.of(context).pop();
                  //                 // Navigator.pop(widget.menuContext);
                  //               });
                  //             } catch (e) {
                  //               EasyLoading.dismiss();
                  //               //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  //             }
                  //           });
                  //         } else if (names.contains(categoryName.toLowerCase().removeAllWhiteSpace())) {
                  //           //EasyLoading.showError('Category Name Already Exists');
                  //           EasyLoading.showError(lang.S.of(context).categoryNameAlreadyExists);
                  //         } else {
                  //           EasyLoading.showError(lang.S.of(context).enterCategoryName);
                  //         }
                  //       },
                  //       child: Column(
                  //         children: [
                  //           Text(
                  //             lang.S.of(context).saveAndPublish,
                  //             style: kTextStyle.copyWith(color: kWhite),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
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
