import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/Subscription/payment.dart';
import 'package:salespro_admin/Screen/Subscription/subscript.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/subacription_plan_provider.dart';
import '../../Repository/subscriptionPlanRepo.dart';
import '../../const.dart';
import '../../model/subscription_model.dart';
import '../../model/subscription_plan_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';

class PurchasePlan extends StatefulWidget {
  const PurchasePlan({
    super.key,
    required this.initialSelectedPackage,
    required this.initPackageValue,
  });
  final String initialSelectedPackage;
  final int initPackageValue;
  // static const String route = '/purchase_plan';

  @override
  // ignore: library_private_types_in_public_api
  _PurchasePlanState createState() => _PurchasePlanState();
}

class _PurchasePlanState extends State<PurchasePlan> {
  ScrollController mainScroll = ScrollController();

  String selectedPayButton = 'Paypal';
  int selectedPackageValue = 0;

  CurrentSubscriptionPlanRepo currentSubscriptionPlanRepo = CurrentSubscriptionPlanRepo();

  SubscriptionModel currentSubscriptionPlan = SubscriptionModel(
    subscriptionName: 'Free',
    subscriptionDate: DateTime.now().toString(),
    saleNumber: 0,
    purchaseNumber: 0,
    partiesNumber: 0,
    dueNumber: 0,
    duration: 0,
    products: 0,
  );

  void getCurrentSubscriptionPlan() async {
    currentSubscriptionPlan = await currentSubscriptionPlanRepo.getCurrentSubscriptionPlans();
    setState(() {
      currentSubscriptionPlan;
    });
  }

  @override
  initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
    getCurrentSubscriptionPlan();
    widget.initPackageValue == 0 ? selectedPackageValue = 2 : 0;
  }

  List<Color> colors = [
    const Color(0xFF06DE90),
    const Color(0xFFF5B400),
    const Color(0xFFFF7468),
  ];
  SubscriptionPlanModel selectedPlan = SubscriptionPlanModel(subscriptionName: '', saleNumber: 0, purchaseNumber: 0, partiesNumber: 0, dueNumber: 0, duration: 0, products: 0, subscriptionPrice: 0, offerPrice: 0);

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: Consumer(builder: (context, ref, __) {
        final subscriptionData = ref.watch(subscriptionPlanProvider);
        return subscriptionData.when(data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              // padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      lang.S.of(context).purchasePremiumPlan,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(
                    thickness: 1.0,
                    color: kNeutral300,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveGridRow(children: [
                          ResponsiveGridCol(
                              lg: 6,
                              md: screenWidth < 700 ? 12 : 6,
                              xs: 12,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: SizedBox(
                                            width: 450,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Align(
                                                  alignment: Alignment.topRight,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.cancel,
                                                        color: kNeutral500,
                                                      ),
                                                      onPressed: () {
                                                        GoRouter.of(context).pop();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 200,
                                                  width: 200,
                                                  decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('images/plan_details_1.png'), fit: BoxFit.cover)),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  lang.S.of(context).freeLifeTimeUpdate,
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 20.0, right: 20),
                                                  child: Text(
                                                    lang.S.of(context).stayAtTheForeFrontOfTechnological,
                                                    textAlign: TextAlign.center,
                                                    style: theme.textTheme.bodyLarge,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6.0),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.14),
                                          blurRadius: 15,
                                          spreadRadius: -5,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 2,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                      leading: Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2.0),
                                          image: const DecorationImage(
                                            image: AssetImage('images/sp1.png'),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        lang.S.of(context).freeLifeTimeUpdate,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      trailing: const Icon(
                                        FeatherIcons.alertCircle,
                                        color: kNeutral500,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                          ResponsiveGridCol(
                              lg: 6,
                              md: screenWidth < 700 ? 12 : 6,
                              xs: 12,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                          child: SizedBox(
                                            width: 450,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                const SizedBox(height: 10),
                                                Align(
                                                  alignment: Alignment.topRight,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: IconButton(
                                                      icon: const Icon(Icons.cancel),
                                                      onPressed: () {
                                                        // Navigator.pop(context);
                                                        GoRouter.of(context).pop();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                const SizedBox(height: 20),
                                                Container(
                                                  height: 200,
                                                  width: 200,
                                                  decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('images/plan_details_2.png'), fit: BoxFit.cover)),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  lang.S.of(context).androidIOSAppSupport,
                                                  textAlign: TextAlign.center,
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 20.0, right: 20),
                                                  child: Text(
                                                    lang.S.of(context).weUnderStand,
                                                    textAlign: TextAlign.center,
                                                    style: theme.textTheme.bodyLarge,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2.0),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.14),
                                          blurRadius: 15,
                                          spreadRadius: -5,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 2,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                      leading: Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2.0),
                                          image: const DecorationImage(
                                            image: AssetImage('images/sp2.png'),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        lang.S.of(context).androidIOSAppSupport,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      trailing: const Icon(
                                        FeatherIcons.alertCircle,
                                        color: kNeutral500,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                        ]),
                        ResponsiveGridRow(children: [
                          ResponsiveGridCol(
                              lg: 6,
                              md: screenWidth < 700 ? 12 : 6,
                              xs: 12,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                          child: SizedBox(
                                            width: 450,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                const SizedBox(height: 10),
                                                Align(
                                                  alignment: Alignment.topRight,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.cancel,
                                                        color: kNeutral500,
                                                      ),
                                                      onPressed: () {
                                                        GoRouter.of(context).pop();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                const SizedBox(height: 10),
                                                Container(
                                                  height: 200,
                                                  width: 200,
                                                  decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('images/plan_details_3.png'), fit: BoxFit.cover)),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  lang.S.of(context).premiumCustomerSupport,
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 20.0, right: 20),
                                                  child: Text(lang.S.of(context).unlockTheFull, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                                                ),
                                                const SizedBox(height: 20),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2.0),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.14),
                                          blurRadius: 15,
                                          spreadRadius: -5,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 2,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                      leading: Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2.0),
                                          image: const DecorationImage(
                                            image: AssetImage('images/sp3.png'),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        lang.S.of(context).premiumCustomerSupport,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      trailing: const Icon(
                                        FeatherIcons.alertCircle,
                                        color: kNeutral500,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                          ResponsiveGridCol(
                              lg: 6,
                              md: screenWidth < 700 ? 12 : 6,
                              xs: 12,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                          child: SizedBox(
                                            width: 450,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                const SizedBox(height: 10),
                                                Align(
                                                  alignment: Alignment.topRight,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: IconButton(
                                                      icon: const Icon(Icons.cancel),
                                                      onPressed: () {
                                                        GoRouter.of(context).pop();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Container(
                                                  height: 200,
                                                  width: 200,
                                                  decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('images/plan_details_4.png'), fit: BoxFit.cover)),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  lang.S.of(context).customInvoiceBranding,
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 20.0, right: 20),
                                                  child: Text(lang.S.of(context).makeALastingImpression, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                                                ),
                                                const SizedBox(height: 20),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2.0),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.14),
                                          blurRadius: 15,
                                          spreadRadius: -5,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 2,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                      leading: Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2.0),
                                          image: const DecorationImage(
                                            image: AssetImage('images/sp4.png'),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        lang.S.of(context).customInvoiceBranding,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      trailing: const Icon(
                                        FeatherIcons.alertCircle,
                                        color: kNeutral500,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                        ]),
                        ResponsiveGridRow(children: [
                          ResponsiveGridCol(
                              lg: 6,
                              md: screenWidth < 700 ? 12 : 6,
                              xs: 12,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                          child: SizedBox(
                                            width: 450,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Align(
                                                  alignment: Alignment.topRight,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.cancel,
                                                        color: kNeutral500,
                                                      ),
                                                      onPressed: () {
                                                        GoRouter.of(context).pop();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Container(
                                                  height: 200,
                                                  width: 200,
                                                  decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('images/plan_details_5.png'), fit: BoxFit.cover)),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  lang.S.of(context).unlimitedUsage,
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 20.0, right: 20),
                                                  child: Text(lang.S.of(context).theNameSysIt, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                                                ),
                                                const SizedBox(height: 20),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2.0),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.14),
                                          blurRadius: 15,
                                          spreadRadius: -5,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 2,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                      leading: Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2.0),
                                          image: const DecorationImage(
                                            image: AssetImage('images/sp5.png'),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        lang.S.of(context).unlimitedUsage,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      trailing: const Icon(
                                        FeatherIcons.alertCircle,
                                        color: kNeutral500,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                          ResponsiveGridCol(
                              lg: 6,
                              md: screenWidth < 700 ? 12 : 6,
                              xs: 12,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                          child: SizedBox(
                                            width: 450,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(10.0),
                                                  child: Align(
                                                    alignment: Alignment.topRight,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.cancel,
                                                        color: kNeutral500,
                                                      ),
                                                      onPressed: () {
                                                        GoRouter.of(context).pop();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Container(
                                                  height: 200,
                                                  width: 200,
                                                  decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('images/plan_details_6.png'), fit: BoxFit.cover)),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  lang.S.of(context).freeDataBackup,
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 20.0, right: 20),
                                                  child: Text(lang.S.of(context).safegurardYourBusinessDate, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                                                ),
                                                const SizedBox(height: 20),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2.0),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.14),
                                          blurRadius: 15,
                                          spreadRadius: -5,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 2,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                      leading: Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2.0),
                                          image: const DecorationImage(
                                            image: AssetImage('images/sp6.png'),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        lang.S.of(context).freeDataBackup,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      trailing: const Icon(
                                        FeatherIcons.alertCircle,
                                        color: kNeutral500,
                                      ),
                                    ),
                                    // child: Row(
                                    //   mainAxisAlignment: MainAxisAlignment.start,
                                    //   children: [
                                    //     Container(
                                    //       height: 40,
                                    //       width: 40,
                                    //       decoration: BoxDecoration(
                                    //         borderRadius: BorderRadius.circular(2.0),
                                    //         image: const DecorationImage(
                                    //           image: AssetImage('images/sp6.png'),
                                    //         ),
                                    //       ),
                                    //     ),
                                    //     const SizedBox(width: 8),
                                    //     Text(
                                    //       lang.S.of(context).freeDataBackup,
                                    //       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    //     ),
                                    //     const Spacer(),
                                    //     const Icon(FeatherIcons.alertCircle),
                                    //   ],
                                    // ),
                                  ),
                                ),
                              ))
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                      lang.S.of(context).buyPremiumPlan,
                      textAlign: TextAlign.start,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 20.0),
                      physics: const ClampingScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: data.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedPlan = data[index];
                            });
                          },
                          child: data[index].offerPrice >= 1
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: SizedBox(
                                    height: (context.width() / 2.5) + 18,
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: data[index].subscriptionName == selectedPlan.subscriptionName ? kPremiumPlanColor2.withOpacity(0.1) : Colors.white,
                                            borderRadius: const BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                            border: Border.all(
                                              width: 1,
                                              color: data[index].subscriptionName == selectedPlan.subscriptionName ? kPremiumPlanColor2 : kPremiumPlanColor,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(10.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(height: 15),
                                              Text(
                                                lang.S.of(context).mobilePlusDesktop,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                data[index].subscriptionName,
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '$globalCurrency${data[index].offerPrice}',
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPremiumPlanColor2),
                                              ),
                                              Text(
                                                '$globalCurrency${data[index].subscriptionPrice}',
                                                style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 14, color: Colors.grey),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '${lang.S.of(context).duration} ${data[index].duration} ${lang.S.of(context).day}',
                                                style: const TextStyle(color: kGreyTextColor),
                                              ),
                                              const SizedBox(height: 5),
                                              data[index].whatsappMarketingEnabled
                                                  ? Text(
                                                      lang.S.of(context).whatsappMarketingEnabled,
                                                      style: const TextStyle(color: kGreyTextColor),
                                                    )
                                                  : const SizedBox(),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          child: Container(
                                            height: 25,
                                            width: 90,
                                            decoration: const BoxDecoration(
                                              color: kPremiumPlanColor2,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10),
                                                bottomRight: Radius.circular(10),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${lang.S.of(context).save} ${(100 - ((data[index].offerPrice * 100) / data[index].subscriptionPrice)).toInt().toString()}%',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 20, right: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      color: data[index].subscriptionName == selectedPlan.subscriptionName ? kPremiumPlanColor2.withOpacity(0.1) : Colors.white,
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                      border: Border.all(width: 1, color: data[index].subscriptionName == selectedPlan.subscriptionName ? kPremiumPlanColor2 : kPremiumPlanColor),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          lang.S.of(context).mobilePlusDesktop,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        Text(
                                          data[index].subscriptionName,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '$globalCurrency${data[index].subscriptionPrice.toString()}',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPremiumPlanColor),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${lang.S.of(context).duration} ${data[index].duration} ${lang.S.of(context).day}',
                                          style: const TextStyle(color: kGreyTextColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(screenWidth < 700 ? screenWidth : 400, 48),
                        ),
                        onPressed: () async {
                          if (selectedPlan.subscriptionName == '') {
                            EasyLoading.showError(lang.S.of(context).pleaseSelectAPlan);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                  subscriptionPlanModel: selectedPlan,
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          lang.S.of(context).payCash,
                        ),
                      ).visible(Subscript.customersActivePlan.subscriptionName != selectedPlan.subscriptionName),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          );
        }, error: (Object error, StackTrace? stackTrace) {
          return Text(error.toString());
        }, loading: () {
          return const Center(child: CircularProgressIndicator());
        });
      }),
    );
  }
}
