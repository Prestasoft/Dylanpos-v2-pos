import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';

/// Modelo de usuario autenticado
class AuthUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String branchId;
  final String? phone;
  final String? userImage;
  final bool isAdmin;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.branchId,
    this.phone,
    this.userImage,
    this.isAdmin = false,
    this.createdAt,
    this.lastLogin,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'user',
      branchId: json['branch_id'] ?? 'stg',
      phone: json['phone'],
      userImage: json['user_image'],
      isAdmin: json['is_admin'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'branch_id': branchId,
        'phone': phone,
        'user_image': userImage,
        'is_admin': isAdmin,
      };
}

/// Modelo de permiso por módulo
class ModulePermission {
  final bool view;
  final bool edit;
  final bool delete;

  const ModulePermission({
    this.view = false,
    this.edit = false,
    this.delete = false,
  });

  factory ModulePermission.fromJson(Map<String, dynamic> json) {
    return ModulePermission(
      view: json['view'] ?? false,
      edit: json['edit'] ?? false,
      delete: json['delete'] ?? false,
    );
  }

  /// Permiso completo (admin)
  static const ModulePermission full = ModulePermission(
    view: true,
    edit: true,
    delete: true,
  );

  /// Sin permisos
  static const ModulePermission none = ModulePermission();

  /// Solo lectura
  static const ModulePermission readOnly = ModulePermission(view: true);
}

/// Servicio de autenticación con PostgreSQL
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String baseUrl =
      'https://sistema.victorguzmanfotografia.com/api';

  // Claves de almacenamiento
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _permissionsKey = 'auth_permissions';
  static const String _branchKey = 'selected_branch';

  // Estado
  String? _token;
  AuthUser? _currentUser;
  Map<String, ModulePermission> _permissions = {};
  String _branchId = 'stg';

  // Stream controller para cambios de autenticación
  final _authStateController = StreamController<AuthUser?>.broadcast();
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  // Getters
  bool get isAuthenticated => _token != null && _currentUser != null;
  AuthUser? get currentUser => _currentUser;
  String get currentBranchId => _branchId;
  String? get token => _token;

  /// Headers con autenticación
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
        'X-Branch-Id': _branchId,
      };

  /// Inicializar servicio - cargar datos guardados
  Future<void> initialize() async {
    try {
      _token = getStringAsync(_tokenKey);
      _branchId = getStringAsync(_branchKey, defaultValue: 'stg');

      final userJson = getStringAsync(_userKey);
      if (userJson.isNotEmpty) {
        _currentUser = AuthUser.fromJson(jsonDecode(userJson));
      }

      final permsJson = getStringAsync(_permissionsKey);
      if (permsJson.isNotEmpty) {
        final permsMap = jsonDecode(permsJson) as Map<String, dynamic>;
        _permissions = permsMap.map(
          (key, value) => MapEntry(
            key,
            ModulePermission.fromJson(value as Map<String, dynamic>),
          ),
        );
      }

      // Verificar si el token sigue válido
      if (_token != null && _token!.isNotEmpty) {
        final isValid = await validateToken();
        if (!isValid) {
          await logout();
        }
      }

      debugPrint(
          '🔐 AuthService inicializado: ${isAuthenticated ? 'Autenticado' : 'No autenticado'}');
    } catch (e) {
      debugPrint('❌ Error inicializando AuthService: $e');
    }
  }

  /// Login con email y password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json', 'X-Branch-Id': _branchId},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _currentUser = AuthUser.fromJson(data['user']);

        // Parsear permisos
        if (data['permissions'] != null) {
          final permsMap = data['permissions'] as Map<String, dynamic>;
          _permissions = permsMap.map(
            (key, value) => MapEntry(
              key,
              ModulePermission.fromJson(value as Map<String, dynamic>),
            ),
          );
        }

        // Guardar en almacenamiento local
        await _saveAuthData();

        // Notificar cambio de estado
        _authStateController.add(_currentUser);

        debugPrint(
            '✅ Login exitoso: ${_currentUser!.email} (${_permissions.length} permisos)');
      }

      return data;
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      return {'error': 'Error de conexión', 'message': e.toString()};
    }
  }

  /// Registrar nuevo usuario
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String role = 'user',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json', 'X-Branch-Id': _branchId},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'role': role,
          'branch_id': _branchId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _currentUser = AuthUser.fromJson(data['user']);

        if (data['permissions'] != null) {
          final permsMap = data['permissions'] as Map<String, dynamic>;
          _permissions = permsMap.map(
            (key, value) => MapEntry(
              key,
              ModulePermission.fromJson(value as Map<String, dynamic>),
            ),
          );
        }

        await _saveAuthData();
        _authStateController.add(_currentUser);

        debugPrint('✅ Registro exitoso: ${_currentUser!.email}');
      }

      return data;
    } catch (e) {
      debugPrint('❌ Error en registro: $e');
      return {'error': 'Error de conexión', 'message': e.toString()};
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      // Llamar endpoint de logout si estamos autenticados
      if (_token != null) {
        try {
          await http.post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: _headers,
          );
        } catch (e) {
          // Ignorar errores de logout del servidor
        }
      }
    } finally {
      // Limpiar datos locales
      _token = null;
      _currentUser = null;
      _permissions = {};

      await removeKey(_tokenKey);
      await removeKey(_userKey);
      await removeKey(_permissionsKey);

      _authStateController.add(null);

      debugPrint('🚪 Sesión cerrada');
    }
  }

  /// Validar si el token actual es válido
  Future<bool> validateToken() async {
    if (_token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = AuthUser.fromJson(data['user']);

        if (data['permissions'] != null) {
          final permsMap = data['permissions'] as Map<String, dynamic>;
          _permissions = permsMap.map(
            (key, value) => MapEntry(
              key,
              ModulePermission.fromJson(value as Map<String, dynamic>),
            ),
          );
        }

        await _saveAuthData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error validando token: $e');
      return false;
    }
  }

  /// Cambiar contraseña
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/password'),
        headers: _headers,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Error de conexión', 'message': e.toString()};
    }
  }

  /// Obtener sesiones activas
  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/sessions'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['sessions']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo sesiones: $e');
      return [];
    }
  }

  /// Cerrar sesión específica
  Future<bool> closeSession(String sessionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/auth/sessions/$sessionId'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Cambiar sucursal activa
  Future<void> setBranchId(String branchId) async {
    _branchId = branchId;
    await setValue(_branchKey, branchId);
    debugPrint('🏢 Sucursal cambiada a: $branchId');
  }

  /// Obtener sucursales disponibles
  Future<List<Map<String, dynamic>>> getBranches() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/branches'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['branches']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo sucursales: $e');
      return [];
    }
  }

  // ==========================================
  // VERIFICACIÓN DE PERMISOS
  // ==========================================

  /// Verificar si tiene permiso de ver un módulo
  bool canView(String module) {
    if (_currentUser?.isAdmin == true) return true;
    return _permissions[module]?.view ?? false;
  }

  /// Verificar si tiene permiso de editar un módulo
  bool canEdit(String module) {
    if (_currentUser?.isAdmin == true) return true;
    return _permissions[module]?.edit ?? false;
  }

  /// Verificar si tiene permiso de eliminar en un módulo
  bool canDelete(String module) {
    if (_currentUser?.isAdmin == true) return true;
    return _permissions[module]?.delete ?? false;
  }

  /// Obtener permiso completo de un módulo
  ModulePermission getPermission(String module) {
    if (_currentUser?.isAdmin == true) return ModulePermission.full;
    return _permissions[module] ?? ModulePermission.none;
  }

  /// Obtener todos los permisos
  Map<String, ModulePermission> get allPermissions => Map.from(_permissions);

  // ==========================================
  // GESTIÓN DE USUARIOS (ADMIN)
  // ==========================================

  /// Obtener lista de usuarios (requiere admin)
  Future<Map<String, dynamic>> getUsers({
    int limit = 50,
    int offset = 0,
    String? search,
    String? branchId,
  }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (search != null) params['search'] = search;
      if (branchId != null) params['branch_id'] = branchId;

      final uri = Uri.parse('$baseUrl/users').replace(queryParameters: params);

      final response = await http.get(uri, headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Obtener usuario por ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Crear usuario (requiere admin)
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String name,
    String? phone,
    String role = 'user',
    String? branchId,
    bool isAdmin = false,
    Map<String, Map<String, bool>>? permissions,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'role': role,
          'branch_id': branchId ?? _branchId,
          'is_admin': isAdmin,
          if (permissions != null) 'permissions': permissions,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Actualizar usuario
  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Actualizar permisos de usuario
  Future<Map<String, dynamic>> updateUserPermissions(
    String userId,
    Map<String, Map<String, bool>> permissions,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/permissions'),
        headers: _headers,
        body: jsonEncode({'permissions': permissions}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Cambiar contraseña de usuario (admin)
  Future<Map<String, dynamic>> setUserPassword(
    String userId,
    String newPassword,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/password'),
        headers: _headers,
        body: jsonEncode({'newPassword': newPassword}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Desactivar usuario
  Future<bool> deactivateUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Activar usuario
  Future<bool> activateUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/activate'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Obtener tipos de permisos disponibles
  Future<List<Map<String, dynamic>>> getPermissionTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/permission-types'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['permissionTypes']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // FUNCIONES PRIVADAS
  // ==========================================

  /// Guardar datos de autenticación
  Future<void> _saveAuthData() async {
    if (_token != null) {
      await setValue(_tokenKey, _token!);
    }
    if (_currentUser != null) {
      await setValue(_userKey, jsonEncode(_currentUser!.toJson()));
    }
    if (_permissions.isNotEmpty) {
      final permsJson = _permissions.map(
        (key, value) => MapEntry(key, {
          'view': value.view,
          'edit': value.edit,
          'delete': value.delete,
        }),
      );
      await setValue(_permissionsKey, jsonEncode(permsJson));
    }
  }

  /// Dispose
  void dispose() {
    _authStateController.close();
  }
}

/// Instancia global del servicio de autenticación
final authService = AuthService();

/// Nombres de módulos para verificar permisos
class PermissionModules {
  static const String dashboard = 'Dashboard';
  static const String sales = 'Ventas/POS';
  static const String salesList = 'Lista de Ventas';
  static const String customers = 'Clientes/Proveedores';
  static const String products = 'Productos';
  static const String purchases = 'Compras';
  static const String purchaseList = 'Lista de Compras';
  static const String inventory = 'Inventario';
  static const String expenses = 'Gastos';
  static const String lossProfit = 'Pérdidas/Ganancias';
  static const String dueList = 'Cuentas por Cobrar';
  static const String reports = 'Reportes';
  static const String hrm = 'Recursos Humanos';
  static const String profile = 'Perfil/Configuración';
  static const String reservations = 'Reservaciones';
  static const String dresses = 'Vestidos';
  static const String services = 'Servicios/Paquetes';
  static const String photoInvoice = 'Facturas Foto';
  static const String audit = 'Auditoría';
  static const String migration = 'Migración BD';
}
