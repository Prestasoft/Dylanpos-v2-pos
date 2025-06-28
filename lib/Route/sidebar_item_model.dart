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


List<SidebarItemModel> get topMenus {
  return <SidebarItemModel>[
    SidebarItemModel(
      name: 'Inicio',
      iconPath: 'images/dashboard_icon/dashboard.svg',
      type: "blank_home",
      navigationPath: '/blank-home',
    ),
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
