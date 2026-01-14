import 'dart:convert';

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

final logInProvider = ChangeNotifierProvider((ref) => LogInRepo());

class LogInRepo extends ChangeNotifier {
  String email = '';
  String password = '';

  final ApiService _apiService = ApiService();

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

        // Filtrar sucursales según permisos del usuario
        List<TenantModel> availableTenants;

        if (isAdmin || branches == null || branches.isEmpty) {
          // Administrador o sin restricciones: todas las sucursales
          availableTenants = TenantConfig.allTenants;
        } else {
          // Usuario con restricciones: solo sus sucursales asignadas
          availableTenants = TenantConfig.allTenants
              .where((tenant) => branches.contains(tenant.id))
              .toList();
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
          print('[LogInRepo.signIn] Login automático a única sucursal: ${tenant.displayName}');
        } else {
          // Múltiples sucursales: mostrar modal de selección
          await _showBranchSelectorModal(context, availableTenants);
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

        // Navegar al home
        context.go('/blank-home');

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

  /// Mostrar modal para seleccionar sucursal (post-login)
  Future<void> _showBranchSelectorModal(BuildContext context, List<TenantModel> tenants) async {
    String selectedId = tenants.first.id;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false, // No permitir cerrar sin seleccionar
      barrierLabel: 'Seleccionar Sucursal',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: false, // Prevenir cierre con botón back
              child: Center(
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
                        // Header
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
                                                  : LinearGradient(
                                                      colors: [Colors.grey.shade300, Colors.grey.shade200],
                                                    ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.location_city_rounded,
                                              color: isSelected ? Colors.white : Colors.grey.shade600,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tenant.city,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected ? const Color(0xFFD59345) : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  tenant.name,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD59345),
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

                        // Botones de acción
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Configurar sucursal seleccionada
                                    await _apiService.setBranchId(selectedId);
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setString('selected_tenant_id', selectedId);

                                    // Cerrar modal y navegar
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      context.go('/blank-home');
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD59345),
                                    foregroundColor: Colors.white,
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
                            ],
                          ),
                        ),
                      ],
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
