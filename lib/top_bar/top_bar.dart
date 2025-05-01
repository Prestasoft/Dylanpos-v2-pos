import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as ri;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:restart_app/restart_app.dart';
import 'package:salespro_admin/Route/static_string.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/global_language.dart';

import '../Provider/profile_provider.dart';
import '../Screen/Widgets/Constant Data/constant.dart';
import '../Screen/currency/global_currency.dart';
import '../const.dart';
import '../model/personal_information_model.dart';

class TopBarWidget extends StatefulWidget {
  const TopBarWidget({super.key, this.onMenuTap});

  final void Function()? onMenuTap;

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
  @override
  void initState() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user?.uid == null) {
      Restart.restartApp();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ri.Consumer(builder: (context, ref, __) {
      AsyncValue<PersonalInformationModel> userProfileDetails = ref.watch(profileDetailsProvider);
      return AppBar(
        backgroundColor: Colors.white,
        leadingWidth: 40,
        leading: rf.ResponsiveValue<Widget?>(
          context,
          conditionalValues: [
            rf.Condition.largerThan(
              name: BreakpointName.MD.name,
              value: null,
            ),
          ],
          defaultValue: IconButton(
            onPressed: widget.onMenuTap,
            icon: const Tooltip(
              message: 'Open Navigation menu',
              waitDuration: Duration(milliseconds: 350),
              child: Icon(Icons.menu),
            ),
          ),
        ).value,
        toolbarHeight: rf.ResponsiveValue<double?>(
          context,
          conditionalValues: [rf.Condition.largerThan(name: BreakpointName.SM.name, value: 70)],
        ).value,
        surfaceTintColor: Colors.transparent,
        title: ri.Consumer(builder: (context, ref, __) {
          AsyncValue<PersonalInformationModel> userProfileDetails = ref.watch(profileDetailsProvider);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            // mainAxisSize: MainAxisSize.min,
            children: [
              // const SizedBox(width: 30.0),
              screenWidth < 670
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                          backgroundColor: const Color(0xFF8424FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                          // side: const BorderSide(color: kBorderColorTextField, width: 1),
                          textStyle: kTextStyle.copyWith(color: kWhite),
                          surfaceTintColor: const Color(0xFF8424FF).withOpacity(0.5),
                          shadowColor: const Color(0xFF8424FF).withOpacity(0.1),
                        ),
                        onPressed: () {
                          // Navigator.pushNamed(context, PosSale.route);
                          context.go('/sales/pos-sales');
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded, color: kWhite),
                            Text(
                              'Pos',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
              screenWidth < 670 ? const SizedBox.shrink() : const SizedBox(width: 10.0),
              screenWidth < 590
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                          padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                          backgroundColor: kMainColor.withValues(alpha: 0.1),
                          side: const BorderSide(color: kMainColor, width: 1),
                          textStyle: kTextStyle.copyWith(color: kWhite),
                          surfaceTintColor: lightGreyColor,
                          shadowColor: lightGreyColor.withOpacity(0.1),
                        ),
                        onPressed: () {
                          // Navigator.pushNamed(context, InventorySales.route);
                          context.go('/sales/inventory-sales');
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded, color: kMainColor),
                            Text(
                              'Facturar Reserva',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: kMainColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
              screenWidth < 590 ? const SizedBox.shrink() : const SizedBox(width: 10.0),
              userProfileDetails.when(data: (details) {
                return SizedBox(
                  width: screenWidth < 335 ? 150 : 180,
                  child: Text(
                    isSubUser ? '${details.companyName ?? ''} [$constSubUserTitle]' : details.companyName ?? '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: context.width() < 900 ? 25 : context.width() * 0.018,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.start,
                  ),
                );
              }, error: (e, stack) {
                return Text(e.toString());
              }, loading: () {
                return const Text('');
              }),
              const Spacer(),
              screenWidth < 590
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                          padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                          backgroundColor: kMainColor.withValues(alpha: 0.05),
                          side: const BorderSide(color: kMainColor, width: 1),
                          textStyle: kTextStyle.copyWith(color: const Color(0xFFFF2525)),
                          surfaceTintColor: kWhite,
                          shadowColor: kMainColor.withOpacity(0.1),
                          foregroundColor: kMainColor.withOpacity(0.1),
                        ),
                        onPressed: () {
                          // Navigator.pushNamed(context, Product.route);
                          context.go('/product');
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded, color: kMainColor),
                            Text(
                              'Product',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kMainColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
              screenWidth < 800 ? const SizedBox.shrink() : const SizedBox(width: 10.0),
              screenWidth < 800
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                          padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                          backgroundColor: const Color(0xFF15CD75).withValues(alpha: 0.05),
                          side: const BorderSide(color: Color(0xFF15CD75), width: 1),
                          textStyle: kTextStyle.copyWith(color: const Color(0xFF15CD75)),
                          surfaceTintColor: kWhite,
                          shadowColor: const Color(0xFF15CD75).withOpacity(0.1),
                          foregroundColor: const Color(0xFF15CD75).withOpacity(0.1),
                        ),
                        onPressed: () {
                          // Navigator.pushNamed(context, PurchaseList.route);
                          // context.go(PurchaseList.route);
                          context.go('/purchase/pos-purchase');
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded, color: Color(0xFF15CD75)),
                            Text(
                              'Purchase',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF15CD75),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
              screenWidth < 1260 ? const SizedBox.shrink() : const SizedBox(width: 10.0),
              screenWidth < 1260 ? const SizedBox.shrink() : const GlobalLanguage(isDrawer: false),
              screenWidth < 1430 ? const SizedBox.shrink() : const SizedBox(width: 10.0),
              screenWidth < 1430 ? const SizedBox.shrink() : const GlobalCurrency(isDrawer: false)
            ],
          );
        }),
        actions: [
          userProfileDetails.when(data: (details) {
            return Theme(
              data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
              child: PopupMenuButton(
                surfaceTintColor: Colors.white,
                padding: EdgeInsets.zero,
                position: PopupMenuPosition.under,
                icon: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DB0F6).withOpacity(0.1),
                    shape: BoxShape.rectangle,
                  ),
                  child: const Icon(Icons.settings, color: Color(0xFF2DB0F6), size: 30.0),
                ),
                itemBuilder: (BuildContext bc) => [
                  PopupMenuItem(
                    onTap: () {
                      // isSubUser ? null : ProfileUpdate(personalInformationModel: details).launch(context);
                      isSubUser ? null : context.go('/profile-update', extra: details);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.manage_accounts_sharp, size: 18.0, color: kTitleColor),
                        const SizedBox(width: 4.0),
                        Text(
                          isSubUser ? '${details.companyName}[$constSubUserTitle]' : lang.S.of(context).prof,
                          style: kTextStyle.copyWith(color: kTitleColor),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      EasyLoading.showSuccess('Successfully Logged Out');
                      // Navigator.of(context).pushAndRemoveUntil(
                      //   MaterialPageRoute(builder: (context) => const EmailLogIn()),
                      //       (route) => false,
                      // );
                      if (context.mounted) {
                        context.go('/', extra: {'replace': true});
                      }
                      // const EmailLogIn().launch(context);
                    },
                    child: Row(
                      children: [
                        const Icon(FeatherIcons.logOut, size: 18.0, color: kTitleColor),
                        const SizedBox(width: 4.0),
                        Text(
                          lang.S.of(context).logOut,
                          style: kTextStyle.copyWith(color: kTitleColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }, error: (e, stack) {
            return Center(
              child: Text(e.toString()),
            );
          }, loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
        ],
      );
    });
  }

  Size get preferredSize => const Size(double.infinity, 64);
}

// class TopBarWidget extends StatelessWidget implements PreferredSizeWidget {
//   const TopBarWidget({super.key, this.onMenuTap});
//
//   final void Function()? onMenuTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.white,
//       leading: rf.ResponsiveValue<Widget?>(
//         context,
//         conditionalValues: [
//           rf.Condition.largerThan(
//             name: BreakpointName.MD.name,
//             value: null,
//           ),
//         ],
//         defaultValue: IconButton(
//           onPressed: onMenuTap,
//           icon: const Tooltip(
//             message: 'Open Navigation menu',
//             waitDuration: Duration(milliseconds: 350),
//             child: Icon(Icons.menu),
//           ),
//         ),
//       ).value,
//       toolbarHeight: rf.ResponsiveValue<double?>(
//         context,
//         conditionalValues: [
//           rf.Condition.largerThan(name: BreakpointName.SM.name, value: 70)
//         ],
//       ).value,
//       surfaceTintColor: Colors.transparent,
//       actions: [
//         PopupMenuButton(
//           icon: const Icon(
//             FeatherIcons.settings,
//             size: 24.0,
//             color: kBlueTextColor,
//           ),
//           padding: EdgeInsets.zero,
//           itemBuilder: (BuildContext bc) => [
//             PopupMenuItem(
//               child: GestureDetector(
//                 onTap: (() {
//                   // changePassword(mainContext: context, manuContext: bc);
//                 }),
//                 child: const Text(
//                   'Change Password',
//                 ),
//               ),
//             ),
//           ],
//           onSelected: (value) {
//             Navigator.pushNamed(context, '$value');
//           },
//         ),
//         const SizedBox(width: 8.0),
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             shape: BoxShape.rectangle,
//             color: kMainColor.withOpacity(0.1),
//           ),
//           child: const Icon(FeatherIcons.logOut, color: kBlueTextColor),
//         ).onTap(() async {
//           await FirebaseAuth.instance.signOut();
//           // ignore: use_build_context_synchronously
//           // const AcnooLoginScreen().launch(context, isNewTask: true);
//           ///---------------push replacement--------------------
//           if (context.mounted) {
//             context.go('/', extra: {'replace': true});
//             // context.pop();
//           }
//         }),
//         const SizedBox(width: 20,)
//       ],
//     );
//   }
//
//   @override
//   Size get preferredSize => const Size(double.infinity, 64);
// }
