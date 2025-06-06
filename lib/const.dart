import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:restart_app/restart_app.dart';

import 'Screen/tax rates/tax_model.dart';
import 'model/add_to_cart_model.dart';
import 'model/sale_transaction_model.dart';
import 'model/user_role_model.dart';

///______________DATA____________
String appsName = 'VICTOR GUZMAN FOTOGRAFIA';
String appsTitle = 'VICTOR GUZMAN FOTOGRAFIA';
String pdfFooter = 'PrestaSoft SRL';
String madeBy = 'Prestasoft.do';
bool isDemo = false;
String invoiceFileName = "VICTOR GUZMAN FOTOGRAFIA";
String demoText = 'You Can\'t change anything in demo mode';
String sideBarLogo = 'images/pos.png';
String appLogo = 'images/mobipos.png';
bool isTwillio = true;
bool isUltraMsg = false;
String nameLogo = 'images/sideLogo.png';
String currentDomain = 'https://prestasoft.do';

///____________Purchase_C0de_______________________________________
// String purchaseCode = 'Enter your purchase code';
String purchaseCode = '3e873705-9a73-4a00-81f9-1f2fbef74e66';

String calculateProductVat({required AddToCartModel product}) {
  if (product.taxType == 'Inclusive') {
    //double taxAmount = purchasePrice / (1 + taxRate) * taxRate;
    double taxRate = product.groupTaxRate / 100;
    print(product.groupTaxRate);
    return (((double.tryParse(product.productPurchasePrice.toString()) ?? 0) /
                (taxRate + 1) *
                taxRate) *
            product.quantity)
        .toStringAsFixed(1);
  } else {
    return (((product.groupTaxRate *
                    (double.tryParse(product.productPurchasePrice.toString()) ??
                        0)) /
                100) *
            product.quantity)
        .toStringAsFixed(1);
  }
}

SaleTransactionModel checkLossProfit(
    {required SaleTransactionModel transitionModel}) {
  double calculateAmountFromPercentage(double percentage, double price) {
    return (percentage * price) / 100;
  }

  num totalQuantity = 0;
  double lossProfit = 0;
  double totalPurchasePrice = 0;
  double totalSalePrice = 0;
  for (var element in transitionModel.productList!) {
    if (element.taxType == 'Exclusive') {
      double tax = calculateAmountFromPercentage(
          element.groupTaxRate.toDouble(),
          (double.tryParse(element.productPurchasePrice.toString()) ?? 0));
      totalPurchasePrice = totalPurchasePrice +
          ((((double.tryParse(element.productPurchasePrice.toString()) ?? 0) +
                  tax) *
              element.quantity));
    } else {
      totalPurchasePrice = totalPurchasePrice +
          ((double.tryParse(element.productPurchasePrice.toString()) ?? 0) *
              element.quantity);
    }

    totalSalePrice =
        totalSalePrice + (double.parse(element.subTotal) * element.quantity);

    totalQuantity = totalQuantity + element.quantity;
  }
  lossProfit = ((totalSalePrice - totalPurchasePrice.toDouble()) -
      double.parse(transitionModel.discountAmount.toString()));

  transitionModel.totalQuantity = totalQuantity;
  transitionModel.lossProfit = double.parse(lossProfit.toStringAsFixed(2));

  return transitionModel;
}

List<TaxModel> getAllTaxFromCartList({required List<AddToCartModel> cart}) {
  List<TaxModel> data = [];
  for (var element in cart) {
    if (element.subTaxes.isNotEmpty) {
      for (var element1 in element.subTaxes) {
        if (!data.any(
          (element2) => element2.name == element1.name,
        )) {
          data.add(element1);
        }
      }
    }
  }
  return data;
}

// String appLogo='images/mobipos.png';
// String appsName = 'Pos Saas';
// String appsTitle = 'Pos Saas Web';
// String pdfFooter = 'POSBharat.com';
// bool isDemo = false;
// String demoText = 'You Can\'t change anything in demo mode';
// String sideBarLogo='images/pos.png';

List<String> selectedNumbers = [];

Future<String?> getSaleID({required String id}) async {
  String? key;
  await FirebaseDatabase.instance
      .ref()
      .child('Admin Panel')
      .child('Seller List')
      .orderByKey()
      .get()
      .then((value) async {
    for (var element in value.children) {
      var data = jsonDecode(jsonEncode(element.value));
      if (data['userId'].toString() == id) {
        key = element.key.toString();
      }
    }
  });
  return key;
}

String constUserId = '';
bool isSubUser = false;
String constSubUserTitle = '';

String subUserEmail = '';

String searchItems = '';

String mainLoginPassword = '';
String mainLoginEmail = '';

UserRoleModel finalUserRoleModel =
    UserRoleModel(email: '', userTitle: '', databaseId: '', permissions: []);

Future<void> setUserDataOnLocalData(
    {required String uid,
    required String subUserTitle,
    required bool isSubUser}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userId', uid);
  await prefs.setString('subUserTitle', subUserTitle);
  await prefs.setBool('isSubUser', isSubUser);
}

Future<void> getUserDataFromLocal() async {
  final prefs = await SharedPreferences.getInstance();
  constUserId = prefs.getString('userId') ?? '';
  constSubUserTitle = prefs.getString('subUserTitle') ?? '';
  isSubUser = prefs.getBool('isSubUser') ?? false;
  String? data = prefs.getString("userPermission");
  data != null
      ? finalUserRoleModel = UserRoleModel.fromJson(jsonDecode(data))
      : null;
}

String userPermissionErrorText = 'Access not granted';

Future<bool> checkUserRolePermission({required String type}) async {
  await getUserDataFromLocal();
  bool permission = true;

  if (isSubUser) {
    switch (type) {
      case 'sale':
        permission = finalUserRoleModel.saleView ?? false;
        break;
      case 'salesList':
        permission = finalUserRoleModel.salesListView ?? false;
        break;
      case 'expense':
        permission = finalUserRoleModel.addExpenseView ?? false;
        break;
      case 'due-list':
        permission = finalUserRoleModel.dueListView ?? false;
        break;
      case 'loss-profit':
        permission = finalUserRoleModel.lossProfitView ?? false;
        break;
      case 'parties':
        permission = finalUserRoleModel.partiesView ?? false;
        break;
      case 'product':
        permission = finalUserRoleModel.productView ?? false;
        break;
      case 'purchaseList':
        permission = finalUserRoleModel.purchaseListView ?? false;
        break;
      case 'purchase':
        permission = finalUserRoleModel.purchaseView ?? false;
        break;
      case 'reports':
        permission = finalUserRoleModel.reportsView ?? false;
        break;
      case 'stock-list':
        permission = finalUserRoleModel.stockView ?? false;
        break;
      case 'profileEdit':
        permission = finalUserRoleModel.profileEditView ?? false;
        break;
      default:
        permission = true;
        break;
    }

    if (permission) {
      return permission;
    } else {
      EasyLoading.showError(userPermissionErrorText);
      return permission;
    }
  } else {
    return true;
  }
}

bool checkUserRolePermissionvV2({required String type}) {
  //await getUserDataFromLocal();
  bool permission = true;

  //if (isSubUser) {
  switch (type) {
    case 'sale':
      permission = finalUserRoleModel.saleView ?? false;
      break;
    case 'salesList':
      permission = finalUserRoleModel.salesListView ?? false;
      break;
    case 'expense':
      permission = finalUserRoleModel.addExpenseView ?? false;
      break;
    case 'due-list':
      permission = finalUserRoleModel.dueListView ?? false;
      break;
    case 'loss-profit':
      permission = finalUserRoleModel.lossProfitView ?? false;
      break;
    case 'parties':
      permission = finalUserRoleModel.partiesView ?? false;
      break;
    case 'product':
      permission = finalUserRoleModel.productView ?? false;
      break;
    case 'purchaseList':
      permission = finalUserRoleModel.purchaseListView ?? false;
      break;
    case 'purchase':
      permission = finalUserRoleModel.purchaseView ?? false;
      break;
    case 'reports':
      permission = finalUserRoleModel.reportsView ?? false;
      break;
    case 'stock-list':
      permission = finalUserRoleModel.stockView ?? false;
      break;
    case 'profileEdit':
      permission = finalUserRoleModel.profileEditView ?? false;
      break;
    default:
      permission = true;
      break;
  }

  if (permission) {
    return permission;
  } else {
    EasyLoading.showError(userPermissionErrorText);
    return permission;
  }
  // } else {
  //   return true;
  // }
}

Future<String> getUserID() async {
  final prefs = await SharedPreferences.getInstance();
  final String? uid = prefs.getString('userId');

  return uid ?? '';
}

void putUserDataImidiyate(
    {required String uid, required String title, required bool isSubUse}) {
  constUserId = uid;
  constSubUserTitle = title;
  isSubUser = isSubUse;
}

List<String> categories = [
  'Select Business Category',
  'Bag & Luggage',
  'Books & Stationery',
  'Clothing',
  'Construction & Raw materials',
  'Coffee & Tea',
  'Cosmetic & Jewellery',
  'Computer & Electronic',
  'E-Commerce',
  'Furniture',
  'General Store',
  'Gift, Toys & flowers',
  'Grocery, Fruits & Bakery',
  'Handicraft',
  'Home & Kitchen',
  'Hardware & sanitary',
  'Internet, Dish & TV',
  'Laundry',
  'Manufacturing',
  'Mobile Top up',
  'Motorbike & parts',
  'Mobile & Gadgets',
  'Pharmacy',
  'Poultry & Agro',
  'Pet & Accessories',
  'Rice mill',
  'Super Shop',
  'Sunglasses',
  'Service & Repairing',
  'Sports & Exercise',
  'Shoes',
  'Saloon & Beauty Parlour',
  'Shop Rent & Office Rent',
  'Trading',
  'Travel Ticket & Rental',
  'Thai Aluminium & Glass',
  'Vehicles & Parts',
  'Others',
];
String dropdownValue = 'Select Business Category';

final currentDate = DateTime.now();
final firstDayOfCurrentMonth = DateTime(currentDate.year, currentDate.month, 1);
final firstDayOfCurrentYear = DateTime(currentDate.year, 1, 1);
final firstDayOfPreviousYear =
    firstDayOfCurrentYear.subtract(const Duration(days: 1));
final lastDayOfPreviousMonth =
    firstDayOfCurrentMonth.subtract(const Duration(days: 1));
final firstDayOfPreviousMonth =
    DateTime(lastDayOfPreviousMonth.year, lastDayOfPreviousMonth.month, 1);

DateFormat dataTypeFormat = DateFormat('dd MMM yyyy');

double safeParseDouble(String? value) {
  return double.tryParse(value ?? '0') ?? 0;
}

void checkCurrentUserAndRestartApp() {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user?.uid == null) {
    Restart.restartApp();
  }
}
