import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/Income/income_Edit.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/income_modle.dart';

import '../../Provider/income_provider.dart';
import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';
import 'income_details.dart';

class IncomeList extends StatefulWidget {
  const IncomeList({Key? key}) : super(key: key);

  static const String route = '/Income';

  @override
  State<IncomeList> createState() => _IncomeListState();
}

class _IncomeListState extends State<IncomeList> {
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

  String searchItem = '';

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

  DateTime selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

  List<String> month = ['This Month', 'Last Month', 'Last 6 Month', 'This Year'];

  String selectedMonth = 'This Month';

  DropdownButton<String> getMonth() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in month) {
      var item = DropdownMenuItem(
        value: des,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(des)),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      isExpanded: true,
      items: dropDownItems,
      value: selectedMonth,
      onChanged: (value) {
        setState(() {
          selectedMonth = value!;
          switch (selectedMonth) {
            case 'This Month':
              {
                var date = DateTime(DateTime.now().year, DateTime.now().month, 1).toString();

                selectedDate = DateTime.parse(date);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'Last Month':
              {
                selectedDate = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
                selected2ndDate = DateTime(DateTime.now().year, DateTime.now().month, 0);
              }
              break;
            case 'Last 6 Month':
              {
                selectedDate = DateTime(DateTime.now().year, DateTime.now().month - 6, 1);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'This Year':
              {
                selectedDate = DateTime(DateTime.now().year, 1, 1);
                selected2ndDate = DateTime.now();
              }
              break;
          }
        });
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  DateTime selected2ndDate = DateTime.now();

  Future<void> _selectedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selected2ndDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selected2ndDate) {
      setState(() {
        selected2ndDate = picked;
      });
    }
  }

  double calculateAllExpense({required List<IncomeModel> allExpense}) {
    double totalExpense = 0;
    for (var element in allExpense) {
      totalExpense += element.amount.toDouble();
    }

    return totalExpense;
  }

  ScrollController mainScroll = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  int _incomeDataPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Consumer(
        builder: (context, ref, child) {
          final incomes = ref.watch(incomeProvider);
          return incomes.when(data: (allIncome) {
            List<IncomeModel> reverseAllIncome = allIncome.reversed.toList();
            List<IncomeModel> showIncome = [];

            for (var element in reverseAllIncome) {
              DateTime incomeDate = DateTime.parse(element.incomeDate);

              DateTime incomeDateOnly = DateTime(incomeDate.year, incomeDate.month, incomeDate.day);
              DateTime selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
              DateTime selected2ndDateOnly = DateTime(selected2ndDate.year, selected2ndDate.month, selected2ndDate.day);

              if (element.incomeFor.toLowerCase().contains(searchItem.toLowerCase()) && (selectedDateOnly.isBefore(incomeDateOnly) || selectedDateOnly.isAtSameMomentAs(incomeDateOnly)) && (selected2ndDateOnly.isAfter(incomeDateOnly) || selected2ndDateOnly.isAtSameMomentAs(incomeDateOnly))) {
                showIncome.add(element);
              }
            }

            // Calculate pagination
            final totalPages = _incomeDataPerPage == -1 ? 1 : (showIncome.length / _incomeDataPerPage).ceil();
            final startIndex = _incomeDataPerPage == -1 ? 0 : (_currentPage - 1) * _incomeDataPerPage;
            final endIndex = _incomeDataPerPage == -1 ? showIncome.length : (startIndex + _incomeDataPerPage).clamp(0, showIncome.length);

            // Get paginated transactions
            final paginatedList = showIncome.sublist(startIndex, endIndex);
            return Scaffold(
                backgroundColor: kDarkWhite,
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //_______________________________top_bar_________________________________________________
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: kWhite,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResponsiveGridRow(rowSegments: 100, children: [
                              ResponsiveGridCol(
                                  xs: 100,
                                  md: 30,
                                  lg: 15,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SizedBox(
                                      height: 48,
                                      child: FormField(
                                        builder: (FormFieldState<dynamic> field) {
                                          return InputDecorator(
                                            decoration: const InputDecoration(),
                                            child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getMonth())),
                                          );
                                        },
                                      ),
                                    ),
                                  )),
                              ResponsiveGridCol(
                                xs: 100,
                                md: 50,
                                lg: 30,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), border: Border.all(color: kGreyTextColor)),
                                      child: Row(
                                        children: [
                                          Container(
                                            decoration: const BoxDecoration(shape: BoxShape.rectangle, color: kGreyTextColor),
                                            height: 48,
                                            child: Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(4.0),
                                                child: Text(
                                                  lang.S.of(context).between,
                                                  style: kTextStyle.copyWith(color: kWhite),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10.0),
                                          Flexible(
                                            child: Text.rich(TextSpan(text: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: theme.textTheme.bodyLarge, children: [
                                              TextSpan(
                                                text: ' ${lang.S.of(context).to} ',
                                                style: theme.textTheme.bodyLarge,
                                              ),
                                              TextSpan(
                                                text: '${selected2ndDate.day}/${selected2ndDate.month}/${selected2ndDate.year}',
                                                style: theme.textTheme.bodyLarge,
                                              )
                                            ])),
                                          ),
                                        ],
                                      )),
                                ),
                              ),
                            ]),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Container(
                                padding: const EdgeInsetsDirectional.only(start: 10.0, end: 20.0, top: 10.0, bottom: 10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: const Color(0xFFCFF4E3),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$globalCurrency ${myFormat.format(double.tryParse(calculateAllExpense(allExpense: incomes.value ?? []).toString()) ?? 0)}',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      lang.S.of(context).totalIncome,
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
                        child: Column(
                          children: [
                            ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              ResponsiveGridCol(
                                xs: 12,
                                md: screenWidth < 850 ? 4 : 6,
                                lg: screenWidth < 1500 ? 6 : 8,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    lang.S.of(context).incomeList,
                                    //'Expenses List',
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              ResponsiveGridCol(
                                xs: 6,
                                md: screenWidth < 850 ? 4 : 3,
                                lg: screenWidth < 1500 ? 3 : 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: ElevatedButton(
                                    onPressed: () => context.go('/income/income-category'),
                                    child: Text(
                                      lang.S.of(context).incomeCategory,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              ResponsiveGridCol(
                                xs: 6,
                                md: screenWidth < 850 ? 4 : 3,
                                lg: screenWidth < 1500 ? 3 : 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: ElevatedButton.icon(
                                      onPressed: () => context.go('/income/new-income'),
                                      icon: const Icon(FeatherIcons.plus, color: kWhite, size: 18.0),
                                      label: Text(
                                        lang.S.of(context).newIncome,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                ),
                              ),
                            ]),
                            const Divider(
                              thickness: 1.0,
                              color: kNeutral300,
                              height: 1,
                            ),
                            const SizedBox(height: 10),

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
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(color: kNeutral300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(child: Text('Show-', style: theme.textTheme.bodyLarge)),
                                        DropdownButton<int>(
                                          isDense: true,
                                          padding: EdgeInsets.zero,
                                          underline: const SizedBox(),
                                          value: _incomeDataPerPage,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.black,
                                          ),
                                          items: [10, 20, 50, 100, -1].map<DropdownMenuItem<int>>((int value) {
                                            return DropdownMenuItem<int>(
                                              value: value,
                                              child: Text(
                                                value == -1 ? "All" : value.toString(),
                                                style: theme.textTheme.bodyLarge,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (int? newValue) {
                                            setState(() {
                                              _incomeDataPerPage = newValue ?? 10;
                                              _currentPage = 1; // Always reset to page 1 when changing items per page
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
                                      });
                                    },
                                    keyboardType: TextInputType.name,
                                    decoration: kInputDecoration.copyWith(
                                      contentPadding: const EdgeInsets.all(10.0),
                                      //hintText: ('Search by Invoice...'),
                                      hintText: ('${lang.S.of(context).searchByInvoice}...'),
                                      suffixIcon: const Icon(
                                        FeatherIcons.search,
                                        color: kTitleColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),

                            ///__________Income_LIst____________________________________________________________________
                            Column(
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
                                              dividerColor: Colors.transparent,
                                              dividerTheme: const DividerThemeData(color: Colors.transparent),
                                            ),
                                            child: DataTable(
                                                border: const TableBorder(
                                                  horizontalInside: BorderSide(
                                                    width: 1,
                                                    color: kNeutral300,
                                                  ),
                                                ),
                                                dataRowColor: const WidgetStatePropertyAll(Colors.white),
                                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                                showBottomBorder: false,
                                                dividerThickness: 0.0,
                                                headingTextStyle: theme.textTheme.titleMedium,
                                                columns: [
                                                  DataColumn(label: Text(lang.S.of(context).SL)),
                                                  DataColumn(label: Text(lang.S.of(context).date)),
                                                  DataColumn(label: Text(lang.S.of(context).createdBy)),
                                                  DataColumn(label: Text(lang.S.of(context).category)),
                                                  DataColumn(label: Text(lang.S.of(context).note)),
                                                  DataColumn(label: Text(lang.S.of(context).paymentType)),
                                                  DataColumn(label: Text(lang.S.of(context).amount)),
                                                  DataColumn(label: Text(lang.S.of(context).setting)),
                                                ],
                                                rows: List.generate(paginatedList.length, (index) {
                                                  return DataRow(cells: [
                                                    ///______________S.L__________________________________________________
                                                    DataCell(
                                                      Text(
                                                        '${startIndex + index + 1}',
                                                      ),
                                                    ),

                                                    ///______________Date__________________________________________________
                                                    DataCell(
                                                      Text(
                                                        paginatedList[index].incomeDate.substring(0, 10),
                                                      ),
                                                    ),

                                                    ///____________Created By_________________________________________________
                                                    DataCell(
                                                      Text(
                                                        paginatedList[index].incomeFor,
                                                      ),
                                                    ),

                                                    ///______Category___________________________________________________________
                                                    DataCell(
                                                      Text(
                                                        paginatedList[index].category,
                                                      ),
                                                    ),

                                                    ///___________note______________________________________________

                                                    DataCell(
                                                      Text(
                                                        paginatedList[index].note.toString(),
                                                      ),
                                                    ),

                                                    ///___________Payment tYpe____________________________________________________
                                                    DataCell(
                                                      Text(
                                                        paginatedList[index].paymentType.toString(),
                                                      ),
                                                    ),

                                                    ///___________Amount____________________________________________________

                                                    DataCell(
                                                      Text(
                                                        myFormat.format(double.tryParse(paginatedList[index].amount.toString()) ?? 0),
                                                      ),
                                                    ),

                                                    ///_______________actions_________________________________________________
                                                    DataCell(
                                                      SizedBox(
                                                        width: 30,
                                                        child: Theme(
                                                          data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                          child: PopupMenuButton(
                                                            surfaceTintColor: Colors.white,
                                                            padding: EdgeInsets.zero,
                                                            itemBuilder: (BuildContext bc) => [
                                                              PopupMenuItem(
                                                                onTap: () {
                                                                  showDialog(
                                                                    barrierDismissible: false,
                                                                    context: context,
                                                                    builder: (BuildContext context) {
                                                                      return StatefulBuilder(
                                                                        builder: (context, setStates) {
                                                                          return Dialog(
                                                                            surfaceTintColor: Colors.white,
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(20.0),
                                                                            ),
                                                                            child: IncomeDetails(income: showIncome[index], manuContext: bc),
                                                                          );
                                                                        },
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    const Icon(Icons.remove_red_eye_outlined, size: 22.0, color: kGreyTextColor),
                                                                    const SizedBox(width: 4.0),
                                                                    Text(
                                                                      lang.S.of(context).view,
                                                                      style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),

                                                              ///____________edit___________________________________________
                                                              PopupMenuItem(
                                                                onTap: () {
                                                                  IncomeEdit(
                                                                    // menuContext: bc,
                                                                    incomeModel: showIncome[index],
                                                                  ).launch(context);
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    Icon(IconlyLight.edit, size: 22.0, color: kGreyTextColor),
                                                                    const SizedBox(width: 4.0),
                                                                    Text(
                                                                      lang.S.of(context).edit,
                                                                      style: theme.textTheme.bodyLarge?.copyWith(
                                                                        color: kGreyTextColor,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                            child: Center(
                                                              child: Container(
                                                                  height: 18,
                                                                  width: 18,
                                                                  alignment: Alignment.centerRight,
                                                                  child: const Icon(
                                                                    Icons.more_vert_sharp,
                                                                    size: 18,
                                                                  )),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ]);
                                                })),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _incomeDataPerPage == -1 ? 'Showing all ${showIncome.length} entries' : 'Showing ${startIndex + 1} to $endIndex of ${showIncome.length} entries',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: kNeutral700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_incomeDataPerPage != -1) // Only show pagination controls when not showing "All"
                                        Container(
                                          alignment: Alignment.center,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: kNeutral300),
                                          ),
                                          child: Row(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    if (_currentPage > 1) {
                                                      setState(() {
                                                        _currentPage--;
                                                      });
                                                    }
                                                  },
                                                  child: Text(
                                                    'Previous',
                                                    style: theme.textTheme.bodyLarge?.copyWith(
                                                      color: kNeutral700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  color: kMainColor,
                                                  border: Border.symmetric(
                                                    vertical: BorderSide(color: kNeutral300),
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  child: Text(
                                                    '$_currentPage',
                                                    style: theme.textTheme.bodyLarge?.copyWith(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  border: Border.symmetric(
                                                    vertical: BorderSide(color: kNeutral300),
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  child: Text(
                                                    '$totalPages',
                                                    style: theme.textTheme.bodyLarge?.copyWith(
                                                      color: kNeutral700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    if (_currentPage < totalPages) {
                                                      setState(() {
                                                        _currentPage++;
                                                      });
                                                    }
                                                  },
                                                  child: Text(
                                                    'Next',
                                                    style: theme.textTheme.bodyLarge?.copyWith(
                                                      color: kNeutral700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ));
            // return ExpensesTableWidget(incomes: allExpenses);
          }, error: (e, stack) {
            return Center(
              child: Text(e.toString()),
            );
          }, loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          });
        },
      ),
    );
  }
}
