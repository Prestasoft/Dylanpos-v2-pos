import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Screen/Authentication/log_in.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Repository/signup_repo.dart';
import '../../Route/static_string.dart';
import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);
  static const String route = '/signup';

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  bool passwordShow = false;
  String? givenPassword;
  String? givenPassword2;

  bool validateAndSave() {
    final form = globalKey.currentState;
    if (form!.validate() && givenPassword == givenPassword2) {
      form.save();
      return true;
    }
    return false;
  }

  bool hidePassword = false;
  bool hideConfirmPassword = false;
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
          final auth = ref.watch(signUpProvider);
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
                            md: 6,
                            sm: 12,
                            xs: 12,
                            child: Center(
                              child: Container(
                                height: tabAndMobileScreen ? MediaQuery.of(context).size.width / 1.1 : MediaQuery.of(context).size.height / 1.2,
                                decoration: BoxDecoration(image: DecorationImage(image: AssetImage(tabAndMobileScreen ? 'images/loginLogo2.png' : 'images/login logo.png'))),
                              ),
                            )),
                        ResponsiveGridCol(
                          md: 6,
                          sm: 12,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 25),
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
                                        text: TextSpan(text: 'Bienvenido a ', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: kLargeFontSize, color: kTitleColor, fontWeight: FontWeight.bold), children: [
                                      TextSpan(
                                        text: dynamicAppsName,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: kLargeFontSize, color: kMainColor, fontWeight: FontWeight.bold),
                                      )
                                    ])),
                                    Text(
                                      'Crea una cuenta para continuar',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: kRegularFontSize, color: kNeutral500),
                                    ),
                                    SizedBox(height: tabAndMobileScreen ? 20 : 40.0),
                                    Form(
                                      key: globalKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AppTextField(
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'El correo no puede estar vacío';
                                              } else if (!value.contains('@')) {
                                                return 'Por favor, introduce un correo válido';
                                              }
                                              return null;
                                            },
                                            onChanged: (value) {
                                              auth.email = value;
                                            },
                                            textFieldType: TextFieldType.EMAIL,
                                            decoration: InputDecoration(
                                              labelText: lang.S.of(context).email,
                                              hintText: 'Introduce tu dirección de correo',
                                            ),
                                          ),
                                          const SizedBox(height: 20.0),
                                          ResponsiveGridRow(children: [
                                            ResponsiveGridCol(
                                              xs: 12,
                                              md: 12,
                                              lg: 6,
                                              child: Padding(
                                                padding: EdgeInsets.only(bottom: 10, right: screenWidth > 1240 ? 10 : 0),
                                                child: AppTextField(
                                                  showCursor: true,
                                                  cursorColor: kTitleColor,
                                                  textFieldType: TextFieldType.PASSWORD,
                                                  obscureText: hidePassword,
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return 'La contraseña no puede estar vacía';
                                                    } else if (value.length < 4) {
                                                      return 'Por favor, introduce una contraseña más larga';
                                                    }
                                                    return null;
                                                  },
                                                  onChanged: (value) {
                                                    auth.password = value;
                                                    givenPassword = value;
                                                  },
                                                  decoration: InputDecoration(
                                                    labelText: lang.S.of(context).password,
                                                    suffixIcon: IconButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            hidePassword = !hidePassword;
                                                          });
                                                        },
                                                        icon: Icon(
                                                          hidePassword ? FeatherIcons.eyeOff : FeatherIcons.eye,
                                                          color: kGreyTextColor,
                                                        )),
                                                    hintText: 'Introduce tu contraseña',
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ResponsiveGridCol(
                                                xs: 12,
                                                md: 12,
                                                lg: 6,
                                                child: Padding(
                                                  padding: EdgeInsets.only(bottom: 10, left: screenWidth > 1240 ? 10 : 0),
                                                  child: AppTextField(
                                                    showCursor: true,
                                                    cursorColor: kTitleColor,
                                                    textFieldType: TextFieldType.PASSWORD,
                                                    onChanged: (value) {
                                                      givenPassword2 = value;
                                                    },
                                                    validator: (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return 'La contraseña no puede estar vacía';
                                                      } else if (value.length < 4) {
                                                        return 'Por favor, introduce una contraseña más larga';
                                                      } else if (givenPassword != givenPassword2) {
                                                        return 'Las contraseñas no coinciden';
                                                      }
                                                      return null;
                                                    },
                                                    obscureText: hidePassword,
                                                    decoration: InputDecoration(
                                                      labelText: lang.S.of(context).confirmPassword,
                                                      suffixIcon: IconButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              hidePassword = !hidePassword;
                                                            });
                                                          },
                                                          icon: Icon(
                                                            hidePassword ? FeatherIcons.eyeOff : FeatherIcons.eye,
                                                            color: kGreyTextColor,
                                                          )),
                                                      hintText: 'Introduce tu contraseña nuevamente',
                                                    ),
                                                  ),
                                                )),
                                          ]),
                                          const SizedBox(height: 20.0),
                                          ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                minimumSize: Size(screenWidth, 48),
                                              ),
                                              onPressed: (() {
                                                if (validateAndSave()) {
                                                  auth.signUp(context);
                                                }
                                              }),
                                              child: Text('Registrarse')),
                                          const SizedBox(height: 20.0),
                                          Center(
                                            child: RichText(
                                              text: TextSpan(
                                                text: '¿Ya tienes una cuenta? ',
                                                style: kTextStyle.copyWith(color: kTitleColor, fontSize: kSmallFontSize),
                                                children: [
                                                  TextSpan(
                                                    text: 'Iniciar sesión',
                                                    style: kTextStyle.copyWith(color: kGreenTextColor, fontSize: kSmallFontSize),
                                                  )
                                                ],
                                              ),
                                            ).onTap(() => context.go(EmailLogIn.route)),
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
