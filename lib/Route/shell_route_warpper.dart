import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:salespro_admin/Route/static_string.dart';
import 'package:salespro_admin/top_bar/top_bar.dart';

import 'fotter.dart';
import 'global_side_bar.dart';

// Colores del sistema de diseño
const Color _doradoPrincipal = Color(0xFFD4A853);
const Color _doradoOscuro = Color(0xFFC9973D);

class ShellRouteWrapper extends StatefulWidget {
  const ShellRouteWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ShellRouteWrapper> createState() => _ShellRouteWrapperState();
}

class _ShellRouteWrapperState extends State<ShellRouteWrapper> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLargeSidebarExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isLaptop =
        rf.ResponsiveBreakpoints.of(context).largerThan(BreakpointName.MD.name);
    Theme.of(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      key: scaffoldKey,
      // backgroundColor: isDark ? AcnooAppColors.kDark1 : AcnooAppColors.kPrimary50,
      drawer: isLaptop
          ? null
          : buildSidebar(isLargeSidebarExpanded), // Drawer for mobile
      bottomNavigationBar: isLaptop ? null : const FooterWidget(),
      // FAB dorado para acción principal en móvil
      floatingActionButton: isMobile ? _buildMobileFAB(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: rf.ResponsiveRowColumn(
        layout: rf.ResponsiveRowColumnType.ROW,
        rowCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Laptop & Desktop Sidebar
          if (isLaptop)
            rf.ResponsiveRowColumnItem(
              columnFit: FlexFit.loose,
              child: buildSidebar(isLargeSidebarExpanded),
            ),

          // Main Content
          rf.ResponsiveRowColumnItem(
            rowFit: FlexFit.tight,
            child: rf.ResponsiveRowColumn(
              layout: rf.ResponsiveRowColumnType.COLUMN,
              children: [
                // Static Topbar
                rf.ResponsiveRowColumnItem(
                  child: buildTopbar(isLaptop),
                ),

                // Route Pages
                rf.ResponsiveRowColumnItem(
                  columnFit: FlexFit.tight,
                  child: widget.child,
                ),

                // Footer
                if (isLaptop)
                  const rf.ResponsiveRowColumnItem(
                    child: FooterWidget(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTopbar(bool isLaptop) {
    return TopBarWidget(
      onMenuTap: () {
        if (isLaptop) {
          // Toggle sidebar expansion for desktop
          setState(() {
            isLargeSidebarExpanded = !isLargeSidebarExpanded;
          });
        } else {
          // Open drawer for mobile
          if (scaffoldKey.currentState != null &&
              scaffoldKey.currentState!.isDrawerOpen == false) {
            scaffoldKey.currentState!.openDrawer();
          }
        }
      },
    );
  }

  Widget buildSidebar(bool iconOnly) {
    return GlobalSideBar(
      rootScaffoldKey: scaffoldKey,
      iconOnly: iconOnly,
      // iconOnly: false,
    );
  }

  /// FAB dorado para acción principal en móvil
  Widget _buildMobileFAB(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton.extended(
        onPressed: () {
          // Mostrar menú de acciones rápidas
          _showQuickActionsSheet(context);
        },
        backgroundColor: _doradoPrincipal,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Acción',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Muestra el bottom sheet con acciones rápidas
  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Título
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Grid de acciones
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildActionTile(
                      context,
                      icon: Icons.receipt_long_rounded,
                      label: 'Facturar',
                      color: const Color(0xFF4CAF50),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/inventory-sales');
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.checkroom_rounded,
                      label: 'Rentar',
                      color: const Color(0xFF9C27B0),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/reservations/rent-clothes');
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.calendar_month_rounded,
                      label: 'Reservar',
                      color: _doradoPrincipal,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/reservations/reservation-calendar');
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.inventory_2_rounded,
                      label: 'Vestimentas',
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/calendario-reservas');
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.people_rounded,
                      label: 'Clientes',
                      color: const Color(0xFFFF9800),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/parties/customer-list');
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.photo_camera_rounded,
                      label: 'Impresiones',
                      color: const Color(0xFF607D8B),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/photo-invoice');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye un tile de acción para el bottom sheet
  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class ShellRouteWrapper extends StatefulWidget {
//   const ShellRouteWrapper({
//     super.key,
//     required this.child,
//   });
//
//   final Widget child;
//
//   @override
//   State<ShellRouteWrapper> createState() => _ShellRouteWrapperState();
// }
//
// class _ShellRouteWrapperState extends State<ShellRouteWrapper> {
//   final scaffoldKey = GlobalKey<ScaffoldState>();
//
//   bool isLargeSidebarExpaned = true;
//
//   @override
//   Widget build(BuildContext context) {
//     final _isLaptop = rf.ResponsiveBreakpoints.of(context).largerThan(
//       BreakpointName.MD.name,
//     );
//     final _theme = Theme.of(context);
//     final _isDark = _theme.brightness == Brightness.dark;
//
//     return Scaffold(
//       key: scaffoldKey,
//       // backgroundColor:
//       // _isDark ? AcnooAppColors.kDark1 : AcnooAppColors.kPrimary50,
//       drawer: rf.ResponsiveValue<Widget?>(
//         context,
//         conditionalValues: [
//           rf.Condition.largerThan(
//             name: BreakpointName.MD.name,
//             value: null,
//           ),
//         ],
//         defaultValue: buildSidebar(_isLaptop && isLargeSidebarExpaned),
//       ).value,
//       bottomNavigationBar: _isLaptop ? null : const FooterWidget(),
//       body: rf.ResponsiveRowColumn(
//         layout: rf.ResponsiveRowColumnType.ROW,
//         rowCrossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Laptop & Desktop Sidebar
//
//           if (_isLaptop)
//             rf.ResponsiveRowColumnItem(
//               columnFit: FlexFit.loose,
//               child: buildSidebar(isLargeSidebarExpaned),
//             ),
//
//           // Main Content
//           rf.ResponsiveRowColumnItem(
//             rowFit: FlexFit.tight,
//             child: rf.ResponsiveRowColumn(
//               layout: rf.ResponsiveRowColumnType.COLUMN,
//               children: [
//                 // Static Topbar
//                 rf.ResponsiveRowColumnItem(
//                   child: buildTopbar(_isLaptop),
//                 ),
//
//                 // Route Breadcrumb Widget
//
//                 // Route Pages
//                 rf.ResponsiveRowColumnItem(
//                   columnFit: FlexFit.tight,
//                   child: widget.child,
//                 ),
//
//                 // Footer
//                 if (_isLaptop)
//                   const rf.ResponsiveRowColumnItem(
//                     child: FooterWidget(),
//                   )
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   TopBarWidget buildTopbar(bool isLaptop) {
//     if (isLaptop) scaffoldKey.currentState?.closeDrawer();
//     return TopBarWidget(
//       onMenuTap: () {
//         if (isLaptop) {
//           setState(() => isLargeSidebarExpaned = !isLargeSidebarExpaned);
//         } else {
//           return scaffoldKey.currentState?.openDrawer();
//         }
//       },
//     );
//   }
//
//   Widget buildSidebar(bool iconOnly) {
//     return GlobalSideBar(
//       rootScaffoldKey: scaffoldKey,
//       iconOnly: iconOnly,
//     );
//   }
// }
