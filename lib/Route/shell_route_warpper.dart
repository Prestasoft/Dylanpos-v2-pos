import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:salespro_admin/Route/static_string.dart';
import 'package:salespro_admin/top_bar/top_bar.dart';

import 'fotter.dart';
import 'global_side_bar.dart';

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
    final bool isLaptop = rf.ResponsiveBreakpoints.of(context).largerThan(BreakpointName.MD.name);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      key: scaffoldKey,
      // backgroundColor: isDark ? AcnooAppColors.kDark1 : AcnooAppColors.kPrimary50,
      drawer: isLaptop ? null : buildSidebar(isLargeSidebarExpanded), // Drawer for mobile
      bottomNavigationBar: isLaptop ? null : const FooterWidget(),
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
          if (scaffoldKey.currentState != null && scaffoldKey.currentState!.isDrawerOpen == false) {
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
