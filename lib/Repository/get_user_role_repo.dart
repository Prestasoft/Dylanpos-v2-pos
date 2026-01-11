import 'package:flutter/foundation.dart';

import '../model/user_role_model.dart';
import '../services/api_service.dart';

/// Repositorio de roles de usuario - Usa PostgreSQL API
class UserRoleRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todos los usuarios/roles desde PostgreSQL
  Future<List<UserRoleModel>> getAllUserRole() async {
    try {
      final response = await _apiService.getUsers(limit: 100);

      if (response.success && response.data != null) {
        final usersData = response.data['users'] as List<dynamic>? ?? [];
        final users = <UserRoleModel>[];

        for (var data in usersData) {
          try {
            if (data is Map<String, dynamic>) {
              // Convertir de formato PostgreSQL a UserRoleModel
              final userRole = UserRoleModel(
                email: data['email'] ?? '',
                userTitle: data['name'] ?? '',
                databaseId: data['id']?.toString() ?? '',
                userRoleName: data['role'] ?? 'user',
                permissions: _parsePermissions(data['permissions']),
              );
              userRole.userKey = data['id']?.toString();
              users.add(userRole);
            }
          } catch (e) {
            debugPrint('Error parsing user role: $e');
          }
        }
        return users;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting users: $e');
      return [];
    }
  }

  /// Convertir permisos del formato PostgreSQL a Permission list
  List<Permission> _parsePermissions(dynamic permissionsData) {
    if (permissionsData == null) return [];

    final permissions = <Permission>[];

    if (permissionsData is Map) {
      permissionsData.forEach((key, value) {
        if (value is Map) {
          permissions.add(Permission(
            type: key.toString(),
            view: value['view'] ?? false,
            edit: value['edit'] ?? false,
            delete: value['delete'] ?? false,
          ));
        }
      });
    } else if (permissionsData is List) {
      for (var perm in permissionsData) {
        if (perm is Map) {
          permissions.add(Permission(
            type: perm['type']?.toString() ?? '',
            view: perm['view'] ?? false,
            edit: perm['edit'] ?? false,
            delete: perm['delete'] ?? false,
          ));
        }
      }
    }

    return permissions;
  }

  /// Obtener todos los usuarios del panel admin (igual que getAllUserRole en PostgreSQL)
  Future<List<UserRoleModel>> getAllUserRoleFromAdmin() async {
    // En PostgreSQL todos los usuarios están en la misma tabla
    return getAllUserRole();
  }

  /// Eliminar un usuario
  Future<bool> deleteUserRole(String userKey, String adminKey, String email) async {
    try {
      if (userKey.isNotEmpty) {
        final response = await _apiService.delete('users/$userKey');
        return response.success;
      }
      return false;
    } catch (e) {
      debugPrint('Error eliminando usuario: $e');
      return false;
    }
  }

  /// Verificar si un usuario puede ser eliminado
  Future<bool> canDeleteUser(UserRoleModel user) async {
    try {
      // No permitir eliminar si es el usuario actual
      final currentUserEmail = _apiService.currentUser?['email'];

      if (user.email == currentUserEmail) {
        return false;
      }

      // Verificar que el usuario tenga email
      if (user.email == null || user.email!.isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error verificando si se puede eliminar usuario: $e');
      return false;
    }
  }

  /// Crear un nuevo usuario
  Future<UserRoleModel?> createUserRole(UserRoleModel userRole, String password) async {
    try {
      final userData = {
        'email': userRole.email,
        'password': password,
        'name': userRole.userTitle,
        'role': userRole.userRoleName,
        'permissions': userRole.permissions.map((p) => {
          'type': p.type,
          'view': p.view,
          'edit': p.edit,
          'delete': p.delete,
        }).toList(),
      };

      final response = await _apiService.createUser(userData);

      if (response.success && response.data != null) {
        final data = response.data['user'];
        return UserRoleModel(
          email: data['email'] ?? '',
          userTitle: data['name'] ?? '',
          databaseId: data['id']?.toString() ?? '',
          userRoleName: data['role'] ?? 'user',
          permissions: _parsePermissions(data['permissions']),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  /// Actualizar un usuario existente
  Future<bool> updateUserRole(String userId, UserRoleModel userRole) async {
    try {
      final userData = {
        'name': userRole.userTitle,
        'role': userRole.userRoleName,
        'permissions': userRole.permissions.map((p) => {
          'type': p.type,
          'view': p.view,
          'edit': p.edit,
          'delete': p.delete,
        }).toList(),
      };

      final response = await _apiService.updateUser(userId, userData);
      return response.success;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }
}
