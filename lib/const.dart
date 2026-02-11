import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:restart_app/restart_app.dart';

import 'Screen/tax rates/tax_model.dart';
import 'model/add_to_cart_model.dart';
import 'model/sale_transaction_model.dart';
import 'model/user_role_model.dart';
import 'services/api_service.dart';

///______________DATA____________
String appsName = 'VICTOR GUZMAN FOTOGRAFIA';
String appsTitle = 'VICTOR GUZMAN FOTOGRAFIA';
String pdfFooter = 'VICTOR GUZMAN FOTOGRAFIA SRL';
String madeBy = 'Prestasoft.do';

/// USUARIOS SUPER ADMIN PROTEGIDOS
/// Estos usuarios NO pueden ser eliminados ni se pueden modificar sus permisos
/// IDs de usuarios protegidos (Admin principal y Victor Guzman)
const List<String> protectedUserIds = [
  '912f2616-c341-4327-96f3-608d7d53a011', // admin@victorguzmanfotografia.com (Administrador)
  '73fc7cc9-8753-4702-bd1b-cb3a8fa53773', // Victor Guzman@gmail.com (Victor Guzman)
];

/// Emails de usuarios protegidos (para validación adicional)
const List<String> protectedUserEmails = [
  'admin@victorguzmanfotografia.com',
  'Victor Guzman@gmail.com',
];

/// Verifica si un usuario está protegido (no puede ser eliminado ni modificado)
bool isProtectedUser(String? userId, String? email) {
  if (userId != null && protectedUserIds.contains(userId)) {
    return true;
  }
  if (email != null && protectedUserEmails.contains(email)) {
    return true;
  }
  return false;
}
bool isDemo = false;
String invoiceFileName = "VICTOR GUZMAN FOTOGRAFIA";
String demoText = 'You Can\'t change anything in demo mode';
String sideBarLogo = 'images/pos.png';
String appLogo = 'images/mobipos.png';
bool isTwillio = true;
bool isUltraMsg = false;
String nameLogo = 'images/namelogo.svg';
String currentDomain = 'https://prestasoft.do';

///____________Purchase_C0de_______________________________________
// String purchaseCode = 'Enter your purchase code';
String purchaseCode = '3e873705-9a73-4a00-81f9-1f2fbef74e66';

String calculateProductVat({required AddToCartModel product}) {
  if (product.taxType == 'Inclusive') {
    //double taxAmount = purchasePrice / (1 + taxRate) * taxRate;
    double taxRate = product.groupTaxRate / 100;
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

    final subTotalValue = double.tryParse(element.subTotal?.toString() ?? '0') ?? 0.0;
    totalSalePrice =
        totalSalePrice + (subTotalValue * element.quantity);

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

/// Obtiene el ID de venta desde el API PostgreSQL
/// Esta función ahora usa el ApiService en lugar de Firebase
Future<String?> getSaleID({required String id}) async {
  // La función ya no es necesaria con PostgreSQL
  // El servidor maneja los IDs internamente
  // Retornamos el mismo ID ya que PostgreSQL usa UUIDs directamente
  return id;
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

// Future<bool> checkUserRolePermission({required String type}) async {
//   await getUserDataFromLocal();
//   bool permission = true;

//   if (isSubUser) {
//     switch (type) {
//       case 'sale':
//         permission = finalUserRoleModel.saleView ?? false;
//         break;
//       case 'salesList':
//         permission = finalUserRoleModel.salesListView ?? false;
//         break;
//       case 'expense':
//         permission = finalUserRoleModel.addExpenseView ?? false;
//         break;
//       case 'due-list':
//         permission = finalUserRoleModel.dueListView ?? false;
//         break;
//       case 'loss-profit':
//         permission = finalUserRoleModel.lossProfitView ?? false;
//         break;
//       case 'parties':
//         permission = finalUserRoleModel.partiesView ?? false;
//         break;
//       case 'product':
//         permission = finalUserRoleModel.productView ?? false;
//         break;
//       case 'purchaseList':
//         permission = finalUserRoleModel.purchaseListView ?? false;
//         break;
//       case 'purchase':
//         permission = finalUserRoleModel.purchaseView ?? false;
//         break;
//       case 'reports':
//         permission = finalUserRoleModel.reportsView ?? false;
//         break;
//       case 'stock-list':
//         permission = finalUserRoleModel.stockView ?? false;
//         break;
//       case 'profileEdit':
//         permission = finalUserRoleModel.profileEditView ?? false;
//         break;
//       default:
//         permission = true;
//         break;
//     }

//     if (permission) {
//       return permission;
//     } else {
//       EasyLoading.showError(userPermissionErrorText);
//       return permission;
//     }
//   } else {
//     return true;
//   }
// }

bool checkUserRoleViewPermissionV2({
  required String type,
}) {
  final match = finalUserRoleModel.permissions.firstWhere(
    (p) => p.type == type,
    orElse: () => Permission(type: type, view: false),
  );

  return match.view;
}

bool checkUserRoleEditPermissionV2({
  required String type,
}) {
  final match = finalUserRoleModel.permissions.firstWhere(
    (p) => p.type == type,
    orElse: () => Permission(type: type, edit: false),
  );

  return match.edit;
}

bool checkUserRoleDeletePermissionV2({
  required String type,
}) {
  final match = finalUserRoleModel.permissions.firstWhere(
    (p) => p.type == type,
    orElse: () => Permission(type: type, delete: false),
  );

  return match.delete;
}

// bool checkUserRolePermissionvV2({required String type}) {
//   //await getUserDataFromLocal();
//   bool permission = true;

//   //if (isSubUser) {
//   switch (type) {
//     case 'sale':
//       permission = finalUserRoleModel.saleView ?? false;
//       break;
//     case 'salesList':
//       permission = finalUserRoleModel.salesListView ?? false;
//       break;
//     case 'expense':
//       permission = finalUserRoleModel.addExpenseView ?? false;
//       break;
//     case 'due-list':
//       permission = finalUserRoleModel.dueListView ?? false;
//       break;
//     case 'loss-profit':
//       permission = finalUserRoleModel.lossProfitView ?? false;
//       break;
//     case 'parties':
//       permission = finalUserRoleModel.partiesView ?? false;
//       break;
//     case 'product':
//       permission = finalUserRoleModel.productView ?? false;
//       break;
//     case 'purchaseList':
//       permission = finalUserRoleModel.purchaseListView ?? false;
//       break;
//     case 'purchase':
//       permission = finalUserRoleModel.purchaseView ?? false;
//       break;
//     case 'reports':
//       permission = finalUserRoleModel.reportsView ?? false;
//       break;
//     case 'stock-list':
//       permission = finalUserRoleModel.stockView ?? false;
//       break;
//     case 'profileEdit':
//       permission = finalUserRoleModel.profileEditView ?? false;
//       break;
//     default:
//       permission = true;
//       break;
//   }

//   if (permission) {
//     return permission;
//   } else {
//     EasyLoading.showError(userPermissionErrorText);
//     return permission;
//   }
//   // } else {
//   //   return true;
//   // }
// }

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

/// Verifica si el usuario actual está autenticado
/// Ahora usa ApiService en lugar de FirebaseAuth
void checkCurrentUserAndRestartApp() {
  final apiService = ApiService();
  if (!apiService.isAuthenticated) {
    Restart.restartApp();
  }
}

/// VALIDACIÓN DE SEGURIDAD: Verifica si el usuario tiene permiso para operar en la sucursal actual
/// Retorna true si el usuario está autorizado, false si no lo está
///
/// Esta función DEBE llamarse antes de crear:
/// - Facturas (ventas)
/// - Reservaciones
/// - Rentas de vestidos
/// - Cualquier transacción que dependa de la sucursal
///
/// Ejemplo de uso:
/// ```dart
/// if (!validateUserBranchAccess(context)) {
///   return; // No continuar con la operación
/// }
/// // Continuar con la creación de la transacción
/// ```
bool validateUserBranchAccess(BuildContext context, {bool showError = true}) {
  try {
    // Obtener la sucursal actual del localStorage
    final currentBranchId = html.window.localStorage['selected_tenant_id'] ?? '';

    if (currentBranchId.isEmpty) {
      debugPrint('⚠️ [validateUserBranchAccess] No hay sucursal seleccionada en localStorage');
      if (showError) {
        _showBranchAccessError(context, 'No hay sucursal seleccionada. Por favor, seleccione una sucursal.');
      }
      return false;
    }

    // Los admins tienen acceso a todas las sucursales
    if (!isSubUser) {
      debugPrint('✅ [validateUserBranchAccess] Usuario es Admin - Acceso permitido a todas las sucursales');
      return true;
    }

    // Obtener allowed_branches del modelo de usuario
    final allowedBranches = finalUserRoleModel.allowedBranches;

    // Si no hay restricciones definidas (null o vacío), permitir acceso
    // Esto es un fallback para usuarios legacy sin configuración
    if (allowedBranches == null || allowedBranches.isEmpty) {
      debugPrint('⚠️ [validateUserBranchAccess] Usuario sin allowed_branches definido - Permitiendo por compatibilidad');
      return true;
    }

    // Verificar si la sucursal actual está en la lista de sucursales permitidas
    final isAuthorized = allowedBranches.contains(currentBranchId);

    if (isAuthorized) {
      debugPrint('✅ [validateUserBranchAccess] Usuario autorizado para sucursal $currentBranchId');
      debugPrint('   Sucursales permitidas: $allowedBranches');
      return true;
    } else {
      debugPrint('🚫 [validateUserBranchAccess] ACCESO DENEGADO');
      debugPrint('   Usuario: ${finalUserRoleModel.userTitle}');
      debugPrint('   Sucursal actual: $currentBranchId');
      debugPrint('   Sucursales permitidas: $allowedBranches');

      if (showError) {
        final branchNames = _getBranchNames(allowedBranches);
        _showBranchAccessError(
          context,
          'No tiene permisos para realizar operaciones en esta sucursal.\n\n'
          'Sus sucursales autorizadas son: $branchNames\n\n'
          'Por favor, cambie a una sucursal autorizada desde el selector de sucursales.',
        );
      }
      return false;
    }
  } catch (e) {
    debugPrint('❌ [validateUserBranchAccess] Error en validación: $e');
    // En caso de error, permitir por seguridad para no bloquear operaciones
    // pero registrar el error para debugging
    return true;
  }
}

/// Convierte códigos de sucursal a nombres legibles
String _getBranchNames(List<String> branchCodes) {
  final Map<String, String> branchNameMap = {
    'stg': 'Santiago',
    'sde': 'Santo Domingo Este',
    'sdo': 'Santo Domingo Oeste',
    'rom': 'La Romana',
  };

  return branchCodes
      .map((code) => branchNameMap[code] ?? code)
      .join(', ');
}

/// Muestra un diálogo de error cuando el usuario no tiene acceso a la sucursal
void _showBranchAccessError(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Acceso Denegado'),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text('Entendido'),
          ),
        ],
      );
    },
  );
}
