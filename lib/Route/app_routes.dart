import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro_admin/Route/shell_route_warpper.dart';
import 'package:salespro_admin/Screen/Authentication/add_profile.dart';
import 'package:salespro_admin/Screen/Authentication/forgot_password.dart';
import 'package:salespro_admin/Screen/Authentication/sign_up.dart';
import 'package:salespro_admin/Screen/Calendar/CalendarDressScreen.dart';
import 'package:salespro_admin/Screen/Category%20List/category_list.dart';
import 'package:salespro_admin/Screen/Customer%20List/add_customer.dart';
import 'package:salespro_admin/Screen/Customer%20List/customer_list.dart';
import 'package:salespro_admin/Screen/Customer%20List/edit_customer.dart';
import 'package:salespro_admin/Screen/Dress/DressScreen.dart';
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
import 'package:salespro_admin/model/income_modle.dart';

import '../Screen/Authentication/log_in.dart';
import '../Screen/Authentication/profile_setup.dart';
import '../Screen/Expenses/expense_edit.dart';
import '../Screen/Expenses/expenses_list.dart';
import '../Screen/HRM/employees/employee_list.dart';
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
import '../model/customer_model.dart';
import '../model/expense_model.dart';
import '../model/personal_information_model.dart';
import '../model/sale_transaction_model.dart';
import 'not_found.dart';

abstract class AcnooAppRoutes {
  static final routerConfig = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return ShellRouteWrapper(
            child: child,
          );
        },
        routes: [
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
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: InventorySales(),
                ),
              ),

              ///---------------------Sales List Route------------------
              GoRoute(
                path: 'sale-list',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: SaleList(),
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

          ///--------------------------Add Customer------------------------
          GoRoute(
            path: '/add-customer',
            builder: (BuildContext context, GoRouterState state) {
              final extra = state.extra as Map<String, dynamic>;
              return AddCustomer(
                typeOfCustomerAdd: extra['typeOfCustomerAdd'] as String,
                listOfPhoneNumber: extra['listOfPhoneNumber'] as List<String>,
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

          ///----------------------------DailyTransactionScreen route-----------
          GoRoute(
            path: '/transaction',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: DailyTransaction(),
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
                  child: EmployeeListScreen(),
                ),
              ),

              ///---------------------Sales List Route------------------
              GoRoute(
                path: 'salaries-list',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: SalariesListScreen(),
                ),
              ),
            ],
          ),
        ],
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
