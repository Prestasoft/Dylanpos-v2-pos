import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/all_expanse_provider.dart';
import 'package:salespro_admin/Provider/expense_category_proivder.dart';
import 'package:salespro_admin/Screen/Expenses/add_category.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import '../../const.dart';
import '../../model/expense_category_model.dart';
import '../../model/expense_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import 'edit_category.dart';

class ExpenseCategory extends StatefulWidget {
  const ExpenseCategory({Key? key}) : super(key: key);

  @override
  State<ExpenseCategory> createState() => _ExpenseCategoryState();
}

class _ExpenseCategoryState extends State<ExpenseCategory> {
  List<int> item = [
    10,
    20,
    30,
    50,
    80,
    100,
  ];
  int selectedItem = 10;
  int itemCount = 10;

  DropdownButton<int> selectItem() {
    List<DropdownMenuItem<int>> dropDownItems = [];
    for (int des in item) {
      var item = DropdownMenuItem(
        value: des,
        child: Text('${des.toString()} items'),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedItem,
      onChanged: (value) {
        setState(() {
          selectedItem = value!;
          itemCount = value;
        });
      },
    );
  }

  String searchItem = '';

  bool checkAnyExpense(
      {required List<ExpenseModel> allList, required String category}) {
    for (var element in allList) {
      if (element.category == category) {
        return false;
      }
    }
    return true;
  }

  void deleteExpenseCategory(
      {required String expenseCategoryName,
      required WidgetRef updateRef,
      required BuildContext context}) async {
    EasyLoading.show(status: 'Deleting..');
    String expenseKey = '';
    await FirebaseDatabase.instance
        .ref(await getUserID())
        .child('Expense Category')
        .orderByKey()
        .get()
        .then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['categoryName'].toString() == expenseCategoryName) {
          expenseKey = element.key.toString();
        }
      }
    });
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("${await getUserID()}/Expense Category/$expenseKey");
    await ref.remove();
    // ignore: unused_result
    updateRef.refresh(expenseCategoryProvider);
    // ignore: use_build_context_synchronously
    GoRouter.of(context).pop();

    EasyLoading.showSuccess('Done');
  }

  final _horizontalScroll = ScrollController();
  int _expenseCategoryPage = 10; // Default number of items to display
  int _currentPage = 1;

  ScrollController mainScroll = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Consumer(
        builder: (context, ref, child) {
          final allExpenseCategory = ref.watch(expenseCategoryProvider);
          final allExpense = ref.watch(expenseProvider);
          return Scaffold(
            backgroundColor: kDarkWhite,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //_______________________________top_bar____________________________
                  // const TopBar(),
                  allExpenseCategory.when(data: (allExpensesCategory) {
                    List<ExpenseCategoryModel> reverseAllExpenseCategory =
                        allExpensesCategory.reversed.toList();
                    List<ExpenseCategoryModel> showExpenseCategory = [];
                    for (var element in reverseAllExpenseCategory) {
                      if (searchItem != '' &&
                          (element.categoryName.contains(searchItem))) {
                        showExpenseCategory.add(element);
                      } else if (searchItem == '') {
                        showExpenseCategory.add(element);
                      }
                    }
                    final totalPages =
                        (showExpenseCategory.length / _expenseCategoryPage)
                            .ceil();
                    final startIndex =
                        (_currentPage - 1) * _expenseCategoryPage;
                    final endIndex = startIndex + _expenseCategoryPage;
                    final paginatedList = showExpenseCategory.sublist(
                      startIndex,
                      endIndex > showExpenseCategory.length
                          ? showExpenseCategory.length
                          : endIndex,
                    );
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            color: kWhite),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).expensecategoryList,
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: () => showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return StatefulBuilder(
                                          builder: (context, setStates) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                              ),
                                              child: AddCategory(
                                                  listOfExpanseCategory:
                                                      allExpensesCategory),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    icon: const Icon(FeatherIcons.plus,
                                        color: kWhite, size: 18.0),
                                    label: Text(
                                      lang.S.of(context).addCategory,
                                      style: kTextStyle.copyWith(color: kWhite),
                                    ),
                                  ).onTap(
                                    () => showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return StatefulBuilder(
                                          builder: (context, setStates) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                              ),
                                              child: AddCategory(
                                                  listOfExpanseCategory:
                                                      allExpensesCategory),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              thickness: 1.0,
                              color: kNeutral300,
                              height: 1,
                            ),

                            ///___________search________________________________________________-
                            ResponsiveGridRow(rowSegments: 100, children: [
                              ResponsiveGridCol(
                                xs: screenWidth < 360
                                    ? 50
                                    : screenWidth > 430
                                        ? 33
                                        : 40,
                                md: screenWidth < 768
                                    ? 24
                                    : screenWidth < 950
                                        ? 20
                                        : 15,
                                lg: screenWidth < 1700 ? 15 : 10,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 48,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(color: kNeutral300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                            child: Text(
                                          'Show-',
                                          style: theme.textTheme.bodyLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                        DropdownButton<int>(
                                          isDense: true,
                                          padding: EdgeInsets.zero,
                                          underline: const SizedBox(),
                                          value: _expenseCategoryPage,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.black,
                                          ),
                                          items: [10, 20, 50, 100, -1]
                                              .map<DropdownMenuItem<int>>(
                                                  (int value) {
                                            return DropdownMenuItem<int>(
                                              value: value,
                                              child: Text(
                                                value == -1
                                                    ? "All"
                                                    : value.toString(),
                                                style:
                                                    theme.textTheme.bodyLarge,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (int? newValue) {
                                            setState(() {
                                              if (newValue == -1) {
                                                _expenseCategoryPage =
                                                    showExpenseCategory
                                                        .length; // Set to -1 for "All"
                                              } else {
                                                _expenseCategoryPage =
                                                    newValue ?? 10;
                                              }
                                              _currentPage = 1;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              ResponsiveGridCol(
                                xs: 100,
                                md: 60,
                                lg: 35,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: TextFormField(
                                    showCursor: true,
                                    cursorColor: kTitleColor,
                                    onChanged: (value) {
                                      setState(() {
                                        searchItem = value;
                                        _currentPage =
                                            1; // Reset to the first page when searching
                                      });
                                    },
                                    keyboardType: TextInputType.name,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.all(10.0),
                                      hintText:
                                          (lang.S.of(context).searchByName),
                                      suffixIcon: const Icon(
                                        FeatherIcons.search,
                                        color: kTitleColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(width: 20.0),

                            ///__________expense_LIst____________________________________________________________________
                            showExpenseCategory.isNotEmpty
                                ? Column(
                                    children: [
                                      LayoutBuilder(
                                        builder: (context, constrains) {
                                          return Scrollbar(
                                            controller: _horizontalScroll,
                                            thumbVisibility: true,
                                            radius: const Radius.circular(8),
                                            thickness: 8,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              controller: _horizontalScroll,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  minWidth: constrains.maxWidth,
                                                ),
                                                child: Theme(
                                                  data: theme.copyWith(
                                                    dividerColor:
                                                        Colors.transparent,
                                                    dividerTheme:
                                                        const DividerThemeData(
                                                            color: Colors
                                                                .transparent),
                                                  ),
                                                  child: DataTable(
                                                    border: const TableBorder(
                                                      horizontalInside:
                                                          BorderSide(
                                                        width: 1,
                                                        color: kNeutral300,
                                                      ),
                                                    ),
                                                    dataRowColor:
                                                        const WidgetStatePropertyAll(
                                                            Colors.white),
                                                    headingRowColor:
                                                        WidgetStateProperty.all(
                                                            const Color(
                                                                0xFFF8F3FF)),
                                                    showBottomBorder: false,
                                                    dividerThickness: 0.0,
                                                    headingTextStyle: theme
                                                        .textTheme.titleMedium,
                                                    columns: [
                                                      DataColumn(
                                                        label: Text(
                                                          lang.S.of(context).SL,
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        headingRowAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        label: Text(
                                                          lang.S
                                                              .of(context)
                                                              .categoryName,
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        headingRowAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        label: Text(
                                                          lang.S
                                                              .of(context)
                                                              .description,
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        headingRowAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        // numeric: true,
                                                        label: Text(
                                                          lang.S
                                                              .of(context)
                                                              .action,
                                                        ),
                                                      ),
                                                    ],
                                                    rows: List.generate(
                                                      paginatedList.length,
                                                      (index) => DataRow(
                                                          cells: [
                                                            DataCell(Text(
                                                                '${startIndex + index + 1}')),
                                                            DataCell(
                                                              Center(
                                                                child: Text(
                                                                  paginatedList[
                                                                          index]
                                                                      .categoryName,
                                                                ),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Center(
                                                                child: Text(
                                                                  paginatedList[
                                                                          index]
                                                                      .categoryDescription,
                                                                ),
                                                              ),
                                                            ),

                                                            ///__________action_menu__________________________________________________________
                                                            DataCell(
                                                              Center(
                                                                child: Theme(
                                                                  data: ThemeData(
                                                                      highlightColor:
                                                                          dropdownItemColor,
                                                                      focusColor:
                                                                          dropdownItemColor,
                                                                      hoverColor:
                                                                          dropdownItemColor),
                                                                  child:
                                                                      PopupMenuButton(
                                                                    surfaceTintColor:
                                                                        Colors
                                                                            .white,
                                                                    icon: const Icon(
                                                                        FeatherIcons
                                                                            .moreVertical,
                                                                        size:
                                                                            18.0),
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    itemBuilder:
                                                                        (BuildContext
                                                                                bc) =>
                                                                            [
                                                                      ///_________Edit___________________________________________
                                                                      PopupMenuItem(
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            showDialog(
                                                                              barrierDismissible: false,
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return StatefulBuilder(
                                                                                  builder: (context, setStates) {
                                                                                    return Dialog(
                                                                                      shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadius.circular(20.0),
                                                                                      ),
                                                                                      child: EditCategory(
                                                                                        listOfExpanseCategory: allExpensesCategory,
                                                                                        expenseCategoryModel: showExpenseCategory[index],
                                                                                        menuContext: bc,
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                );
                                                                              },
                                                                            );
                                                                          },
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              const Icon(
                                                                                IconlyLight.edit,
                                                                                color: kNeutral500,
                                                                                size: 22,
                                                                              ),
                                                                              const SizedBox(width: 4.0),
                                                                              Text(
                                                                                lang.S.of(context).edit,
                                                                                style: theme.textTheme.bodyLarge?.copyWith(color: kNeutral500),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),

                                                                      ///____________Delete___________________________________________
                                                                      PopupMenuItem(
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            if (checkAnyExpense(
                                                                                allList: allExpense.value!,
                                                                                category: showExpenseCategory[index].categoryName)) {
                                                                              showDialog(
                                                                                  barrierDismissible: false,
                                                                                  context: context,
                                                                                  builder: (BuildContext dialogContext) {
                                                                                    return Center(
                                                                                      child: Container(
                                                                                        width: 450,
                                                                                        decoration: const BoxDecoration(
                                                                                          color: Colors.white,
                                                                                          borderRadius: BorderRadius.all(
                                                                                            Radius.circular(15),
                                                                                          ),
                                                                                        ),
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.all(10.0),
                                                                                          child: Column(
                                                                                            mainAxisSize: MainAxisSize.min,
                                                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                                            children: [
                                                                                              Padding(
                                                                                                padding: const EdgeInsets.all(10.0),
                                                                                                child: Text(
                                                                                                  lang.S.of(context).areYouWantToDeleteThisCustomer,
                                                                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                                                                    fontWeight: FontWeight.w600,
                                                                                                  ),
                                                                                                  textAlign: TextAlign.center,
                                                                                                ),
                                                                                              ),
                                                                                              const SizedBox(height: 10),
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
                                                                                                      onPressed: () {
                                                                                                        // Navigator.pop(dialogContext);
                                                                                                        // Navigator.pop(bc);
                                                                                                        GoRouter.of(context).pop();
                                                                                                      },
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
                                                                                                        deleteExpenseCategory(
                                                                                                          expenseCategoryName: showExpenseCategory[index].categoryName,
                                                                                                          updateRef: ref,
                                                                                                          context: dialogContext,
                                                                                                        );
                                                                                                        GoRouter.of(dialogContext).pop();
                                                                                                      },
                                                                                                      child: Text(
                                                                                                        lang.S.of(context).delete,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                              ]),
                                                                                              // Row(
                                                                                              //   mainAxisAlignment: MainAxisAlignment.center,
                                                                                              //   mainAxisSize: MainAxisSize.min,
                                                                                              //   children: [
                                                                                              //     ElevatedButton(
                                                                                              //       style: ElevatedButton.styleFrom(
                                                                                              //         backgroundColor: Colors.red,
                                                                                              //       ),
                                                                                              //       onPressed: () {
                                                                                              //         Navigator.pop(dialogContext);
                                                                                              //         Navigator.pop(bc);
                                                                                              //       },
                                                                                              //       child: Text(
                                                                                              //         lang.S.of(context).cancel,
                                                                                              //       ),
                                                                                              //     ),
                                                                                              //     const SizedBox(width: 30),
                                                                                              //     ElevatedButton(
                                                                                              //       onPressed: () {
                                                                                              //         deleteExpenseCategory(
                                                                                              //           expenseCategoryName: showExpenseCategory[index].categoryName,
                                                                                              //           updateRef: ref,
                                                                                              //           context: dialogContext,
                                                                                              //         );
                                                                                              //         GoRouter.of(dialogContext).pop();
                                                                                              //       },
                                                                                              //       child: Text(
                                                                                              //         lang.S.of(context).delete,
                                                                                              //       ),
                                                                                              //     ),
                                                                                              //   ],
                                                                                              // )
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  });
                                                                            } else {
                                                                              EasyLoading.showError('This category Cannot be deleted');
                                                                            }
                                                                          },
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              HugeIcon(
                                                                                icon: HugeIcons.strokeRoundedDelete02,
                                                                                color: kNeutral500,
                                                                                size: 22,
                                                                              ),
                                                                              const SizedBox(width: 4.0),
                                                                              Text(
                                                                                lang.S.of(context).delete,
                                                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                                                  color: kNeutral500,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ]),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '${lang.S.of(context).showing} ${startIndex + 1} to ${endIndex > showExpenseCategory.length ? showExpenseCategory.length : endIndex} of ${showExpenseCategory.length} entries',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                InkWell(
                                                  overlayColor:
                                                      WidgetStateProperty.all<
                                                          Color>(Colors.grey),
                                                  hoverColor: Colors.grey,
                                                  onTap: _currentPage > 1
                                                      ? () => setState(
                                                          () => _currentPage--)
                                                      : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                              kBorderColorTextField),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                        bottomLeft:
                                                            Radius.circular(
                                                                4.0),
                                                        topLeft:
                                                            Radius.circular(
                                                                4.0),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(lang.S
                                                          .of(context)
                                                          .previous),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color:
                                                            kBorderColorTextField),
                                                    color: kMainColor,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$_currentPage',
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color:
                                                            kBorderColorTextField),
                                                    color: Colors.transparent,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$totalPages',
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  hoverColor: Colors.blue
                                                      .withValues(alpha: 0.1),
                                                  overlayColor:
                                                      WidgetStateProperty.all<
                                                          Color>(Colors.blue),
                                                  onTap: _currentPage <
                                                          totalPages
                                                      ? () => setState(
                                                          () => _currentPage++)
                                                      : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                              kBorderColorTextField),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                        bottomRight:
                                                            Radius.circular(
                                                                4.0),
                                                        topRight:
                                                            Radius.circular(
                                                                4.0),
                                                      ),
                                                    ),
                                                    child: const Center(
                                                        child: Text('Next')),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : EmptyWidget(
                                    title: lang.S
                                        .of(context)
                                        .noExpenseCategoryFound),
                          ],
                        ),
                      ),
                    );

                    // return ExpensesTableWidget(expenses: allExpenses);
                  }, error: (e, stack) {
                    return Center(
                      child: Text(e.toString()),
                    );
                  }, loading: () {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }),
                  // Visibility(visible: MediaQuery.of(context).size.height != 0, child: ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
