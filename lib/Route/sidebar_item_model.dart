import 'package:flutter/material.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../model/user_role_model.dart';
import '../const.dart';

// ============================================================================
// COLORES DE SECCIÓN - Sistema de colores por categoría
// ============================================================================
class SidebarSectionColors {
  // Principal (Dorado elegante)
  static const Color principal = Color(0xFFD4A853);

  // Vestimentas & Servicios (Púrpura elegante)
  static const Color vestimentas = Color(0xFF8B5CF6);

  // Ventas & Comercial (Verde éxito)
  static const Color ventas = Color(0xFF10B981);

  // Finanzas (Azul corporativo)
  static const Color finanzas = Color(0xFF3B82F6);

  // Inventario (Naranja)
  static const Color inventario = Color(0xFFF59E0B);

  // Clientes & Proveedores (Cyan)
  static const Color contactos = Color(0xFF06B6D4);

  // Reportes (Índigo)
  static const Color reportes = Color(0xFF6366F1);

  // Administración (Gris profesional)
  static const Color admin = Color(0xFF6B7280);

  // Recursos Humanos (Rosa)
  static const Color rrhh = Color(0xFFEC4899);

  // Auditoría (Rojo)
  static const Color auditoria = Color(0xFFEF4444);
}

class SidebarItemModel {
  final String name;
  final String iconPath;
  final IconData? materialIcon;  // Nuevo: soporte para Material Icons
  final Color? sectionColor;     // Nuevo: color de la sección
  final SidebarItemType sidebarItemType;
  final List<SidebarSubmenuModel>? submenus;
  final String? navigationPath;
  final bool isPage;
  final String type;

  SidebarItemModel({
    required this.name,
    required this.iconPath,
    this.materialIcon,
    this.sectionColor,
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
  final IconData? materialIcon;  // Nuevo: icono para submenú

  SidebarSubmenuModel({
    required this.name,
    this.navigationPath,
    this.isPage = false,
    required this.type,
    this.materialIcon,
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

// ============================================================================
// MENÚ PRINCIPAL - Organizado por secciones con iconos Material y colores
// ============================================================================
List<SidebarItemModel> get topMenus {
  return <SidebarItemModel>[
    // ══════════════════════════════════════════════════════════════════════
    // SECCIÓN: PRINCIPAL (Dorado)
    // ══════════════════════════════════════════════════════════════════════
    SidebarItemModel(
      name: lang.S.current.dashBoard,
      iconPath: 'images/dashboard_icon/dashboard.svg',
      materialIcon: Icons.dashboard_rounded,
      sectionColor: SidebarSectionColors.principal,
      type: "dashboard",
      navigationPath: '/dashboard',
    ),

    // ══════════════════════════════════════════════════════════════════════
    // SECCIÓN: VESTIMENTAS & SERVICIOS (Púrpura)
    // ══════════════════════════════════════════════════════════════════════
    SidebarItemModel(
      name: 'Servicios',
      iconPath: 'images/dashboard_icon/dashboard.svg',
      materialIcon: Icons.design_services_rounded,
      sectionColor: SidebarSectionColors.vestimentas,
      sidebarItemType: SidebarItemType.submenu,
      type: "services",
      navigationPath: '/service-package',
      submenus: [
        SidebarSubmenuModel(
          name: 'Registrar Paquete',
          type: "register_package",
          navigationPath: '/service-package/register-package',
          materialIcon: Icons.add_box_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Registrar Vestimenta',
          type: "register_clothing",
          navigationPath: '/service-package/dresses',
          materialIcon: Icons.dry_cleaning_rounded,
        ),
      ],
    ),
    SidebarItemModel(
      name: 'Reservas',
      iconPath: 'images/dashboard_icon/dashboard.svg',
      materialIcon: Icons.event_available_rounded,
      sectionColor: SidebarSectionColors.vestimentas,
      sidebarItemType: SidebarItemType.submenu,
      type: "reservations",
      navigationPath: '/reservations',
      submenus: [
        SidebarSubmenuModel(
          name: 'Rentar Vestimentas',
          type: "rent_clothing",
          navigationPath: '/reservations/rent-clothes',
          materialIcon: Icons.checkroom_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Reservar Paquete',
          type: "reserve_package",
          navigationPath: '/reservations/list',
          materialIcon: Icons.event_note_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Calendario',
          type: "reservation_calendar",
          navigationPath: '/reservations/calendario',
          materialIcon: Icons.calendar_month_rounded,
        ),
      ],
    ),

    // ══════════════════════════════════════════════════════════════════════
    // SECCIÓN: VENTAS & COMERCIAL (Verde)
    // ══════════════════════════════════════════════════════════════════════
    SidebarItemModel(
      name: lang.S.current.sales,
      iconPath: 'images/dashboard_icon/sales.svg',
      materialIcon: Icons.point_of_sale_rounded,
      sectionColor: SidebarSectionColors.ventas,
      sidebarItemType: SidebarItemType.submenu,
      type: "sales",
      navigationPath: '/sales',
      submenus: [
        SidebarSubmenuModel(
          name: lang.S.current.inventorySales,
          type: "inventory_sales",
          navigationPath: '/sales/inventory-sales',
          materialIcon: Icons.shopping_cart_rounded,
        ),
        SidebarSubmenuModel(
          name: lang.S.current.salesList,
          type: "sales_list",
          navigationPath: '/sales/sale-list',
          materialIcon: Icons.receipt_long_rounded,
        ),
        SidebarSubmenuModel(
          name: lang.S.current.saleReturn,
          type: "sales_return",
          navigationPath: '/sales/sales-return-list',
          materialIcon: Icons.assignment_return_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Cotizaciones',
          type: "quotation_list",
          navigationPath: '/sales/quotation-list',
          materialIcon: Icons.request_quote_rounded,
        ),
      ],
    ),
    SidebarItemModel(
      name: "Confirmaciones",
      iconPath: 'images/dashboard_icon/reports.svg',
      materialIcon: Icons.verified_rounded,
      sectionColor: SidebarSectionColors.ventas,
      type: "confirmations",
      navigationPath: '/sale-confirmations',
    ),
    SidebarItemModel(
      name: 'Impresión',
      iconPath: 'images/dashboard_icon/product.svg',
      materialIcon: Icons.print_rounded,
      sectionColor: SidebarSectionColors.ventas,
      sidebarItemType: SidebarItemType.submenu,
      type: "inventory_sales",
      submenus: [
        SidebarSubmenuModel(
          name: 'Facturar Impresión',
          type: "inventory_sales",
          navigationPath: '/photo-invoice',
          materialIcon: Icons.receipt_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Lista de Ventas',
          type: "inventory_sales",
          navigationPath: '/sales/photo-sales-list',
          materialIcon: Icons.list_alt_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Tipos de Servicios',
          type: "inventory_sales",
          navigationPath: '/sales/photo-product-service-types',
          materialIcon: Icons.category_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Gestión Productos',
          type: "inventory_sales",
          navigationPath: '/sales/photo-products-services',
          materialIcon: Icons.inventory_2_rounded,
        ),
      ],
    ),

    // ══════════════════════════════════════════════════════════════════════
    // SECCIÓN: FINANZAS (Azul)
    // ══════════════════════════════════════════════════════════════════════
    SidebarItemModel(
      name: 'Cuentas x Cobrar',
      iconPath: 'images/dashboard_icon/due_list.svg',
      materialIcon: Icons.account_balance_wallet_rounded,
      sectionColor: SidebarSectionColors.finanzas,
      type: "dues",
      navigationPath: '/due-list',
    ),
    SidebarItemModel(
      name: 'Transferencias',
      iconPath: 'images/dashboard_icon/income.svg',
      materialIcon: Icons.swap_horiz_rounded,
      sectionColor: SidebarSectionColors.finanzas,
      type: "transfers",
      navigationPath: '/transfer-verifications',
    ),
    SidebarItemModel(
      name: lang.S.current.expense,
      iconPath: 'images/dashboard_icon/expense.svg',
      materialIcon: Icons.money_off_rounded,
      sectionColor: SidebarSectionColors.finanzas,
      type: "expense",
      navigationPath: '/expense',
    ),
    SidebarItemModel(
      name: lang.S.current.income,
      iconPath: 'images/dashboard_icon/income.svg',
      materialIcon: Icons.attach_money_rounded,
      sectionColor: SidebarSectionColors.finanzas,
      type: "income",
      navigationPath: '/income',
    ),
    SidebarItemModel(
      name: 'Bancos',
      iconPath: 'images/dashboard_icon/income.svg',
      materialIcon: Icons.account_balance_rounded,
      sectionColor: SidebarSectionColors.finanzas,
      type: "banks",
      navigationPath: '/bank/bank-list',
    ),
    SidebarItemModel(
      name: lang.S.current.ledger,
      iconPath: 'images/dashboard_icon/leder.svg',
      materialIcon: Icons.menu_book_rounded,
      sectionColor: SidebarSectionColors.finanzas,
      type: "ledger",
      navigationPath: '/ledger',
    ),
    SidebarItemModel(
      name: lang.S.current.lossProfit,
      iconPath: 'images/dashboard_icon/loss_profit.svg',
      materialIcon: Icons.trending_up_rounded,
      sectionColor: SidebarSectionColors.finanzas,
      type: "loss_profit",
      navigationPath: '/loss-profit',
    ),

    // ══════════════════════════════════════════════════════════════════════
    // SECCIÓN: COMPRAS (Naranja)
    // ══════════════════════════════════════════════════════════════════════
    SidebarItemModel(
      name: lang.S.current.purchase,
      iconPath: 'images/dashboard_icon/purchase.svg',
      materialIcon: Icons.shopping_bag_rounded,
      sectionColor: SidebarSectionColors.inventario,
      sidebarItemType: SidebarItemType.submenu,
      type: "purchases",
      navigationPath: '/purchase',
      submenus: [
        SidebarSubmenuModel(
          name: 'Nueva Compra',
          type: "pos_purchase",
          navigationPath: '/purchase/pos-purchase',
          materialIcon: Icons.add_shopping_cart_rounded,
        ),
        SidebarSubmenuModel(
          name: lang.S.current.purchaseList,
          type: "purchase_list",
          navigationPath: '/purchase/purchase-list',
          materialIcon: Icons.list_alt_rounded,
        ),
        SidebarSubmenuModel(
          name: lang.S.current.purchaseReturn,
          type: "purchase_return",
          navigationPath: '/purchase/purchase-return',
          materialIcon: Icons.assignment_return_rounded,
        ),
      ],
    ),

    // ══════════════════════════════════════════════════════════════════════
    // SECCIÓN: INVENTARIO (Naranja)
    // ══════════════════════════════════════════════════════════════════════
    SidebarItemModel(
      name: lang.S.current.categories,
      iconPath: 'images/dashboard_icon/category.svg',
      materialIcon: Icons.folder_rounded,
      sectionColor: SidebarSectionColors.inventario,
      type: "categories",
      navigationPath: '/category-list',
    ),
    SidebarItemModel(
      name: lang.S.current.product,
      iconPath: 'images/dashboard_icon/product.svg',
      materialIcon: Icons.inventory_rounded,
      sectionColor: SidebarSectionColors.inventario,
      type: "products",
      navigationPath: '/product',
    ),
    SidebarItemModel(
      name: lang.S.current.warehouse,
      iconPath: 'images/dashboard_icon/warehouse.svg',
      materialIcon: Icons.warehouse_rounded,
      sectionColor: SidebarSectionColors.inventario,
      type: "warehouses",
      navigationPath: '/warehouse-list',
    ),
    SidebarItemModel(
      name: 'Inventario',
      iconPath: 'images/dashboard_icon/stock_list.svg',
      materialIcon: Icons.inventory_2_rounded,
      sectionColor: SidebarSectionColors.inventario,
      type: "inventory_list",
      navigationPath: '/stock-list',
    ),
    SidebarItemModel(
      name: 'Equipos',
      iconPath: 'images/dashboard_icon/stock_list.svg',
      materialIcon: Icons.camera_alt_rounded,
      sectionColor: SidebarSectionColors.inventario,
      type: "inventory_list",
      navigationPath: '/equipment-stock-list',
    ),

    // ══════════════════════════════════════════════════════════════════════
    // SECCIÓN: CLIENTES & PROVEEDORES (Cyan)
    // ══════════════════════════════════════════════════════════════════════
    SidebarItemModel(
      name: lang.S.current.customerList,
      iconPath: 'images/dashboard_icon/customer.svg',
      materialIcon: Icons.people_rounded,
      sectionColor: SidebarSectionColors.contactos,
      type: "customers",
      navigationPath: '/customer-list',
    ),
    SidebarItemModel(
      name: lang.S.current.supplierList,
      iconPath: 'images/dashboard_icon/supplier_list.svg',
      materialIcon: Icons.local_shipping_rounded,
      sectionColor: SidebarSectionColors.contactos,
      type: "suppliers",
      navigationPath: '/supplier-list',
    ),

    // ══════════════════════════════════════════════════════════════════════
    // SECCIÓN: REPORTES (Índigo)
    // ══════════════════════════════════════════════════════════════════════
    SidebarItemModel(
      name: lang.S.current.reports,
      iconPath: 'images/dashboard_icon/reports.svg',
      materialIcon: Icons.bar_chart_rounded,
      sectionColor: SidebarSectionColors.reportes,
      type: "reports",
      navigationPath: '/reports',
    ),
    SidebarItemModel(
      name: 'DGII',
      iconPath: 'images/dashboard_icon/reports.svg',
      materialIcon: Icons.account_balance_rounded,
      sectionColor: SidebarSectionColors.reportes,
      type: "reports",
      navigationPath: '/dgii',
    ),

    // ══════════════════════════════════════════════════════════════════════
    // SECCIÓN: RECURSOS HUMANOS (Rosa)
    // ══════════════════════════════════════════════════════════════════════
    SidebarItemModel(
      name: 'Recursos Humanos',
      iconPath: 'images/dashboard_icon/hrm.svg',
      materialIcon: Icons.groups_rounded,
      sectionColor: SidebarSectionColors.rrhh,
      sidebarItemType: SidebarItemType.submenu,
      type: "hrm",
      navigationPath: '/hrm',
      submenus: [
        SidebarSubmenuModel(
          name: 'Empleados',
          type: "employees",
          navigationPath: '/hrm/employee',
          materialIcon: Icons.badge_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Cargos',
          type: "designations",
          navigationPath: '/hrm/designation-list',
          materialIcon: Icons.work_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Nómina',
          type: "salary_list",
          navigationPath: '/hrm/salaries-list',
          materialIcon: Icons.payments_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Asistencia',
          type: "attendance",
          navigationPath: '/hrm/attendance',
          materialIcon: Icons.fingerprint_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Vacaciones',
          type: "vacations",
          navigationPath: '/hrm/vacations',
          materialIcon: Icons.beach_access_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Préstamos',
          type: "loans",
          navigationPath: '/hrm/loans',
          materialIcon: Icons.account_balance_wallet_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Prestaciones',
          type: "prestaciones",
          navigationPath: '/hrm/prestaciones',
          materialIcon: Icons.savings_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Reportes TSS',
          type: "tss_reports",
          navigationPath: '/hrm/tss-reports',
          materialIcon: Icons.article_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Cumpleaños',
          type: "birthdays",
          navigationPath: '/hrm/birthdays',
          materialIcon: Icons.cake_rounded,
        ),
        SidebarSubmenuModel(
          name: 'Rentabilidad',
          type: "rentability",
          navigationPath: '/hrm/rentability',
          materialIcon: Icons.analytics_rounded,
        ),
      ],
    ),

    // ══════════════════════════════════════════════════════════════════════
    // SECCIÓN: ADMINISTRACIÓN (Gris)
    // ══════════════════════════════════════════════════════════════════════
    SidebarItemModel(
      name: 'Usuarios',
      iconPath: 'images/dashboard_icon/user_role.svg',
      materialIcon: Icons.manage_accounts_rounded,
      sectionColor: SidebarSectionColors.admin,
      type: "user_roles",
      navigationPath: '/user-role',
    ),
    SidebarItemModel(
      name: 'Config. Sucursal',
      iconPath: 'images/dashboard_icon/warehouse.svg',
      materialIcon: Icons.store_rounded,
      sectionColor: SidebarSectionColors.admin,
      type: "user_roles",
      navigationPath: '/branch-settings',
    ),
    SidebarItemModel(
      name: lang.S.current.taxRate,
      iconPath: 'images/dashboard_icon/tax_rate.svg',
      materialIcon: Icons.percent_rounded,
      sectionColor: SidebarSectionColors.admin,
      type: "tax_rates",
      navigationPath: '/tax-rates',
    ),

    // ══════════════════════════════════════════════════════════════════════
    // SECCIÓN: AUDITORÍA (Rojo)
    // ══════════════════════════════════════════════════════════════════════
    SidebarItemModel(
      name: 'Auditoría',
      iconPath: 'images/dashboard_icon/user_role.svg',
      materialIcon: Icons.history_rounded,
      sectionColor: SidebarSectionColors.auditoria,
      type: "audit",
      navigationPath: '/audit',
    ),
    SidebarItemModel(
      name: 'Papelera',
      iconPath: 'images/dashboard_icon/due_list.svg',
      materialIcon: Icons.delete_rounded,
      sectionColor: SidebarSectionColors.auditoria,
      type: "audit",
      navigationPath: '/deleted-items',
    ),
  ];
}

List<SidebarItemModel> getTopMenusForUser(UserRoleModel user) {
  // IMPORTANTE: SIEMPRE verificar permisos si el usuario tiene permisos definidos
  // Sin importar si es admin o no. Solo mostrar todos los menús si:
  // 1. No es sub-usuario Y
  // 2. No tiene permisos específicos definidos
  final hasDefinedPermissions = user.permissions.isNotEmpty &&
      user.permissions.any((p) => p.view || p.edit || p.delete);

  return topMenus.where((menu) {
    // Si no es sub-usuario Y no tiene permisos definidos, mostrar todos
    if (!isSubUser && !hasDefinedPermissions) {
      return true;
    }

    // Si tiene permisos definidos (sea admin o no), SIEMPRE filtrar por permisos
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
