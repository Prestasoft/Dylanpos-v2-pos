import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Screen/Authentication/log_in.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Route/static_string.dart';
import '../Widgets/Constant Data/constant.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});
  static const String route = '/resetPassword';
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  late String email;
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  bool validateAndSave() {
    final form = globalKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabAndMobileScreen = isMobileAndTab(screenWidth);
    responsiveValue<double>(context, xs: 24, md: 24, lg: 40);
    responsiveValue<double>(context, xs: 14, md: 14, lg: 20);
    responsiveValue<double>(context, xs: 14, md: 14, lg: 18);
    return Scaffold(
        backgroundColor: kMainColor,
        body: Consumer(builder: (context, ref, watch) {
          final settingProvider = ref.watch(generalSettingProvider);
          return settingProvider.when(data: (setting) {
            final dynamicNameLogo = setting.commonHeaderLogo.isNotEmpty
                ? setting.commonHeaderLogo
                : null;
            final dynamicLogo =
                setting.mainLogo.isNotEmpty ? setting.mainLogo : null;
            return Padding(
              padding: screenWidth < 400
                  ? const EdgeInsets.all(8)
                  : const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dynamicNameLogo != null
                        ? Image.network(
                            dynamicNameLogo,
                            height: 50,
                          )
                        : SvgPicture.asset(nameLogo, height: 50),
                    Center(
                      child: ResponsiveGridRow(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ResponsiveGridCol(
                                lg: 6,
                                md: 6,
                                sm: 12,
                                xs: 12,
                                child: Center(
                                  child: Container(
                                    height: tabAndMobileScreen
                                        ? MediaQuery.of(context).size.width /
                                            1.1
                                        : MediaQuery.of(context).size.height /
                                            1.2,
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: AssetImage(tabAndMobileScreen
                                                ? 'images/loginLogo2.png'
                                                : 'images/login logo.png'))),
                                  ),
                                )),
                            ResponsiveGridCol(
                              md: 6,
                              sm: 12,
                              lg: 6,
                              xs: 12,
                              child: Padding(
                                padding: screenWidth < 380
                                    ? EdgeInsets.zero
                                    : const EdgeInsets.only(
                                        left: 20, right: 25),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                        tabAndMobileScreen ? 20 : 40),
                                    child: Column(
                                      children: [
                                        Center(
                                          child: Column(
                                            children: [
                                              dynamicLogo != null
                                                  ? Container(
                                                      height: 100,
                                                      width: 200,
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          image: NetworkImage(
                                                              dynamicLogo),
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      height: 100,
                                                      width: 200,
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          image: AssetImage(
                                                              appLogo),
                                                        ),
                                                      ),
                                                    ),
                                              const SizedBox(height: 5.0),
                                              Text(
                                                lang.S
                                                    .of(context)
                                                    .resetYourPassword,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        color: kGreyTextColor,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 16.0),
                                              Form(
                                                key: globalKey,
                                                child: Column(
                                                  children: [
                                                    AppTextField(
                                                      showCursor: true,
                                                      cursorColor: kTitleColor,
                                                      textFieldType:
                                                          TextFieldType.EMAIL,
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          // return 'Email can\'n be empty';
                                                          return lang.S
                                                              .of(context)
                                                              .emailCanNotBeEmpty;
                                                        } else if (!value
                                                            .contains('@')) {
                                                          ///return 'Please enter a valid email';
                                                          return lang.S
                                                              .of(context)
                                                              .pleaseEnterAValidEmail;
                                                        }
                                                        return null;
                                                      },
                                                      onChanged: (value) {
                                                        email = value;
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                        prefixIcon: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 8),
                                                          child: Container(
                                                            alignment: Alignment
                                                                .center,
                                                            width: 48,
                                                            decoration:
                                                                const BoxDecoration(
                                                              border: Border(
                                                                  right: BorderSide(
                                                                      color:
                                                                          kBorderColor)),
                                                              // color: Color(0xff98A2B3),
                                                            ),
                                                            child: HugeIcon(
                                                              icon: HugeIcons
                                                                  .strokeRoundedMail01,
                                                              color:
                                                                  kNeutral600,
                                                              size: 24.0,
                                                            ),
                                                          ),
                                                        ),
                                                        hintText: lang.S
                                                            .of(context)
                                                            .enterYourEmailAddress,
                                                        hintStyle:
                                                            kTextStyle.copyWith(
                                                                color:
                                                                    kGreyTextColor),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: 20.0),
                                                    ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          minimumSize: Size(
                                                              screenWidth, 48),
                                                        ),
                                                        onPressed: (() async {
                                                          if (validateAndSave()) {
                                                            try {
                                                              // EasyLoading.show(status: "Sending Reset Email");
                                                              EasyLoading.show(
                                                                  status: lang.S
                                                                      .of(context)
                                                                      .sendingResetEmail);
                                                              // await FirebaseAuth.instance.sendPasswordResetEmail(
                                                              //   email: email,
                                                              // );
                                                              await FirebaseAuth
                                                                  .instance
                                                                  .sendPasswordResetEmail(
                                                                email: email,
                                                              );
                                                              //EasyLoading.showSuccess('Please Check Your Inbox');
                                                              EasyLoading
                                                                  .showSuccess(lang
                                                                      .S
                                                                      .of(context)
                                                                      .pleaseCheckYourInbox);
                                                              if (!mounted)
                                                                return;
                                                              context.go(
                                                                  EmailLogIn
                                                                      .route);
                                                              // Navigator.pushNamed(context, EmailLogIn.route);
                                                            } on FirebaseAuthException catch (e) {
                                                              if (e.code ==
                                                                  'user-not-found') {
                                                                // EasyLoading.showError('No user found for that email.');
                                                                EasyLoading
                                                                    .showError(
                                                                        '${lang.S.of(context).noUserFoundForThatEmail}.');
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    // content: Text('No user found for that email.'),
                                                                    content: Text(
                                                                        '${lang.S.of(context).noUserFoundForThatEmail}.'),
                                                                    duration: Duration(
                                                                        seconds:
                                                                            3),
                                                                  ),
                                                                );
                                                              } else if (e
                                                                      .code ==
                                                                  'wrong-password') {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    //content: Text('Wrong password provided for that user.'),
                                                                    content: Text(
                                                                        '${lang.S.of(context).wrongPasswordProvidedForThatUser}.'),
                                                                    duration: Duration(
                                                                        seconds:
                                                                            3),
                                                                  ),
                                                                );
                                                              }
                                                            } catch (e) {
                                                              EasyLoading
                                                                  .showError(e
                                                                      .toString());
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                      e.toString()),
                                                                  duration:
                                                                      const Duration(
                                                                          seconds:
                                                                              3),
                                                                ),
                                                              );
                                                            }
                                                          }
                                                        }),
                                                        child: Text(lang.S
                                                            .of(context)
                                                            .resetYourPassword)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
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
