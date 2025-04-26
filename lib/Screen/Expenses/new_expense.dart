// ignore_for_file: unused_result

import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/all_expanse_provider.dart';
import 'package:salespro_admin/Provider/expense_category_proivder.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/expense_model.dart';

import '../../Provider/daily_transaction_provider.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../model/daily_transaction_model.dart';
import '../../model/expense_category_model.dart';
import '../Widgets/Constant Data/constant.dart';

class NewExpense extends StatefulWidget {
  const NewExpense({super.key});

  @override
  State<NewExpense> createState() => _NewExpenseState();
}

class _NewExpenseState extends State<NewExpense> {
  bool saleButtonClicked = false;

  void showCategoryPopUp() {
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: SizedBox(
                width: 600,
                height: context.height() / 2.5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(shape: BoxShape.rectangle),
                            child: const Icon(
                              FeatherIcons.plus,
                              color: kTitleColor,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            lang.S.of(context).addCategory,
                            style: kTextStyle.copyWith(color: kTitleColor, fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const Icon(
                            FeatherIcons.x,
                            color: kTitleColor,
                            size: 50.0,
                          ).onTap(() {
                            finish(context);
                          })
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Divider(
                        thickness: 1.0,
                        color: kGreyTextColor.withOpacity(0.2),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          Text(
                            lang.S.of(context).nam,
                            style: kTextStyle.copyWith(color: kTitleColor, fontSize: 18.0),
                          ),
                          const SizedBox(width: 50),
                          SizedBox(
                            width: 400,
                            child: Expanded(
                              child: AppTextField(
                                showCursor: true,
                                cursorColor: kTitleColor,
                                textFieldType: TextFieldType.NAME,
                                decoration: kInputDecoration.copyWith(
                                  hintText: lang.S.of(context).name,
                                  hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Divider(
                        thickness: 1.0,
                        color: kGreyTextColor.withOpacity(0.2),
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: kRedTextColor),
                            child: Text(
                              lang.S.of(context).cancel,
                              style: kTextStyle.copyWith(color: kWhite),
                            ),
                          ).onTap(() {
                            finish(context);
                          }),
                          const SizedBox(
                            width: 5.0,
                          ),
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: kGreenTextColor),
                            child: Text(
                              lang.S.of(context).submit,
                              style: kTextStyle.copyWith(color: kWhite),
                            ),
                          ).onTap(() {
                            finish(context);
                          })
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  List<String> categories = [];

  List<String> get paymentMethods => [
        // 'Cash',
        lang.S.current.cash,
        //'Bank',
        lang.S.current.bank,
        //'Card',
        lang.S.current.card,
        //'Mobile Payment',
        lang.S.current.mobilePayment,
        //'Snacks',
        lang.S.current.snacks,
      ];

  String? selectedCategories;
  late String selectedPaymentType = paymentMethods.first;

  DropdownButton<String> getCategories() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in categories) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(Icons.keyboard_arrow_down),
      //hint: const Text('Select expense category'),
      hint: Text(lang.S.of(context).selectExpenseCategory),
      items: dropDownItems,
      value: selectedCategories,
      onChanged: (value) {
        setState(() {
          selectedCategories = value!;
        });
      },
    );
  }

  DropdownButton<String> getPaymentMethods() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in paymentMethods) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedPaymentType,
      onChanged: (value) {
        setState(() {
          selectedPaymentType = value!;
        });
      },
    );
  }

  Future<void> category() async {
    await FirebaseDatabase.instance.ref(await getUserID()).child('Expense Category').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = ExpenseCategoryModel.fromJson(jsonDecode(jsonEncode(element.value)));
        categories.add(data.categoryName);
      }
    });
    setState(() {});
  }

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
    category();
  }

  String expenseAmount = '0';
  TextEditingController expanseForNameController = TextEditingController();
  TextEditingController expanseAmountController = TextEditingController();
  TextEditingController expanseNoteController = TextEditingController();
  TextEditingController expanseRefController = TextEditingController();
  ScrollController mainScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(
      builder: (context, ref, child) {
        final expenseCategory = ref.watch(expenseCategoryProvider);

        return Scaffold(
          backgroundColor: kDarkWhite,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              // height: MediaQuery.of(context).size.height - 240,
              // padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text.rich(TextSpan(
                                text: lang.S.of(context).expense,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: lang.S.of(context).addUpdateExpenseList,
                                    style: theme.textTheme.bodyLarge?.copyWith(color: kNeutral500),
                                  )
                                ])),
                          ),

                          IconButton(
                              onPressed: () {
                                GoRouter.of(context).pop();
                              },
                              icon: const Icon(FeatherIcons.x, size: 22.0)),
                          // const Icon(FeatherIcons.x, color: kTitleColor, size: 30.0).onTap(() => Navigator.pop(context))
                        ],
                      ),
                    ),
                    const Divider(
                      thickness: 1.0,
                      color: kNeutral300,
                      height: 1,
                    ),

                    ///______date_&_category____________________________________
                    ResponsiveGridRow(children: [
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              height: 48,
                              child: FormField(
                                builder: (FormFieldState<dynamic> field) {
                                  return InputDecorator(
                                    decoration: InputDecoration(
                                      suffixIcon: const Icon(IconlyLight.calendar, color: kGreyTextColor),
                                      contentPadding: const EdgeInsets.all(8.0),
                                      labelText: lang.S.of(context).expenseDate,
                                      hintText: lang.S.of(context).enterExpenseDate,
                                    ),
                                    child: Text(
                                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  );
                                },
                              ).onTap(() => _selectDate(context)),
                            ),
                          )),
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              height: 48,
                              child: FormField(
                                builder: (FormFieldState<dynamic> field) {
                                  return InputDecorator(
                                    decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.all(8.0),
                                        //labelText: 'Category'
                                        labelText: lang.S.of(context).category),
                                    child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getCategories())),
                                  );
                                },
                              ),
                            ),
                          )),
                    ]),

                    ///________payment Type_&_expanseFor_______________________________
                    ResponsiveGridRow(children: [
                      //-------------expense for----------------------
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              showCursor: true,
                              controller: expanseForNameController,
                              validator: (value) {
                                if (value.isEmptyOrNull) {
                                  // return 'Please Enter Name';
                                  return lang.S.of(context).pleaseEnterName;
                                }
                                return null;
                              },
                              onSaved: (value) {
                                expanseForNameController.text = value!;
                              },
                              cursorColor: kTitleColor,
                              decoration: InputDecoration(
                                labelText: lang.S.of(context).expenseFor,
                                hintText: lang.S.of(context).enterName,
                              ),
                            ),
                          )),
                      //---------------payment type------------------------
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              height: 48,
                              child: FormField(
                                builder: (FormFieldState<dynamic> field) {
                                  return InputDecorator(
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(8.0),
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                      labelText: lang.S.of(context).paymentType,
                                    ),
                                    child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getPaymentMethods())),
                                  );
                                },
                              ),
                            ),
                          )),
                    ]),

                    ///_______amount_reference_number______________________________________
                    ResponsiveGridRow(children: [
                      //------------amount----------------------
                      ResponsiveGridCol(
                          md: 6,
                          xs: 12,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              showCursor: true,
                              controller: expanseAmountController,
                              onChanged: (value) {
                                expenseAmount = value.replaceAll(',', '');
                                var formattedText = myFormat.format(int.parse(expenseAmount));
                                expanseAmountController.value = expanseAmountController.value.copyWith(
                                  text: formattedText,
                                  selection: TextSelection.collapsed(offset: formattedText.length),
                                );
                              },
                              validator: (value) {
                                if (expenseAmount.isEmptyOrNull) {
                                  //return 'please Inter Amount';
                                  return lang.S.of(context).pleaseInterAmount;
                                } else if (double.tryParse(expenseAmount) == null) {
                                  //return 'Enter a valid Amount';
                                  return lang.S.of(context).enterAValidAmount;
                                }
                                return null;
                              },
                              onSaved: (value) {
                                expanseAmountController.text = value!;
                              },
                              cursorColor: kTitleColor,
                              decoration: InputDecoration(
                                labelText: lang.S.of(context).amount,
                                hintText: lang.S.of(context).enterAmount,
                              ),
                            ),
                          )),
                      //---------------reference-----------------------
                      ResponsiveGridCol(
                          md: 6,
                          xs: 12,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              showCursor: true,
                              controller: expanseRefController,
                              validator: (value) {
                                return null;
                              },
                              onSaved: (value) {
                                expanseRefController.text = value!;
                              },
                              cursorColor: kTitleColor,
                              decoration: InputDecoration(
                                labelText: lang.S.of(context).referenceNumber,
                                hintText: lang.S.of(context).enterReferenceNumber,
                              ),
                            ),
                          ))
                    ]),

                    ///_________note____________________________________________________
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        showCursor: true,
                        controller: expanseNoteController,
                        validator: (value) {
                          if (value == null) {
                            //return 'please Inter Amount';
                            return lang.S.of(context).pleaseInterAmount;
                          }
                          return null;
                        },
                        onSaved: (value) {
                          expanseNoteController.text = value!;
                        },
                        cursorColor: kTitleColor,
                        decoration: InputDecoration(
                          labelText: lang.S.of(context).note,
                          hintText: lang.S.of(context).enterNote,
                        ),
                      ),
                    ),

                    ///___________buttons___________________________________________
                    const SizedBox(height: 10.0),
                    ResponsiveGridRow(rowSegments: 100, children: [
                      ResponsiveGridCol(md: screenWidth < 768 ? 15 : 25, xs: 100, lg: 30, child: const SizedBox.shrink()),
                      ResponsiveGridCol(
                        md: screenWidth < 768 ? 35 : 25,
                        xs: 100,
                        lg: 20,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              GoRouter.of(context).pop();
                            },
                            child: Text(
                              lang.S.of(context).cancel,
                            ),
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        md: screenWidth < 768 ? 35 : 25,
                        xs: 100,
                        lg: 20,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ElevatedButton(
                            onPressed: saleButtonClicked
                                ? () {}
                                : () async {
                                    if (validateAndSave() && selectedCategories != null && selectedCategories!.isNotEmpty) {
                                      ExpenseModel expense = ExpenseModel(
                                        expenseDate: selectedDate.toString(),
                                        category: selectedCategories.toString(),
                                        account: '',
                                        amount: expenseAmount,
                                        expanseFor: expanseForNameController.text,
                                        paymentType: selectedPaymentType,
                                        referenceNo: expanseRefController.text,
                                        note: expanseNoteController.text,
                                      );
                                      try {
                                        setState(() {
                                          saleButtonClicked = true;
                                        });
                                        EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                                        final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Expense');
                                        await productInformationRef.push().set(expense.toJson()).then((_) {
                                          EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully, duration: const Duration(milliseconds: 500));

                                          DailyTransactionModel dailyTransaction = DailyTransactionModel(
                                            name: expense.expanseFor,
                                            date: expense.expenseDate,
                                            type: 'Expense',
                                            total: expense.amount.toDouble(),
                                            paymentIn: 0,
                                            paymentOut: expense.amount.toDouble(),
                                            remainingBalance: expense.amount.toDouble(),
                                            id: expense.expenseDate,
                                            expenseModel: expense,
                                          );
                                          postDailyTransaction(dailyTransactionModel: dailyTransaction);

                                          ref.refresh(expenseProvider);
                                          ref.refresh(dailyTransactionProvider);

                                          Future.delayed(const Duration(milliseconds: 100), () {
                                            if (mounted) {
                                              GoRouter.of(context).pop();
                                            }
                                          });
                                        }).catchError((error) {
                                          setState(() {
                                            saleButtonClicked = false;
                                          });
                                          EasyLoading.dismiss();
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                                        });
                                      } catch (e) {
                                        setState(() {
                                          saleButtonClicked = false;
                                        });
                                        EasyLoading.dismiss();
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                      }
                                    } else {
                                      EasyLoading.showInfo(lang.S.of(context).pleaseSelectACategory);
                                    }
                                  },
                            child: Text(
                              lang.S.of(context).saveAndPublish,
                            ),
                          ),
                          // ElevatedButton(
                          //     onPressed: saleButtonClicked
                          //         ? () {}
                          //         : () async {
                          //             if (validateAndSave() && selectedCategories != null && selectedCategories!.isNotEmpty) {
                          //               ExpenseModel expense = ExpenseModel(
                          //                 expenseDate: selectedDate.toString(),
                          //                 category: selectedCategories.toString(),
                          //                 account: '',
                          //                 amount: expenseAmount,
                          //                 expanseFor: expanseForNameController.text,
                          //                 paymentType: selectedPaymentType,
                          //                 referenceNo: expanseRefController.text,
                          //                 note: expanseNoteController.text,
                          //               );
                          //               try {
                          //                 setState(() {
                          //                   saleButtonClicked = true;
                          //                 });
                          //                 EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                          //                 final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Expense');
                          //                 await productInformationRef.push().set(expense.toJson());
                          //                 EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully, duration: const Duration(milliseconds: 500));
                          //
                          //                 ///________daily_transactionModel_________________________________________________________________________
                          //
                          //                 DailyTransactionModel dailyTransaction = DailyTransactionModel(
                          //                   name: expense.expanseFor,
                          //                   date: expense.expenseDate,
                          //                   type: 'Expense',
                          //                   total: expense.amount.toDouble(),
                          //                   paymentIn: 0,
                          //                   paymentOut: expense.amount.toDouble(),
                          //                   remainingBalance: expense.amount.toDouble(),
                          //                   id: expense.expenseDate,
                          //                   expenseModel: expense,
                          //                 );
                          //                 postDailyTransaction(dailyTransactionModel: dailyTransaction);
                          //
                          //                 ///____provider_refresh____________________________________________
                          //                 ref.refresh(expenseProvider);
                          //                 ref.refresh(dailyTransactionProvider);
                          //
                          //                 Future.delayed(const Duration(milliseconds: 100), () {
                          //                   // const Product().launch(context, isNewTask: true);
                          //                   GoRouter.of(context).pop();
                          //                   context.go('/expense');
                          //                   // Navigator.pop(context);
                          //                   // Navigator.of(context).pushReplacementNamed(ExpensesList.route);
                          //                 });
                          //               } catch (e) {
                          //                 setState(() {
                          //                   saleButtonClicked = false;
                          //                 });
                          //                 EasyLoading.dismiss();
                          //                 //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          //               }
                          //             } else {
                          //               //EasyLoading.showInfo('Please select a category');
                          //               EasyLoading.showInfo(lang.S.of(context).pleaseSelectACategory);
                          //             }
                          //           },
                          //     child: Text(
                          //       lang.S.of(context).saveAndPublish,
                          //     )),
                        ),
                      ),
                      ResponsiveGridCol(md: screenWidth < 768 ? 15 : 25, xs: 100, lg: 30, child: const SizedBox.shrink()),
                    ]),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
