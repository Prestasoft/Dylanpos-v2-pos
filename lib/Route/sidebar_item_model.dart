import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../model/user_role_model.dart';

class SidebarItemModel {
  final String name;
  final String iconPath;
  final SidebarItemType sidebarItemType;
  final List<SidebarSubmenuModel>? submenus;
  final String? navigationPath;
  final bool isPage;
  final String type;

  SidebarItemModel({
    required this.name,
    required this.iconPath,
    this.sidebarItemType = SidebarItemType.tile,
    this.submenus,
    this.navigationPath,
    this.isPage = false,
    required this.type,
  }) : assert(
          sidebarItemType != SidebarItemType.submenu ||
              (submenus != null && submenus.isNotEmpty),
          'Sub menus cannot be null or empty if the item type is submenu',
        );
}

class SidebarSubmenuModel {
  final String name;
  final String? navigationPath;
  final bool isPage;
  final String type;

  SidebarSubmenuModel({
    required this.name,
    this.navigationPath,
    this.isPage = false,
    required this.type,
  });
}

class GroupedMenuModel {
  final String name;
  final List<SidebarItemModel> menus;

  GroupedMenuModel({
    required this.name,
    required this.menus,
  });
}

enum SidebarItemType { tile, submenu }

// List<SidebarItemModel> get topMenus {
//   return <SidebarItemModel>[
//     SidebarItemModel(
//       name: lang.S.current.dashBoard,
//       iconPath: 'images/dashboard_icon/dashboard.svg',
//       type: "dashboard",
//       navigationPath: '/dashboard',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       name: 'Servicios', // Nombre del paquete
//       iconPath:
//           'images/dashboard_icon/dashboard.svg', // Icono para la sección del paquete
//       sidebarItemType:
//           SidebarItemType.submenu, // Esto indica que tendrá submenús
//       type: "servicios",
//       navigationPath:
//           '/service-package', // Ruta principal para el paquete (corregido)
//       submenus: [
//         SidebarSubmenuModel(
//           name: 'Registrar Paquete', // Submenú para registrar un nuevo paquete
//           type: "",
//           navigationPath:
//               '/register-package', // Ruta para registrar el paquete (corregido)
//         ),
//         SidebarSubmenuModel(
//           name:
//               'Registrar Vestimenta', // Submenú para registrar un nuevo paquete
//           type: "",
//           navigationPath:
//               '/dresses', // Ruta para registrar el paquete (corregido)
//         ),
//       ],
//     ),
//     SidebarItemModel(
//       name: 'Reservas',
//       iconPath: 'images/dashboard_icon/dashboard.svg',
//       sidebarItemType: SidebarItemType.submenu,
//       type: "",
//       navigationPath: '/reservations',
//       submenus: [
//         SidebarSubmenuModel(
//           name: 'Rentar Vestimentas',
//           type: "",
//           navigationPath: '/rent-clothes', // NO '/reservations-list'
//         ),
//         SidebarSubmenuModel(
//           name: 'Reservar Paquete',
//           type: "",
//           navigationPath: '/list', // NO '/reservations-list'
//         ),
//         SidebarSubmenuModel(
//           name: 'Reservas',
//           type: "",
//           navigationPath: '/calendario', // NO '/reservations-list'
//         ),
//       ],
//     ),
//     SidebarItemModel(
//       name: lang.S.current.sales,
//       iconPath: 'images/dashboard_icon/sales.svg',
//       sidebarItemType: SidebarItemType.submenu,
//       type: "",
//       navigationPath: '/sales',
//       submenus: [
//         SidebarSubmenuModel(
//           name: 'Pos',
//           type: "",
//           navigationPath: '/pos-sales',
//         ),
//         SidebarSubmenuModel(
//           name: lang.S.current.inventorySales,
//           type: "",
//           navigationPath: '/inventory-sales',
//         ),
//         SidebarSubmenuModel(
//           name: lang.S.current.salesList,
//           type: "",
//           navigationPath: '/sale-list',
//         ),
//         SidebarSubmenuModel(
//           name: lang.S.current.saleReturn,
//           type: "",
//           navigationPath: '/sales-return-list',
//         ),
//         SidebarSubmenuModel(
//           name: 'Lista de cotizaciones',
//           type: "",
//           navigationPath: '/quotation-list',
//         ),
//       ],
//     ),
//     SidebarItemModel(
//       //name: 'Widgets',
//       name: lang.S.current.purchase,
//       iconPath: 'images/dashboard_icon/purchase.svg',
//       sidebarItemType: SidebarItemType.submenu,
//       type: "",
//       navigationPath: '/purchase',
//       submenus: [
//         SidebarSubmenuModel(
//           name: lang.S.current.purchase,
//           type: "",
//           navigationPath: '/pos-purchase',
//         ),
//         SidebarSubmenuModel(
//           name: lang.S.current.purchaseList,
//           type: "",
//           navigationPath: '/purchase-list',
//         ),
//         SidebarSubmenuModel(
//           name: lang.S.current.purchaseReturn,
//           type: "",
//           navigationPath: '/purchase-return',
//         ),
//       ],
//     ),
//     SidebarItemModel(
//       // name: 'Dashboard',
//       name: lang.S.current.categories,
//       iconPath: 'images/dashboard_icon/category.svg',
//       type: "",
//       navigationPath: '/category-list',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       // name: 'Dashboard',
//       name: lang.S.current.product,
//       iconPath: 'images/dashboard_icon/product.svg',
//       type: "",
//       navigationPath: '/product',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       // name: 'Dashboard',
//       name: lang.S.current.warehouse,
//       iconPath: 'images/dashboard_icon/warehouse.svg',
//       type: "",
//       navigationPath: '/warehouse-list',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       // name: 'Dashboard',
//       name: lang.S.current.supplierList,
//       iconPath: 'images/dashboard_icon/supplier_list.svg',
//       type: "",
//       navigationPath: '/supplier-list',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       name: lang.S.current.customerList,
//       iconPath: 'images/dashboard_icon/customer.svg',
//       type: "",
//       navigationPath: '/customer-list',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       name: lang.S.current.dueList,
//       iconPath: 'images/dashboard_icon/due_list.svg',
//       type: "",
//       navigationPath: '/due-list',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       name: lang.S.current.ledger,
//       iconPath: 'images/dashboard_icon/leder.svg',
//       type: "",
//       navigationPath: '/ledger',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       name: lang.S.current.lossProfit,
//       iconPath: 'images/dashboard_icon/loss_profit.svg',
//       type: "",
//       navigationPath: '/loss-profit',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       name: lang.S.current.expense,
//       iconPath: 'images/dashboard_icon/expense.svg',
//       type: "",
//       navigationPath: '/expense',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       name: lang.S.current.income,
//       iconPath: 'images/dashboard_icon/income.svg',
//       type: "",
//       navigationPath: '/income',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       name: lang.S.current.transaction,
//       iconPath: 'images/dashboard_icon/transaction.svg',
//       type: "",
//       navigationPath: '/transaction',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       name: lang.S.current.reports,
//       iconPath: 'images/dashboard_icon/reports.svg',
//       type: "",
//       navigationPath: '/reports',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     // SidebarItemModel(
//     //   name: 'WhatsApp Marketing',
//     //   iconPath: 'images/dashboard_icon/reports.svg',
//     //type: "",
//     //navigationPath: '/whatsapp-marketing',
//     //   // sidebarItemType: SidebarItemType.submenu,
//     // ),
//     SidebarItemModel(
//       name: 'Lista de Inventario',
//       iconPath: 'images/dashboard_icon/stock_list.svg',
//       type: "",
//       navigationPath: '/stock-list',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     // SidebarItemModel(
//     //  name: lang.S.current.subciption,
//     //  iconPath: 'images/dashboard_icon/subscription.svg',
//     //type: "",
//     //navigationPath: '/subscription',
//     // sidebarItemType: SidebarItemType.submenu,
//     //),
//     SidebarItemModel(
//       name: lang.S.current.userRole,
//       iconPath: 'images/dashboard_icon/user_role.svg',
//       type: "",
//       navigationPath: '/user-role',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       name: lang.S.current.taxRate,
//       iconPath: 'images/dashboard_icon/tax_rate.svg',
//       type: "",
//       navigationPath: '/tax-rates',
//       // sidebarItemType: SidebarItemType.submenu,
//     ),
//     SidebarItemModel(
//       //name: 'Widgets',
//       name: 'Gestion de Nomina',
//       iconPath: 'images/dashboard_icon/hrm.svg',
//       sidebarItemType: SidebarItemType.submenu,
//       type: "",
//       navigationPath: '/hrm',
//       submenus: [
//         SidebarSubmenuModel(
//           name: lang.S.current.designationList,
//           type: "",
//           navigationPath: '/designation-list',
//         ),
//         SidebarSubmenuModel(
//           name: 'Empleados',
//           type: "",
//           navigationPath: '/employee',
//         ),
//         SidebarSubmenuModel(
//           name: 'Lista de Salarios',
//           type: "",
//           navigationPath: '/salaries-list',
//         ),
//       ],
//     ),
//   ];
// }

List<SidebarItemModel> get topMenus {
  return <SidebarItemModel>[
    SidebarItemModel(
      name: lang.S.current.dashBoard,
      iconPath: 'images/dashboard_icon/dashboard.svg',
      type: "dashboard",
      navigationPath: '/dashboard',
    ),
    SidebarItemModel(
      name: 'Servicios',
      iconPath: 'images/dashboard_icon/dashboard.svg',
      sidebarItemType: SidebarItemType.submenu,
      type: "services",
      navigationPath: '/service-package',
      submenus: [
        SidebarSubmenuModel(
          name: 'Registrar Paquete',
          type: "register_package",
          navigationPath: '/register-package',
        ),
        SidebarSubmenuModel(
          name: 'Registrar Vestimenta',
          type: "register_clothing",
          navigationPath: '/dresses',
        ),
      ],
    ),
    SidebarItemModel(
      name: 'Reservas',
      iconPath: 'images/dashboard_icon/dashboard.svg',
      sidebarItemType: SidebarItemType.submenu,
      type: "reservations",
      navigationPath: '/reservations',
      submenus: [
        SidebarSubmenuModel(
          name: 'Rentar Vestimentas',
          type: "rent_clothing",
          navigationPath: '/rent-clothes',
        ),
        SidebarSubmenuModel(
          name: 'Reservar Paquete',
          type: "reserve_package",
          navigationPath: '/list',
        ),
        SidebarSubmenuModel(
          name: 'Reservas',
          type: "reservation_calendar",
          navigationPath: '/calendario',
        ),
      ],
    ),
    SidebarItemModel(
      name: lang.S.current.sales,
      iconPath: 'images/dashboard_icon/sales.svg',
      sidebarItemType: SidebarItemType.submenu,
      type: "sales",
      navigationPath: '/sales',
      submenus: [
        SidebarSubmenuModel(
          name: 'Pos',
          type: "pos_sales",
          navigationPath: '/pos-sales',
        ),
        SidebarSubmenuModel(
          name: lang.S.current.inventorySales,
          type: "inventory_sales",
          navigationPath: '/inventory-sales',
        ),
        SidebarSubmenuModel(
          name: lang.S.current.salesList,
          type: "sales_list",
          navigationPath: '/sale-list',
        ),
        SidebarSubmenuModel(
          name: lang.S.current.saleReturn,
          type: "sales_return",
          navigationPath: '/sales-return-list',
        ),
        SidebarSubmenuModel(
          name: 'Lista de cotizaciones',
          type: "quotation_list",
          navigationPath: '/quotation-list',
        ),
      ],
    ),
    SidebarItemModel(
      name: lang.S.current.purchase,
      iconPath: 'images/dashboard_icon/purchase.svg',
      sidebarItemType: SidebarItemType.submenu,
      type: "purchases",
      navigationPath: '/purchase',
      submenus: [
        SidebarSubmenuModel(
          name: lang.S.current.purchase,
          type: "pos_purchase",
          navigationPath: '/pos-purchase',
        ),
        SidebarSubmenuModel(
          name: lang.S.current.purchaseList,
          type: "purchase_list",
          navigationPath: '/purchase-list',
        ),
        SidebarSubmenuModel(
          name: lang.S.current.purchaseReturn,
          type: "purchase_return",
          navigationPath: '/purchase-return',
        ),
      ],
    ),
    SidebarItemModel(
      name: lang.S.current.categories,
      iconPath: 'images/dashboard_icon/category.svg',
      type: "categories",
      navigationPath: '/category-list',
    ),
    SidebarItemModel(
      name: lang.S.current.product,
      iconPath: 'images/dashboard_icon/product.svg',
      type: "products",
      navigationPath: '/product',
    ),
    SidebarItemModel(
      name: lang.S.current.warehouse,
      iconPath: 'images/dashboard_icon/warehouse.svg',
      type: "warehouses",
      navigationPath: '/warehouse-list',
    ),
    SidebarItemModel(
      name: lang.S.current.supplierList,
      iconPath: 'images/dashboard_icon/supplier_list.svg',
      type: "suppliers",
      navigationPath: '/supplier-list',
    ),
    SidebarItemModel(
      name: lang.S.current.customerList,
      iconPath: 'images/dashboard_icon/customer.svg',
      type: "customers",
      navigationPath: '/customer-list',
    ),
    SidebarItemModel(
      name: lang.S.current.dueList,
      iconPath: 'images/dashboard_icon/due_list.svg',
      type: "dues",
      navigationPath: '/due-list',
    ),
    SidebarItemModel(
      name: lang.S.current.ledger,
      iconPath: 'images/dashboard_icon/leder.svg',
      type: "ledger",
      navigationPath: '/ledger',
    ),
    SidebarItemModel(
      name: lang.S.current.lossProfit,
      iconPath: 'images/dashboard_icon/loss_profit.svg',
      type: "loss_profit",
      navigationPath: '/loss-profit',
    ),
    SidebarItemModel(
      name: lang.S.current.expense,
      iconPath: 'images/dashboard_icon/expense.svg',
      type: "expense",
      navigationPath: '/expense',
    ),
    SidebarItemModel(
      name: lang.S.current.income,
      iconPath: 'images/dashboard_icon/income.svg',
      type: "income",
      navigationPath: '/income',
    ),
    SidebarItemModel(
      name: lang.S.current.transaction,
      iconPath: 'images/dashboard_icon/transaction.svg',
      type: "transaction",
      navigationPath: '/transaction',
    ),
    SidebarItemModel(
      name: lang.S.current.reports,
      iconPath: 'images/dashboard_icon/reports.svg',
      type: "reports",
      navigationPath: '/reports',
    ),
    SidebarItemModel(
      name: 'Lista de Inventario',
      iconPath: 'images/dashboard_icon/stock_list.svg',
      type: "inventory_list",
      navigationPath: '/stock-list',
    ),
    SidebarItemModel(
      name: lang.S.current.userRole,
      iconPath: 'images/dashboard_icon/user_role.svg',
      type: "user_roles",
      navigationPath: '/user-role',
    ),
    SidebarItemModel(
      name: lang.S.current.taxRate,
      iconPath: 'images/dashboard_icon/tax_rate.svg',
      type: "tax_rates",
      navigationPath: '/tax-rates',
    ),
    SidebarItemModel(
      name: 'Gestion de Nomina',
      iconPath: 'images/dashboard_icon/hrm.svg',
      sidebarItemType: SidebarItemType.submenu,
      type: "hrm",
      navigationPath: '/hrm',
      submenus: [
        SidebarSubmenuModel(
          name: lang.S.current.designationList,
          type: "designations",
          navigationPath: '/designation-list',
        ),
        SidebarSubmenuModel(
          name: 'Empleados',
          type: "employees",
          navigationPath: '/employee',
        ),
        SidebarSubmenuModel(
          name: 'Lista de Salarios',
          type: "salary_list",
          navigationPath: '/salaries-list',
        ),
      ],
    ),
  ];
}

List<SidebarItemModel> getTopMenusForUser(UserRoleModel user) {
  return topMenus.where((menu) {
    final canView = user.canView(menu.type);
    if (!canView) return false;

    if (menu.sidebarItemType == SidebarItemType.submenu &&
        menu.submenus != null) {
      menu.submenus!.removeWhere(
          (submenu) => submenu.type.isNotEmpty && !user.canView(submenu.type));
    }

    return true;
  }).toList();
}
