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

        debugPrint('🔵 [UserRoleRepo] Cargando ${usersData.length} usuarios');

        for (var data in usersData) {
          try {
            if (data is Map<String, dynamic>) {
              final userName = data['name'] ?? data['email'] ?? 'unknown';
              final permissionsRaw = data['permissions'];

              debugPrint('🔵 [UserRoleRepo] Usuario: $userName');
              debugPrint('🔵 [UserRoleRepo] Permissions raw type: ${permissionsRaw.runtimeType}');
              debugPrint('🔵 [UserRoleRepo] Permissions raw: $permissionsRaw');

              final parsedPermissions = _parsePermissions(permissionsRaw);
              final activeCount = parsedPermissions.where((p) => p.view || p.edit || p.delete).length;
              debugPrint('🟢 [UserRoleRepo] Usuario $userName - Permisos parseados: ${parsedPermissions.length}, activos: $activeCount');

              // Convertir de formato PostgreSQL a UserRoleModel
              final userRole = UserRoleModel(
                email: data['email'] ?? '',
                userTitle: data['name'] ?? '',
                username: data['username'] ?? '',
                databaseId: data['id']?.toString() ?? '',
                userRoleName: data['role'] ?? 'user',
                branchId: data['branch_id'] ?? '',
                branchName: data['branch_name'] ?? '',
                allowedBranches: data['allowed_branches'] is List
                    ? List<String>.from(data['allowed_branches'])
                    : null,
                permissions: parsedPermissions,
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
    if (permissionsData == null) {
      debugPrint('⚠️ [_parsePermissions] permissionsData es NULL');
      return [];
    }

    final permissions = <Permission>[];

    debugPrint('🔵 [_parsePermissions] Tipo de datos: ${permissionsData.runtimeType}');

    if (permissionsData is Map) {
      debugPrint('🔵 [_parsePermissions] Parseando como Map con ${permissionsData.length} keys');
      permissionsData.forEach((key, value) {
        if (value is Map) {
          final view = value['view'] == true;
          final edit = value['edit'] == true;
          final delete = value['delete'] == true;
          permissions.add(Permission(
            type: key.toString(),
            view: view,
            edit: edit,
            delete: delete,
          ));
          if (view || edit || delete) {
            debugPrint('🟢 [_parsePermissions] Permiso activo: $key -> view=$view, edit=$edit, delete=$delete');
          }
        }
      });
    } else if (permissionsData is List) {
      debugPrint('🔵 [_parsePermissions] Parseando como List con ${permissionsData.length} items');
      for (var perm in permissionsData) {
        if (perm is Map) {
          final view = perm['view'] == true;
          final edit = perm['edit'] == true;
          final delete = perm['delete'] == true;
          permissions.add(Permission(
            type: perm['type']?.toString() ?? '',
            view: view,
            edit: edit,
            delete: delete,
          ));
          if (view || edit || delete) {
            debugPrint('🟢 [_parsePermissions] Permiso activo: ${perm['type']} -> view=$view, edit=$edit, delete=$delete');
          }
        }
      }
    } else {
      debugPrint('⚠️ [_parsePermissions] Tipo no reconocido: ${permissionsData.runtimeType}');
    }

    debugPrint('🔵 [_parsePermissions] Total permisos parseados: ${permissions.length}');
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
      // Transform permissions array to object format for backend
      final permissionsObject = <String, dynamic>{};
      for (var p in userRole.permissions) {
        permissionsObject[p.type] = {
          'view': p.view,
          'edit': p.edit,
          'delete': p.delete,
        };
      }

      final userData = {
        'email': userRole.email,
        'password': password,
        'name': userRole.userTitle,
        'role': userRole.userRoleName,
        'branch_id': userRole.branchId ?? 'stg',
        'allowed_branches': userRole.allowedBranches,
        'permissions': permissionsObject,
      };

      final response = await _apiService.createUser(userData);

      if (response.success && response.data != null) {
        final data = response.data['user'];
        return UserRoleModel(
          email: data['email'] ?? '',
          userTitle: data['name'] ?? '',
          username: data['username'] ?? '',
          databaseId: data['id']?.toString() ?? '',
          userRoleName: data['role'] ?? 'user',
          branchId: data['branch_id'] ?? '',
          branchName: data['branch_name'] ?? '',
          allowedBranches: data['allowed_branches'] is List
              ? List<String>.from(data['allowed_branches'])
              : null,
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
      // Transform permissions array to object format for backend
      final permissionsObject = <String, dynamic>{};
      for (var p in userRole.permissions) {
        permissionsObject[p.type] = {
          'view': p.view,
          'edit': p.edit,
          'delete': p.delete,
        };
      }

      final userData = {
        'name': userRole.userTitle,
        'role': userRole.userRoleName,
        'branch_id': userRole.branchId ?? 'stg',
        'allowed_branches': userRole.allowedBranches,
        'permissions': permissionsObject,
      };

      final response = await _apiService.updateUser(userId, userData);
      return response.success;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }
}
