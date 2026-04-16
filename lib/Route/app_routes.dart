import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro_admin/Route/shell_route_warpper.dart';
import 'package:salespro_admin/services/api_service.dart';
import 'package:salespro_admin/const.dart' show isDressOperator, finalUserRoleModel, isSubUser;
import 'package:salespro_admin/Screen/Authentication/add_profile.dart';
import 'package:salespro_admin/Screen/Authentication/forgot_password.dart';
import 'package:salespro_admin/Screen/Authentication/sign_up.dart';
import 'package:salespro_admin/Screen/Tenant/tenant_selector_screen.dart';
import 'package:salespro_admin/Screen/Calendar/CalendarDressScreen.dart';
import 'package:salespro_admin/Screen/Category%20List/category_list.dart';
import 'package:salespro_admin/Screen/Customer%20List/add_customer.dart';
import 'package:salespro_admin/Screen/Customer%20List/customer_list.dart';
import 'package:salespro_admin/Screen/Customer%20List/customer_profile_screen.dart';
import 'package:salespro_admin/Screen/Customer%20List/edit_customer.dart';
import 'package:salespro_admin/Screen/Dress/DressScreen.dart';
import 'package:salespro_admin/Screen/Dress/dress_operator_home_screen.dart';
import 'package:salespro_admin/Screen/Due%20List/due_list_screen.dart';
import 'package:salespro_admin/Screen/Expenses/expense_category.dart';
import 'package:salespro_admin/Screen/Expenses/new_expense.dart';
import 'package:salespro_admin/Screen/HRM/Designation/designation_list.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/salaries_list_screen.dart';
import 'package:salespro_admin/Screen/Income/income_category.dart';
import 'package:salespro_admin/Screen/Income/new_income.dart';
import 'package:salespro_admin/Screen/Inventory%20Sales/inventory_sales.dart';
import 'package:salespro_admin/Screen/POS%20Sale/pos_sale.dart';
import 'package:salespro_admin/Screen/PackageService/RegisterPackageScreen.dart';
import 'package:salespro_admin/Screen/PackageService/ServicePackageScreen.dart';
import 'package:salespro_admin/Screen/Purchase%20List/purchase_list.dart';
import 'package:salespro_admin/Screen/Purchase%20Return/purchase_returns_list.dart';
import 'package:salespro_admin/Screen/Purchase/purchase.dart';
import 'package:salespro_admin/Screen/Reservation/ReservationCalendarScreen.dart';
import 'package:salespro_admin/Screen/Reservation/aditional_clothes_reservation_screen.dart';
import 'package:salespro_admin/Screen/Reservation/clothes_reservation_screen.dart';
import 'package:salespro_admin/Screen/Reservation/package_list_screen.dart';
import 'package:salespro_admin/Screen/Sale%20List/sale_edit.dart';
import 'package:salespro_admin/Screen/Sale%20List/sale_list.dart';
import 'package:salespro_admin/Screen/Sales%20Return/sales_returns_list.dart';
import 'package:salespro_admin/Screen/User%20Role%20System/user_role_screen.dart';
import 'package:salespro_admin/Screen/Whatsapp%20Marketing/whatsapp_marketing_screen.dart';
import 'package:salespro_admin/Screen/quatation_screen/quatation_screen.dart';
import 'package:salespro_admin/Screen/Confirmation/sale_confirmations_list.dart';
import 'package:salespro_admin/Screen/Audit/audit_screen.dart';
import 'package:salespro_admin/Screen/Deleted%20Items/deleted_items_screen.dart';
import 'package:salespro_admin/model/income_modle.dart';
import 'package:salespro_admin/Screen/Bank/bank_list.dart';

import '../Screen/Authentication/log_in.dart';
import '../Screen/Authentication/profile_setup.dart';
import '../Screen/Expenses/expense_edit.dart';
import '../Screen/Expenses/expenses_list.dart';
import '../Screen/HRM/employees/employee_list_v2.dart';
import '../Screen/HRM/attendance/attendance_screen.dart';
import '../Screen/HRM/vacations/vacations_screen.dart';
import '../Screen/HRM/loans/loans_screen.dart';
import '../Screen/HRM/prestaciones/prestaciones_screen.dart';
import '../Screen/HRM/tss_reports/tss_reports_screen.dart';
import '../Screen/HRM/birthdays/employee_birthdays_screen.dart';
import '../Screen/HRM/Rentability/rentability_dashboard.dart';
import '../Screen/HRM/Rentability/pending_invoices_screen.dart';
import '../Screen/HRM/hrm_dashboard.dart';
import '../Screen/HRM/assignments/today_assignments_screen.dart';
import '../Screen/HRM/assignments/efficiency_reports_screen.dart';
import '../Screen/HRM/assignments/department_status_screen.dart';
import '../Screen/Home/home_screen.dart';
import '../Screen/Income/income_Edit.dart';
import '../Screen/Income/income_list.dart';
import '../Screen/Ledger Screen/ledger_screen.dart';
import '../Screen/LossProfit/lossProfit_screen.dart';
import '../Screen/POS Sale/show_sale_payment_popup.dart';
import '../Screen/Product/WarebasedProduct.dart';
import '../Screen/Product/add_product.dart';
import '../Screen/Product/edit_product.dart';
import '../Screen/Product/product barcode/barcode_generate.dart';
import '../Screen/Product/product.dart';
import '../Screen/Purchase List/purchase_edit.dart';
import '../Screen/Purchase Return/purchase_return_screen.dart';
import '../Screen/Quotation List/quotation_list.dart';
import '../Screen/Reports/current_stock_widget.dart';
import '../Screen/Reports/daily_transaction.dart';
import '../Screen/Daily Transaction Dashboard/daily_transaction_dashboard.dart';
import '../Screen/Reports/report_screen.dart';
import '../Screen/Sales Return/sales_return_screen.dart';
import '../Screen/Subscription/purchase_plan.dart';
import '../Screen/Subscription/subscription_plan_page.dart';
import '../Screen/Supplier List/supplier_list.dart';
import '../Screen/WareHouse/ware_house_list.dart';
import '../Screen/WareHouse/warehouse_details.dart';
import '../Screen/Widgets/Pop UP/Purchase/purchase_payment_popup.dart';
import '../Screen/tax rates/tax_model.dart';
import '../Screen/tax rates/tax_rate_screen.dart';
import '../Screen/Equipments/areas_equipments_screen.dart';
import '../Screen/Branch Settings/branch_settings_screen.dart';
import '../model/customer_model.dart';
import '../model/expense_model.dart';
import '../model/personal_information_model.dart';
import '../model/sale_transaction_model.dart';
import 'not_found.dart';
import 'package:salespro_admin/Screen/blank_home.dart';
import 'package:salespro_admin/Screen/Photo%20Invoice/photo_invoice_screen_v2.dart';
import 'package:salespro_admin/Screen/Photo%20Invoice/photo_sales_list_screen.dart';
import 'package:salespro_admin/Screen/Photo%20Invoice/photo_products_services_screen.dart';
import 'package:salespro_admin/Screen/Photo%20Invoice/photo_product_service_types_screen.dart';
import 'package:salespro_admin/test_invoice_generation.dart';
import 'package:salespro_admin/Screen/Admin/database_cleanup_screen.dart';
import 'package:salespro_admin/Screen/Admin/database_migration_screen.dart';
import 'package:salespro_admin/Screen/test_supabase_login.dart';
import 'package:salespro_admin/Screen/Transfer%20Verifications/transfer_verifications_screen.dart';
import 'package:salespro_admin/Screen/DGII/dgii_screen.dart';
import 'package:salespro_admin/Screen/Invoice%20Corrections/invoice_corrections_screen.dart';
abstract class AcnooAppRoutes {
  // Instancia global de ApiService para verificar autenticación
  static final ApiService _apiService = ApiService();

  /// Obtiene el permiso requerido para una ruta específica
  /// Retorna null si la ruta no requiere permiso especial (rutas públicas/generales)
  static String? _getRequiredPermissionForRoute(String path) {
    // Mapeo de rutas a permisos requeridos
    // Ventas
    if (path.startsWith('/sales/inventory-sales') || path == '/inventory-sales') return 'inventory_sales';
    if (path.startsWith('/sales/sale-list')) return 'sales_list';
    if (path.startsWith('/sales/sales-return')) return 'sales_return';
    if (path.startsWith('/sales/quotation')) return 'quotation_list';
    if (path.startsWith('/sales/pos-sales') || path == '/pos-sales') return 'pos_sales';
    if (path.startsWith('/sales')) return 'sales';

    // Compras
    if (path.startsWith('/purchase/pos-purchase')) return 'pos_purchase';
    if (path.startsWith('/purchase/purchase-list')) return 'purchase_list';
    if (path.startsWith('/purchase/purchase-return')) return 'purchase_return';
    if (path.startsWith('/purchase')) return 'purchases';

    // Servicios y Paquetes
    if (path.startsWith('/service-package/register-package')) return 'register_package';
    if (path.startsWith('/service-package/dresses')) return 'register_clothing';
    if (path.startsWith('/service-package')) return 'services';

    // Reservas
    if (path.startsWith('/reservations/rent-clothes')) return 'rent_clothing';
    if (path.startsWith('/reservations/list')) return 'reserve_package';
    if (path.startsWith('/reservations/calendario') || path == '/calendario-reservas') return 'reservation_calendar';
    if (path.startsWith('/reservations')) return 'reservations';

    // Finanzas
    if (path.startsWith('/expense')) return 'expense';
    if (path.startsWith('/income')) return 'income';
    if (path.startsWith('/due-list')) return 'dues';
    if (path.startsWith('/ledger')) return 'ledger';
    if (path.startsWith('/loss-profit')) return 'loss_profit';
    if (path.startsWith('/bank')) return 'banks';
    if (path.startsWith('/transfer')) return 'transfers';

    // Inventario
    if (path.startsWith('/product')) return 'products';
    if (path.startsWith('/category')) return 'categories';
    if (path.startsWith('/warehouse')) return 'warehouses';
    if (path.startsWith('/stock-list') || path.startsWith('/equipment-stock')) return 'inventory_list';

    // Contactos
    if (path.startsWith('/customer')) return 'customers';
    if (path.startsWith('/supplier')) return 'suppliers';

    // Reportes y Auditoría
    if (path.startsWith('/reports')) return 'reports';
    if (path.startsWith('/dgii')) return 'reports';
    if (path.startsWith('/audit')) return 'audit';
    if (path.startsWith('/deleted-items')) return 'audit';

    // HRM
    if (path.startsWith('/hrm/employee')) return 'employees';
    if (path.startsWith('/hrm/designation')) return 'designations';
    if (path.startsWith('/hrm/salaries')) return 'salary_list';
    if (path.startsWith('/hrm/attendance')) return 'attendance';
    if (path.startsWith('/hrm/vacations')) return 'vacations';
    if (path.startsWith('/hrm/loans')) return 'loans';
    if (path.startsWith('/hrm/prestaciones')) return 'prestaciones';
    if (path.startsWith('/hrm/tss')) return 'tss_reports';
    if (path.startsWith('/hrm/birthdays')) return 'birthdays';
    if (path.startsWith('/hrm/rentability')) return 'rentability';
    if (path.startsWith('/hrm')) return 'hrm';

    // Configuración
    if (path.startsWith('/user-role')) return 'user_roles';
    if (path.startsWith('/tax-rate')) return 'tax_rates';

    // Confirmaciones
    if (path.startsWith('/sale-confirmations')) return 'confirmations';

    // Photo Invoice (usa permiso de inventory_sales)
    if (path.startsWith('/photo-invoice') || path.startsWith('/sales/photo')) return 'inventory_sales';

    // Rutas que no requieren permiso especial (dashboard, home, etc.)
    return null;
  }

  static final routerConfig = GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      // Verificar autenticación del usuario usando ApiService (PostgreSQL)
      final isAuthenticated = _apiService.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/' ||
                         state.matchedLocation == '/log-in' ||
                         state.matchedLocation == '/sign-up' ||
                         state.matchedLocation == '/forgot-password' ||
                         state.matchedLocation == '/profile-setup' ||
                         state.matchedLocation == '/subscription' ||
                         state.matchedLocation == '/select-branch' ||
                         state.matchedLocation == '/test-supabase' ||
                         state.matchedLocation == '/blank-home' ||
                         state.matchedLocation == '/dress-operator-home';

      // Si NO está autenticado y NO está en una página de login, redirigir a login
      if (!isAuthenticated && !isLoggingIn) {
        return '/';
      }

      // Si está autenticado y está en la página de login, redirigir a dashboard
      if (isAuthenticated && state.matchedLocation == '/') {
        return '/dashboard';
      }

      // PROTECCIÓN: Usuarios dress_operator solo pueden acceder a rutas específicas
      if (isAuthenticated && isDressOperator()) {
        final currentPath = state.matchedLocation;
        // Rutas permitidas para dress_operator
        final allowedPaths = [
          '/dress-operator-home',
          '/service-package/dresses',  // Estado de Vestimentas
          '/calendario-reservas',       // Disponibilidad de Vestimentas
        ];

        // Si intenta acceder a cualquier otra ruta, redirigir a su home
        if (!allowedPaths.any((path) => currentPath.startsWith(path))) {
          return '/dress-operator-home';
        }
      }

      // PROTECCIÓN POR PERMISOS: Verificar si el usuario tiene permisos definidos
      // y si tiene acceso a la ruta solicitada
      if (isAuthenticated && !isDressOperator()) {
        final hasDefinedPermissions = finalUserRoleModel.permissions.isNotEmpty &&
            finalUserRoleModel.permissions.any((p) => p.view || p.edit || p.delete);

        // Solo aplicar restricciones si el usuario tiene permisos definidos
        if (hasDefinedPermissions || isSubUser) {
          final currentPath = state.matchedLocation;
          final requiredPermission = _getRequiredPermissionForRoute(currentPath);

          if (requiredPermission != null) {
            final canAccess = finalUserRoleModel.canView(requiredPermission);
            if (!canAccess) {
              // Redirigir a blank-home si no tiene permiso
              return '/blank-home';
            }
          }
        }
      }

      // Permitir navegación normal
      return null;
    },
    routes: [
      // Ruta para BlankHome (ahora dentro del ShellRoute para mostrar menú y barra)
      ShellRoute(
        builder: (context, state, child) {
          return ShellRouteWrapper(
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/blank-home',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: BlankHome(),
            ),
          ),
          // Limpieza de base de datos (TEMPORAL)
          GoRoute(
            path: '/database-cleanup',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: DatabaseCleanupScreen(),
            ),
          ),
          // Migración de base de datos a API propia
          GoRoute(
            path: '/database-migration',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: DatabaseMigrationScreen(),
            ),
          ),
                    // ...existing code...
          ///-----------------------DashBoard Route---------------------------
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: MtHomeScreen(),
            ),
          ),

              GoRoute(
            path: '/calendario-reservas',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: CalendarDressScreen(),
            ),
          ),



          GoRoute(
            path: '/reservations',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: ServicePackageScreen(),
            ),
            routes: [
              GoRoute(
                path: 'rent-clothes', // SOLO 'list' (NO '/reservations-list')
                builder: (context, state) => const ClothesReservationScreen(),
              ),
              GoRoute(
                path: 'list', // SOLO 'list' (NO '/reservations-list')
                builder: (context, state) => const PackageListScreen(),
              ),
              GoRoute(
                path: 'list2', // SOLO 'list' (NO '/reservations-list')
                builder: (context, state) => const AdditionalClothesReservationScreen(),
              ),
              GoRoute(
                path: 'calendario',
                builder: (context, state) => const ReservationCalendarScreen(),
              ),
            ],
          ),




          GoRoute(
            path: '/service-package', // Ruta principal para Paquete de Servicio
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: ServicePackageScreen(), // Pantalla principal del Paquete
            ),
            routes: [
              GoRoute(
                path: 'register-package',
                builder: (context, state) => const ServicePackageList(), // Pantalla de registro
              ),
              GoRoute(
                path: 'dresses',
                builder: (context, state) => const DressScreen(), // Pantalla de registro
              ),
            ],
          ),

          // ///---------update profile--------------------------
          // GoRoute(
          //   path: '/profile-update',
          //   name: 'profile-update',
          //   builder: (context, state) {
          //     final details = state.extra as PersonalInformationModel;
          //     return ProfileUpdate(personalInformationModel: details);
          //   },
          // ),

          ///-----------------------------Sales Route------------------------
          GoRoute(
            path: '/sales',
            redirect: (context, state) async {
              if (state.fullPath == '/sales') {
                return '/sales/pos-sales';
              }
              return null;
            },
            routes: [

              GoRoute(
                path: 'pos-sales',
                builder: (context, state) {
                  // Check if state.extra is null
                  if (state.extra == null || state.extra is! SaleTransactionModel) {
                    // Handle the error case
                    return PosSale();
                  }
                  // Safely cast state.extra to SaleTransactionModel
                  final quotation = state.extra as SaleTransactionModel;
                  return PosSale(quotation: quotation);
                },
              ),

              ///----------------------payment popup------------------------
              GoRoute(
                path: 'show-payment-popup',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final transitionModel = extra['transitionModel'];
                  final isFromQuotation = extra['isFromQuotation'] ?? false;

                  return ShowPaymentPopUp(
                    transitionModel: transitionModel,
                    isFromQuotation: isFromQuotation,
                  );
                },
              ),

              ///-----------------Inventory Sales Route---------------------
              GoRoute(
                path: 'inventory-sales',
                pageBuilder: (context, state) {
                  // Extraer el reservationId si viene como parámetro extra
                  final extra = state.extra as Map<String, dynamic>?;
                  final reservationId = extra?['reservationId'] as String?;

                  return NoTransitionPage<void>(
                    child: InventorySales(reservationId: reservationId),
                  );
                },
              ),

              ///---------------------Sales List Route------------------
              GoRoute(
                path: 'sale-list',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: SaleList(),
                ),
              ),

              ///---------------------Photo Invoice Route--------------------------
              GoRoute(
                path: 'photo-invoice',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: PhotoInvoiceScreenV2(),
                ),
              ),
              
              ///---------------------Photo Sales List Route--------------------------
              GoRoute(
                path: 'photo-sales-list',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: PhotoSalesListScreen(),
                ),
              ),
              
              ///---------------------Photo Products Services Route--------------------------
              GoRoute(
                path: 'photo-products-services',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: PhotoProductsServicesScreen(),
                ),
              ),
              
              ///---------------------Photo Product Service Types Route--------------------------
              GoRoute(
                path: 'photo-product-service-types',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: PhotoProductServiceTypesScreen(),
                ),
              ),
              
              ///---------------------Test Invoice Route--------------------------
              GoRoute(
                path: 'test-invoice',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: TestInvoiceGeneration(),
                ),
              ),
              
              ///---------------------Sales Return Route--------------------------
              GoRoute(
                path: 'sales-return-list',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: SalesReturn(),
                ),
              ),

              GoRoute(
                path: 'sales-return',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?; // Extract passed data
                  return SalesReturnScreen(
                    personalInformationModel: extra?['personalInformationModel'],
                    saleTransactionModel: extra?['saleTransactionModel'],
                  );
                },
              ),

              GoRoute(
                path: '/sales-edit',
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as SaleEdit;
                  return SaleEdit(
                    transitionModel: args.transitionModel,
                    personalInformationModel: args.personalInformationModel,
                    isPosScreen: args.isPosScreen,
                    popUpContext: context,
                  );
                },
              ),

              ///-------------------------Quotation Route---------------------
              GoRoute(
                  path: 'quotation-list',
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                        child: QuotationList(),
                      ),
                  routes: [
                    ///-----------------Quotation screen------------------
                    GoRoute(
                      path: 'quotation-screen',
                      pageBuilder: (context, state) => const NoTransitionPage<void>(
                        child: QuotationScreen(),
                      ),
                    ),
                  ]),
            ],
          ),

          ///----------------------purchase route---------------------------
          GoRoute(
            path: '/purchase',
            redirect: (context, state) async {
              if (state.fullPath == '/purchase') {
                return '/purchase/pos-purchase';
              }
              return null;
            },
            routes: [
              ///----------------Pos Purchase Route------------------------------
              GoRoute(
                path: 'pos-purchase',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: Purchase(),
                ),
              ),

              ///----------------------purchase payments-------------------
              GoRoute(
                path: 'purchase-payment-popup',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};

                  return PurchaseShowPaymentPopUp(
                    transitionModel: extra['transitionModel'],
                  );
                },
              ),

              ///---------------------Purchase List Route------------------
              GoRoute(
                path: 'purchase-list',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: PurchaseList(),
                ),
              ),

              ///---------------------Purchase Return Route--------------------------
              GoRoute(
                path: 'purchase-return',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: PurchaseReturn(),
                ),
              ),

              ///---------------------purchase edit------------------
              GoRoute(
                path: 'purchase-edit',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};

                  return PurchaseEdit(
                    personalInformationModel: extra['personalInformationModel'],
                    isPosScreen: extra['isPosScreen'] ?? false,
                    purchaseTransitionModel: extra['purchaseTransitionModel'],
                    popupContext: extra['popupContext'],
                  );
                },
              ),

              ///-----------------------purchase return-------------------
              GoRoute(
                path: '/purchase-returns',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return PurchaseReturnScreen(
                    purchaseTransactionModel: extra['purchaseTransactionModel'],
                    personalInformationModel: extra['personalInformationModel'],
                  );
                },
              ),
            ],
          ),

          ///--------------------------Category------------------------
          GoRoute(
            path: '/category-list',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: CategoryList(),
            ),
          ),

          ///----------------------Product------------------------------------
          GoRoute(
              path: '/product',
              pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: Product(),
                  ),
              routes: [
                ///----------------------add product-------------------
                GoRoute(
                  path: 'add-product',
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;

                    return AddProduct(
                      allProductsCodeList: extra?['allProductsCodeList'] ?? [],
                      warehouseBasedProductModel: (extra?['warehouseBasedProductModel'] as List<dynamic>?)?.map((e) => e as WarehouseBasedProductModel).toList() ?? [],
                    );
                  },
                ),

                ///--------------edit product----------------------------------
                GoRoute(
                  path: 'edit-product',
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    return EditProduct(
                      productModel: extra?['productModel'], // Pass productModel as is
                      allProductsNameList: extra?['allProductsNameList'] ?? [],
                      groupTaxModel: (extra?['groupTaxModel'] as List<dynamic>?)
                              ?.map((e) => e as GroupTaxModel) // Ensure correct type conversion
                              .toList() ??
                          [],
                    );
                  },
                ),
                ///----------------barcode-generator----------------------------
                GoRoute(
                    path: 'barcode-generator',
                    pageBuilder: (context, state) => const NoTransitionPage<void>(
                          child: BarcodeGenerate(),
                ))
              ]),

          ///--------------------Ware house Route----------------------------
          GoRoute(
            path: '/warehouse-list',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: WareHouseList(),
            ),
          ),

          ///-----------------------Supplier List----------------------------
          GoRoute(
            path: '/supplier-list',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: SupplierList(),
            ),
          ),

          ///--------------------------Customer List------------------------
          GoRoute(
            path: '/customer-list',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: CustomerList(),
            ),
          ),

          ///--------------------------Customer Profile------------------------
          GoRoute(
            path: '/customer-profile/:id',
            builder: (context, state) {
              final customerId = state.pathParameters['id'] ?? '';
              final extra = state.extra as Map<String, dynamic>?;
              final customerName = extra?['customerName'] as String?;
              return CustomerProfileScreen(
                customerId: customerId,
                customerName: customerName,
              );
            },
          ),

          ///--------------------------Add Customer------------------------
          GoRoute(
            path: '/add-customer',
            builder: (BuildContext context, GoRouterState state) {
              final extra = state.extra as Map<String, dynamic>;
              return AddCustomer(
                typeOfCustomerAdd: extra['typeOfCustomerAdd'] as String,
                listOfPhoneNumber: extra['listOfPhoneNumber'] as List<String>,
                listOfCedulas: extra['listOfCedulas'] as List<String>? ?? [],
              );
            },
          ),

          ///---------------edit customer---------------------------
          GoRoute(
            path: '/edit-customer',
            builder: (context, state) {
              // Extract the data from the `extra` parameter
              final extra = state.extra as Map<String, dynamic>;
              final customerModel = extra['customerModel'] as CustomerModel;
              final allPreviousCustomer = extra['allPreviousCustomer'] as List<CustomerModel>;
              final typeOfCustomerAdd = extra['typeOfCustomerAdd'] as String;

              return EditCustomer(
                allPreviousCustomer: allPreviousCustomer,
                customerModel: customerModel,
                typeOfCustomerAdd: typeOfCustomerAdd,
              );
            },
          ),

          ///------------------warehouse details----------------------------
          GoRoute(
            path: '/warehouse-details/:id',
            builder: (context, state) {
              final String warehouseID = state.pathParameters['id']!;
              final String warehouseName = state.extra as String;
              return WareHouseDetails(warehouseID: warehouseID, warehouseName: warehouseName);
            },
          ),

          ///-----------------------Due List Route--------------------------
          GoRoute(
            path: '/due-list',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: DueList(),
            ),
          ),

          ///-----------------------Transfer Verifications Route--------------------------
          GoRoute(
            path: '/transfer-verifications',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: TransferVerificationsScreen(),
            ),
          ),

          ///-----------------------DGII - Comprobantes Fiscales Route--------------------------
          GoRoute(
            path: '/dgii',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: DgiiScreen(),
            ),
          ),

          ///-----------------------Invoice Corrections Route--------------------------
          GoRoute(
            path: '/invoice-corrections',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: InvoiceCorrectionsScreen(),
            ),
          ),

          ///------------------Ledger----------------------------------------
          GoRoute(
            path: '/ledger',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: LedgerScreen(),
            ),
          ),

          ///---------------------Loss Profit Route-----------------------------
          GoRoute(
            path: '/loss-profit',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: LossProfitScreen(),
            ),
          ),

          ///--------------------------Expense Route----------------------------
          GoRoute(
              path: '/expense',
              pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: ExpensesList(),
                  ),
              routes: [
                ///---------------------------------New Expense Route-------
                GoRoute(
                  path: 'new-expense',
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: NewExpense(),
                  ),
                ),

                ///-----------------expense category--------------------------
                GoRoute(
                  path: 'expense-category',
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: ExpenseCategory(),
                  ),
                ),

                GoRoute(
                  path: 'edit-expense',
                  pageBuilder: (context, state) {
                    final expenseModel = state.extra as ExpenseModel; // Assuming you pass the data as extra
                    return NoTransitionPage<void>(
                      child: ExpenseEdit(
                        expenseModel: expenseModel,
                        // menuContext: bc,
                      ),
                    );
                  },
                )
              ]),

          ///---------------------------Income Route----------------------------
          GoRoute(
              path: '/income',
              pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: IncomeList(),
                  ),
              routes: [
                ///---------------------------------New Expense Route-------
                GoRoute(
                  path: 'new-income',
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: NewIncome(),
                  ),
                ),
                GoRoute(
                  path: 'income-category',
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: IncomeCategory(),
                  ),
                ),
                GoRoute(
                  path: 'edit-income',
                  pageBuilder: (context, state) {
                    final incomeModel = state.extra as IncomeModel; // Assuming you pass the data as extra
                    return NoTransitionPage<void>(
                      child: IncomeEdit(
                        incomeModel: incomeModel,
                        // menuContext: bc,
                      ),
                    );
                  },
                )
              ]),

          ///---------------------------Bank Route----------------------------
          GoRoute(
            path: '/bank/bank-list',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: BankList(),
            ),
          ),

          ///----------------------------DailyTransactionScreen route-----------
          GoRoute(
            path: '/transaction',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: DailyTransaction(),
            ),
          ),

          ///----------------------------DailyTransactionDashboard route-----------
          GoRoute(
            path: '/transaction-dashboard',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: DailyTransactionDashboard(),
            ),
          ),

          ///----------------Report Route----------------------------------
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: SaleReports(),
            ),
          ),

          ///---------------------Stock List------------------------------------
          GoRoute(
            path: '/stock-list',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: CurrentStockWidget(),
            ),
          ),

          //---------------------Equipment Stock List------------------------------------
          GoRoute(
            path: '/equipment-stock-list',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: AreasEquipmentsScreen(),
            ),
          ),

          //---------------------Confirmation List------------------------------------
          GoRoute(
            path: '/sale-confirmations',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: SaleConfirmationsScreen(),
            ),
          ),
          
          //---------------------Photo Invoice Route------------------------------------
          GoRoute(
            path: '/photo-invoice',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: PhotoInvoiceScreenV2(),
            ),
          ),

          ///---------------------Audit Route------------------------------------
          GoRoute(
            path: '/audit',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: AuditScreen(),
            ),
          ),

          ///---------------------Deleted Items Route------------------------------------
          GoRoute(
            path: '/deleted-items',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: DeletedItemsScreen(),
            ),
          ),

          ///----------------------whatsapp marketing-------------------------
          GoRoute(
            path: '/whatsapp-marketing',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: WhatsappMarketingScreen(),
            ),
          ),

          ///------------------------SubscriptionPage Route---------------------
          GoRoute(
              path: '/subscription',
              pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: SubscriptionPage(),
                  ),
              routes: [
                GoRoute(
                  path: 'purchase-plan',
                  builder: (context, state) {
                    final args = state.extra as Map<String, dynamic>? ??
                        {
                          'initialSelectedPackage': 'defaultPackage', // Provide a default value
                          'initPackageValue': 0, // Provide a default value
                        };
                    return PurchasePlan(
                      initialSelectedPackage: args['initialSelectedPackage'],
                      initPackageValue: args['initPackageValue'],
                    );
                  },
                ),
              ]),

          ///-----------------User Role Screen----------------------------------
          GoRoute(
            path: '/user-role',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: UserRoleScreen(),
            ),
          ),

          ///-----------------Branch Settings Screen----------------------------------
          GoRoute(
            path: '/branch-settings',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: BranchSettingsScreen(),
            ),
          ),

          ///------------------------TaxRates---------------------
          GoRoute(
            path: '/tax-rates',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: TaxRates(),
            ),
          ),
          // ///-----------------User Role Screen----------------------------------
          // GoRoute(
          //   path: UserRoleScreen.route,
          //   pageBuilder: (context, state) => const NoTransitionPage<void>(
          //     child: UserRoleScreen(),
          //   ),
          // ),
          ///------------------------Hrm Route----------------------------------
          GoRoute(
            path: '/hrm',
            redirect: (context, state) async {
              if (state.fullPath == '/hrm') {
                return '/hrm/designation-list';
              }
              return null;
            },
            routes: [
              ///----------------Designation Route------------------------------
              GoRoute(
                path: 'designation-list',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: DesignationListScreen(),
                ),
              ),

              ///-----------------Employee Route---------------------
              GoRoute(
                path: 'employee',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: EmployeeListV2Screen(),
                ),
              ),

              ///---------------------Sales List Route------------------
              GoRoute(
                path: 'salaries-list',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: SalariesListScreen(),
                ),
              ),

              ///---------------------Attendance Route------------------
              GoRoute(
                path: 'attendance',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: AttendanceScreen(),
                ),
              ),

              ///---------------------Vacations Route------------------
              GoRoute(
                path: 'vacations',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: VacationsScreen(),
                ),
              ),

              ///---------------------Loans Route------------------
              GoRoute(
                path: 'loans',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: LoansScreen(),
                ),
              ),

              ///---------------------Prestaciones Route------------------
              GoRoute(
                path: 'prestaciones',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: PrestacionesScreen(),
                ),
              ),

              ///---------------------TSS Reports Route------------------
              GoRoute(
                path: 'tss-reports',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: TSSReportsScreen(),
                ),
              ),

              ///---------------------Birthdays Route------------------
              GoRoute(
                path: 'birthdays',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: EmployeeBirthdaysScreen(),
                ),
              ),

              ///---------------------Assignments Route------------------
              GoRoute(
                path: 'today-assignments',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: TodayAssignmentsScreen(),
                ),
              ),

              ///---------------------Department Status Route------------------
              GoRoute(
                path: 'department-status',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: DepartmentStatusScreen(),
                ),
              ),

              ///---------------------Efficiency Reports Route------------------
              GoRoute(
                path: 'efficiency-reports',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: EfficiencyReportsScreen(),
                ),
              ),

              ///---------------------Rentability Route------------------
              GoRoute(
                path: 'rentability',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: RentabilityDashboardScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'pending-invoices',
                    pageBuilder: (context, state) => const NoTransitionPage<void>(
                      child: PendingInvoicesScreen(),
                    ),
                  ),
                ],
              ),

              ///---------------------HRM Dashboard Route------------------
              GoRoute(
                path: 'dashboard',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: HRMDashboardScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      // Pantalla de inicio para Operador de Vestimentas (rol dress_operator)
      // FUERA del ShellRoute para que NO muestre sidebar ni header
      GoRoute(
        path: '/dress-operator-home',
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: DressOperatorHomeScreen(),
        ),
      ),
      /// Ruta para selector de sucursal (multi-tenant)
      GoRoute(
        path: TenantSelectorScreen.route,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: TenantSelectorScreen(),
        ),
      ),
      // Test Supabase (TEMPORAL - para probar conexión)
      GoRoute(
        path: '/test-supabase',
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: TestSupabaseLogin(),
        ),
      ),
      GoRoute(
        path: EmailLogIn.route,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: EmailLogIn(),
        ),
      ),
      GoRoute(path: SignUp.route, pageBuilder: (context, state) => const NoTransitionPage<void>(child: SignUp())),
      GoRoute(path: ForgotPassword.route, pageBuilder: (context, state) => const NoTransitionPage<void>(child: ForgotPassword())),
      GoRoute(path: ProfileAdd.route, pageBuilder: (context, state) => const NoTransitionPage<void>(child: ProfileAdd())),
      GoRoute(
        path: '/profile-update',
        name: 'profile-update',
        builder: (context, state) {
          final details = state.extra;
          if (details is! PersonalInformationModel) {
            // Optionally, navigate back or show an error widget
            return const Placeholder();
          }
          return ProfileUpdate(personalInformationModel: details);
        },
      ),
    ],
    errorPageBuilder: (context, state) => const NoTransitionPage(
      child: NotFoundView(),
    ),
  );
}
