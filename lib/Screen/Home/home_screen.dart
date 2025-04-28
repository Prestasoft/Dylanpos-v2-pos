// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/Home/dashbord_stock.dart';
import 'package:salespro_admin/Screen/Home/top_report_widget.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/home_report_model.dart';
import 'package:salespro_admin/model/product_model.dart';

import '../../Provider/all_expanse_provider.dart';
import '../../Provider/income_provider.dart';
import '../../Provider/purchase_transaction_single.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/add_to_cart_model.dart';
import '../../model/customer_model.dart';
import '../../model/due_transaction_model.dart';
import '../../model/expense_model.dart';
import '../../model/income_modle.dart';
import '../../model/sale_transaction_model.dart';
import '../../subscription.dart';
import '../currency/currency_provider.dart';
import 'total_count_widget.dart';

class MtHomeScreen extends StatefulWidget {
  const MtHomeScreen({super.key});

  static const String route = '/dashBoard';

  @override
  State<MtHomeScreen> createState() => _MtHomeScreenState();
}

class _MtHomeScreenState extends State<MtHomeScreen> {
  int totalStock = 0;
  double totalSalePrice = 0;
  double totalParPrice = 0;
  // void _setupHistory() {
  //   html.window.history.replaceState(null, '', html.window.location.href);
  //   html.window.history.pushState(null, '', html.window.location.href);
  //   html.window.onPopState.listen((event) {
  //     html.window.history.pushState(null, '', html.window.location.href);
  //     Navigator.pushNamed(context, '/dashBoard');
  //   });
  // }

  List<String> status = [
    'This Month',
    'Last Month',
    'April',
    'March',
    'February',
  ];
  final _horizontalScroll = ScrollController();
  final _verticalScroll = ScrollController();
  String selectedStatus = 'This Month';

  DropdownButton<String> getStatus() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in status) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedStatus,
      onChanged: (value) {
        setState(() {
          selectedStatus = value!;
        });
      },
    );
  }

  List<String> dates = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
  ];

  String selectedDate = 'January';

  DropdownButton<String> selectDate() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in dates) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedDate,
      onChanged: (value) {
        setState(() {
          selectedDate = value!;
        });
      },
    );
  }

  bool isOn = false;

  double calculateTotal(List<dynamic> purchases) {
    double totalPurchase = 0.0;
    for (var element in purchases) {
      totalPurchase += element.totalAmount!;
    }
    return totalPurchase;
  }

  double calculateTotalSale(List<SaleTransactionModel> sales) {
    double totalSale = 0.0;
    for (var element in sales) {
      totalSale += element.totalAmount!;
    }
    return totalSale;
  }

  List<HomeReport> getLastCustomerName(List<SaleTransactionModel> model) {
    List<HomeReport> customers = [];
    model.reversed.toList().forEach((element) {
      HomeReport report = HomeReport(element.customerName, element.totalAmount.toString());
      customers.add(report);
    });
    return customers;
  }

  List<HomeReport> getLastPurchaserName(List<dynamic> model) {
    List<HomeReport> customers = [];
    model.reversed.toList().forEach((element) {
      HomeReport report = HomeReport(element.customerName, element.totalAmount.toString());
      customers.add(report);
    });
    return customers;
  }

  List<HomeReport> getLastDueName(List<DueTransactionModel> model) {
    List<HomeReport> customers = [];
    model.reversed.toList().forEach((element) {
      HomeReport report = HomeReport(element.customerName, element.payDueAmount.toString());
      customers.add(report);
    });
    return customers;
  }

  List<TopSellReport> getTopSellingReport(List<AddToCartModel> model) {
    return model
        .map(
          (element) => TopSellReport(
            element.productName,
            element.productPurchasePrice.toString(),
            element.productBrandName,
            element.quantity.toString(),
            element.productImage,
          ),
        )
        .toList();
  }

  bool isAfterFirstDayOfCurrentMonth(DateTime date) {
    return date.isAfter(firstDayOfCurrentMonth);
  }

  // List<TopCustomer> getTopCustomer(List<CustomerModel> model) {
  //   List<TopCustomer> customers = [];
  //   model.reversed.toList().forEach((element) {
  //     TopCustomer report = TopCustomer(element.customerName, element.phoneNumber, element.dueAmount, element.profilePicture);
  //     customers.add(report);
  //   });
  //   return customers;
  // }

  List<TopCustomer> getTopCustomer(List<CustomerModel> model) {
    return model
        .map(
          (element) => TopCustomer(
            element.customerName,
            element.openingBalance.toString() ?? '',
            element.phoneNumber,
            element.profilePicture.toString(),
          ),
        )
        .toList();
  }

  List<String> items = ['Today', 'Last 7 Days', 'This Month', 'This Year'];

  List<String> baseFlagsCode = [
    'US',
    'ES',
    'IN',
    'SA',
    'FR',
    'BD',
    'TR',
    'CN',
    'JP',
    'RO',
    'DE',
    'VN',
    'IT',
    'TH',
    'PT',
    'IL',
    'PL',
    'HU',
    'FI',
    'KR',
    'MY',
    'ID',
    'UA',
    'BA',
    'GR',
    'NL',
    'Pk',
    'LK',
    'IR',
    'RS',
    'KH',
    'LA',
    'RU',
    'IN',
    'IN',
    'IN',
    'ZA',
    'CZ',
    'SE',
    'SK',
    'TZ',
    'AL',
    'DK',
    'AZ',
    'KZ',
    'HR',
    'NP',
    'AM',
    'AS',
    'BE',
    'CA',
    'CY',
    'ET',
    'EU',
    'GL',
    'IN',
    'AM',
    'IS',
    'KG',
    'LT',
    'LV',
    'MK',
    'IN',
    'NO',
    'IN',
    'AF',
  ];
  List<String> countryList = [
    'English',
    'Spanish',
    'Hindi',
    'Arabic',
    'France',
    'Bengali',
    'Turkish',
    'Chinese',
    'Japanese',
    'Romanian',
    'Germany',
    'Vietnamese',
    'Italian',
    'Thai',
    'Portuguese',
    'Hebrew',
    'Polish',
    'Hungarian',
    'Finland',
    'Korean',
    'Malay',
    'Indonesian',
    'Ukrainian',
    'Bosnian',
    'Greek',
    'Dutch',
    'Urdu',
    'Sinhala',
    'Persian',
    'Serbian',
    'Khmer',
    'Lao',
    'Russian',
    'Kannada',
    'Marathi',
    'Tamil',
    'Afrikaans',
    'Czech',
    'Swedish',
    'Slovak',
    'Swahili',
    'Albanian',
    'Danish',
    'Azerbaijani',
    'Kazakh',
    'Croatian',
    'Nepali', //47
    'Amharic',
    'Assamese',
    'Belarusian',
    'Catalan',
    'Welsh',
    'Estonian',
    'Basque',
    'Galician',
    'Gujarati',
    'Armenian',
    'Icelandic',
    'Kirghiz Kyrgyz',
    'Lithuanian',
    'Latvian',
    'Macedonian',
    'Malayalam',
    'Norwegian',
    'Panjabi',
    'Pushto', //66
  ];
  String selectedCountry = 'Spanish';

  List<String> currencyList = [
    'USD',
    'TK',
    'Rupee',
    'Riyal',
  ];
  String selectedCurrency = 'USD';

  Future<void> saveData(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedLanguage', data);
  }

  getData() async {
    final prefs = await SharedPreferences.getInstance();
    selectedCountry = prefs.getString('savedLanguage') ?? selectedCountry;
    setState(() {});
  }

  Future<void> saveDataOnLocal({required String key, required String type, required dynamic value}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (type == 'bool') prefs.setBool(key, value);
    if (type == 'string') prefs.setString(key, value);
  }

  String? dropdownValue = 'Tsh (TZ Shillings)';
  List<IconData> iconsList = [
    MdiIcons.accountGroupOutline,
    MdiIcons.accountGroupOutline,
    MdiIcons.fileChartOutline,
    MdiIcons.cart,
    MdiIcons.textBox,
    Icons.post_add_outlined,
  ];

  List<String> titleList = [
    'Add Client',
    'Add Supplier',
    'Create Product',
    'Create Sale',
    'Create Purchase',
    'Add Quotation',
  ];

  Future<void> addUser() async {
    if (await Subscription.subscriptionChecker(item: 'Parties')) {
      context.push(
        '/add-customer',
        extra: {
          'typeOfCustomerAdd': 'Buyer',
          'listOfPhoneNumber': [],
        },
      );
      // showDialog(
      //     barrierDismissible: false,
      //     context: context,
      //     builder: (BuildContext context) {
      //       return const AddCustomer(
      //         typeOfCustomerAdd: 'Buyer',
      //         listOfPhoneNumber: [],
      //       );
      //     });
    } else {
      //EasyLoading.showError('Update your plan first\nAdd Customer limit is over.');
      EasyLoading.showError('${lang.S.of(context).updateYourPlanFirstAddCustomerLimitIsOver}.');
    }
  }

  Future<void> addSupplier() async {
    if (await Subscription.subscriptionChecker(item: 'Parties')) {
      context.push(
        '/add-customer',
        extra: {
          'typeOfCustomerAdd': 'Supplier',
          'listOfPhoneNumber': [],
        },
      );
      // showDialog(
      //     barrierDismissible: false,
      //     context: context,
      //     builder: (BuildContext context) {
      //       return const AddCustomer(
      //         typeOfCustomerAdd: 'Supplier',
      //         listOfPhoneNumber: [],
      //         sideBarNumber: 5,
      //       );
      //     });
    } else {
      // EasyLoading.showError('Update your plan first\nAdd Customer limit is over.');
      EasyLoading.showError('${lang.S.of(context).updateYourPlanFirstAddCustomerLimitIsOver}.');
    }
  }

  Future<void> createProduct() async {
    if (await Subscription.subscriptionChecker(item: 'Products')) {
      context.push(
        '/product/add-product',
        extra: {
          'allProductsCodeList': [],
          'warehouseBasedProductModel': [],
        },
      );
    } else {
      EasyLoading.showError(lang.S.of(context).updateYourPlanFirst);
    }
  }

  Future<void> addSales() async {
    if (await Subscription.subscriptionChecker(item: 'Sales')) {
      // Navigator.pushNamed(context, PosSale.route);
      context.go('pos-sales');
    } else {
      EasyLoading.showError(lang.S.of(context).updateYourPlanFirst);
    }
  }

  Future<void> addPurchase() async {
    if (await Subscription.subscriptionChecker(item: 'Purchase')) {
      // Navigator.pushNamed(context, Purchase.route);
      context.go('pos-purchase');
    } else {
      EasyLoading.showError(lang.S.of(context).updateYourPlanFirst);
    }
  }

  final ScrollController mainSideScroller = ScrollController();

  double totalProfitCurrentMonth = 0;
  double totalProfitPreviousMonth = 0;
  double totalLoss = 0;
  static DateTime fromDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  static DateTime toDate = DateTime.now();
  static String selectedIndex = 'Today';

  Future<void> _refresh() {
    return getUserID().then((user) {
      setState(() => user = user);
    });
  }

  bool isFirstTime = true;

  int i = 0;

//__________________________________Sale_Statistics__________________

  ScrollController scrollController = ScrollController();
  List<SaleTransactionModel> totalSaleOfYear = [];
  List<SaleTransactionModel> saleCountOfcurrentMonth = [];
  List<SaleTransactionModel> saleCountOfLastMonth = [];
  List<SaleTransactionModel> saleCountOfLastYear = [];
  double totalSaleOfCurrentYear = 0;
  double totalSaleOfPreviousYear = 0;
  double totalSaleOfCurrentMonth = 0;
  List<double> monthlySale = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  List<int> dailySaleOfCurrentMonth = [];
  List<int> dailySale = [];
  double totalSaleOfLastMonth = 0;
  List<SaleTransactionModel> saleList = [];

  //__________________________________Expense_Statistics__________________

  List<ExpenseModel> totalExpenseOfYear = [];
  List<ExpenseModel> expenseCountOfCurrentMonth = [];
  List<ExpenseModel> expenseCountOfLastMonth = [];
  List<ExpenseModel> expenseCountOfLastYear = [];
  double totalExpenseOfCurrentYear = 0;
  double totalExpenseOfPreviousYear = 0;
  double totalExpenseOfCurrentMonth = 0;
  List<double> monthlyExpense = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  List<int> dailyExpenseOfCurrentMonth = [];
  List<int> dailyExpense = [];
  double totalExpenseOfLastMonth = 0;
  List<ExpenseModel> expenseList = [];

  //__________________________________income_Statistics__________________

  List<IncomeModel> totalIncomeOfYear = [];
  List<IncomeModel> incomeCountOfCurrentMonth = [];
  List<IncomeModel> incomeCountOfLastMonth = [];
  List<IncomeModel> iCountOfLastYear = [];
  double totalIncomeOfCurrentYear = 0;
  double totalIncomeOfPreviousYear = 0;
  double totalIncomeOfCurrentMonth = 0;
  List<double> monthlyIncome = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  List<int> dailyIncomeOfCurrentMonth = [];
  List<int> dailyIncome = [];
  double totalIncomeOfLastMonth = 0;
  List<IncomeModel> incomeList = [];
  List<SaleTransactionModel> totalSaleList = [];
  List<SaleTransactionModel> recentFive = [];

  double totalPaid = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    getAllTotal();
    getData();
    selectedCountry;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Subscription.getUserLimitsData(context: context, wannaShowMsg: true);
    });
    for (int i = 0; i < DateTime(currentDate.year, currentDate.month + 1, 0).day; i++) {
      dailySaleOfCurrentMonth.add(0);
    }
    for (int i = 0; i < DateTime(currentDate.year, currentDate.month + 1, 0).day; i++) {
      dailySale.add(0);
    }
    for (int i = 0; i < DateTime(currentDate.year, currentDate.month + 1, 0).day; i++) {
      dailyExpenseOfCurrentMonth.add(0);
    }
    for (int i = 0; i < DateTime(currentDate.year, currentDate.month + 1, 0).day; i++) {
      dailyExpense.add(0);
    }
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  List<SaleTransactionModel> shopList = [];

  //__________________top_purchase_report_________________________________________

  List<TopPurchaseReport> getTopPurchaseReport(List<ProductModel> model) {
    return model
        .map(
          (element) => TopPurchaseReport(
            element.productName,
            element.productPurchasePrice.toString() ?? '',
            element.productCategory,
            element.productPicture,
            element.productStock,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    print('---------confirm---------------');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    i++;
    getUserDataFromLocal();
    return SafeArea(
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: Consumer(
          builder: (_, ref, watch) {
            AsyncValue<List<SaleTransactionModel>> transactionReport = ref.watch(transitionProvider);
            final incomes = ref.watch(incomeProvider);
            final expenses = ref.watch(expenseProvider);
            final purchaseTransactionReport = ref.watch(purchaseTransitionProviderSIngle);
            return SingleChildScrollView(
              controller: _verticalScroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  expenses.when(data: (allExpenses) {
                    return transactionReport.when(data: (transaction) {
                      ///___________________________________________all_expense_data___________________
                      totalExpenseOfYear = [];
                      expenseCountOfCurrentMonth = [];
                      expenseCountOfLastMonth = [];
                      expenseCountOfLastYear = [];
                      totalExpenseOfCurrentYear = 0;
                      totalExpenseOfPreviousYear = 0;
                      totalExpenseOfCurrentMonth = 0;
                      monthlyExpense = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
                      totalExpenseOfLastMonth = 0;
                      expenseList = [];
                      for (var element in allExpenses) {
                        final expenseDate = DateTime.tryParse(element.expenseDate.toString()) ?? DateTime.now();
                        if (expenseDate.isAfter(firstDayOfCurrentYear)) {
                          totalExpenseOfCurrentYear += double.parse(element.amount.toString());
                          monthlyExpense[expenseDate.month - 1] += double.parse(element.amount.toString());
                          dailyExpense[expenseDate.day - 1] += int.parse(element.amount);
                          totalExpenseOfYear.add(element);

                          if (expenseDate.isAfter(firstDayOfCurrentMonth)) {
                            totalExpenseOfCurrentMonth += double.parse(element.amount.toString());
                            expenseCountOfCurrentMonth.add(element);
                            dailyExpenseOfCurrentMonth[expenseDate.day - 1]++;
                          }

                          if (expenseDate.isAfter(firstDayOfPreviousMonth) && expenseDate.isBefore(firstDayOfCurrentMonth)) {
                            totalExpenseOfLastMonth += double.parse(element.amount.toString());
                            expenseCountOfLastMonth.add(element);
                          }
                          if (expenseDate.isAfter(firstDayOfPreviousYear) && expenseDate.isBefore(firstDayOfCurrentYear)) {
                            totalExpenseOfPreviousYear += double.parse(element.amount.toString());
                            expenseCountOfLastYear.add(element);
                          }
                        }
                      }

                      //____________________________________________________________________________________________________________

                      //___________________________________________all_sales_data___________________
                      totalSaleOfYear = [];
                      saleCountOfcurrentMonth = [];
                      saleCountOfLastMonth = [];
                      saleCountOfLastYear = [];
                      totalSaleOfCurrentYear = 0;
                      totalSaleOfPreviousYear = 0;
                      totalSaleOfCurrentMonth = 0;
                      monthlySale = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
                      totalSaleOfLastMonth = 0;
                      saleList = [];
                      totalProfitCurrentMonth = 0;
                      totalProfitPreviousMonth = 0;

                      for (var element in transaction) {
                        final saleDate = DateTime.tryParse(element.purchaseDate.toString()) ?? DateTime.now();
                        if (saleDate.isAfter(firstDayOfCurrentYear)) {
                          totalSaleOfCurrentYear += double.parse(element.totalAmount.toString());
                          monthlySale[saleDate.month - 1] += double.parse(element.totalAmount.toString());
                          if (saleDate.day >= 1 && saleDate.day <= dailySale.length) {
                            dailySale[saleDate.day - 1] += element.totalAmount!.round();
                          } else {
                            print("Invalid day: ${saleDate.day}");
                          }
                          // dailySale[saleDate.day - 1] += element.totalAmount!.round();
                          totalSaleOfYear.add(element);

                          if (saleDate.isAfter(firstDayOfCurrentMonth)) {
                            totalSaleOfCurrentMonth += double.parse(element.totalAmount.toString());
                            saleCountOfcurrentMonth.add(element);
                            dailySaleOfCurrentMonth[saleDate.day - 1]++;
                            element.lossProfit!.isNegative ? totalLoss = totalLoss + element.lossProfit!.abs() : totalProfitCurrentMonth = double.parse(totalProfitCurrentMonth.toString()) + double.parse(element.lossProfit!.toString());
                          }

                          if (saleDate.isAfter(firstDayOfPreviousMonth) && saleDate.isBefore(firstDayOfCurrentMonth)) {
                            totalSaleOfLastMonth += double.parse(element.totalAmount.toString());
                            saleCountOfLastMonth.add(element);
                            element.lossProfit!.isNegative ? totalLoss = totalLoss + element.lossProfit!.abs() : totalProfitCurrentMonth = double.parse(totalProfitCurrentMonth.toString()) + double.parse(element.lossProfit!.toString());
                          }
                          if (saleDate.isAfter(firstDayOfPreviousYear) && saleDate.isBefore(firstDayOfCurrentYear)) {
                            totalSaleOfPreviousYear += double.parse(element.totalAmount.toString());
                            saleCountOfLastYear.add(element);
                          }
                        }
                      }
                      //_______________________________________total_sale_count_____________
                      int currentMonthUserCount = saleCountOfcurrentMonth.length;
                      int previousMonthSale = saleCountOfLastMonth.length;
                      double percentageChange = 0.0;
                      if (previousMonthSale > 0) {
                        percentageChange = ((currentMonthUserCount - previousMonthSale) / previousMonthSale) * 100;
                      } else if (previousMonthSale == 0) {
                        percentageChange = (currentMonthUserCount - previousMonthSale) * 100;
                      } else {
                        percentageChange = ((currentMonthUserCount - previousMonthSale).abs() / previousMonthSale.abs()) * 100;
                      }

                      //_______________________________________total_sale_amount_____________
                      int currentMonthSaleAmount = saleCountOfcurrentMonth.length;
                      int previousMonthSaleAmount = saleCountOfLastMonth.length;
                      double salePercentage = 0.0;
                      if (previousMonthSaleAmount > 0) {
                        salePercentage = ((currentMonthSaleAmount - previousMonthSaleAmount) / previousMonthSaleAmount) * 100;
                      } else if (previousMonthSaleAmount == 0) {
                        salePercentage = (currentMonthSaleAmount - previousMonthSaleAmount) * 100;
                      } else {
                        salePercentage = ((currentMonthSaleAmount - previousMonthSaleAmount).abs() / previousMonthSaleAmount.abs()) * 100;
                      }

                      // _______________________________________total_profit_amount_____________
                      int currentMonthProfit = totalProfitCurrentMonth.round();
                      int previousMonthProfit = totalProfitPreviousMonth.round();
                      double profitPercentage = 0.0;
                      if (previousMonthProfit > 0) {
                        profitPercentage = ((currentMonthProfit - previousMonthProfit) / previousMonthProfit) * 100;
                      } else if (previousMonthProfit == 0) {
                        profitPercentage = (currentMonthProfit - previousMonthProfit) * 100;
                      } else {
                        profitPercentage = ((currentMonthProfit - previousMonthProfit).abs() / previousMonthProfit.abs()) * 100;
                      }

                      // _______________________________________total_income_amount_____________
                      int currentMonthExpense = totalExpenseOfCurrentMonth.round();
                      int previousMonthExpense = totalExpenseOfLastMonth.round();
                      double expensePercentage = 0.0;
                      if (previousMonthExpense > 0) {
                        expensePercentage = ((currentMonthExpense - previousMonthExpense) / previousMonthExpense) * 100;
                      } else if (previousMonthExpense == 0) {
                        expensePercentage = (currentMonthExpense - previousMonthExpense) * 100;
                      } else {
                        expensePercentage = ((currentMonthExpense - previousMonthExpense).abs() / previousMonthExpense.abs()) * 100;
                      }

                      return Column(
                        children: [
                          ResponsiveGridRow(rowSegments: 120, children: [
                            ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: screenWidth < 1500
                                  ? 40
                                  : screenWidth < 1800
                                      ? 30
                                      : 24,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TotalSummary(
                                  title: lang.S.of(context).tSale,
                                  // count: '${showList.length}',
                                  count: '${saleCountOfcurrentMonth.length}',
                                  withOutCurrency: true,
                                  footerTitle: 'Este Mes',
                                  backgroundColor: const Color(0xFFB9FDEC),
                                  icon: 'images/cust.svg',
                                  predictIcon: percentageChange >= 0 ? FontAwesomeIcons.arrowUpLong : FontAwesomeIcons.arrowDownLong,
                                  predictIconColor: percentageChange >= 0 ? Colors.green : Colors.red,
                                  monthlyDifferent: '${percentageChange.toStringAsFixed(2)}%',
                                  difWithoutCurrency: true,
                                ),
                              ),
                            ),
                            ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: screenWidth < 1500
                                  ? 40
                                  : screenWidth < 1800
                                      ? 30
                                      : 24,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TotalSummary(
                                  title: lang.S.of(context).sAmount,
                                  count: '$totalSaleOfCurrentMonth',
                                  withOutCurrency: false,
                                  footerTitle: 'Este Mes',
                                  backgroundColor: const Color(0xFFDFDAFF),
                                  icon: 'images/sale.svg',
                                  predictIcon: percentageChange >= 0 ? FontAwesomeIcons.arrowUpLong : FontAwesomeIcons.arrowDownLong,
                                  predictIconColor: percentageChange >= 0 ? Colors.green : Colors.red,
                                  monthlyDifferent: '${salePercentage.toStringAsFixed(2)}%',
                                  difWithoutCurrency: false,
                                ),
                              ),
                            ),
                            ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: screenWidth < 1500
                                  ? 40
                                  : screenWidth < 1800
                                      ? 30
                                      : 24,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TotalSummary(
                                  title: lang.S.of(context).profit,
                                  count: "$totalProfitCurrentMonth",
                                  withOutCurrency: false,
                                  footerTitle: 'Este Mes',
                                  backgroundColor: const Color(0xFFC8E6FE),
                                  icon: 'images/pur.svg',
                                  predictIcon: percentageChange >= 0 ? FontAwesomeIcons.arrowUpLong : FontAwesomeIcons.arrowDownLong,
                                  predictIconColor: percentageChange >= 0 ? Colors.green : Colors.red,
                                  monthlyDifferent: '${profitPercentage.toStringAsFixed(2)}%',
                                  difWithoutCurrency: false,
                                ),
                              ),
                            ),
                            ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: screenWidth < 1500
                                  ? 40
                                  : screenWidth < 1800
                                      ? 30
                                      : 24,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TotalSummary(
                                  title: lang.S.of(context).expenses,
                                  count: "$totalExpenseOfCurrentMonth",
                                  withOutCurrency: false,
                                  footerTitle: 'Este Mes',
                                  backgroundColor: const Color(0xFFFFD6E2),
                                  icon: 'images/ex.svg',
                                  predictIcon: percentageChange >= 0 ? FontAwesomeIcons.arrowUpLong : FontAwesomeIcons.arrowDownLong,
                                  predictIconColor: percentageChange >= 0 ? Colors.green : Colors.red,
                                  monthlyDifferent: '${expensePercentage.toStringAsFixed(2)}%',
                                  difWithoutCurrency: false,
                                ),
                              ),
                            ),
                            ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: screenWidth < 1500
                                  ? 40
                                  : screenWidth < 1800
                                      ? 30
                                      : 24,
                              child: incomes.when(data: (allIncome) {
                                totalIncomeOfYear = [];
                                incomeCountOfCurrentMonth = [];
                                incomeCountOfLastMonth = [];
                                totalIncomeOfCurrentYear = 0;
                                totalIncomeOfPreviousYear = 0;
                                totalIncomeOfCurrentMonth = 0;
                                monthlyIncome = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
                                totalIncomeOfLastMonth = 0;
                                incomeList = [];

                                for (var element in allIncome) {
                                  final incomeDate = DateTime.tryParse(element.incomeDate.toString()) ?? DateTime.now();
                                  if (incomeDate.isAfter(firstDayOfCurrentYear)) {
                                    totalIncomeOfCurrentYear += double.parse(element.amount.toString());
                                    monthlyIncome[incomeDate.month - 1] += double.parse(element.amount.toString());
                                    totalIncomeOfYear.add(element);

                                    if (incomeDate.isAfter(firstDayOfCurrentMonth)) {
                                      totalIncomeOfCurrentMonth += double.parse(element.amount.toString());
                                      incomeCountOfCurrentMonth.add(element);
                                    }

                                    if (incomeDate.isAfter(firstDayOfPreviousMonth) && incomeDate.isBefore(firstDayOfCurrentMonth)) {
                                      totalIncomeOfLastMonth += double.parse(element.amount.toString());
                                      incomeCountOfLastMonth.add(element);
                                    }
                                  }
                                }

                                // _______________________________________total_expense_amount_____________
                                int currentMonthIncome = totalIncomeOfCurrentMonth.round();
                                int previousMonthIncome = totalIncomeOfLastMonth.round();
                                double incomePercentage = 0.0;
                                if (previousMonthIncome > 0) {
                                  incomePercentage = ((currentMonthIncome - previousMonthIncome) / previousMonthIncome) * 100;
                                } else if (previousMonthIncome == 0) {
                                  incomePercentage = (currentMonthIncome - previousMonthIncome) * 100;
                                } else {
                                  incomePercentage = ((currentMonthIncome - previousMonthIncome).abs() / previousMonthIncome.abs()) * 100;
                                }

                                return Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: TotalSummary(
                                    title: lang.S.of(context).inc,
                                    count: "$totalIncomeOfCurrentMonth",
                                    withOutCurrency: false,
                                    footerTitle: 'Este Mes',
                                    backgroundColor: const Color(0xFFC5FDBF),
                                    icon: 'images/in.svg',
                                    predictIcon: percentageChange >= 0 ? FontAwesomeIcons.arrowUpLong : FontAwesomeIcons.arrowDownLong,
                                    predictIconColor: percentageChange >= 0 ? Colors.green : Colors.red,
                                    monthlyDifferent: '${incomePercentage.toStringAsFixed(2)}%',
                                    difWithoutCurrency: false,
                                  ),
                                );
                              }, error: (e, stack) {
                                return Center(
                                  child: Text(e.toString()),
                                );
                              }, loading: () {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }),
                            ),
                          ]),
                          ResponsiveGridRow(rowSegments: 120, children: [
                            //------------statics chart--------------
                            ResponsiveGridCol(
                                xs: 120,
                                md: 120,
                                lg: 80,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: IncomeExpenseLineChart(
                                    totalSaleCurrentMonths: totalSaleOfCurrentMonth,
                                    totalSaleLastMonth: totalSaleOfLastMonth,
                                    totalSaleCurrentYear: totalSaleOfCurrentYear,
                                    monthlySale: monthlySale,
                                    dailySale: dailySale,
                                    totalSaleCount: 0.0,
                                    freeUser: 0.0,
                                    totalExpenseCurrentYear: totalExpenseOfCurrentYear,
                                    totalExpenseCurrentMonths: totalExpenseOfCurrentMonth,
                                    totalExpenseLastMonth: totalExpenseOfLastMonth,
                                    monthlyExpense: monthlyExpense,
                                    dailyExpense: dailyExpense,
                                  ),
                                )),
                            //------Dahsbord Stock value----------
                            ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: 40,
                              child: const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: DashboardStockWidget(),
                              ),
                            ),
                            //--------top selling product------------------
                            ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: 40,
                              child: TopReportWidget(
                                transactionReport: transactionReport,
                                purchaseTransactionReport: purchaseTransactionReport,
                                reportType: "TopSelling",
                              ),
                            ),
                            //-----------top customer----------------------------
                            ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: 40,
                              child: TopReportWidget(
                                transactionReport: transactionReport,
                                purchaseTransactionReport: purchaseTransactionReport,
                                reportType: "TopCustomer",
                              ),
                            ),
                            //-----------------top 5 purchasing product-----------------
                            ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: 40,
                              child: TopReportWidget(
                                transactionReport: transactionReport,
                                purchaseTransactionReport: purchaseTransactionReport,
                                reportType: "TopPurchasing",
                              ),
                            ),
                          ]),
                        ],
                      );
                    }, error: (e, stack) {
                      return Center(
                        child: Text(e.toString()),
                      );
                    }, loading: () {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    });
                  }, error: (e, stack) {
                    return Center(
                      child: Text(e.toString()),
                    );
                  }, loading: () {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(8),
                              )),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedActivity02,
                                      color: Colors.black,
                                      size: 24.0,
                                    ),
                                    const SizedBox(width: 8.0),
                                    Flexible(
                                      child: Text(
                                        lang.S.of(context).recentSale,
                                        maxLines: 1,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  screenWidth < 400
                                      ? SizedBox.shrink()
                                      : Text(
                                          totalSaleList.length > 5
                                              ? '${lang.S.of(context).showing} ${recentFive.length} ${lang.S.of(context).OF} ${totalSaleList.length}'
                                              : '${lang.S.of(context).showing} ${totalSaleList.length} ${lang.S.of(context).OF} ${totalSaleList.length}',
                                          style: theme.textTheme.titleSmall,
                                        ),
                                  TextButton(
                                    onPressed: () {
                                      // Navigator.pushNamed(context, SaleList.route);
                                      context.go('/sales/sale-list');
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          lang.S.of(context).viewAll,
                                          //'View All',
                                          style: kTextStyle.copyWith(color: kMainColor),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_right,
                                          color: kMainColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        transactionReport.when(data: (sellerSnap) {
                          shopList = sellerSnap;
                          List<SaleTransactionModel> recentSaleList = shopList.length > 5 ? shopList.sublist(shopList.length - 5) : shopList;
                          recentSaleList = recentSaleList.reversed.toList();
                          totalSaleList = shopList;
                          recentFive = recentSaleList;
                          return Scrollbar(
                            thumbVisibility: true,
                            controller: _horizontalScroll,
                            thickness: 8.0,
                            child: LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                                double kWidth = constraints.maxWidth;
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
                                        minWidth: kWidth,
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
                                          headingRowColor: WidgetStateProperty.all(const Color(0xffF5F5F5)),
                                          showBottomBorder: false,
                                          dividerThickness: 0.0,
                                          headingTextStyle: theme.textTheme.titleMedium,
                                          columns: [
                                            DataColumn(
                                              label: Text(
                                                lang.S.of(context).SL,
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                lang.S.of(context).date,
                                              ),
                                            ),
                                            DataColumn(
                                                label: Text(
                                              lang.S.of(context).invoice,
                                            )),
                                            DataColumn(
                                                label: Flexible(
                                                    child: Text(
                                              lang.S.of(context).partyName,
                                            ))),
                                            DataColumn(
                                                label: Flexible(
                                                    child: Text(
                                              lang.S.of(context).paymentType,
                                            ))),
                                            DataColumn(
                                                label: Text(
                                              lang.S.of(context).amount,
                                            )),
                                            DataColumn(
                                                label: Text(
                                              lang.S.of(context).paid,
                                            )),
                                            DataColumn(
                                                label: Text(
                                              lang.S.of(context).due,
                                            )),
                                            DataColumn(
                                                label: Text(
                                              lang.S.of(context).status,
                                            )),
                                            // DataColumn(
                                            //     label:
                                            //         Text('Action', style: kTextStyle.copyWith(color: kTitleColor, overflow: TextOverflow.ellipsis))),
                                          ],
                                          rows: List.generate(
                                            recentSaleList.reversed.toList().length,
                                            (index) => DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    (index + 1).toString(),
                                                    textAlign: TextAlign.start,
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(dataTypeFormat.format(
                                                    DateTime.parse(
                                                      recentSaleList[index].purchaseDate.toString(),
                                                    ),
                                                  )),
                                                ),
                                                DataCell(
                                                  Text(
                                                    recentSaleList[index].invoiceNumber.toString(),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(recentSaleList[index].customerName.toString()),
                                                ),
                                                DataCell(
                                                  Text(recentSaleList[index].paymentType.toString()),
                                                ),
                                                DataCell(
                                                  Text('$globalCurrency${recentSaleList[index].totalAmount.toString()}'),
                                                ),
                                                DataCell(
                                                  Text('$globalCurrency${((recentSaleList[index].totalAmount!) - (double.parse(recentSaleList[index].dueAmount.toString())))}'),
                                                ),
                                                DataCell(
                                                  Text('$globalCurrency${recentSaleList[index].dueAmount.toString()}'),
                                                ),
                                                DataCell(
                                                  Text(recentSaleList[index].isPaid == true ? lang.S.of(context).paid : lang.S.of(context).unpaid),
                                                ),
                                                // DataCell(
                                                //   PopupMenuButton(
                                                //     icon: const Icon(Icons.more_vert_rounded, size: 18.0),
                                                //     padding: EdgeInsets.zero,
                                                //     itemBuilder: (BuildContext bc) => [
                                                //       PopupMenuItem(
                                                //         child: GestureDetector(
                                                //           onTap: () {
                                                //             // Navigator.push(context, MaterialPageRoute(builder: (context) => const EditParty()));
                                                //           },
                                                //           child: Row(
                                                //             children: [
                                                //               const Icon(IconlyLight.edit_square, size: 18.0, color: kGreyTextColor),
                                                //               const SizedBox(width: 4.0),
                                                //               Text(
                                                //                 'View/Edit',
                                                //                 style: kTextStyle.copyWith(color: kGreyTextColor),
                                                //               ),
                                                //             ],
                                                //           ),
                                                //         ),
                                                //       ),
                                                //     ],
                                                //     onSelected: (value) {
                                                //       Navigator.pushNamed(context, '$value');
                                                //     },
                                                //   ),
                                                // ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }, error: (e, stack) {
                          return Center(
                            child: Text(e.toString()),
                          );
                        }, loading: () {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void getAllTotal() async {
    // ignore: unused_local_variable
    List<ProductModel> productList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Products').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        totalStock = totalStock + (int.tryParse(data['productStock']) ?? 0);
        totalSalePrice = totalSalePrice + (num.parse(data['productSalePrice']) * num.parse(data['productStock']));
        totalParPrice = totalParPrice + (num.parse(data['productPurchasePrice']) * num.parse(data['productStock']));

        // productList.add(ProductModel.fromJson(jsonDecode(jsonEncode(element.value))));
      }
    });
    setState(() {});
  }
}
