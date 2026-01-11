import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Servicio de autenticación usando Supabase Auth
/// Reemplaza Firebase Auth
class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  SupabaseClient get _client => supabaseService.client;
  GoTrueClient get _auth => _client.auth;

  // =========================================
  // ESTADO DE AUTENTICACIÓN
  // =========================================

  /// Usuario actual
  User? get currentUser => _auth.currentUser;

  /// ID del usuario actual
  String? get currentUserId => currentUser?.id;

  /// Email del usuario actual
  String? get currentUserEmail => currentUser?.email;

  /// ¿Está autenticado?
  bool get isAuthenticated => currentUser != null;

  /// Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // =========================================
  // MÉTODOS DE AUTENTICACIÓN
  // =========================================

  /// Iniciar sesión con email y contraseña
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Supabase Auth: Iniciando sesión con $email');

      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        debugPrint('✅ Login exitoso: ${response.user!.email}');

        // Obtener datos del usuario desde la tabla users
        await _loadUserProfile(response.user!.id);
      }

      return response;
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      rethrow;
    }
  }

  /// Registrar nuevo usuario
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String branchId,
    String role = 'user',
  }) async {
    try {
      debugPrint('📝 Supabase Auth: Registrando usuario $email');

      // 1. Crear usuario en Supabase Auth
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name,
          'branch_id': branchId,
          'role': role,
        },
      );

      if (response.user != null) {
        // 2. Crear perfil en tabla users
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          name: name,
          branchId: branchId,
          role: role,
        );

        debugPrint('✅ Registro exitoso: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Error en registro: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Supabase Auth: Cerrando sesión');
      await _auth.signOut();
      _cachedUserProfile = null;
      debugPrint('✅ Sesión cerrada');
    } catch (e) {
      debugPrint('❌ Error al cerrar sesión: $e');
      rethrow;
    }
  }

  /// Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('📧 Enviando email de recuperación a $email');
      await _auth.resetPasswordForEmail(email.trim());
      debugPrint('✅ Email de recuperación enviado');
    } catch (e) {
      debugPrint('❌ Error al enviar email de recuperación: $e');
      rethrow;
    }
  }

  /// Actualizar contraseña
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
      debugPrint('✅ Contraseña actualizada');
    } catch (e) {
      debugPrint('❌ Error al actualizar contraseña: $e');
      rethrow;
    }
  }

  // =========================================
  // PERFIL DE USUARIO
  // =========================================

  Map<String, dynamic>? _cachedUserProfile;

  /// Obtener perfil del usuario actual
  Map<String, dynamic>? get userProfile => _cachedUserProfile;

  /// Branch ID del usuario actual
  String? get currentBranchId => _cachedUserProfile?['branch_id'];

  /// Rol del usuario actual
  String? get currentUserRole => _cachedUserProfile?['role'];

  /// Permisos del usuario actual
  Map<String, dynamic>? get currentUserPermissions =>
      _cachedUserProfile?['permissions'] as Map<String, dynamic>?;

  /// Cargar perfil del usuario desde la tabla users
  Future<void> _loadUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _cachedUserProfile = response;
        debugPrint('👤 Perfil cargado: ${response['name']} (${response['role']})');
      }
    } catch (e) {
      debugPrint('⚠️ Error al cargar perfil: $e');
    }
  }

  /// Crear perfil de usuario en la tabla users
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String name,
    required String branchId,
    required String role,
  }) async {
    try {
      await _client.from('users').insert({
        'id': userId,
        'email': email,
        'name': name,
        'branch_id': branchId,
        'role': role,
        'permissions': {},
        'is_active': true,
      });
      debugPrint('👤 Perfil de usuario creado en tabla users');
    } catch (e) {
      debugPrint('⚠️ Error al crear perfil: $e');
    }
  }

  /// Actualizar perfil del usuario
  Future<void> updateProfile({
    String? name,
    String? phone,
    Map<String, dynamic>? permissions,
  }) async {
    if (currentUserId == null) return;

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (permissions != null) updates['permissions'] = permissions;

      await _client
          .from('users')
          .update(updates)
          .eq('id', currentUserId!);

      // Recargar perfil
      await _loadUserProfile(currentUserId!);

      debugPrint('✅ Perfil actualizado');
    } catch (e) {
      debugPrint('❌ Error al actualizar perfil: $e');
      rethrow;
    }
  }

  /// Recargar perfil del usuario actual
  Future<void> refreshProfile() async {
    if (currentUserId != null) {
      await _loadUserProfile(currentUserId!);
    }
  }
}

/// Instancia global del servicio de autenticación
final supabaseAuth = SupabaseAuthService();
