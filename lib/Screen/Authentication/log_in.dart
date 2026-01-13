import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Repository/login_repo.dart';
import 'package:salespro_admin/Route/static_string.dart';
//import 'package:salespro_admin/Screen/Authentication/sign_up.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/services/tenant/tenant_model.dart';
import 'package:salespro_admin/services/tenant/tenant_cache_service.dart';

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
  // Inicializar como strings vacíos para evitar null
  String email = '';
  String password = '';
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  String? user;

  // Tenant/Sucursal actual
  String _currentTenantCity = 'Cargando...';
  String _currentTenantId = '';

  bool validateAndSave() {
    final form = globalKey.currentState;
    if (form!.validate()) {
      form.save();
      // Asegurar que email y password estén limpios
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

  void _loadCurrentTenant() async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId = prefs.getString('selected_tenant_id') ?? 'sde';
    final tenant = TenantConfig.getTenantById(tenantId);
    if (mounted && tenant != null) {
      setState(() {
        _currentTenantCity = tenant.city;
        _currentTenantId = tenant.id;
      });
    }
  }

  void _showChangeBranchDialog(BuildContext context) {
    final allTenants = TenantConfig.allTenants;
    String? selectedId = _currentTenantId;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width > 500 ? 450 : MediaQuery.of(context).size.width * 0.92,
                  constraints: const BoxConstraints(maxHeight: 600),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 40,
                        spreadRadius: 5,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header con gradiente
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD59345),
                              const Color(0xFFE8A85C),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.business_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Seleccionar Sucursal',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Elige la ubicación donde deseas trabajar',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lista de sucursales
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: Column(
                            children: allTenants.map((tenant) {
                              final isSelected = tenant.id == selectedId;
                              final isCurrent = tenant.id == _currentTenantId;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedId = tenant.id;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [
                                                const Color(0xFFD59345).withValues(alpha: 0.15),
                                                const Color(0xFFE8A85C).withValues(alpha: 0.08),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: isSelected ? null : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFD59345)
                                            : Colors.grey.shade200,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFD59345).withValues(alpha: 0.2),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        // Avatar con icono de ubicación
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? const LinearGradient(
                                                    colors: [Color(0xFFD59345), Color(0xFFE8A85C)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : null,
                                            color: isSelected ? null : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.location_city_rounded,
                                              color: isSelected ? Colors.white : Colors.grey.shade500,
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Información
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      tenant.city,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: isSelected
                                                            ? const Color(0xFFD59345)
                                                            : Colors.grey.shade800,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isCurrent) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.shade100,
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Text(
                                                        'Actual',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.green.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                tenant.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Radio button estilizado
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: isSelected
                                                ? const LinearGradient(
                                                    colors: [Color(0xFFD59345), Color(0xFFE8A85C)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : null,
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFFD59345)
                                                  : Colors.grey.shade300,
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Footer con botones
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: selectedId != _currentTenantId
                                    ? () {
                                        Navigator.of(context).pop();
                                        final tenant = TenantConfig.getTenantById(selectedId!);
                                        if (tenant != null) {
                                          _switchToTenant(tenant);
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: const Color(0xFFD59345),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.swap_horiz_rounded,
                                      color: selectedId != _currentTenantId
                                          ? Colors.white
                                          : Colors.grey.shade500,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cambiar Sucursal',
                                      style: TextStyle(
                                        color: selectedId != _currentTenantId
                                            ? Colors.white
                                            : Colors.grey.shade500,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
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
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _switchToTenant(TenantModel tenant) async {
    // Mostrar diálogo de confirmación profesional
    if (!mounted) return;

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width > 450 ? 420 : MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono animado
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD59345).withValues(alpha: 0.15),
                          const Color(0xFFE8A85C).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horizontal_circle_rounded,
                      size: 56,
                      color: Color(0xFFD59345),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  const Text(
                    'Cambiar de Sucursal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Información del cambio
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // De
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Actual',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentTenantCity,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        // Flecha
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: const Color(0xFFD59345),
                            size: 28,
                          ),
                        ),
                        // A
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Nueva',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tenant.city,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD59345),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Advertencia
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Se limpiará la caché y la página se recargará automáticamente.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFFD59345),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Confirmar Cambio',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
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
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );

    if (confirmed != true) return;

    // Mostrar loading mientras se limpia la caché
    EasyLoading.show(status: 'Preparando cambio de sucursal...');

    try {
      // Usar el servicio de caché para limpiar y recargar
      final cacheService = TenantCacheService();

      // Limpiar caché (cierra sesión de Firebase, limpia SharedPreferences y localStorage)
      await cacheService.clearCacheForTenantSwitch(tenant.id);

      EasyLoading.showSuccess('Recargando aplicación...', duration: const Duration(seconds: 1));

      // Esperar un momento para que el usuario vea el mensaje
      await Future.delayed(const Duration(milliseconds: 800));

      // Recargar la página automáticamente
      cacheService.reloadWebPage();

    } catch (e) {
      EasyLoading.dismiss();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar de sucursal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _checkIfComingFromUpdate() async {
    final isFromUpdate = await VersionCheckService().isComingFromUpdate();
    if (isFromUpdate && mounted) {
      // Mostrar mensaje de éxito
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
      backgroundColor: Colors.transparent, // Cambiado a transparente para mostrar la imagen de fondo
      body: Container(
        height: MediaQuery.of(context).size.height, // Asegurar que ocupe toda la altura
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/fondo2.webp'), // Cambia la ruta si deseas otra imagen
            fit: BoxFit.cover,
          ),
        ),
        child: Consumer(
          builder: (context, ref, watch) {
            final loginProvider = ref.watch(logInProvider);
            final settingProvider = ref.watch(generalSettingProvider);
            return settingProvider.when(
              data: (setting) {
                final dynamicNameLogo = setting.commonHeaderLogo.isNotEmpty ? setting.commonHeaderLogo : null;
                final dynamicAppsName = setting.commonHeaderLogo.isNotEmpty ? setting.title : appsName;
                return Padding(
                  padding: screenWidth < 400 ? const EdgeInsets.all(8) : const EdgeInsets.all(20.0),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 40, // Restar el padding
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - 40,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        // Logo comentado - dynamicNameLogo != null ? Image.network(dynamicNameLogo, height: 50) : SvgPicture.asset(nameLogo, height: 50),
                        Center(
                          child: ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                            ResponsiveGridCol(
                                lg: 6,
                                md: screenWidth < 650 ? 12 : 6,
                                xs: 12,
                                child: Center(
                                  child: Container(
                                    height: tabAndMobileScreen ? MediaQuery.of(context).size.width / 1.1 : MediaQuery.of(context).size.height / 1.2,
                                    decoration: BoxDecoration(image: DecorationImage(image: AssetImage(tabAndMobileScreen ? 'images/loginLogo2.png' : 'images/loginLogo2.png'))),
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: RichText(
                                                  text: TextSpan(text: '${_currentTenantCity.toUpperCase()} ', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: kTitleColor, fontWeight: FontWeight.bold), children: [
                                                TextSpan(
                                                  text: dynamicAppsName,
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: const Color.fromRGBO(0, 167, 250, 1), fontWeight: FontWeight.bold),
                                                )
                                              ])),
                                            ),
                                            // Botón para cambiar sucursal
                                            TextButton.icon(
                                              onPressed: () => _showChangeBranchDialog(context),
                                              icon: const Icon(Icons.store, size: 18, color: Color(0xFFD59345)),
                                              label: const Text('Cambiar', style: TextStyle(color: Color(0xFFD59345), fontSize: 12)),
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ),
                                          ],
                                        ),
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
                                                textFieldType: TextFieldType.NAME,
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
                                                        icon: HugeIcons.strokeRoundedUser,
                                                        color: kNeutral600,
                                                        size: 24.0,
                                                      ),
                                                    ),
                                                  ),
                                                  labelText: 'Usuario o Email',
                                                  labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                  hintText: 'Ingrese su usuario o email',
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
                                              const SizedBox(height: 10.0),
                                              Row(
                                                children: [
                                                  Checkbox(
                                                    value: rememberMe,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        rememberMe = value ?? false;
                                                      });
                                                    },
                                                  ),
                                                  Text('Recordar credenciales', style: Theme.of(context).textTheme.bodyMedium),
                                                ],
                                              ),
                                              const SizedBox(height: 20.0),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  minimumSize: Size(screenWidth, 48),
                                                  backgroundColor: const Color(0xFFD59345), // Cambiado a color #d59345
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
                                                child: Text(lang.S.of(context).login),
                                              ),
                                              const SizedBox(height: 20.0),
                                              
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
                                        
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              // Badge de versión en pantalla de login
                                              Center(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        const Color(0xFF6366f1).withOpacity(0.1),
                                                        const Color(0xFF8b5cf6).withOpacity(0.1),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: const Color(0xFF6366f1).withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
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
                                                        'v2.1.76',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF6366f1),
                                                        ),
                                                      ),
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
                                ),
                              ),
                            )
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
              error: (e, stack) {
                return Text(e.toString());
              },
              loading: () {
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
