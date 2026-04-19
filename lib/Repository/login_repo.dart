import 'dart:convert';
import 'dart:ui';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../services/api_service.dart';
import '../services/audit_service.dart';
import '../services/tenant/tenant_model.dart';
import '../const.dart';
import '../model/user_role_model.dart';
import '../Screen/Widgets/Constant Data/constant.dart';

final logInProvider = ChangeNotifierProvider((ref) => LogInRepo());

class LogInRepo extends ChangeNotifier {
  String email = '';
  String password = '';

  final ApiService _apiService = ApiService();

  /// Determina la ruta de inicio según el rol del usuario
  /// Operadores de vestimentas van a /dress-operator-home
  /// Otros usuarios van a /blank-home
  String _getHomeRouteForUser() {
    if (isDressOperator()) {
      return dressOperatorHomePath;
    }
    final role = _apiService.currentUser?['role']?.toString() ?? '';
    if (role == 'employee') {
      // Recepcionistas van a Seguimiento Clientes
      final desigName = (_apiService.currentUser?['scoped_designation_name'] ?? '').toString().toLowerCase();
      if (desigName.contains('recepcion') || desigName.contains('vendedor') || desigName.contains('tienda')) {
        return '/client-tracking';
      }
      return '/hrm/my-tasks';
    }
    if (role == 'department_head') {
      // Encargada de recepción va directo a Asignaciones
      final desigName = (_apiService.currentUser?['scoped_designation_name'] ?? '').toString().toLowerCase();
      if (desigName.contains('recepcion') || desigName.contains('vendedor') || desigName.contains('tienda')) {
        return '/hrm/today-assignments';
      }
      return '/hrm/department-status';
    }
    return '/blank-home';
  }

  Future<void> signIn(BuildContext context) async {
    EasyLoading.show(status: 'Login...');
    try {
      mainLoginEmail = email;
      mainLoginPassword = password;

      // Usar nuestra API de PostgreSQL para autenticación
      final result = await _apiService.login(email, password);

      if (result.success) {
        EasyLoading.showSuccess('Successful');

        // Obtener datos del usuario
        final user = result.user!;
        final userId = user['id'] ?? '';
        final userName = user['name'] ?? 'Usuario';
        final userEmail = user['email'] ?? email;
        final isAdmin = user['is_admin'] ?? false;

        // Configurar variables globales
        constUserId = userId;
        constSubUserTitle = userName;
        isSubUser = !isAdmin;

        // Convertir permisos de la API a UserRoleModel
        finalUserRoleModel = _apiService.toUserRoleModel();

        // Guardar en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userPermission', json.encode(finalUserRoleModel.toJson()));

        // LÓGICA INTELIGENTE DE SELECCIÓN DE SUCURSALES
        // Obtener allowed_branches del usuario
        final allowedBranches = user['allowed_branches'] as List<dynamic>?;
        List<String>? branches = allowedBranches?.map((e) => e.toString()).toList();

        // Debug log para diagnóstico
        print('🔐 [Login] Usuario: $userName');
        print('🔐 [Login] isAdmin: $isAdmin');
        print('🔐 [Login] userRoleName: ${finalUserRoleModel.userRoleName}');
        print('🔐 [Login] isDressOperator(): ${isDressOperator()}');
        print('🔐 [Login] homeRoute: ${_getHomeRouteForUser()}');
        print('🔐 [Login] allowed_branches desde API: $allowedBranches');
        print('🔐 [Login] branches parseado: $branches');

        // Filtrar sucursales según permisos del usuario
        List<TenantModel> availableTenants;

        // REGLA PRINCIPAL: Si el usuario tiene allowed_branches definido y NO vacío,
        // SIEMPRE usar esas sucursales, sin importar si es admin o no.
        // Solo mostrar TODAS las sucursales si allowed_branches es null/vacío Y es admin.

        if (branches != null && branches.isNotEmpty) {
          // Usuario con sucursales específicas asignadas: SIEMPRE respetar esta configuración
          availableTenants = TenantConfig.allTenants
              .where((tenant) => branches.contains(tenant.id))
              .toList();
          print('🔐 [Login] Sucursales según allowed_branches: ${availableTenants.map((t) => t.id).toList()}');
        } else if (isAdmin) {
          // Admin SIN restricciones específicas: todas las sucursales
          availableTenants = TenantConfig.allTenants;
          print('🔐 [Login] Admin sin restricciones - TODAS las sucursales');
        } else {
          // Usuario sin allowed_branches y no admin: error de configuración
          availableTenants = [];
          print('🔐 [Login] Usuario sin sucursales asignadas y no es admin');
        }

        // Decidir flujo según cantidad de sucursales disponibles
        if (availableTenants.isEmpty) {
          // Sin sucursales asignadas (error de configuración)
          EasyLoading.showError('No tienes sucursales asignadas. Contacta al administrador.');
          return;
        } else if (availableTenants.length == 1) {
          // Una sola sucursal: login automático
          final tenant = availableTenants.first;
          await _apiService.setBranchId(tenant.id);
          await prefs.setString('selected_tenant_id', tenant.id);
          // CRÍTICO: También actualizar localStorage para que ApiService y providers usen el branch correcto
          html.window.localStorage['selected_tenant_id'] = tenant.id;
          print('[LogInRepo.signIn] Login automático a única sucursal: ${tenant.displayName}');
          print('[LogInRepo.signIn] localStorage[selected_tenant_id] actualizado a: ${tenant.id}');
        } else {
          // Múltiples sucursales: mostrar modal de selección
          // Pasamos los datos del usuario para que el modal pueda completar el flujo
          await _showBranchSelectorModal(
            context,
            availableTenants,
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            isAdmin: isAdmin,
          );
          // El modal configurará la sucursal seleccionada
          return; // No continuar aquí, el modal manejará la navegación
        }

        await setUserDataOnLocalData(
          uid: userId,
          subUserTitle: userName,
          isSubUser: !isAdmin,
        );

        putUserDataImidiyate(
          uid: userId,
          title: userName,
          isSubUse: !isAdmin,
        );

        // Registrar login en auditoría
        await AuditService().logLogin(userId, userName, userEmail);

        // Navegar al home según el rol del usuario
        context.go(_getHomeRouteForUser());

      } else {
        EasyLoading.showError(result.error ?? 'Error de autenticación');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Error de autenticación'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      EasyLoading.showError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Mostrar modal para seleccionar sucursal (post-login) - Tema Oscuro/Dorado
  Future<void> _showBranchSelectorModal(
    BuildContext context,
    List<TenantModel> tenants, {
    required String userId,
    required String userName,
    required String userEmail,
    required bool isAdmin,
  }) async {
    String selectedId = tenants.first.id;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Seleccionar Sucursal',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: false,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: MediaQuery.of(context).size.width > 500 ? 450 : MediaQuery.of(context).size.width * 0.92,
                        constraints: const BoxConstraints(maxHeight: 600),
                        decoration: BoxDecoration(
                          color: kAppDarkBg.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: kAppGoldPrimary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kAppGoldPrimary.withValues(alpha: 0.15),
                              blurRadius: 40,
                              spreadRadius: 5,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header con gradiente dorado
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    kAppGoldDark.withValues(alpha: 0.3),
                                    kAppGoldPrimary.withValues(alpha: 0.15),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: kAppGoldPrimary.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Icono con borde dorado
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: kAppGoldPrimary.withValues(alpha: 0.5),
                                        width: 2,
                                      ),
                                      gradient: LinearGradient(
                                        colors: [
                                          kAppGoldDark.withValues(alpha: 0.3),
                                          kAppGoldPrimary.withValues(alpha: 0.1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [kAppGoldLight, kAppGoldPrimary],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      child: const Icon(
                                        Icons.business_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Título con gradiente dorado
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [kAppGoldLight, kAppGoldPrimary, kAppGoldLight],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ).createShader(bounds),
                                    child: const Text(
                                      'Seleccionar Sucursal',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Elige la ubicación donde deseas trabajar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.6),
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
                                  children: tenants.map((tenant) {
                                    final isSelected = tenant.id == selectedId;

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
                                            color: isSelected
                                                ? kAppGoldPrimary.withValues(alpha: 0.15)
                                                : kAppCardBg,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected
                                                  ? kAppGoldPrimary
                                                  : Colors.white.withValues(alpha: 0.1),
                                              width: isSelected ? 2 : 1,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: kAppGoldPrimary.withValues(alpha: 0.25),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            children: [
                                              // Icono de ubicación
                                              Container(
                                                width: 52,
                                                height: 52,
                                                decoration: BoxDecoration(
                                                  gradient: isSelected
                                                      ? const LinearGradient(
                                                          colors: [kAppGoldDark, kAppGoldPrimary],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        )
                                                      : null,
                                                  color: isSelected ? null : kAppDarkBg,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: isSelected ? null : Border.all(
                                                    color: Colors.white.withValues(alpha: 0.1),
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.location_city_rounded,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : kAppGoldPrimary.withValues(alpha: 0.7),
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              // Texto de sucursal
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      tenant.city,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: isSelected
                                                            ? kAppGoldLight
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      tenant.name,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.white.withValues(alpha: 0.5),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Check de selección
                                              if (isSelected)
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [kAppGoldDark, kAppGoldPrimary],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
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

                            // Botón Continuar con gradiente dorado
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [kAppGoldDark, kAppGoldPrimary, kAppGoldLight],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
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
                                        onPressed: () async {
                                          // Configurar sucursal seleccionada
                                          await _apiService.setBranchId(selectedId);
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.setString('selected_tenant_id', selectedId);

                                          // CRÍTICO: También guardar en localStorage para que otros providers lo lean
                                          html.window.localStorage['selected_tenant_id'] = selectedId;

                                          // CRÍTICO: Completar el flujo de inicialización del usuario
                                          // (igual que cuando hay una sola sucursal)
                                          await setUserDataOnLocalData(
                                            uid: userId,
                                            subUserTitle: userName,
                                            isSubUser: !isAdmin,
                                          );

                                          putUserDataImidiyate(
                                            uid: userId,
                                            title: userName,
                                            isSubUse: !isAdmin,
                                          );

                                          // Registrar login en auditoría
                                          await AuditService().logLogin(userId, userName, userEmail);

                                          // Cerrar modal y navegar según el rol del usuario
                                          if (context.mounted) {
                                            // Debug para diagnóstico de rol
                                            print('🔐 [Modal] userRoleName: ${finalUserRoleModel.userRoleName}');
                                            print('🔐 [Modal] isDressOperator(): ${isDressOperator()}');
                                            print('🔐 [Modal] homeRoute: ${_getHomeRouteForUser()}');

                                            Navigator.of(context).pop();
                                            context.go(_getHomeRouteForUser());
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          foregroundColor: kAppDarkBg,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Continuar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Cerrar sesión
  Future<void> signOut(BuildContext context) async {
    await _apiService.logout();

    // Limpiar variables globales
    constUserId = '';
    constSubUserTitle = '';
    isSubUser = false;
    finalUserRoleModel = UserRoleModel(
      email: '',
      userTitle: '',
      databaseId: '',
      permissions: [],
    );

    // Limpiar SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userPermission');
    await prefs.remove('userId');
    await prefs.remove('subUserTitle');
    await prefs.remove('isSubUser');

    // Navegar al login
    context.go('/login');
  }

  /// Verificar si hay sesión activa
  Future<bool> checkSession() async {
    await _apiService.init();

    if (_apiService.isAuthenticated) {
      // Cargar datos del usuario
      final user = _apiService.currentUser;
      if (user != null) {
        constUserId = user['id'] ?? '';
        constSubUserTitle = user['name'] ?? '';
        isSubUser = !(user['is_admin'] ?? false);
        finalUserRoleModel = _apiService.toUserRoleModel();
        return true;
      }
    }
    return false;
  }
}

// Función helper para verificar sesión al iniciar la app
Future<bool> initializeSession() async {
  final apiService = ApiService();
  await apiService.init();

  if (apiService.isAuthenticated) {
    final user = apiService.currentUser;
    if (user != null) {
      constUserId = user['id'] ?? '';
      constSubUserTitle = user['name'] ?? '';
      isSubUser = !(user['is_admin'] ?? false);
      finalUserRoleModel = apiService.toUserRoleModel();

      // Guardar en SharedPreferences para compatibilidad
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', constUserId);
      await prefs.setString('subUserTitle', constSubUserTitle);
      await prefs.setBool('isSubUser', isSubUser);
      await prefs.setString('userPermission', json.encode(finalUserRoleModel.toJson()));

      return true;
    }
  }
  return false;
}
