import 'package:collection/collection.dart';
import 'package:expansion_widget/expansion_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:salespro_admin/global_language.dart';
import '../Provider/general_setting_provider.dart';
import '../Provider/subacription_plan_provider.dart';
import '../Screen/Widgets/Constant Data/constant.dart';
import '../Screen/currency/global_currency.dart';
import '../model/subscription_model.dart';

class GlobalSideBar extends StatefulWidget {
  const GlobalSideBar({
    super.key,
    required this.rootScaffoldKey,
    this.iconOnly = false,
  });

  final GlobalKey<ScaffoldState> rootScaffoldKey;
  final bool iconOnly;

  @override
  State<GlobalSideBar> createState() => _GlobalSideBarState();
}

class _GlobalSideBarState extends State<GlobalSideBar> {
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
  void checkSubscriptionData() async {
    subscriptionModel =
        await currentSubscriptionPlanRepo.getCurrentSubscriptionPlans();

    setState(() {
      subscriptionModel;
    });
  }

  @override
  void initState() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user?.uid == null) {
      Restart.restartApp();
    }
    checkSubscriptionData();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    print(finalUserRoleModel);
    final filteredMenus = getTopMenusForUser(finalUserRoleModel);
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
            ResponsiveRowColumnItem(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.iconOnly
                        ? const SizedBox.shrink()
                        : Row(
                            children: [
                              screenWidth > 1260
                                  ? const SizedBox.shrink()
                                  : const GlobalLanguage(isDrawer: true),
                              screenWidth > 1430
                                  ? const SizedBox.shrink()
                                  : const SizedBox(width: 10.0),
                              screenWidth > 1430
                                  ? const SizedBox.shrink()
                                  : const GlobalCurrency(isDrawer: true),
                              // GlobalCurrency(),
                            ],
                          ),
                    widget.iconOnly
                        ? const SizedBox.shrink()
                        : screenWidth > 1260 && screenWidth > 1430
                            ? const SizedBox.shrink()
                            : const SizedBox(height: 16),
                    widget.iconOnly
                        ? const SizedBox.shrink()
                        : Row(
                            children: [
                              screenWidth > 590
                                  ? const SizedBox.shrink()
                                  : SizedBox(
                                      height: 40,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 8, 15, 8),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30.0)),
                                          backgroundColor: kMainColor
                                              .withValues(alpha: 0.05),
                                          side: const BorderSide(
                                              color: kMainColor, width: 1),
                                          textStyle: kTextStyle.copyWith(
                                              color: const Color(0xFFFF2525)),
                                          surfaceTintColor: kWhite,
                                          shadowColor:
                                              kMainColor.withValues(alpha: 0.1),
                                          foregroundColor:
                                              kMainColor.withValues(alpha: 0.1),
                                        ),
                                        onPressed: () {
                                          // Navigator.pushNamed(context, Product.route);
                                          context
                                              .go('/service-package/dresses');
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.add_rounded,
                                                color: kMainColor),
                                            Text(
                                              'Vestidos',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                      color: kMainColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              screenWidth > 1260
                                  ? const SizedBox.shrink()
                                  : screenWidth > 1260
                                      ? const SizedBox.shrink()
                                      : const SizedBox(width: 10.0),
                              screenWidth > 800
                                  ? const SizedBox.shrink()
                                  : SizedBox(
                                      height: 40,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30.0)),
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 8, 15, 8),
                                          backgroundColor:
                                              const Color(0xFF15CD75)
                                                  .withValues(alpha: 0.05),
                                          side: const BorderSide(
                                              color: Color(0xFF15CD75),
                                              width: 1),
                                          textStyle: kTextStyle.copyWith(
                                              color: const Color(0xFF15CD75)),
                                          surfaceTintColor: kWhite,
                                          shadowColor: const Color(0xFF15CD75)
                                              .withOpacity(0.1),
                                          foregroundColor:
                                              const Color(0xFF15CD75)
                                                  .withOpacity(0.1),
                                        ),
                                        onPressed: () {
                                          // Navigator.pushNamed(context, PurchaseList.route);
                                          // context.go(PurchaseList.route);
                                          context.go('/calendario-reservas');
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.add_rounded,
                                                color: Color(0xFF15CD75)),
                                            Text(
                                              'Calendario',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color:
                                                        const Color(0xFF15CD75),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                    widget.iconOnly
                        ? const SizedBox.shrink()
                        : screenWidth > 590 && screenWidth > 1260
                            ? const SizedBox.shrink()
                            : const SizedBox(height: 16),
                    widget.iconOnly
                        ? const SizedBox.shrink()
                        : Row(
                            children: [
                              screenWidth > 670
                                  ? const SizedBox.shrink()
                                  : SizedBox(
                                      height: 40,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30.0)),
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 8, 15, 8),

                                          backgroundColor:
                                              const Color(0xFF8424FF),
                                          // side: const BorderSide(color: kBorderColorTextField, width: 1),
                                          textStyle: kTextStyle.copyWith(
                                              color: kWhite),
                                          surfaceTintColor:
                                              const Color(0xFF8424FF)
                                                  .withOpacity(0.5),
                                          shadowColor: const Color(0xFF8424FF)
                                              .withOpacity(0.1),
                                        ),
                                        onPressed: () {
                                          // Navigator.pushNamed(context, PosSale.route);
                                          context.go('/sales/pos-sales');
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.add_rounded,
                                                color: kWhite),
                                            Text(
                                              'Rentar',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              screenWidth > 670
                                  ? const SizedBox.shrink()
                                  : const SizedBox(width: 16.0),
                              screenWidth > 590
                                  ? const SizedBox.shrink()
                                  : SizedBox(
                                      height: 40,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 8, 15, 8),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30.0)),
                                          backgroundColor:
                                              kMainColor.withValues(alpha: 0.1),
                                          side: const BorderSide(
                                              color: kMainColor, width: 1),
                                          textStyle: kTextStyle.copyWith(
                                              color: kWhite),
                                          surfaceTintColor: lightGreyColor,
                                          shadowColor:
                                              lightGreyColor.withOpacity(0.1),
                                        ),
                                        onPressed: () {
                                          // Navigator.pushNamed(context, InventorySales.route);
                                          context.go('/inventory-sales');
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.add_rounded,
                                                color: kMainColor),
                                            Text(
                                              'Facturar',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: kMainColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                    widget.iconOnly
                        ? const SizedBox.shrink()
                        : screenWidth > 670 && screenWidth > 590
                            ? const SizedBox.shrink()
                            : const SizedBox(height: 16),
                  ],
                ),
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
                      final _selectedInfo = _isSelected(context, menu);
                      return ResponsiveRowColumnItem(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SidebarMenuItem(
                            iconOnly: widget.iconOnly,
                            menuTile: menu,
                            groupName: menu.name,
                            isSelected: _selectedInfo.isSelectedMenu,
                            selectedSubmenu: _selectedInfo.selectedSubmenu,
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
    Theme.of(context);
    return Consumer(
      builder: (_, ref, watch) {
        final settingProvider = ref.watch(generalSettingProvider);
        return settingProvider.when(data: (setting) {
          final logo =
              setting.mainLogo.isNotEmpty == true ? setting.mainLogo : appLogo;
          final nameLogo = setting.commonHeaderLogo.isNotEmpty == true
              ? setting.sidebarLogo
              : 'images/sideLogo.png';
          return Container(
            padding: const EdgeInsets.all(16),
            height: ResponsiveValue<double?>(
              context,
              conditionalValues: [
                Condition.largerThan(
                  name: BreakpointName.SM.name,
                  value: 70,
                ),
              ],
            ).value,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: kNeutral300,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment:
                  iconOnly ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (iconOnly)
                  Image.network(
                    logo,
                    height: 38,
                    width: 33,
                  ),
                if (!iconOnly)
                  Image.network(
                    nameLogo,
                    height: 38,
                    width: 150,
                  ),
              ],
            ),
          );
        }, error: (e, stack) {
          return Text(e.toString());
        }, loading: () {
          return Center(
            child: CircularProgressIndicator(),
          );
        });
      },
    );
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
      final _mainRoute = menu.navigationPath;
      final _submenuRoute = submenu?.navigationPath;
      if (_mainRoute != null && _submenuRoute != null) {
        _route = _mainRoute + _submenuRoute;
      }
    }

    if (_route == null || _route.isEmpty) {
      ScaffoldMessenger.of(widget.rootScaffoldKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Unknown Route')),
      );
      return;
    }

    ctx.go(_route);
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

    const _selectedPrimaryColor = Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: BoxConstraints.tight(const Size.fromHeight(48)),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: isSelected ? kMainColor : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        padding: EdgeInsets.only(left: iconOnly ? 8 : 16, right: 8),
        child: Row(
          mainAxisAlignment:
              iconOnly ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            // Icon
            SvgPicture.asset(
              menuTile.iconPath,
              height: 23,
              width: 23,
              colorFilter: ColorFilter.mode(
                isSelected ? _selectedPrimaryColor : Colors.white,
                BlendMode.srcIn,
              ),
            ),
            // Icon(
            //   menuTile.icon,
            //   color: isSelected ? _selectedPrimaryColor : Colors.white,
            // ),

            if (!iconOnly)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Menu title
                      Text(
                        menuTile.name,
                        style: _theme.textTheme.titleMedium?.copyWith(
                          color:
                              isSelected ? _selectedPrimaryColor : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Trailing Icon
                      Icon(
                        isExpanded ? MdiIcons.chevronDown : Icons.chevron_right,
                        color: isSelected ? _selectedPrimaryColor : null,
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

    final _selectedPrimaryColor = _theme.primaryColor;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () => onChanged?.call(submenu),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: _isSelectedSubmenu
            ? _selectedPrimaryColor.withValues(alpha: 0.20)
            : null,
        title: Text(submenu.name),
        leading: Radio<SidebarSubmenuModel?>(
            value: submenu,
            groupValue: selectedSubmenu,
            onChanged: onChanged,
            fillColor: WidgetStateProperty.resolveWith((states) {
              return _isSelectedSubmenu
                  ? _selectedPrimaryColor
                  : iconOnly
                      ? kGreyTextColor
                      : Colors.white;
            })),
        titleTextStyle: _theme.textTheme.bodyLarge?.copyWith(
          color: _isSelectedSubmenu
              ? _selectedPrimaryColor
              : iconOnly
                  ? kGreyTextColor
                  : Colors.white,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: EdgeInsets.only(left: iconOnly ? 8 : 8, right: 8),
        trailing: const Icon(Icons.chevron_right),
        iconColor: _isSelectedSubmenu
            ? _selectedPrimaryColor
            : iconOnly
                ? kGreyTextColor
                : Colors.white,
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
