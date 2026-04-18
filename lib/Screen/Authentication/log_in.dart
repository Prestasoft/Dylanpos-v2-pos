import 'dart:io';
import 'dart:ui';

// Firebase Auth deshabilitado - Usar ApiService para autenticación
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Repository/login_repo.dart';
import 'package:salespro_admin/Route/static_string.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Repository/signup_repo.dart';
import '../Widgets/Constant Data/constant.dart';
import 'forgot_password.dart';
import '../../services/version_check_service.dart';

class EmailLogIn extends StatefulWidget {
  const EmailLogIn({super.key});

  static const String route = '/';

  @override
  State<EmailLogIn> createState() => _EmailLogInState();
}

class _EmailLogInState extends State<EmailLogIn> {
  String email = '';
  String password = '';
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  String? user;

  bool validateAndSave() {
    final form = globalKey.currentState;
    if (form!.validate()) {
      form.save();
      email = email.trim();
      password = password.trim();
      if (email.isEmpty || password.isEmpty) {
        return false;
      }
      return true;
    }
    return false;
  }

  bool hidePassword = true;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkIfComingFromUpdate();
    _loadCurrentTenant();
  }

  void _loadCurrentTenant() async {}

  void _checkIfComingFromUpdate() async {
    final isFromUpdate = await VersionCheckService().isComingFromUpdate();
    if (isFromUpdate && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualización completada. Por favor, inicia sesión nuevamente.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      });
    }
  }

  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('saved_email') ?? '';
      password = prefs.getString('saved_password') ?? '';
      rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  void _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

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

  // Firebase Auth deshabilitado - Ya no se usa currentUser de Firebase
  // var currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final tabAndMobileScreen = isMobileAndTab(screenWidth);
    final kRegularFontSize = responsiveValue<double>(context, xs: 14, md: 14, lg: 16);
    final kSmallFontSize = responsiveValue<double>(context, xs: 14, md: 14, lg: 16);

    return Scaffold(
      backgroundColor: kAppDarkBg,
      body: Container(
        height: screenHeight,
        width: screenWidth,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/fondo_login.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Consumer(
          builder: (context, ref, watch) {
            final loginProvider = ref.watch(logInProvider);
            final settingProvider = ref.watch(generalSettingProvider);
            return settingProvider.when(
              data: (setting) {
                final dynamicAppsName = setting.commonHeaderLogo.isNotEmpty ? setting.title : appsName;

                // Layout para pantallas grandes (>= 1100px): imagen izquierda + formulario derecha
                if (screenWidth >= 1100) {
                  return Row(
                    children: [
                      // Columna izquierda: Imagen promocional de Victor Guzmán
                      Expanded(
                        flex: 6,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: kAppGoldPrimary.withValues(alpha: 0.3),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'images/portada_victor.png',
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Columna derecha: Formulario de login
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: _buildLoginFormContent(
                              loginProvider: loginProvider,
                              dynamicAppsName: dynamicAppsName,
                              kRegularFontSize: kRegularFontSize,
                              kSmallFontSize: kSmallFontSize,
                              maxWidth: 420,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Layout móvil/tablet: formulario centrado
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildLoginFormContent(
                      loginProvider: loginProvider,
                      dynamicAppsName: dynamicAppsName,
                      kRegularFontSize: kRegularFontSize,
                      kSmallFontSize: kSmallFontSize,
                      maxWidth: tabAndMobileScreen ? screenWidth * 0.9 : 450,
                    ),
                  ),
                );
              },
              error: (e, stack) {
                return Center(
                  child: Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
              loading: () {
                return const Center(
                  child: CircularProgressIndicator(color: kAppGoldPrimary),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Widget del formulario de login con estilo glassmorphism dorado/negro
  Widget _buildLoginFormContent({
    required LogInRepo loginProvider,
    required String dynamicAppsName,
    required double kRegularFontSize,
    required double kSmallFontSize,
    required double maxWidth,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kAppDarkBg.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: kAppGoldPrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo / Título con gradiente dorado
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: kAppGoldGradient,
                  ).createShader(bounds),
                  child: Text(
                    dynamicAppsName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenido de nuevo',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: kRegularFontSize,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),

                // Formulario
                Form(
                  key: globalKey,
                  child: Column(
                    children: [
                      // Campo Email/Usuario
                      TextFormField(
                        showCursor: true,
                        cursorColor: kAppGoldPrimary,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Usuario o email requerido';
                          }
                          return null;
                        },
                        initialValue: email,
                        onChanged: (value) {
                          loginProvider.email = value.trim();
                          email = value.trim();
                        },
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: kAppGoldPrimary, width: 0.5)),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.person_outline, color: kAppGoldPrimary, size: 22),
                            ),
                          ),
                          labelText: 'Usuario o Email',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Ingrese su usuario o email',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                          filled: true,
                          fillColor: kAppCardBg,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kAppGoldPrimary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo Password
                      TextFormField(
                        showCursor: true,
                        cursorColor: kAppGoldPrimary,
                        keyboardType: TextInputType.visiblePassword,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Password can\'t be empty';
                          } else if (value.trim().length < 4) {
                            return 'Please enter a bigger password';
                          }
                          return null;
                        },
                        initialValue: password,
                        onChanged: (value) {
                          loginProvider.password = value.trim();
                          password = value.trim();
                        },
                        onEditingComplete: () async {
                          password = password.trim();
                          if (validateAndSave()) {
                            bool isActive = await checkUser(context: context);
                            if (isActive) {
                              password = password.trim();
                              _saveCredentials();
                              loginProvider.email = email.trim();
                              loginProvider.password = password;
                              loginProvider.signIn(context);
                            } else {
                              EasyLoading.showInfo(lang.S.of(context).pleaseUseTheValidPurchaseCodeToUseTheApp);
                            }
                          }
                        },
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: kAppGoldPrimary, width: 0.5)),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.lock_outline, color: kAppGoldPrimary, size: 22),
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
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                          labelText: lang.S.of(context).password,
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: lang.S.of(context).enterYourPassword,
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                          filled: true,
                          fillColor: kAppCardBg,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kAppGoldPrimary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Recordar credenciales
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value ?? false;
                                });
                              },
                              activeColor: kAppGoldPrimary,
                              checkColor: kAppDarkBg,
                              side: const BorderSide(color: Colors.white38),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recordar credenciales',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Botón de Login con gradiente dorado
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: kAppGoldGradient,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kAppGoldPrimary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            password = password.trim();
                            if (validateAndSave()) {
                              bool isActive = await checkUser(context: context);
                              if (isActive) {
                                password = password.trim();
                                _saveCredentials();
                                loginProvider.email = email.trim();
                                loginProvider.password = password;
                                loginProvider.signIn(context);
                              } else {
                                EasyLoading.showInfo(lang.S.of(context).pleaseUseTheValidPurchaseCodeToUseTheApp);
                              }
                            }
                          },
                          child: Text(
                            lang.S.of(context).login,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kAppDarkBg,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Forgot Password
                      TextButton(
                        onPressed: () {
                          context.go(ForgotPassword.route);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              MdiIcons.lockAlertOutline,
                              color: Colors.white54,
                              size: kSmallFontSize,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lang.S.of(context).forgotPassword,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: kSmallFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Badge de versión con estilo dorado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: kAppCardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: kAppGoldPrimary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Líneas decorativas doradas
                            Container(
                              width: 20,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    kAppGoldPrimary.withValues(alpha: 0.5),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22c55e),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'v2.1.537',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kAppGoldPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 20,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    kAppGoldPrimary.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
