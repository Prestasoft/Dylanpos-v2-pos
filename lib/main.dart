// import 'dart:convert'; // No usado actualmente
// Firebase deshabilitado - No se está usando
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart' hide S;
import 'package:provider/provider.dart' as pro;
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Language/language_provider.dart';
import 'package:salespro_admin/Screen/HRM/assignments/widgets/task_theme_provider.dart';
import 'package:salespro_admin/Route/app_routes.dart';
import 'package:salespro_admin/services/tenant/tenant_model.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:salespro_admin/const.dart';
import 'package:url_strategy/url_strategy.dart';
// import 'package:http/http.dart' as http; // No usado actualmente
import 'Route/static_string.dart';
import 'Screen/Widgets/Constant Data/constant.dart';
import 'Screen/Widgets/Constant Data/theme.dart';
import 'Screen/currency/currency_provider.dart';
// Firebase deshabilitado
// import 'firebase_options.dart';
import 'generated/l10n.dart';
import 'model/paypal_info_model.dart';
import 'services/version_check_service.dart';
import 'widgets/update_dialog.dart';

// Firebase Messaging deshabilitado - No se está usando
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar SharedPreferences para nb_utils
  await initialize();

  ResponsiveGridBreakpoints.value = ResponsiveGridBreakpoints(
    sm: 576,
    md: 1240,
    lg: double.infinity,
  );
  setPathUrlStrategy();

  // Inicializar Firebase con el tenant guardado o el default
  // IMPORTANTE: Leer directamente de localStorage porque nb_utils puede tener caché vieja
  String savedTenantId = '';
  if (kIsWeb) {
    savedTenantId = html.window.localStorage['selected_tenant_id'] ?? '';
    debugPrint('🌐 localStorage - selected_tenant_id: $savedTenantId');
  }
  // Fallback a nb_utils si localStorage está vacío
  if (savedTenantId.isEmpty) {
    savedTenantId = getStringAsync('selected_tenant_id');
    debugPrint('📦 nb_utils - selected_tenant_id: $savedTenantId');
  }

  TenantModel targetTenant;
  if (savedTenantId.isNotEmpty) {
    targetTenant = TenantConfig.getTenantById(savedTenantId) ?? TenantConfig.defaultTenant;
  } else {
    targetTenant = TenantConfig.defaultTenant;
  }

  debugPrint('🏢 Tenant seleccionado: ${targetTenant.city} (${targetTenant.id})');

  // Firebase deshabilitado - No se está usando
  // await Firebase.initializeApp(
  //   options: targetTenant.firebaseOptions,
  // );

  // Guardar el tenant actual en ambos: SharedPreferences y localStorage
  await setValue('selected_tenant_id', targetTenant.id);
  if (kIsWeb) {
    html.window.localStorage['selected_tenant_id'] = targetTenant.id;
    debugPrint('💾 localStorage actualizado con tenant: ${targetTenant.id}');
  }

  // Firebase Messaging deshabilitado
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // IMPORTANTE: Inicializar ApiService ANTES de runApp para cargar token de sesión
  // Esto permite que el router verifique autenticación correctamente al recargar página
  await ApiService().init();
  debugPrint('🔐 ApiService inicializado - isAuthenticated: ${ApiService().isAuthenticated}');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final VersionCheckService _versionCheckService = VersionCheckService();
  
  @override
  void initState() {
    super.initState();
    // Firebase Messaging deshabilitado
    // _initFirebaseMessaging();
    _initVersionCheck();
  }
  
  @override
  void dispose() {
    _versionCheckService.stopVersionCheck();
    super.dispose();
  }

  // Firebase Messaging deshabilitado - No se está usando
  // Future<void> _initFirebaseMessaging() async {
  //   FirebaseMessaging messaging = FirebaseMessaging.instance;
  //
  //   // Solicita permiso para notificaciones
  //   await messaging.requestPermission();
  //
  //   // Obtiene el token FCM
  //   String? token = await messaging.getToken(
  //     vapidKey: 'BHihs1laCgF-by2riBdLNshy3Zivz9LITx4Ut_Xv34KIwZGEof8X8u-lTRQG7Iwi1K2WBDXUkRNbYi0Z_7ov7fo' // Santiago VAPID key
  //   );
  //
  //   if (token != null) {
  //     // Guarda el token FCM en PostgreSQL API
  //     try {
  //       final apiService = ApiService();
  //       await apiService.put('settings/fcm-token', {'fcmToken': token});
  //     } catch (e) {
  //       // Error silencioso
  //     }
  //   }
  //
  //   // Escucha notificaciones mientras la app está activa (foreground)
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     // Aquí puedes disparar un modal, alerta, badge, etc.
  //   });
  // }
  
  void _initVersionCheck() {
    // Configurar callback para cuando se detecte una actualización
    _versionCheckService.onUpdateAvailable = (versionInfo) {
      // Mostrar diálogo de actualización si el contexto está disponible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Usar try-catch para evitar errores si el Navigator no está disponible
          try {
            final navigatorState = Navigator.maybeOf(context);
            if (navigatorState != null) {
              showUpdateDialog(context, versionInfo);
            } else {
              debugPrint('⚠️ Navigator no disponible para mostrar diálogo de actualización');
            }
          } catch (e) {
            debugPrint('⚠️ Error al mostrar diálogo de actualización: $e');
          }
        }
      });
    };

    // Iniciar verificación periódica (cada 5 minutos)
    _versionCheckService.startVersionCheck(
      interval: const Duration(minutes: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    getPaypalInfo();
    return pro.MultiProvider(
      providers: [
        pro.ChangeNotifierProvider<LanguageChangeProvider>(
          create: (context) => LanguageChangeProvider(),
        ),
        pro.ChangeNotifierProvider<CurrencyProvider>(
          create: (context) => CurrencyProvider(),
        ),
        pro.ChangeNotifierProvider<TaskThemeProvider>(
          create: (context) => TaskThemeProvider(),
        ),
      ],
      child: Builder(
        builder: (context) => rf.ResponsiveBreakpoints.builder(
          breakpoints: [
            rf.Breakpoint(start: BreakpointName.XS.start, end: BreakpointName.XS.end, name: BreakpointName.XS.name),
            rf.Breakpoint(start: BreakpointName.SM.start, end: BreakpointName.SM.end, name: BreakpointName.SM.name),
            rf.Breakpoint(start: BreakpointName.MD.start, end: BreakpointName.MD.end, name: BreakpointName.MD.name),
            rf.Breakpoint(start: BreakpointName.LG.start, end: BreakpointName.LG.end, name: BreakpointName.LG.name),
            rf.Breakpoint(start: BreakpointName.XL.start, end: BreakpointName.XL.end, name: BreakpointName.XL.name),
          ],
          child: MaterialApp.router(
            locale: pro.Provider.of<LanguageChangeProvider>(context, listen: true).currentLocale,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            builder: EasyLoading.init(),
            debugShowCheckedModeBanner: false,
            title: appsTitle,
            theme: AcnooTheme.kLightTheme(context),
            routerConfig: AcnooAppRoutes.routerConfig,
          ),
        ),
      ),
    );
  }

  /// Obtener información de PayPal - Usa PostgreSQL API
  Future<void> getPaypalInfo() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('settings/paypal-info');

      if (response.success && response.data != null) {
        final paypalData = response.data['paypalInfo'] ?? response.data;
        PaypalInfoModel paypalInfoModel = PaypalInfoModel.fromJson(
          Map<String, dynamic>.from(paypalData)
        );

        paypalClientId = paypalInfoModel.paypalClientId;
        paypalClientSecret = paypalInfoModel.paypalClientSecret;
      }
    } catch (e) {
      // Error silencioso - configuración de PayPal no disponible
    }
  }
}
