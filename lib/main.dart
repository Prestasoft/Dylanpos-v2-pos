import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Language/language_provider.dart';
import 'package:salespro_admin/Route/app_routes.dart';
import 'package:salespro_admin/Screen/Payment%20Handler/payment_success.dart';
import 'package:salespro_admin/const.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:http/http.dart' as http;
import 'Route/static_string.dart';
import 'Screen/Widgets/Constant Data/constant.dart';
import 'Screen/Widgets/Constant Data/theme.dart';
import 'Screen/currency/currency_provider.dart';
import 'firebase_options.dart';
import 'generated/l10n.dart';
import 'model/paypal_info_model.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔕 Background FCM message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ResponsiveGridBreakpoints.value = ResponsiveGridBreakpoints(
    sm: 576,
    md: 1240,
    lg: double.infinity,
  );
  setPathUrlStrategy();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicita permiso para notificaciones
    await messaging.requestPermission();

    // Obtiene el token FCM
    String? token = await messaging.getToken(
      // vapidKey: 'BE356sfDxE_ue2ju2QB8ZpoWMSlmnPAExkdyoxdy34xwaw3QluB51SU9W2Rz5T8kpQYDlyxR53Xm9-q2EnO259w' //key santo domingo
      vapidKey: 'BGNqh0uT5XjU36uZosNSQbAJ-J0_V6kyPcMwQ_PE6WpoqKn4kkKpES-mc7caR6V8XEYZjQ3Dbz4AFZhpS-dMUcQ' //key santiago
    );

    if (token != null) {
      print('📲 Token FCM generado: $token');

      // Guarda el token directamente en Firebase Realtime Database
      try {
        final userId = await getUserID();
        final databaseRef = FirebaseDatabase.instance.ref('$userId/fcmToken');
        await databaseRef.set(token);
        print('✅ Token FCM guardado en Firebase');
      } catch (e) {
        print('❌ Error al guardar token en Firebase: $e');
      }
    }

    // Escucha notificaciones mientras la app está activa (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Notificación en primer plano: ${message.notification?.title}');
      // Aquí puedes disparar un modal, alerta, badge, etc.
    });
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

  Future<void> getPaypalInfo() async {
    DatabaseReference paypalRef = FirebaseDatabase.instance.ref('Admin Panel/Paypal Info');

    final paypalData = await paypalRef.get();
    PaypalInfoModel paypalInfoModel = PaypalInfoModel.fromJson(jsonDecode(jsonEncode(paypalData.value)));

    paypalClientId = paypalInfoModel.paypalClientId;
    paypalClientSecret = paypalInfoModel.paypalClientSecret;
  }
}
