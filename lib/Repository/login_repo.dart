import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../services/api_service.dart';
import '../services/audit_service.dart';
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

        // IMPORTANTE: Sincronizar branch_id con el tenant seleccionado en la UI
        // Esto asegura que después del login, la API use el tenant correcto
        final selectedTenantId = prefs.getString('selected_tenant_id');
        if (selectedTenantId != null && selectedTenantId.isNotEmpty) {
          // Forzar que la API use el tenant seleccionado
          await _apiService.setBranchId(selectedTenantId);
          print('[LogInRepo.signIn] Branch sincronizado con selected_tenant_id: $selectedTenantId');
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
