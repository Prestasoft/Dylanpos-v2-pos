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
import 'package:salespro_admin/Provider/daily_transaction_provider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/income_modle.dart';

import '../../Provider/income_provider.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../model/daily_transaction_model.dart';
import '../../model/expense_category_model.dart';
import '../Widgets/Constant Data/constant.dart';
import 'income_list.dart';

class NewIncome extends StatefulWidget {
  const NewIncome({super.key});

  static const String route = '/IncomeList/NewIncome';

  @override
  State<NewIncome> createState() => _NewIncomeState();
}

class _NewIncomeState extends State<NewIncome> {
  bool saveButtonClicked = false;

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
                            decoration:
                                const BoxDecoration(shape: BoxShape.rectangle),
                            child: const Icon(
                              FeatherIcons.plus,
                              color: kTitleColor,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            lang.S.of(context).addCategory,
                            style: kTextStyle.copyWith(
                                color: kTitleColor,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold),
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
                            style: kTextStyle.copyWith(
                                color: kTitleColor, fontSize: 18.0),
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
                                  hintStyle: kTextStyle.copyWith(
                                      color: kGreyTextColor),
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
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: kRedTextColor),
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
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: kGreenTextColor),
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
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  List<String> categories = [];

  List<String> get paymentMethods => [
        //'Cash',
        lang.S.current.cash,
        //'Bank',
        lang.S.current.bank,
        //'Card',
        lang.S.current.card,
        // 'Mobile Payment',
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
      hint: Text(
        lang.S.of(context).selectCategory,
        // 'Select category',
        style: kTextStyle.copyWith(color: kTitleColor),
      ),
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
    final userId = await getUserID();

    await FirebaseDatabase.instance
        .ref(userId)
        .child('Income Category')
        .orderByKey()
        .get()
        .then((value) {
      for (var element in value.children) {
        var data = ExpenseCategoryModel.fromJson(
            jsonDecode(jsonEncode(element.value)));
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

  String incomeText = '0';
  TextEditingController incomeForNameController = TextEditingController();
  TextEditingController incomeAmountController = TextEditingController();
  TextEditingController incomeNoteController = TextEditingController();
  TextEditingController incomeRefController = TextEditingController();
  ScrollController mainScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          backgroundColor: kDarkWhite,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0), color: kWhite),
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
                                text: '${lang.S.of(context).income} ',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        lang.S.of(context).addUpdateIncomeList,
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(color: kNeutral500),
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
                    const SizedBox(height: 8),
                    ResponsiveGridRow(children: [
                      ///__________date_picker________________________________
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
                                    suffixIcon: const Icon(IconlyLight.calendar,
                                        color: kGreyTextColor),
                                    contentPadding: const EdgeInsets.all(8.0),
                                    labelText: lang.S.of(context).incomeDate,
                                    hintText:
                                        lang.S.of(context).enterIncomeDate,
                                  ),
                                  child: Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                );
                              },
                            ).onTap(() => _selectDate(context)),
                          ),
                        ),
                      ),

                      ///_____category___________________________________________
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
                                      labelText: lang.S.of(context).category),
                                  child: Theme(
                                      data: ThemeData(
                                          highlightColor: dropdownItemColor,
                                          focusColor: dropdownItemColor,
                                          hoverColor: dropdownItemColor),
                                      child: DropdownButtonHideUnderline(
                                          child: getCategories())),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ]),
                    ResponsiveGridRow(children: [
                      ///___________________Expanse for_______________________________
                      ResponsiveGridCol(
                        xs: 12,
                        md: 6,
                        lg: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            showCursor: true,
                            controller: incomeForNameController,
                            validator: (value) {
                              if (value.isEmptyOrNull) {
                                //return 'Please Enter Name';
                                return lang.S.of(context).pleaseEnterName;
                              }
                              return null;
                            },
                            onSaved: (value) {
                              incomeForNameController.text = value!;
                            },
                            cursorColor: kTitleColor,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).incomeFor,
                              hintText: lang.S.of(context).enterName,
                            ),
                          ),
                        ),
                      ),

                      ///________PaymentType__________________________________
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
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      labelText:
                                          lang.S.of(context).paymentType),
                                  child: Theme(
                                    data: ThemeData(
                                        highlightColor: dropdownItemColor,
                                        focusColor: dropdownItemColor,
                                        hoverColor: dropdownItemColor),
                                    child: DropdownButtonHideUnderline(
                                      child: getPaymentMethods(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ]),

                    ///_______amount_reference_number______________________________________
                    ResponsiveGridRow(children: [
                      ///_________________Amount_____________________________
                      ResponsiveGridCol(
                        md: 6,
                        lg: 6,
                        xs: 12,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            showCursor: true,
                            controller: incomeAmountController,
                            onChanged: (value) {
                              incomeText = value.replaceAll(',', '');
                              var formattedText =
                                  myFormat.format(int.parse(incomeText));
                              incomeAmountController.value =
                                  incomeAmountController.value.copyWith(
                                text: formattedText,
                                selection: TextSelection.collapsed(
                                    offset: formattedText.length),
                              );
                            },
                            validator: (value) {
                              if (incomeText.isEmptyOrNull) {
                                //return 'please Inter Amount';
                                return lang.S.of(context).pleaseInterAmount;
                              } else if (double.tryParse(incomeText) == null) {
                                //return 'Enter a valid Amount';
                                return lang.S.of(context).enterAValidAmount;
                              }
                              return null;
                            },
                            onSaved: (value) {
                              incomeAmountController.text = value!;
                            },
                            cursorColor: kTitleColor,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).amount,
                              hintText: lang.S.of(context).enterAmount,
                            ),
                          ),
                        ),
                      ),

                      ///_______reference_________________________________
                      ResponsiveGridCol(
                        md: 6,
                        lg: 6,
                        xs: 12,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            showCursor: true,
                            controller: incomeRefController,
                            validator: (value) {
                              return null;
                            },
                            onSaved: (value) {
                              incomeRefController.text = value!;
                            },
                            cursorColor: kTitleColor,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).referenceNumber,
                              hintText: lang.S.of(context).enterReferenceNumber,
                            ),
                          ),
                        ),
                      ),
                    ]),

                    ///_________note____________________________________________________
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        showCursor: true,
                        controller: incomeNoteController,
                        validator: (value) {
                          if (value == null) {
                            // return 'please Enter Amount';
                            return lang.S.of(context).pleaseEnterAmount;
                          }
                          return null;
                        },
                        onSaved: (value) {
                          incomeNoteController.text = value!;
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
                      ResponsiveGridCol(
                          md: screenWidth < 768 ? 15 : 25,
                          xs: 100,
                          lg: 30,
                          child: const SizedBox.shrink()),
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
                              onPressed: saveButtonClicked
                                  ? () async {}
                                  : () async {
                                      if (validateAndSave() &&
                                          selectedCategories != null &&
                                          selectedCategories!.isNotEmpty) {
                                        IncomeModel income = IncomeModel(
                                          incomeDate: selectedDate.toString(),
                                          category:
                                              selectedCategories.toString(),
                                          account: '',
                                          amount: incomeText,
                                          incomeFor:
                                              incomeForNameController.text,
                                          paymentType: selectedPaymentType,
                                          referenceNo: incomeRefController.text,
                                          note: incomeNoteController.text,
                                        );
                                        try {
                                          setState(() {
                                            saveButtonClicked = true;
                                          });
                                          EasyLoading.show(
                                              status:
                                                  '${lang.S.of(context).loading}...',
                                              dismissOnTap: false);
                                          final DatabaseReference
                                              productInformationRef =
                                              FirebaseDatabase.instance
                                                  .ref()
                                                  .child(await getUserID())
                                                  .child('Income');
                                          await productInformationRef
                                              .push()
                                              .set(income.toJson());

                                          ///________daily_transactionModel_________________________________________________________________________

                                          DailyTransactionModel
                                              dailyTransaction =
                                              DailyTransactionModel(
                                            name: income.incomeFor,
                                            date: income.incomeDate,
                                            type: 'Income',
                                            total: income.amount.toDouble(),
                                            paymentIn: income.amount.toDouble(),
                                            paymentOut: 0,
                                            remainingBalance:
                                                income.amount.toDouble(),
                                            id: income.incomeDate,
                                            incomeModel: income,
                                          );
                                          postDailyTransaction(
                                              dailyTransactionModel:
                                                  dailyTransaction);

                                          ///____provider_refresh____________________________________________
                                          // ignore: unused_result
                                          ref.refresh(incomeProvider);
                                          // ignore: unused_result
                                          ref.refresh(dailyTransactionProvider);
                                          EasyLoading.showSuccess(
                                              lang.S
                                                  .of(context)
                                                  .addedSuccessfully,
                                              duration: const Duration(
                                                  milliseconds: 500));

                                          Future.delayed(
                                              const Duration(milliseconds: 100),
                                              () {
                                            // Navigator.pop(context);
                                            // Navigator.of(context).pushReplacementNamed(IncomeList.route);
                                            context.go(IncomeList.route);
                                          });
                                        } catch (e) {
                                          setState(() {
                                            saveButtonClicked = false;
                                          });
                                          EasyLoading.dismiss();
                                          //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                        }
                                      } else {
                                        // EasyLoading.showInfo('Please select a category');
                                        EasyLoading.showInfo(lang.S
                                            .of(context)
                                            .pleaseSelectACategory);
                                      }
                                    },
                              child: Text(
                                lang.S.of(context).saveAndPublish,
                              )),
                        ),
                      ),
                      ResponsiveGridCol(
                          md: screenWidth < 768 ? 15 : 25,
                          xs: 100,
                          lg: 30,
                          child: const SizedBox.shrink()),
                    ]),
                    // Row(
                    //   mainAxisSize: MainAxisSize.max,
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     ///_______cancel__________________________________________________
                    //
                    //     GestureDetector(
                    //       onTap: () {
                    //         Navigator.pop(context);
                    //       },
                    //       child: Container(
                    //         width: 120,
                    //         padding: const EdgeInsets.all(10.0),
                    //         decoration: BoxDecoration(
                    //           borderRadius: BorderRadius.circular(5.0),
                    //           color: Colors.red,
                    //         ),
                    //         child: Center(
                    //           child: Text(
                    //             lang.S.of(context).cancel,
                    //             style: kTextStyle.copyWith(color: kWhite),
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 20),
                    //
                    //     ///________save__________________________________________________
                    //     Container(
                    //       width: 120,
                    //       padding: const EdgeInsets.all(10.0),
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(5.0),
                    //         color: kGreenTextColor,
                    //       ),
                    //       child: Center(
                    //         child: Text(
                    //           lang.S.of(context).saveAndPublish,
                    //           style: kTextStyle.copyWith(color: kWhite),
                    //         ),
                    //       ),
                    //     ).onTap(
                    //       saveButtonClicked
                    //           ? () async {}
                    //           : () async {
                    //               if (validateAndSave() && selectedCategories != null && selectedCategories!.isNotEmpty) {
                    //                 IncomeModel income = IncomeModel(
                    //                   incomeDate: selectedDate.toString(),
                    //                   category: selectedCategories.toString(),
                    //                   account: '',
                    //                   amount: incomeText,
                    //                   incomeFor: incomeForNameController.text,
                    //                   paymentType: selectedPaymentType,
                    //                   referenceNo: incomeRefController.text,
                    //                   note: incomeNoteController.text,
                    //                 );
                    //                 try {
                    //                   setState(() {
                    //                     saveButtonClicked = true;
                    //                   });
                    //                   EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                    //                   final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Income');
                    //                   await productInformationRef.push().set(income.toJson());
                    //
                    //                   ///________daily_transactionModel_________________________________________________________________________
                    //
                    //                   DailyTransactionModel dailyTransaction = DailyTransactionModel(
                    //                     name: income.incomeFor,
                    //                     date: income.incomeDate,
                    //                     type: 'Income',
                    //                     total: income.amount.toDouble(),
                    //                     paymentIn: income.amount.toDouble(),
                    //                     paymentOut: 0,
                    //                     remainingBalance: income.amount.toDouble(),
                    //                     id: income.incomeDate,
                    //                     incomeModel: income,
                    //                   );
                    //                   postDailyTransaction(dailyTransactionModel: dailyTransaction);
                    //
                    //                   ///____provider_refresh____________________________________________
                    //                   ref.refresh(incomeProvider);
                    //                   ref.refresh(dailyTransactionProvider);
                    //                   EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully, duration: const Duration(milliseconds: 500));
                    //
                    //                   Future.delayed(const Duration(milliseconds: 100), () {
                    //                     Navigator.pop(context);
                    //                     Navigator.of(context).pushReplacementNamed(IncomeList.route);
                    //                   });
                    //                 } catch (e) {
                    //                   setState(() {
                    //                     saveButtonClicked = false;
                    //                   });
                    //                   EasyLoading.dismiss();
                    //                   //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    //                 }
                    //               } else {
                    //                 // EasyLoading.showInfo('Please select a category');
                    //                 EasyLoading.showInfo(lang.S.of(context).pleaseSelectACategory);
                    //               }
                    //             },
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 20.0),
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
