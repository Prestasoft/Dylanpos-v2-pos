import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Repository/login_repo.dart';
import 'package:salespro_admin/Route/static_string.dart';
import 'package:salespro_admin/Screen/Authentication/sign_up.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Repository/signup_repo.dart';
import '../Widgets/Constant Data/constant.dart';
import 'forgot_password.dart';

class EmailLogIn extends StatefulWidget {
  const EmailLogIn({super.key});

  static const String route = '/';

  @override
  State<EmailLogIn> createState() => _EmailLogInState();
}

class _EmailLogInState extends State<EmailLogIn> {
  late String email, password;
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  String? user;

  bool validateAndSave() {
    final form = globalKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  bool hidePassword = true;
  Future<bool> checkUser({required BuildContext context}) async {
    final isActive = await PurchaseModel().isActiveBuyer();
    if (isActive) {
      validateAndSave();
      return true;
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Not Active User"),
          content: const Text("Please use the valid purchase code to use the app."),
          actions: [
            TextButton(
              onPressed: () {
                // Exit app
                if (Platform.isAndroid) {
                  SystemNavigator.pop();
                } else {
                  exit(0);
                }
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return false;
    }
  }

  void showPopUP() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: SizedBox(
            height: 400,
            width: 600,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        FeatherIcons.x,
                        color: kTitleColor,
                      ).onTap(() {
                        finish(context);
                      }),
                    ],
                  ),
                  const SizedBox(height: 100.0),
                  Text(
                    lang.S.of(context).pleaseDownloadOurMobileApp,
                    textAlign: TextAlign.center,
                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 21.0),
                  ),
                  const SizedBox(height: 50.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 60,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          image: const DecorationImage(image: AssetImage('images/playstore.png'), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 20.0),
                      Container(
                        height: 60,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          image: const DecorationImage(image: AssetImage('images/appstore.png'), fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  var currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabAndMobileScreen = isMobileAndTab(screenWidth);
    final kLargeFontSize = responsiveValue<double>(context, xs: 24, md: 24, lg: 40);
    final kRegularFontSize = responsiveValue<double>(context, xs: 14, md: 14, lg: 20);
    final kSmallFontSize = responsiveValue<double>(context, xs: 14, md: 14, lg: 18);

    return Scaffold(
        backgroundColor: kMainColor,
        body: Consumer(builder: (context, ref, watch) {
          final loginProvider = ref.watch(logInProvider);
          final settingProvider = ref.watch(generalSettingProvider);
          return settingProvider.when(data: (setting) {
            final dynamicNameLogo = setting.commonHeaderLogo.isNotEmpty ? setting.commonHeaderLogo : null;
            final dynamicAppsName = setting.commonHeaderLogo.isNotEmpty ? setting.title : appsName;
            return Padding(
              padding: screenWidth < 400 ? const EdgeInsets.all(8) : const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dynamicNameLogo != null ? Image.network(dynamicNameLogo, height: 50) : SvgPicture.asset(nameLogo, height: 50),
                    Center(
                      child: ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        ResponsiveGridCol(
                            lg: 6,
                            md: screenWidth < 650 ? 12 : 6,
                            xs: 12,
                            child: Center(
                              child: Container(
                                height: tabAndMobileScreen ? MediaQuery.of(context).size.width / 1.1 : MediaQuery.of(context).size.height / 1.2,
                                decoration: BoxDecoration(image: DecorationImage(image: AssetImage(tabAndMobileScreen ? 'images/loginLogo2.png' : 'images/login logo.png'))),
                              ),
                            )),
                        ResponsiveGridCol(
                          md: screenWidth < 650 ? 12 : 6,
                          sm: 12,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: screenWidth < 380 ? EdgeInsets.zero : const EdgeInsets.only(left: 20, right: 25),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(tabAndMobileScreen ? 20 : 40),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                        text: TextSpan(text: 'Santo Domingo ', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: kLargeFontSize, color: kTitleColor, fontWeight: FontWeight.bold), children: [
                                      TextSpan(
                                        text: dynamicAppsName,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: kLargeFontSize, color: kMainColor, fontWeight: FontWeight.bold),
                                      )
                                    ])),
                                    Text(
                                      'Bienvenido de nuevo, por favor inicia sesión en tu cuenta',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: kRegularFontSize, color: kNeutral500),
                                    ),
                                    SizedBox(height: tabAndMobileScreen ? 20 : 40.0),
                                    Form(
                                      key: globalKey,
                                      child: Column(
                                        children: [
                                          AppTextField(
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: kTitleColor),
                                            textFieldType: TextFieldType.EMAIL,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Email can\'n be empty';
                                              } else if (!value.contains('@')) {
                                                return 'Please enter a valid email';
                                              }
                                              return null;
                                            },
                                            onChanged: (value) {
                                              loginProvider.email = value;
                                            },
                                            decoration: kInputDecoration.copyWith(
                                              prefixIcon: Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  width: 48,
                                                  decoration: const BoxDecoration(
                                                    border: Border(right: BorderSide(color: kBorderColor)),
                                                    // color: Color(0xff98A2B3),
                                                  ),
                                                  child:  HugeIcon(
                                                    icon: HugeIcons.strokeRoundedMail01,
                                                    color: kNeutral600,
                                                    size: 24.0,
                                                  ),
                                                ),
                                              ),
                                              labelText: lang.S.of(context).email,
                                              labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                              hintText: lang.S.of(context).enterYourEmailAddress,
                                              hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                            ),
                                          ),
                                          const SizedBox(height: 20.0),
                                          TextFormField(
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            keyboardType: TextInputType.visiblePassword,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: kTitleColor),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Password can\'t be empty';
                                              } else if (value.length < 4) {
                                                return 'Please enter a bigger password';
                                              }
                                              return null;
                                            },
                                            onChanged: (value) {
                                              loginProvider.password = value;
                                            },
                                            obscureText: hidePassword,
                                            decoration: kInputDecoration.copyWith(
                                              prefixIcon: Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  width: 48,
                                                  decoration: const BoxDecoration(
                                                    border: Border(right: BorderSide(color: kBorderColor)),
                                                    // color: Color(0xff98A2B3),
                                                  ),
                                                  child:  HugeIcon(
                                                    icon: HugeIcons.strokeRoundedSquareLock02,
                                                    color: kNeutral600,
                                                    size: 24.0,
                                                  ),
                                                ),
                                              ),
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    hidePassword = !hidePassword;
                                                  });
                                                },
                                                icon: Icon(
                                                  hidePassword ? FeatherIcons.eyeOff : FeatherIcons.eye,
                                                  color: kGreyTextColor,
                                                ),
                                              ),
                                              labelText: lang.S.of(context).password,
                                              labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                              hintText: lang.S.of(context).enterYourPassword,
                                              hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                            ),
                                          ),
                                          const SizedBox(height: 20.0),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: Size(screenWidth, 48),
                                            ),
                                            onPressed: () async {
                                              if (validateAndSave()) {
                                                bool isActive = await checkUser(context: context);
                                                if (isActive) {
                                                  loginProvider.signIn(context);
                                                } else {
                                                  //EasyLoading.showInfo('Please use the valid purchase code to use the app.');
                                                  EasyLoading.showInfo('${lang.S.of(context).pleaseUseTheValidPurchaseCodeToUseTheApp}.');
                                                }
                                              }
                                            },
                                            child: Text(lang.S.of(context).login),
                                          ),
                                          const SizedBox(height: 20.0),
                                          // ResponsiveGridRow(children: [
                                          //   ResponsiveGridCol(
                                          //     xs: 6,
                                          //     md: screenWidth < 576 && screenWidth < 890 ? 6 : 12,
                                          //     lg: 6,
                                          //     child: IconButton(
                                          //         onPressed: () {
                                          //           context.go(ForgotPassword.route);
                                          //         },
                                          //         icon: Row(
                                          //           crossAxisAlignment: CrossAxisAlignment.center,
                                          //           mainAxisAlignment: MainAxisAlignment.center,
                                          //           children: [
                                          //             Icon(
                                          //               MdiIcons.lockAlertOutline,
                                          //               color: kTitleColor,
                                          //               size: kSmallFontSize,
                                          //             ),
                                          //             const SizedBox(width: 5.0),
                                          //             Text(
                                          //               lang.S.of(context).forgotPassword,
                                          //               textAlign: TextAlign.center,
                                          //               style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: kNeutral600, fontSize: kSmallFontSize),
                                          //             )
                                          //           ],
                                          //         )),
                                          //   ),
                                          //   ResponsiveGridCol(
                                          //       md: screenWidth < 576 && screenWidth < 890 ? 6 : 12,
                                          //       child: TextButton(
                                          //         onPressed: () {
                                          //           context.go(SignUp.route);
                                          //         },
                                          //         child: Text(
                                          //           lang.S.of(context).registration,
                                          //           style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kMainColor, fontSize: kSmallFontSize),
                                          //           textAlign: TextAlign.end,
                                          //         ),
                                          //       )),
                                          // ]),
                                          Row(
                                            spacing: 2,
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              IconButton(
                                                  padding: EdgeInsets.zero,
                                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                  onPressed: () {
                                                    context.go(ForgotPassword.route);
                                                  },
                                                  icon: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        MdiIcons.lockAlertOutline,
                                                        color: kTitleColor,
                                                        size: kSmallFontSize,
                                                      ),
                                                      const SizedBox(width: 5.0),
                                                      Text(
                                                        lang.S.of(context).forgotPassword,
                                                        textAlign: TextAlign.center,
                                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: kNeutral600, fontSize: kSmallFontSize),
                                                      )
                                                    ],
                                                  )),
                                              const Spacer(),
                                              TextButton(
                                                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: const VisualDensity(horizontal: -4, vertical: -4)),
                                                onPressed: () {
                                                  context.go(SignUp.route);
                                                },
                                                child: Text(
                                                  lang.S.of(context).registration,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kMainColor, fontSize: kSmallFontSize),
                                                  textAlign: TextAlign.end,
                                                ),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ]),
                    ),
                  ],
                ),
              ),
            );
          }, error: (e, stack) {
            return Text(e.toString());
          }, loading: () {
            return Center(
              child: CircularProgressIndicator(),
            );
          });
        }));
  }
}
