import 'package:salespro_admin/generated/l10n.dart' as lang;

class SidebarItemModel {
  final String name;
  final String iconPath;
  final SidebarItemType sidebarItemType;
  final List<SidebarSubmenuModel>? submenus;
  final String? navigationPath;
  final bool isPage;

  SidebarItemModel({
    required this.name,
    required this.iconPath,
    this.sidebarItemType = SidebarItemType.tile,
    this.submenus,
    this.navigationPath,
    this.isPage = false,
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

  SidebarSubmenuModel({
    required this.name,
    this.navigationPath,
    this.isPage = false,
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
      name: lang.S.current.dashBoard,
      iconPath: 'images/dashboard_icon/dashboard.svg',
      navigationPath: '/dashboard',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      name: 'Servicios', // Nombre del paquete
      iconPath:
          'images/dashboard_icon/dashboard.svg', // Icono para la sección del paquete
      sidebarItemType:
          SidebarItemType.submenu, // Esto indica que tendrá submenús
      navigationPath:
          '/service-package', // Ruta principal para el paquete (corregido)
      submenus: [
        SidebarSubmenuModel(
          name: 'Registrar Paquete', // Submenú para registrar un nuevo paquete
          navigationPath:
              '/register-package', // Ruta para registrar el paquete (corregido)
        ),
        SidebarSubmenuModel(
          name:
              'Registrar Vestimenta', // Submenú para registrar un nuevo paquete
          navigationPath:
              '/dresses', // Ruta para registrar el paquete (corregido)
        ),
      ],
    ),
    SidebarItemModel(
      name: 'Reservas',
      iconPath: 'images/dashboard_icon/dashboard.svg',
      sidebarItemType: SidebarItemType.submenu,
      navigationPath: '/reservations',
      submenus: [
        SidebarSubmenuModel(
          name: 'Rentar Vestimentas',
          navigationPath: '/rent-clothes', // NO '/reservations-list'
        ),
        SidebarSubmenuModel(
          name: 'Reservar Paquete',
          navigationPath: '/list', // NO '/reservations-list'
        ),
        SidebarSubmenuModel(
          name: 'Reservas',
          navigationPath: '/calendario', // NO '/reservations-list'
        ),
      ],
    ),
    SidebarItemModel(
      name: lang.S.current.sales,
      iconPath: 'images/dashboard_icon/sales.svg',
      sidebarItemType: SidebarItemType.submenu,
      navigationPath: '/sales',
      submenus: [
        SidebarSubmenuModel(
          name: 'Pos',
          navigationPath: '/pos-sales',
        ),
        SidebarSubmenuModel(
          name: lang.S.current.inventorySales,
          navigationPath: '/inventory-sales',
        ),
        SidebarSubmenuModel(
          name: lang.S.current.salesList,
          navigationPath: '/sale-list',
        ),
        SidebarSubmenuModel(
          name: lang.S.current.saleReturn,
          navigationPath: '/sales-return-list',
        ),
        SidebarSubmenuModel(
          name: 'Lista de cotizaciones',
          navigationPath: '/quotation-list',
        ),
      ],
    ),
    SidebarItemModel(
      //name: 'Widgets',
      name: lang.S.current.purchase,
      iconPath: 'images/dashboard_icon/purchase.svg',
      sidebarItemType: SidebarItemType.submenu,
      navigationPath: '/purchase',
      submenus: [
        SidebarSubmenuModel(
          name: lang.S.current.purchase,
          navigationPath: '/pos-purchase',
        ),
        SidebarSubmenuModel(
          name: lang.S.current.purchaseList,
          navigationPath: '/purchase-list',
        ),
        SidebarSubmenuModel(
          name: lang.S.current.purchaseReturn,
          navigationPath: '/purchase-return',
        ),
      ],
    ),
    SidebarItemModel(
      // name: 'Dashboard',
      name: lang.S.current.categories,
      iconPath: 'images/dashboard_icon/category.svg',
      navigationPath: '/category-list',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      // name: 'Dashboard',
      name: lang.S.current.product,
      iconPath: 'images/dashboard_icon/product.svg',
      navigationPath: '/product',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      // name: 'Dashboard',
      name: lang.S.current.warehouse,
      iconPath: 'images/dashboard_icon/warehouse.svg',
      navigationPath: '/warehouse-list',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      // name: 'Dashboard',
      name: lang.S.current.supplierList,
      iconPath: 'images/dashboard_icon/supplier_list.svg',
      navigationPath: '/supplier-list',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      name: lang.S.current.customerList,
      iconPath: 'images/dashboard_icon/customer.svg',
      navigationPath: '/customer-list',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      name: lang.S.current.dueList,
      iconPath: 'images/dashboard_icon/due_list.svg',
      navigationPath: '/due-list',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      name: lang.S.current.ledger,
      iconPath: 'images/dashboard_icon/leder.svg',
      navigationPath: '/ledger',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      name: lang.S.current.lossProfit,
      iconPath: 'images/dashboard_icon/loss_profit.svg',
      navigationPath: '/loss-profit',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      name: lang.S.current.expense,
      iconPath: 'images/dashboard_icon/expense.svg',
      navigationPath: '/expense',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      name: lang.S.current.income,
      iconPath: 'images/dashboard_icon/income.svg',
      navigationPath: '/income',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      name: lang.S.current.transaction,
      iconPath: 'images/dashboard_icon/transaction.svg',
      navigationPath: '/transaction',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      name: lang.S.current.reports,
      iconPath: 'images/dashboard_icon/reports.svg',
      navigationPath: '/reports',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    // SidebarItemModel(
    //   name: 'WhatsApp Marketing',
    //   iconPath: 'images/dashboard_icon/reports.svg',
    //   navigationPath: '/whatsapp-marketing',
    //   // sidebarItemType: SidebarItemType.submenu,
    // ),
    SidebarItemModel(
      name: 'Lista de Inventario',
      iconPath: 'images/dashboard_icon/stock_list.svg',
      navigationPath: '/stock-list',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    // SidebarItemModel(
    //  name: lang.S.current.subciption,
    //  iconPath: 'images/dashboard_icon/subscription.svg',
    //  navigationPath: '/subscription',
    // sidebarItemType: SidebarItemType.submenu,
    //),
    SidebarItemModel(
      name: lang.S.current.userRole,
      iconPath: 'images/dashboard_icon/user_role.svg',
      navigationPath: '/user-role',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      name: lang.S.current.taxRate,
      iconPath: 'images/dashboard_icon/tax_rate.svg',
      navigationPath: '/tax-rates',
      // sidebarItemType: SidebarItemType.submenu,
    ),
    SidebarItemModel(
      //name: 'Widgets',
      name: 'Gestion de Nomina',
      iconPath: 'images/dashboard_icon/hrm.svg',
      sidebarItemType: SidebarItemType.submenu,
      navigationPath: '/hrm',
      submenus: [
        SidebarSubmenuModel(
          name: lang.S.current.designationList,
          navigationPath: '/designation-list',
        ),
        SidebarSubmenuModel(
          name: 'Empleados',
          navigationPath: '/employee',
        ),
        SidebarSubmenuModel(
          name: 'Lista de Salarios',
          navigationPath: '/salaries-list',
        ),
      ],
    ),
  ];
}
