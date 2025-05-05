import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Repository/paypal_repo.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/subscription_model.dart';

import '../../Provider/subacription_plan_provider.dart';
import '../../Repository/subscriptionPlanRepo.dart';
import '../../const.dart';
import '../../model/subscription_plan_model.dart';
import '../Widgets/Constant Data/constant.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({
    super.key,
  });

  static const String route = '/subscription_plans';

  @override
  // ignore: library_private_types_in_public_api
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  CurrentSubscriptionPlanRepo currentSubscriptionPlanRepo =
      CurrentSubscriptionPlanRepo();

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
  SubscriptionPlanModel? subscriptionPlanModel;
  int? initPackageValue;
  Duration? remainTime;
  List<String> initialPackageService = ['0', '0', '0', '0', '0'];
  List<String> originalPackageService = ['0', '0', '0', '0', '0'];

  void checkSubscriptionData() async {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      EasyLoading.show(status: lang.S.of(context).loading);
      subscriptionModel =
          await CurrentSubscriptionPlanRepo().getCurrentSubscriptionPlans();
      initialPackageService[0] = subscriptionModel.saleNumber.toString();
      initialPackageService[1] = subscriptionModel.purchaseNumber.toString();
      initialPackageService[2] = subscriptionModel.dueNumber.toString();
      initialPackageService[3] = subscriptionModel.partiesNumber.toString();
      initialPackageService[4] = subscriptionModel.products.toString();
      subscriptionPlanModel = await CurrentSubscriptionPlanRepo()
          .getSubscriptionPlanByName(subscriptionModel.subscriptionName);
      originalPackageService[0] =
          subscriptionPlanModel?.saleNumber.toString() ?? '0';
      originalPackageService[1] =
          subscriptionPlanModel?.purchaseNumber.toString() ?? '0';
      originalPackageService[2] =
          subscriptionPlanModel?.dueNumber.toString() ?? '0';
      originalPackageService[3] =
          subscriptionPlanModel?.partiesNumber.toString() ?? '0';
      originalPackageService[4] =
          subscriptionPlanModel?.products.toString() ?? '0';
      EasyLoading.dismiss();
      setState(() {});
    });
  }

  @override
  initState() {
    super.initState();
    checkSubscriptionData();
    checkCurrentUserAndRestartApp();
  }

  List<Color> colors = [
    const Color(0xFF06DE90),
    const Color(0xFFF5B400),
    const Color(0xFFFF7468),
  ];
  PaypalRepo paypalRepo = PaypalRepo();
  SubscriptionPlanModel selectedPlan = SubscriptionPlanModel(
      subscriptionName: '',
      saleNumber: 0,
      purchaseNumber: 0,
      partiesNumber: 0,
      dueNumber: 0,
      duration: 0,
      products: 0,
      subscriptionPrice: 0,
      offerPrice: 0);
  ScrollController mainScroll = ScrollController();

  List<String> nameList = [
    'Sales',
    'Purchase',
    'Due collection',
    'Parties',
    'Products'
  ];
  List<Color> colorList = [
    const Color(0xffff5722),
    const Color(0xff028a7e),
    const Color(0xff03a9f4),
    const Color(0xffe040fb),
    const Color(0xff4caf50),
  ];

  List<IconData> iconList = [
    Icons.add_shopping_cart_rounded,
    FontAwesomeIcons.solidMoneyBill1,
    Icons.phonelink_outlined,
    FeatherIcons.users,
    FontAwesomeIcons.handHoldingDollar,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: Consumer(builder: (context, ref, __) {
        final subscriptionData = ref.watch(subscriptionPlanProvider);
        return subscriptionData.when(data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0), color: kWhite),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      lang.S.of(context).yourPackage,
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
                            xs: 12,
                            md: 6,
                            lg: screenWidth < 1550 ? 4 : 3,
                            child: Container(
                              padding: const EdgeInsets.all(10.0),
                              // height: 80,
                              decoration: BoxDecoration(
                                  color: kMainColor.withOpacity(0.2),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10))),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${subscriptionModel.subscriptionName} ${lang.S.of(context).plan}',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text.rich(TextSpan(
                                            text:
                                                lang.S.of(context).yourAreUsing,
                                            style: theme.textTheme.bodyLarge,
                                            children: [
                                              TextSpan(
                                                text:
                                                    ' ${subscriptionModel.subscriptionName} ',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  color: kMainColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              TextSpan(
                                                text: lang.S.of(context).plan,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  color: kMainColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ])),
                                        // Row(
                                        //   children: [
                                        //     Text(
                                        //       lang.S.of(context).yourAreUsing,
                                        //       style: theme.textTheme.bodyLarge,
                                        //     ),
                                        //     const SizedBox(width: 5),
                                        //     Text(
                                        //       '${subscriptionModel.subscriptionName} ${lang.S.of(context).plan}',
                                        //       style: theme.textTheme.titleMedium?.copyWith(
                                        //         color: kMainColor,
                                        //         fontWeight: FontWeight.w600,
                                        //       ),
                                        //     ),
                                        //   ],
                                        // ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20.0),
                                  Container(
                                    height: 91,
                                    width: 91,
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: kMainColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${(DateTime.parse(subscriptionModel.subscriptionDate).difference(DateTime.now()).inDays.abs() - subscriptionModel.duration).abs()}',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(color: Colors.white),
                                        ),
                                        Text(
                                          'Days Left',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            color: Colors.white,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 15),
                  //______________________________________________Package_Features
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      lang.S.of(context).packageFeature,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  ResponsiveGridRow(
                      rowSegments: 120,
                      children: List.generate(nameList.length, (i) {
                        return ResponsiveGridCol(
                            xs: 120,
                            md: 60,
                            lg: 24,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.14),
                                      blurRadius: 15,
                                      spreadRadius: -5,
                                    ),
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 2,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: colorList[i]
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.rectangle,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Icon(iconList[i],
                                              color: colorList[i]),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            nameList[i],
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10.0),
                                    Row(
                                      children: [
                                        Text(
                                          lang.S.of(context).remaining,
                                          style: const TextStyle(
                                              color: kGreyTextColor),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          initialPackageService[i] == '-202'
                                              ? lang.S.of(context).unlimited
                                              : '(${initialPackageService[i]}/${originalPackageService[i]})',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ));
                      })),
                  // SizedBox(
                  //   height: 150,
                  //   child: ListView.builder(
                  //       scrollDirection: Axis.horizontal,
                  //       shrinkWrap: true,
                  //       physics: const BouncingScrollPhysics(),
                  //       itemCount: nameList.length,
                  //       padding: const EdgeInsets.all(10.0),
                  //       itemBuilder: (_, i) {
                  //         return Padding(
                  //           padding: const EdgeInsets.all(10.0),
                  //           child: Container(
                  //             padding: const EdgeInsets.all(10.0),
                  //             decoration: BoxDecoration(
                  //               borderRadius: BorderRadius.circular(8.0),
                  //               color: Colors.white,
                  //               boxShadow: [
                  //                 BoxShadow(
                  //                   color: Colors.black.withValues(alpha: 0.14),
                  //                   blurRadius: 15,
                  //                   spreadRadius: -5,
                  //                 ),
                  //                 BoxShadow(
                  //                   color: Colors.black.withValues(alpha: 0.05),
                  //                   blurRadius: 2,
                  //                   spreadRadius: 0,
                  //                   offset: const Offset(0, 2),
                  //                 ),
                  //               ],
                  //             ),
                  //             child: Column(
                  //               crossAxisAlignment: CrossAxisAlignment.start,
                  //               children: [
                  //                 Row(
                  //                   children: [
                  //                     Container(
                  //                       padding: const EdgeInsets.all(8.0),
                  //                       decoration: BoxDecoration(
                  //                         color: colorList[i].withOpacity(0.1),
                  //                         shape: BoxShape.rectangle,
                  //                         borderRadius: BorderRadius.circular(4),
                  //                       ),
                  //                       child: Icon(iconList[i], color: colorList[i]),
                  //                     ),
                  //                     const SizedBox(width: 8),
                  //                     Text(
                  //                       nameList[i],
                  //                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  //                     ),
                  //                   ],
                  //                 ),
                  //                 const SizedBox(height: 10.0),
                  //                 Row(
                  //                   children: [
                  //                     Text(
                  //                       lang.S.of(context).remaining,
                  //                       style: const TextStyle(color: kGreyTextColor),
                  //                     ),
                  //                     const SizedBox(width: 20),
                  //                     Text(
                  //                       initialPackageService[i] == '-202' ? lang.S.of(context).unlimited : '(${initialPackageService[i] ?? ''}/${originalPackageService[i]})',
                  //                       style: const TextStyle(color: Colors.grey),
                  //                     ),
                  //                   ],
                  //                 )
                  //               ],
                  //             ),
                  //           ),
                  //         );
                  //       }),
                  // ),
                  // const SizedBox(height: 15),
                  //______________________________________________Package_Features
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      lang.S.of(context).forUnlimitedUses,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).visible(subscriptionModel.subscriptionName != 'Lifetime'),
                  const SizedBox(height: 20),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(screenWidth < 570 ? 570 : 400, 48),
                        ),
                        onPressed: () {
                          context.go('/subscription/purchase-plan', extra: {
                            'initialSelectedPackage': 'Yearly',
                            'initPackageValue': 0,
                          });
                        },
                        child: Text(
                          lang.S.of(context).updateNow,
                        ),
                      ),
                      // child: ElevatedButton(
                      //   style: ElevatedButton.styleFrom(minimumSize: Size(screenWidth < 570 ? 570 : 400, 48)),
                      //   onPressed: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => const PurchasePlan(
                      //           initialSelectedPackage: 'Yearly',
                      //           initPackageValue: 0,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      //   child: Text(
                      //     lang.S.of(context).updateNow,
                      //   ),
                      // ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
