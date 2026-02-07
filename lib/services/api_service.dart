import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import '../model/user_role_model.dart';

/// Servicio API para comunicarse con el servidor PostgreSQL
/// Reemplaza Firebase Realtime Database
class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Configuración del servidor
  static const String baseUrl = 'https://sistema.victorguzmanfotografia.com/api';

  // Token JWT almacenado
  String? _token;
  String? _branchId;
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _permissions;

  // Getters
  String? get token => _token;
  String? get branchId => _branchId;
  Map<String, dynamic>? get currentUser => _currentUser;
  Map<String, dynamic>? get permissions => _permissions;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Headers comunes para las peticiones
  /// IMPORTANTE: Siempre usa _getEffectiveBranchId() para obtener el branch correcto
  /// CRÍTICO: Este getter SIEMPRE lee de localStorage para garantizar consistencia
  Map<String, String> get _headers {
    // FORZAR lectura DIRECTA de localStorage - NUNCA usar cache
    final localStorageBranch = _readLocalStorageBranch();
    final effectiveBranch = localStorageBranch ?? _branchId;

    // Debug agresivo para producción - REMOVER cuando se resuelva el bug
    print('═══════════════════════════════════════════════════════════');
    print('[ApiService._headers] 🔴 DEBUG BRANCH SYNC');
    print('  📦 localStorage[selected_tenant_id]: $localStorageBranch');
    print('  📦 _branchId cache: $_branchId');
    print('  ✅ USANDO BRANCH: $effectiveBranch');
    print('═══════════════════════════════════════════════════════════');

    // Si hay desincronización, forzar actualización del cache
    if (localStorageBranch != null && localStorageBranch != _branchId) {
      print('[ApiService._headers] ⚠️ DESINCRONIZACIÓN! Forzando cache a: $localStorageBranch');
      _branchId = localStorageBranch;
    }

    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
      if (effectiveBranch != null && effectiveBranch.isNotEmpty) 'X-Branch-Id': effectiveBranch,
    };
  }

  /// Lee el branch_id directamente de localStorage (helper síncrono)
  String? _readLocalStorageBranch() {
    try {
      return html.window.localStorage['selected_tenant_id'];
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el branch_id efectivo, priorizando selected_tenant_id sobre _branchId
  /// CRÍTICO: SIEMPRE lee de localStorage como fuente de verdad
  /// Esto asegura que después de un cambio de sucursal, la API use el branch correcto
  String? _getEffectiveBranchId() {
    // 1. SIEMPRE intentar leer de localStorage primero (es la fuente de verdad)
    try {
      final selectedTenant = html.window.localStorage['selected_tenant_id'];
      if (selectedTenant != null && selectedTenant.isNotEmpty) {
        // Si es diferente al cacheado, FORZAR actualización del cache
        if (selectedTenant != _branchId) {
          print('[ApiService._getEffectiveBranchId] ⚠️ DESINCRONIZACIÓN DETECTADA!');
          print('  localStorage: $selectedTenant');
          print('  _branchId cache: $_branchId');
          print('  Forzando sincronización a: $selectedTenant');
          _branchId = selectedTenant;
        }
        return selectedTenant;
      }
    } catch (e) {
      print('[ApiService._getEffectiveBranchId] Error leyendo localStorage: $e');
    }

    // 2. Si localStorage está vacío o hay error, usar el cache (fallback)
    print('[ApiService._getEffectiveBranchId] localStorage vacío, usando cache: $_branchId');
    return _branchId;
  }

  /// Fuerza la sincronización del branch con localStorage
  /// Llamar este método después de cambiar de sucursal para garantizar consistencia
  void forceSyncBranchFromLocalStorage() {
    try {
      final selectedTenant = html.window.localStorage['selected_tenant_id'];
      if (selectedTenant != null && selectedTenant.isNotEmpty) {
        _branchId = selectedTenant;
        print('[ApiService.forceSyncBranchFromLocalStorage] Branch forzado a: $selectedTenant');
      }
    } catch (e) {
      print('[ApiService.forceSyncBranchFromLocalStorage] Error: $e');
    }
  }

  /// Inicializar el servicio cargando datos de SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('api_token');

    // IMPORTANTE: Usar selected_tenant_id como fuente de verdad para branch_id
    // Esto asegura que la API use el tenant seleccionado en la UI, no el branch_id del usuario
    final selectedTenantId = prefs.getString('selected_tenant_id');
    final userBranchId = prefs.getString('api_branch_id');

    // Priorizar: selected_tenant_id > api_branch_id (del usuario)
    _branchId = selectedTenantId?.isNotEmpty == true ? selectedTenantId : userBranchId;

    // Debug log
    print('[ApiService.init] selected_tenant_id: $selectedTenantId, api_branch_id: $userBranchId, usando: $_branchId');

    final userJson = prefs.getString('api_user');
    if (userJson != null) {
      _currentUser = jsonDecode(userJson);
    }

    final permissionsJson = prefs.getString('api_permissions');
    if (permissionsJson != null) {
      _permissions = jsonDecode(permissionsJson);
    }
  }

  /// Login con email y password
  /// Retorna true si el login fue exitoso
  Future<LoginResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _token = data['token'];
        _currentUser = data['user'];
        _permissions = data['permissions'];

        // IMPORTANTE: Priorizar selected_tenant_id sobre el branch_id del usuario
        // Esto permite que un usuario (ej: admin@victorpos.com con branch_id=stg)
        // pueda ver datos de otra sucursal si seleccionó esa sucursal en el login
        final prefs = await SharedPreferences.getInstance();
        final selectedTenantId = prefs.getString('selected_tenant_id');
        final userBranchId = _currentUser?['branch_id'];

        // Si hay un tenant seleccionado, usarlo; sino, usar el branch_id del usuario
        _branchId = (selectedTenantId?.isNotEmpty == true) ? selectedTenantId : userBranchId;

        print('[ApiService.login] selected_tenant_id: $selectedTenantId, user.branch_id: $userBranchId, usando: $_branchId');

        // Guardar en SharedPreferences
        await prefs.setString('api_token', _token!);
        await prefs.setString('api_branch_id', _branchId ?? '');
        await prefs.setString('api_user', jsonEncode(_currentUser));
        await prefs.setString('api_permissions', jsonEncode(_permissions));

        return LoginResult(
          success: true,
          user: _currentUser,
          permissions: _permissions,
          token: _token,
        );
      } else {
        final error = jsonDecode(response.body);
        return LoginResult(
          success: false,
          error: error['message'] ?? 'Error de autenticación',
        );
      }
    } catch (e) {
      return LoginResult(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    _token = null;
    _branchId = null;
    _currentUser = null;
    _permissions = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
    await prefs.remove('api_branch_id');
    await prefs.remove('api_user');
    await prefs.remove('api_permissions');
  }

  /// Actualizar el branchId activo (cuando el usuario cambia de sucursal)
  /// Este método debe llamarse cuando se selecciona un nuevo tenant
  Future<void> setBranchId(String newBranchId) async {
    _branchId = newBranchId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_branch_id', newBranchId);
    print('[ApiService.setBranchId] Branch actualizado a: $newBranchId');
  }

  /// Sincronizar el branchId con el tenant seleccionado
  /// Llamar esto después de cambiar de tenant para asegurar consistencia
  Future<void> syncBranchWithSelectedTenant() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedTenantId = prefs.getString('selected_tenant_id');
    if (selectedTenantId != null && selectedTenantId.isNotEmpty && selectedTenantId != _branchId) {
      _branchId = selectedTenantId;
      await prefs.setString('api_branch_id', selectedTenantId);
      print('[ApiService.syncBranchWithSelectedTenant] Branch sincronizado a: $selectedTenantId');
    }
  }

  /// Obtener usuario actual
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = data['user'];
        return _currentUser;
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return null;
  }

  /// Verificar permisos de un módulo
  bool hasPermission(String module, {bool view = false, bool edit = false, bool delete = false}) {
    if (_permissions == null) return false;

    // Si es admin, tiene todos los permisos
    if (_currentUser?['is_admin'] == true) return true;

    final modulePermission = _permissions?[module];
    if (modulePermission == null) return false;

    if (view && modulePermission['view'] != true) return false;
    if (edit && modulePermission['edit'] != true) return false;
    if (delete && modulePermission['delete'] != true) return false;

    return true;
  }

  /// Convertir permisos de la API a UserRoleModel (para compatibilidad)
  UserRoleModel toUserRoleModel() {
    if (_currentUser == null) {
      return UserRoleModel(
        email: '',
        userTitle: '',
        databaseId: '',
        permissions: [],
      );
    }

    List<Permission> permissionsList = [];
    if (_permissions != null) {
      _permissions!.forEach((key, value) {
        permissionsList.add(Permission(
          type: key,
          view: value['view'] ?? false,
          edit: value['edit'] ?? false,
          delete: value['delete'] ?? false,
        ));
      });
    }

    return UserRoleModel(
      email: _currentUser?['email'] ?? '',
      userTitle: _currentUser?['name'] ?? '',
      username: _currentUser?['username'] ?? '',
      databaseId: _currentUser?['id'] ?? '',
      userRoleName: _currentUser?['role'] ?? '',
      branchId: _currentUser?['branch_id'] ?? '',
      branchName: _currentUser?['branch_name'] ?? '',
      allowedBranches: _currentUser?['allowed_branches'] is List
          ? List<String>.from(_currentUser!['allowed_branches'])
          : null,
      permissions: permissionsList,
    );
  }

  // ==================== MÉTODOS CRUD GENÉRICOS ====================

  /// GET request
  Future<ApiResponse> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$baseUrl/$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      // 🔴🔴🔴 DEBUG CRÍTICO - INICIO 🔴🔴🔴
      final localStorageBranch = _readLocalStorageBranch();
      final currentHeaders = _headers;
      print('');
      print('🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴');
      print('[ApiService.GET] LLAMADA API');
      print('  📡 URL: $uri');
      print('  📦 localStorage[selected_tenant_id]: $localStorageBranch');
      print('  📦 _branchId (cache interno): $_branchId');
      print('  📤 Header X-Branch-Id enviado: ${currentHeaders['X-Branch-Id']}');
      print('  📤 Headers completos: $currentHeaders');
      print('🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴');
      print('');
      // 🔴🔴🔴 DEBUG CRÍTICO - FIN 🔴🔴🔴

      final response = await http.get(uri, headers: currentHeaders);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  /// POST request
  Future<ApiResponse> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  /// PUT request
  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    try {
      print('📤 [ApiService.PUT] Endpoint: $endpoint');
      print('📤 [ApiService.PUT] Body keys: ${body.keys.toList()}');

      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📥 [ApiService.PUT] Status: ${response.statusCode}');
      print('📥 [ApiService.PUT] Response: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ [ApiService.PUT] Error: $e');
      return ApiResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  /// DELETE request
  Future<ApiResponse> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  /// Manejar respuesta HTTP
  ApiResponse _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        return ApiResponse(success: true, data: data);
      } catch (e) {
        return ApiResponse(success: true, data: response.body);
      }
    } else if (response.statusCode == 401) {
      // Token expirado o inválido
      logout();
      return ApiResponse(success: false, error: 'Sesión expirada', statusCode: 401);
    } else {
      try {
        final error = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: error['message'] ?? error['error'] ?? 'Error del servidor',
          statusCode: response.statusCode,
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error del servidor: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    }
  }

  // ==================== MÉTODOS ESPECÍFICOS ====================

  /// Obtener clientes
  Future<ApiResponse> getCustomers({int limit = 100, int offset = 0, String? search}) async {
    return get('customers', queryParams: {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (search != null) 'search': search,
    });
  }

  /// Crear cliente
  Future<ApiResponse> createCustomer(Map<String, dynamic> customer) async {
    return post('customers', customer);
  }

  /// Actualizar cliente
  Future<ApiResponse> updateCustomer(String id, Map<String, dynamic> customer) async {
    return put('customers/$id', customer);
  }

  /// Eliminar cliente
  Future<ApiResponse> deleteCustomer(String id) async {
    return delete('customers/$id');
  }

  /// Obtener productos
  Future<ApiResponse> getProducts({int limit = 100, int offset = 0, String? search}) async {
    return get('products', queryParams: {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (search != null) 'search': search,
    });
  }

  /// Obtener vestidos
  Future<ApiResponse> getDresses({int limit = 100, int offset = 0, String? search}) async {
    return get('dresses', queryParams: {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (search != null) 'search': search,
    });
  }

  /// Obtener servicios
  Future<ApiResponse> getServices({int limit = 100, int offset = 0}) async {
    return get('services', queryParams: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });
  }

  /// Obtener reservaciones
  Future<ApiResponse> getReservations({int limit = 100, int offset = 0, String? date}) async {
    return get('reservations', queryParams: {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (date != null) 'date': date,
    });
  }

  /// Obtener ventas
  Future<ApiResponse> getSales({int limit = 100, int offset = 0, String? startDate, String? endDate}) async {
    return get('sales', queryParams: {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
  }

  /// Crear venta
  Future<ApiResponse> createSale(Map<String, dynamic> sale) async {
    return post('sales', sale);
  }

  /// Obtener gastos
  Future<ApiResponse> getExpenses({int limit = 100, int offset = 0}) async {
    return get('expenses', queryParams: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });
  }

  /// Crear gasto
  Future<ApiResponse> createExpense(Map<String, dynamic> expense) async {
    return post('expenses', expense);
  }

  /// Obtener usuarios
  Future<ApiResponse> getUsers({int limit = 100, int offset = 0}) async {
    return get('users', queryParams: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });
  }

  /// Crear usuario
  Future<ApiResponse> createUser(Map<String, dynamic> user) async {
    return post('users', user);
  }

  /// Actualizar usuario
  Future<ApiResponse> updateUser(String id, Map<String, dynamic> user) async {
    return put('users/$id', user);
  }

  /// Obtener sucursales
  Future<ApiResponse> getBranches() async {
    return get('auth/branches');
  }

  /// Registrar nuevo usuario
  Future<ApiResponse> register({
    required String email,
    required String password,
    required String name,
    String? branchId,
    String? role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          if (branchId != null) 'branch_id': branchId,
          if (role != null) 'role': role,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(success: true, data: data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: error['message'] ?? 'Error al registrar',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  /// Crear servicio
  Future<ApiResponse> createService(Map<String, dynamic> service) async {
    return post('services', service);
  }

  /// Actualizar servicio
  Future<ApiResponse> updateService(String id, Map<String, dynamic> service) async {
    return put('services/$id', service);
  }

  /// Eliminar servicio
  Future<ApiResponse> deleteService(String id) async {
    return delete('services/$id');
  }

  /// Crear producto
  Future<ApiResponse> createProduct(Map<String, dynamic> product) async {
    return post('products', product);
  }

  /// Actualizar producto
  Future<ApiResponse> updateProduct(String id, Map<String, dynamic> product) async {
    return put('products/$id', product);
  }

  /// Eliminar producto
  Future<ApiResponse> deleteProduct(String id) async {
    return delete('products/$id');
  }

  /// Crear vestido
  Future<ApiResponse> createDress(Map<String, dynamic> dress) async {
    return post('dresses', dress);
  }

  /// Actualizar vestido
  Future<ApiResponse> updateDress(String id, Map<String, dynamic> dress) async {
    return put('dresses/$id', dress);
  }

  /// Eliminar vestido
  Future<ApiResponse> deleteDress(String id) async {
    return delete('dresses/$id');
  }

  /// Crear reservación
  Future<ApiResponse> createReservation(Map<String, dynamic> reservation) async {
    return post('reservations', reservation);
  }

  /// Actualizar reservación
  Future<ApiResponse> updateReservation(String id, Map<String, dynamic> reservation) async {
    return put('reservations/$id', reservation);
  }

  /// Eliminar reservación
  Future<ApiResponse> deleteReservation(String id) async {
    return delete('reservations/$id');
  }

  /// Actualizar venta
  Future<ApiResponse> updateSale(String id, Map<String, dynamic> sale) async {
    return put('sales/$id', sale);
  }

  /// Eliminar venta
  Future<ApiResponse> deleteSale(String id) async {
    return delete('sales/$id');
  }

  /// Actualizar gasto
  Future<ApiResponse> updateExpense(String id, Map<String, dynamic> expense) async {
    return put('expenses/$id', expense);
  }

  /// Eliminar gasto
  Future<ApiResponse> deleteExpense(String id) async {
    return delete('expenses/$id');
  }

  /// Eliminar usuario
  Future<ApiResponse> deleteUser(String id) async {
    return delete('users/$id');
  }

  /// Obtener categorías
  Future<ApiResponse> getCategories({int limit = 100}) async {
    return get('categories', queryParams: {'limit': limit.toString()});
  }

  /// Crear categoría
  Future<ApiResponse> createCategory(Map<String, dynamic> category) async {
    return post('categories', category);
  }

  /// Obtener ingresos
  Future<ApiResponse> getIncomes({int limit = 100, int offset = 0}) async {
    return get('incomes', queryParams: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });
  }

  /// Crear ingreso
  Future<ApiResponse> createIncome(Map<String, dynamic> income) async {
    return post('incomes', income);
  }

  /// Actualizar ingreso
  Future<ApiResponse> updateIncome(String id, Map<String, dynamic> income) async {
    return put('incomes/$id', income);
  }

  /// Eliminar ingreso
  Future<ApiResponse> deleteIncome(String id) async {
    return delete('incomes/$id');
  }

  /// Obtener bancos
  Future<ApiResponse> getBanks({int limit = 100}) async {
    return get('banks', queryParams: {'limit': limit.toString()});
  }

  /// Crear banco
  Future<ApiResponse> createBank(Map<String, dynamic> bank) async {
    return post('banks', bank);
  }

  /// Actualizar banco
  Future<ApiResponse> updateBank(String id, Map<String, dynamic> bank) async {
    return put('banks/$id', bank);
  }

  /// Eliminar banco
  Future<ApiResponse> deleteBank(String id) async {
    return delete('banks/$id');
  }
}

/// Resultado del login
class LoginResult {
  final bool success;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? permissions;
  final String? token;
  final String? error;

  LoginResult({
    required this.success,
    this.user,
    this.permissions,
    this.token,
    this.error,
  });
}

/// Respuesta genérica de la API
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  /// Alias para obtener el mensaje de error
  String? get message => error;
}
