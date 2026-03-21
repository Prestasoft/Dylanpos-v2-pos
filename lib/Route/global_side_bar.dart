import 'package:collection/collection.dart';
import 'package:expansion_widget/expansion_widget.dart';
// Firebase Auth deshabilitado - Usar ApiService para autenticación
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:restart_app/restart_app.dart';
import 'package:salespro_admin/Route/sidebar_item_model.dart';
import 'package:salespro_admin/Route/static_string.dart';
import 'package:salespro_admin/const.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../Provider/general_setting_provider.dart';
import '../Provider/subacription_plan_provider.dart';
import '../Screen/Widgets/Constant Data/constant.dart';
import '../Screen/currency/global_currency.dart';
import '../model/subscription_model.dart';
import '../services/audit_service.dart';
import '../services/api_service.dart';
import '../services/deletion_password_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../Repository/profile_details_repo.dart';
import '../services/tenant/tenant_model.dart';
import '../Provider/menu_order_provider.dart';
import '../Screen/Widgets/menu_order_editor_modal.dart';
import 'package:nb_utils/nb_utils.dart';

class GlobalSideBar extends ConsumerStatefulWidget {
  const GlobalSideBar({
    super.key,
    required this.rootScaffoldKey,
    this.iconOnly = false,
  });

  final GlobalKey<ScaffoldState> rootScaffoldKey;
  final bool iconOnly;

  @override
  ConsumerState<GlobalSideBar> createState() => _GlobalSideBarState();
}

class _GlobalSideBarState extends ConsumerState<GlobalSideBar> {
  SubscriptionModel subscriptionModel = SubscriptionModel(
    subscriptionName: '',
    subscriptionDate: DateTime.now().toString(),
    saleNumber: 0,
    purchaseNumber: 0,
    partiesNumber: 0,
    dueNumber: 0,
    duration: 0,
    products: 0,
  );

 SidebarItemModel  homeTab = SidebarItemModel(
      name: 'Inicio',
      iconPath: 'images/dashboard_icon/dashboard.svg',
      materialIcon: Icons.home_rounded,
      sectionColor: SidebarSectionColors.principal,
      type: "blank_home",
      navigationPath: '/blank-home',
    );
  void checkSubscriptionData() async {
    subscriptionModel =
        await currentSubscriptionPlanRepo.getCurrentSubscriptionPlans();

    setState(() {
      subscriptionModel;
    });
  }

  @override
  void initState() {
    // Firebase Auth deshabilitado - Usar ApiService para verificar autenticación
    final apiService = ApiService();
    if (!apiService.isAuthenticated) {
      Restart.restartApp();
    }
    checkSubscriptionData();
    getUserDataFromLocal();
    _configureAuditService();
    super.initState();
  }

  /// Configurar AuditService con información del usuario actual si está logueado
  void _configureAuditService() async {
    // Firebase Auth deshabilitado - Usar ApiService para obtener datos del usuario
    final apiService = ApiService();
    if (apiService.isAuthenticated) {
      await getUserDataFromLocal(); // Asegurar que los datos estén cargados

      String userName = 'Usuario';
      // Obtener email y userId desde currentUser map de ApiService
      String userEmail = apiService.currentUser?['email']?.toString() ?? 'email_no_disponible';
      String userId = apiService.currentUser?['id']?.toString() ?? '';

      // Si es sub-usuario, usar esa información
      if (isSubUser && constSubUserTitle.isNotEmpty) {
        userName = constSubUserTitle;
        userEmail = (finalUserRoleModel.email?.isNotEmpty == true) ? finalUserRoleModel.email! : userEmail;
        userId = constUserId.isNotEmpty ? constUserId : userId;
      } else {
        // Si es usuario principal, intentar obtener nombre desde el perfil
        try {
          final profileData = await ProfileRepo().getDetails();
          userName = profileData.companyName.isNotEmpty ? profileData.companyName : userEmail.split('@')[0];
        } catch (e) {
          // Si no se puede obtener el perfil, usar el email como nombre
          userName = userEmail.split('@')[0];
        }
      }

      // Configurar AuditService sin triggear un nuevo login
      AuditService.setCurrentUser(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Obtener menús filtrados por permisos
    final baseMenus = getTopMenusForUser(finalUserRoleModel);

    // Aplicar orden personalizado si existe
    final menuOrderState = ref.watch(menuOrderProvider);
    final filteredMenus = menuOrderState.when(
      data: (menuOrder) {
        if (menuOrder.menuOrder.isEmpty) {
          return baseMenus;
        }
        return ref.read(menuOrderProvider.notifier).applyOrder(baseMenus);
      },
      loading: () => baseMenus,
      error: (_, __) => baseMenus,
    );

    final selectedInfoHome = _isSelected(context, homeTab);
    return Drawer(
      backgroundColor: Colors.black,
      clipBehavior: Clip.none,
      width: widget.iconOnly
          ? 80
          : ResponsiveValue<double?>(
              context,
              conditionalValues: [
                Condition.largerThan(
                  name: BreakpointName.SM.name,
                  value: 300,
                ),
              ],
            ).value,
      shape: const BeveledRectangleBorder(),
      child: SafeArea(
        child: ResponsiveRowColumn(
          layout: ResponsiveRowColumnType.COLUMN,
          columnCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            ResponsiveRowColumnItem(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildHeader(context, iconOnly: widget.iconOnly),
              ),
            ),
            // ══════════════════════════════════════════════════════════════════
            // Sección de moneda (solo visible en tablet/desktop, móvil usa top bar)
            // ══════════════════════════════════════════════════════════════════
            ResponsiveRowColumnItem(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Solo mostrar selector de moneda en pantallas medianas
                    // En móvil (<600px) las acciones están en el top bar
                    if (!widget.iconOnly && screenWidth >= 600 && screenWidth <= 1430)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: const GlobalCurrency(isDrawer: true),
                      ),
                  ],
                ),
              ),
            ),
            ResponsiveRowColumnItem(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ResponsiveRowColumnItem(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SidebarMenuItem(
                            iconOnly: widget.iconOnly,
                            menuTile: homeTab,
                            groupName: homeTab.name,
                            isSelected: selectedInfoHome.isSelectedMenu,
                            selectedSubmenu: selectedInfoHome.selectedSubmenu,
                            onTap: () => _handleNavigation(context, homeTab),
                            onSubmenuTap: (value) => _handleNavigation(
                              context,
                              homeTab,
                              submenu: value,
                            ),
                          ),
                        ),
                      )
              ),
            ),
            ResponsiveRowColumnItem(
              columnFit: FlexFit.tight,
              child: SingleChildScrollView(
                child: ResponsiveRowColumn(
                  layout: ResponsiveRowColumnType.COLUMN,
                  columnCrossAxisAlignment: CrossAxisAlignment.start,
                  columnPadding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Top Menus

                    //...topMenus.map((menu) {
                    ...filteredMenus.map((menu) {
                      final selectedInfo = _isSelected(context, menu);
                      return ResponsiveRowColumnItem(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SidebarMenuItem(
                            iconOnly: widget.iconOnly,
                            menuTile: menu,
                            groupName: menu.name,
                            isSelected: selectedInfo.isSelectedMenu,
                            selectedSubmenu: selectedInfo.selectedSubmenu,
                            onTap: () => _handleNavigation(context, menu),
                            onSubmenuTap: (value) => _handleNavigation(
                              context,
                              menu,
                              submenu: value,
                            ),
                          ),
                        ),
                      );
                    }),

                    // Botón de configuración del orden del menú (solo admin)
                    if (!isSubUser)
                      ResponsiveRowColumnItem(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          child: _buildMenuOrderButton(context),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ResponsiveRowColumnItem(
            //   child: Padding(
            //     padding: const EdgeInsets.all(10.0),
            //     child: Container(
            //       width: MediaQuery.of(context).size.width * .50,
            //       padding: widget.iconOnly
            //           ? EdgeInsets.all(6)
            //           : const EdgeInsets.symmetric(
            //               horizontal: 12, vertical: 14),
            //       decoration: BoxDecoration(
            //           borderRadius: BorderRadius.circular(8.0),
            //           color: kMainColor),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         //  children: [
            //         //  Row(
            //         //   crossAxisAlignment: CrossAxisAlignment.start,
            //         //  children: [
            //         //   SvgPicture.asset(
            //         //     'images/dashboard_icon/crown.svg',
            //         //     height: 35,
            //         //     width: 35,
            //         //    ),
            //         //    if (!widget.iconOnly) const SizedBox(width: 10),
            //         //    if (!widget.iconOnly)
            //         //  Expanded(
            //         //    child: Column(
            //         //    crossAxisAlignment: CrossAxisAlignment.start,
            //         //  children: [
            //         //    Text(
            //         //   subscriptionModel.subscriptionName,
            //         //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //         //    color: kWhite,
            //         //    fontWeight: FontWeight.w600,
            //         //    fontSize: 18,
            //         //    ),
            //         //   maxLines: 3,
            //         //  ),
            //         //  Text(
            //         //   'Expires in: ${(DateTime.parse(subscriptionModel.subscriptionDate).difference(DateTime.now()).inDays.abs() - subscriptionModel.duration).abs()} Days',
            //         //   style: Theme.of(context).textTheme.titleSmall?.copyWith(
            //         //       color: kWhite,
            //         //       fontWeight: FontWeight.w500,
            //         //       ),
            //         //   maxLines: 3,
            //         //     ).visible(subscriptionModel.subscriptionName != 'Lifetime'),
            //         //    SizedBox(height: 10),
            //         //      ElevatedButton(style: ElevatedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.3)), backgroundColor: Colors.white.withValues(alpha: 0.2)), onPressed: () => context.go('/subscription'), child: Text('Actualizar Plan'))
            //         //    ],
            //         //   ),
            //         //    ),
            //         // ],
            //         // ),
            //          Wrap(
            //         //   direction: Axis.horizontal,
            //         //   crossAxisAlignment: WrapCrossAlignment.start,
            //         //   // alignment: WrapAlignment.spaceAround,
            //         //   children: [
            //         //     SvgPicture.asset('images/dashboard_icon/crown.svg'),
            //         //     if (!widget.iconOnly) const SizedBox(width: 10),
            //         //     if (!widget.iconOnly)
            //         //       Column(
            //         //         crossAxisAlignment: CrossAxisAlignment.start,
            //         //         children: [
            //         //           Text(
            //         //             'Your are using ${subscriptionModel.subscriptionName} package',
            //         //             style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //         //                   color: kWhite,
            //         //                   fontWeight: FontWeight.w600,
            //         //                 ),
            //         //             maxLines: 3,
            //         //           ),
            //         //           Text(
            //         //             'Expires in ${(DateTime.parse(subscriptionModel.subscriptionDate).difference(DateTime.now()).inDays.abs() - subscriptionModel.duration).abs()} Days',
            //         //             style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //         //                   color: kWhite,
            //         //                   fontWeight: FontWeight.w600,
            //         //                 ),
            //         //             maxLines: 3,
            //         //           ).visible(subscriptionModel.subscriptionName != 'Lifetime'),
            //         //         ],
            //         //       ),
            //         //   ],
            //         // ),
            //         // Row(
            //         //  mainAxisAlignment: MainAxisAlignment.end,
            //         // children: [
            //         // Text(
            //         // lang.S.of(context).upgradeOnMobileApp,
            //         //  style: kTextStyle.copyWith(color: kYellowColor, fontWeight: FontWeight.bold),
            //         // ),
            //         // const Icon(
            //         //  FontAwesomeIcons.arrowRight,
            //         //  color: kYellowColor,
            //         // ),
            //         // ],
            //         // ).visible(false),
            //         //],
            //       ),
            //     ),
            //   ),
            // )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {bool iconOnly = false}) {
    return Consumer(
      builder: (_, ref, watch) {
        final settingProvider = ref.watch(generalSettingProvider);
        return settingProvider.when(data: (setting) {
          // Obtener el nombre de la sucursal desde el tenant actual
          final tenantId = getStringAsync('selected_tenant_id');
          final tenant = TenantConfig.getTenantById(tenantId) ?? TenantConfig.defaultTenant;
          final branchName = tenant.city.toUpperCase();
          final initials = branchName.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join('').toUpperCase();

          // Verificar si el usuario es admin (no es subUser) o tiene sucursales permitidas
          final isAdmin = !isSubUser;

          // Verificar si el usuario tiene permiso de cambio de sucursal
          final apiService = ApiService();
          final currentUserModel = apiService.toUserRoleModel();
          final canChangeBranch = isAdmin || (currentUserModel.allowedBranches != null && currentUserModel.allowedBranches!.isNotEmpty);

          // Color principal del header (dorado elegante)
          const headerColor = SidebarSectionColors.principal;

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: iconOnly ? 8 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              // Gradiente sutil para elegancia
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  headerColor.withValues(alpha: 0.15),
                  headerColor.withValues(alpha: 0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  width: 1.5,
                  color: headerColor.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: iconOnly
                // ══════════════════════════════════════════════════════════
                // MODO ICONO: Solo iniciales con tooltip
                // ══════════════════════════════════════════════════════════
                ? Tooltip(
                    message: branchName,
                    child: InkWell(
                      onTap: canChangeBranch ? () => _showBranchSelectorDialog(context, tenant) : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              headerColor,
                              headerColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: headerColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                // ══════════════════════════════════════════════════════════
                // MODO EXPANDIDO: Logo + Nombre + Botón cambiar
                // ══════════════════════════════════════════════════════════
                : Row(
                    children: [
                      // Logo/Iniciales de la sucursal
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              headerColor,
                              headerColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: headerColor.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.store_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nombre de la sucursal
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SUCURSAL',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: headerColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              branchName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Botón de cambiar sucursal
                      if (canChangeBranch)
                        InkWell(
                          onTap: () => _showBranchSelectorDialog(context, tenant),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: headerColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: headerColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.swap_horiz_rounded,
                              color: headerColor,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
          );
        }, error: (e, stack) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error cargando',
                    style: TextStyle(color: Colors.red[300], fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }, loading: () {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: iconOnly ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SidebarSectionColors.principal,
                  ),
                ),
                if (!iconOnly) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Cargando...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          );
        });
      },
    );
  }

  /// Muestra el diálogo para seleccionar sucursal
  void _showBranchSelectorDialog(BuildContext context, TenantModel currentTenant) {
    // Obtener las sucursales permitidas del usuario
    final apiService = ApiService();
    final currentUserModel = apiService.toUserRoleModel();
    final allowedBranches = currentUserModel.allowedBranches;

    // Debug log para diagnóstico
    debugPrint('🔐 [BranchSelector] Usuario: ${currentUserModel.userTitle}');
    debugPrint('🔐 [BranchSelector] allowedBranches del usuario: $allowedBranches');
    debugPrint('🔐 [BranchSelector] Total sucursales configuradas: ${TenantConfig.allTenants.length}');

    // Filtrar sucursales según permisos
    // PRIORIDAD: Si tiene allowedBranches definidas, filtrar por esas (sin importar si es admin)
    // Solo mostrar todas si allowedBranches es null o vacío
    final availableTenants = (allowedBranches != null && allowedBranches.isNotEmpty)
        ? TenantConfig.allTenants.where((tenant) =>
            allowedBranches.contains(tenant.id)
          ).toList()
        : TenantConfig.allTenants;

    debugPrint('🔐 [BranchSelector] Sucursales disponibles para este usuario: ${availableTenants.map((t) => t.id).toList()}');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.store, color: kMainColor),
            const SizedBox(width: 10),
            const Text('Cambiar Sucursal'),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sucursal actual: ${currentTenant.city}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...availableTenants.map((tenant) {
                final isSelected = tenant.id == currentTenant.id;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? kMainColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        tenant.initials,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    tenant.city,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? kMainColor : null,
                    ),
                  ),
                  subtitle: Text(tenant.shortName),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: kMainColor)
                      : const Icon(Icons.chevron_right),
                  selected: isSelected,
                  selectedTileColor: kMainColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: isSelected
                      ? null
                      : () => _changeBranch(dialogContext, tenant),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Cambia a otra sucursal
  void _changeBranch(BuildContext context, TenantModel newTenant) async {
    // Mostrar confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar cambio'),
        content: Text(
          '¿Desea cambiar a la sucursal ${newTenant.city}?\n\nLa aplicación se reiniciará para aplicar los cambios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cambiar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // IMPORTANTE: Guardar en localStorage directamente para web
      // El main.dart lee primero de localStorage
      if (kIsWeb) {
        html.window.localStorage['selected_tenant_id'] = newTenant.id;
        debugPrint('💾 localStorage actualizado con tenant: ${newTenant.id}');
      }

      // También guardar en SharedPreferences como backup
      await setValue('selected_tenant_id', newTenant.id);

      // Cerrar el diálogo de selección
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Recargar la página completamente para reinicializar Firebase con el nuevo tenant
      if (kIsWeb) {
        html.window.location.reload();
      } else {
        Restart.restartApp();
      }
    }
  }

  _SelectionInfo _isSelected(BuildContext context, SidebarItemModel menu) {
    final isSubmenu = menu.sidebarItemType == SidebarItemType.submenu;
    final currentRoute = GoRouter.of(context)
        .routeInformationProvider
        .value
        .uri
        .toString()
        .toLowerCase()
        .trim();

    final isSelectedMenu =
        currentRoute == menu.navigationPath?.toLowerCase().trim();

    if (isSubmenu) {
      final routeSegments = currentRoute
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList();

      if (routeSegments.length > 1) {
        final selectedSubMenu = menu.submenus?.firstWhereOrNull(
          (submenu) =>
              submenu.navigationPath?.split('/').last == routeSegments.last,
        );
        if (selectedSubMenu != null) {
          return _SelectionInfo(true, selectedSubMenu);
        }
      }
    }

    return _SelectionInfo(isSelectedMenu, null);
  }

  void _handleNavigation(
    BuildContext ctx,
    SidebarItemModel menu, {
    SidebarSubmenuModel? submenu,
  }) {
    widget.rootScaffoldKey.currentState?.closeDrawer();
    String? _route;

    if (menu.sidebarItemType == SidebarItemType.tile) {
      _route = menu.navigationPath;
    } else if (menu.sidebarItemType == SidebarItemType.submenu) {
      final _submenuRoute = submenu?.navigationPath;
      if (_submenuRoute != null) {
        // Use the submenu route directly since it already contains the full path
        _route = _submenuRoute;
      }
    }

    if (_route == null || _route.isEmpty) {
      ScaffoldMessenger.of(widget.rootScaffoldKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Unknown Route')),
      );
      return;
    }

    if (_route == '/hrm/loans') {
      _showPasswordDialog(ctx, () {
        ctx.go(_route!);
      });
      return;
    }

    ctx.go(_route);
  }

  void _showPasswordDialog(BuildContext context, VoidCallback onSuccess) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.deepPurple),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Clave de Autorización',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingrese la clave de autorización para acceder a Préstamos:'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Clave',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              onSubmitted: (_) async {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  EasyLoading.showError('Ingrese la clave');
                  return;
                }
                EasyLoading.show();
                final isValid = await DeletionPasswordService.validatePassword(password);
                EasyLoading.dismiss();
                if (isValid) {
                  Navigator.pop(ctx);
                  onSuccess();
                } else {
                  EasyLoading.showError('Clave incorrecta');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) {
                EasyLoading.showError('Ingrese la clave');
                return;
              }
              EasyLoading.show();
              final isValid = await DeletionPasswordService.validatePassword(password);
              EasyLoading.dismiss();
              if (isValid) {
                Navigator.pop(ctx);
                onSuccess();
              } else {
                EasyLoading.showError('Clave incorrecta');
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  /// Botón para abrir el editor de orden del menú (solo admin)
  Widget _buildMenuOrderButton(BuildContext context) {
    const doradoPrincipal = Color(0xFFD4A853);

    if (widget.iconOnly) {
      // Versión compacta para modo iconOnly
      return Tooltip(
        message: 'Ordenar menú',
        child: InkWell(
          onTap: () => MenuOrderEditorModal.show(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: doradoPrincipal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: doradoPrincipal.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.reorder_rounded,
              color: doradoPrincipal,
              size: 20,
            ),
          ),
        ),
      );
    }

    // Versión expandida
    return InkWell(
      onTap: () => MenuOrderEditorModal.show(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: doradoPrincipal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: doradoPrincipal.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: doradoPrincipal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.reorder_rounded,
                color: doradoPrincipal,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ordenar Menú',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Personalizar orden',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionInfo {
  final bool isSelectedMenu;
  final SidebarSubmenuModel? selectedSubmenu;

  _SelectionInfo(this.isSelectedMenu, this.selectedSubmenu);
}

class SidebarMenuItem extends StatelessWidget {
  const SidebarMenuItem({
    super.key,
    this.iconOnly = false,
    required this.menuTile,
    this.isSelected = false,
    this.selectedSubmenu,
    this.onSubmenuTap,
    this.onTap,
    this.groupName,
  });

  final bool iconOnly;
  final SidebarItemModel menuTile;
  final bool isSelected;
  final SidebarSubmenuModel? selectedSubmenu;
  final void Function(SidebarSubmenuModel? value)? onSubmenuTap;
  final void Function()? onTap;
  final String? groupName;

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);

    if (menuTile.sidebarItemType == SidebarItemType.submenu) {
      if (iconOnly) {
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: PopupMenuButton<SidebarSubmenuModel?>(
            offset: const Offset(80 - 16, 0),
            shape: const BeveledRectangleBorder(),
            clipBehavior: Clip.antiAlias,
            tooltip: menuTile.name,
            color: _theme.colorScheme.primaryContainer,
            itemBuilder: (context) => [
              // Group Name
              if (groupName != null)
                _CustomIconOnlySubmenu(
                  enabled: false,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          groupName!,
                          style: _theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(MdiIcons.chevronDown),
                      ],
                    ),
                  ),
                ),
              // Submenus
              ...?menuTile.submenus?.map(
                (submenu) {
                  return _CustomIconOnlySubmenu<SidebarSubmenuModel>(
                    value: submenu,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildSubmenu(
                        context,
                        submenu,
                        onChanged: (value) {
                          Navigator.pop(context, value);
                          onSubmenuTap?.call(value);
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
            child: _buildMenu(context, onTap: null),
          ),
        );
      }
      return ExpansionWidget(
        titleBuilder: (aV, eIV, iE, tF) => _buildMenu(
          context,
          onTap: () => tF(animated: true),
          isExpanded: iE,
        ),
        initiallyExpanded: isSelected,
        content: Padding(
          padding: const EdgeInsets.only(top: 8, left: 36),
          child: Column(
            children: [
              ...?menuTile.submenus?.map(
                (submenu) => _buildSubmenu(
                  context,
                  submenu,
                  onChanged: onSubmenuTap,
                ),
              )
            ],
          ),
        ),
      );
    }

    if (iconOnly) {
      return Tooltip(
        message: menuTile.name,
        child: _buildMenu(context, onTap: onTap),
      );
    }
    return _buildMenu(context, onTap: onTap);
  }

  Widget _buildMenu(
    BuildContext context, {
    required void Function()? onTap,
    bool isExpanded = false,
  }) {
    final _theme = Theme.of(context);

    // Usar el color de sección si está definido, si no usar blanco
    final sectionColor = menuTile.sectionColor ?? Colors.white;
    const _selectedPrimaryColor = Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: BoxConstraints.tight(const Size.fromHeight(48)),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: isSelected
              ? sectionColor.withValues(alpha: 0.9)
              : sectionColor.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? sectionColor : sectionColor.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
        ),
        padding: EdgeInsets.only(left: iconOnly ? 8 : 12, right: 8),
        child: Row(
          mainAxisAlignment:
              iconOnly ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            // Usar Material Icon si está disponible, si no usar SVG
            if (menuTile.materialIcon != null)
              Icon(
                menuTile.materialIcon,
                size: 22,
                color: isSelected ? _selectedPrimaryColor : sectionColor,
              )
            else
              SvgPicture.asset(
                menuTile.iconPath,
                height: 22,
                width: 22,
                colorFilter: ColorFilter.mode(
                  isSelected ? _selectedPrimaryColor : sectionColor,
                  BlendMode.srcIn,
                ),
              ),

            if (!iconOnly)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Menu title
                      Flexible(
                        child: Text(
                          menuTile.name,
                          style: _theme.textTheme.titleMedium?.copyWith(
                            color: isSelected ? _selectedPrimaryColor : Colors.white,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Trailing Icon (solo para submenús)
                      if (menuTile.sidebarItemType == SidebarItemType.submenu)
                        Icon(
                          isExpanded ? MdiIcons.chevronDown : Icons.chevron_right,
                          color: isSelected ? _selectedPrimaryColor : sectionColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSubmenu(
    BuildContext context,
    SidebarSubmenuModel submenu, {
    void Function(SidebarSubmenuModel? value)? onChanged,
  }) {
    final _theme = Theme.of(context);
    final _isSelectedSubmenu = selectedSubmenu == submenu;

    // Usar el color de sección del menú padre
    final sectionColor = menuTile.sectionColor ?? kMainColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged?.call(submenu),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: iconOnly ? 8 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: _isSelectedSubmenu
                ? sectionColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: _isSelectedSubmenu
                ? Border.all(color: sectionColor.withValues(alpha: 0.4), width: 1)
                : null,
          ),
          child: Row(
            children: [
              // Icono del submenú (Material Icon o indicador de selección)
              if (submenu.materialIcon != null)
                Icon(
                  submenu.materialIcon,
                  size: 18,
                  color: _isSelectedSubmenu
                      ? sectionColor
                      : iconOnly
                          ? kGreyTextColor
                          : Colors.white70,
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSelectedSubmenu
                        ? sectionColor
                        : Colors.white30,
                    border: _isSelectedSubmenu
                        ? Border.all(color: sectionColor, width: 2)
                        : null,
                  ),
                ),
              const SizedBox(width: 10),
              // Nombre del submenú
              Expanded(
                child: Text(
                  submenu.name,
                  style: _theme.textTheme.bodyMedium?.copyWith(
                    color: _isSelectedSubmenu
                        ? sectionColor
                        : iconOnly
                            ? kGreyTextColor
                            : Colors.white,
                    fontWeight: _isSelectedSubmenu ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Flecha de navegación
              Icon(
                Icons.chevron_right,
                size: 18,
                color: _isSelectedSubmenu
                    ? sectionColor
                    : iconOnly
                        ? kGreyTextColor
                        : Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomIconOnlySubmenu<T> extends StatefulWidget
    implements PopupMenuEntry<T> {
  const _CustomIconOnlySubmenu({
    super.key,
    this.enabled = true,
    this.value,
    required this.child,
  });
  final bool enabled;
  final T? value;
  final Widget child;

  @override
  State<_CustomIconOnlySubmenu> createState() => _CustomIconOnlySubmenuState();

  @override
  double get height => 0;

  @override
  bool represents(value) => value == this.value;
}

class _CustomIconOnlySubmenuState<T> extends State<_CustomIconOnlySubmenu> {
  @protected
  void handleTap() {
    Navigator.pop<T>(context, widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: Colors.transparent,
      onTap: widget.enabled ? handleTap : null,
      child: widget.child,
    );
  }
}
