import '../../../../services/api_service.dart';
import '../model/employee_model.dart';

/// Servicio para crear/gestionar credenciales de acceso de un empleado.
///
/// Flujo:
///   1. POST /auth/register con datos del empleado + permisos mínimos
///   2. PUT /hrm/employees/{id} para persistir user_id + can_login = true
///
/// Roles soportados:
///   - 'employee'           → ve solo sus tareas (/my-tasks)
///   - 'department_head'    → ve su departamento + panel encargado
class EmployeeCredentialsService {
  final ApiService _apiService = ApiService();

  /// Permisos mínimos de un empleado regular (solo sus tareas)
  static const List<Map<String, dynamic>> _employeePermissions = [
    {'type': 'my_tasks', 'view': true, 'edit': true, 'delete': false},
  ];

  /// Permisos del encargado (ve departamento + puede asignar)
  /// NO incluye 'hrm' para que no aparezca "Recursos Humanos" en sidebar
  static const List<Map<String, dynamic>> _headPermissions = [
    {'type': 'department_head', 'view': true, 'edit': true, 'delete': false},
    {'type': 'my_tasks', 'view': true, 'edit': true, 'delete': false},
  ];

  /// Crea credenciales para el empleado y vincula user_id + can_login en BD
  ///
  /// Retorna `CreateCredentialsResult.success(userId)` si todo funcionó,
  /// o `CreateCredentialsResult.failure(reason)` si falló en algún paso.
  Future<CreateCredentialsResult> createCredentials({
    required EmployeeModel employee,
    required String username,
    required String password,
    required bool isDepartmentHead,
    required String branchId,
  }) async {
    try {
      final permissions = isDepartmentHead ? _headPermissions : _employeePermissions;
      final permissionsObject = _toPermissionsObject(permissions);
      final role = isDepartmentHead ? 'department_head' : 'employee';

      String? userId;

      // Buscar si ya existe un user vinculado a este empleado (por userId o por linked_employee_id)
      String? existingUserId = employee.userId;
      if (existingUserId == null || existingUserId.isEmpty) {
        // Buscar en la API por linked_employee_id
        final searchResp = await _apiService.get('users', queryParams: {
          'search': employee.id?.toString() ?? '',
          'limit': '5',
        });
        if (searchResp.success && searchResp.data != null) {
          final users = searchResp.data['users'] as List<dynamic>? ?? [];
          for (final u in users) {
            if (u is Map && u['linked_employee_id']?.toString() == employee.id?.toString()) {
              existingUserId = u['id']?.toString();
              break;
            }
          }
        }
      }

      if (existingUserId != null && existingUserId.isNotEmpty) {
        // Reactivar: actualizar datos del user existente
        final updateResp = await _apiService.put(
          'users/$existingUserId',
          {
            'name': employee.fullName,
            'email': username,
            'username': username,
            'role': role,
            'branch_id': branchId,
            'allowed_branches': [branchId],
            'is_active': true,
            'permissions': permissionsObject,
            'scoped_designation_id': employee.designationId,
            'linked_employee_id': employee.id?.toString(),
          },
        );

        if (updateResp.success) {
          // Cambiar contraseña
          await _apiService.put(
            'auth/users/$existingUserId/reset-password',
            {'newPassword': password},
          );
          userId = existingUserId;
        }
      }

      // Si no se pudo reactivar, crear nuevo
      if (userId == null) {
        final registerBody = {
          'email': username,
          'username': username,
          'password': password,
          'name': employee.fullName,
          'role': role,
          'branch_id': branchId,
          'allowed_branches': [branchId],
          'permissions': permissionsObject,
          'scoped_designation_id': employee.designationId,
          'linked_employee_id': employee.id?.toString(),
        };

        final registerResponse = await _apiService.post('auth/register', registerBody);

        if (!registerResponse.success) {
          return CreateCredentialsResult.failure(
            registerResponse.message ?? 'No se pudo crear el usuario',
          );
        }

        userId = _extractUserId(registerResponse.data);
        if (userId == null) {
          return CreateCredentialsResult.failure(
            'Respuesta inválida del servidor: falta user_id',
          );
        }
      }

      // Vincular el user_id al empleado y activar can_login
      employee.userId = userId;
      employee.canLogin = true;
      employee.isDepartmentHead = isDepartmentHead;

      final updateResponse = await _apiService.put(
        'hrm/employees/${employee.id}',
        {
          'user_id': userId,
          'can_login': true,
          'is_department_head': isDepartmentHead,
        },
      );

      if (!updateResponse.success) {
        return CreateCredentialsResult.failure(
          'Usuario creado (ID $userId) pero falló la vinculación al empleado. '
          'Contacta soporte.',
        );
      }

      return CreateCredentialsResult.success(userId);
    } catch (e) {
      return CreateCredentialsResult.failure('Error: $e');
    }
  }

  /// Revoca acceso: desactiva can_login en el empleado.
  /// No elimina el user del sistema (por auditoría).
  Future<CreateCredentialsResult> revokeAccess({required EmployeeModel employee}) async {
    try {
      final response = await _apiService.put(
        'hrm/employees/${employee.id}',
        {'can_login': false},
      );
      if (response.success) {
        employee.canLogin = false;
        return CreateCredentialsResult.success(employee.userId ?? '');
      }
      return CreateCredentialsResult.failure(
        response.message ?? 'No se pudo revocar el acceso',
      );
    } catch (e) {
      return CreateCredentialsResult.failure('Error: $e');
    }
  }

  /// Backend espera permisos como objeto { type: {view, edit, delete} }
  /// (ver patrón en add_user_role_screen.dart)
  Map<String, dynamic> _toPermissionsObject(List<Map<String, dynamic>> list) {
    final obj = <String, dynamic>{};
    for (final p in list) {
      obj[p['type'] as String] = {
        'view': p['view'] ?? false,
        'edit': p['edit'] ?? false,
        'delete': p['delete'] ?? false,
      };
    }
    return obj;
  }

  String? _extractUserId(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      if (data['user'] is Map) return data['user']['id']?.toString();
      if (data['id'] != null) return data['id'].toString();
      if (data['userId'] != null) return data['userId'].toString();
    }
    return null;
  }
}

class CreateCredentialsResult {
  final bool ok;
  final String? userId;
  final String? errorMessage;

  const CreateCredentialsResult._(this.ok, this.userId, this.errorMessage);

  factory CreateCredentialsResult.success(String userId) =>
      CreateCredentialsResult._(true, userId, null);

  factory CreateCredentialsResult.failure(String message) =>
      CreateCredentialsResult._(false, null, message);
}
