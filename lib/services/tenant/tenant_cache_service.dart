import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:nb_utils/nb_utils.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Servicio para gestionar la limpieza de caché al cambiar de sucursal
/// Garantiza que no haya datos mezclados entre sucursales
class TenantCacheService {
  static final TenantCacheService _instance = TenantCacheService._internal();
  factory TenantCacheService() => _instance;
  TenantCacheService._internal();

  /// Claves que se deben PRESERVAR al cambiar de sucursal
  static const List<String> _keysToPreserve = [
    'selected_tenant_id',      // ID de la sucursal seleccionada
    'saved_email',             // Email guardado para login
    'saved_password',          // Password guardado para login
    'remember_me',             // Checkbox de recordar credenciales
    'language',                // Idioma seleccionado
    'currency',                // Moneda seleccionada
    'theme_mode',              // Modo de tema (claro/oscuro)
  ];

  /// Claves que se deben ELIMINAR específicamente (datos de negocio)
  /// Se usa como referencia para saber qué tipo de datos se eliminan
  // ignore: unused_field
  static const List<String> _businessDataKeys = [
    'userID',
    'userId',
    'user_role',
    'user_permission',
    'subscription_data',
    'business_data',
    'personal_info',
    'last_sync',
    'cached_products',
    'cached_customers',
    'cached_sales',
    'fcm_token',
  ];

  /// Limpia toda la caché excepto las claves preservadas
  Future<void> clearCacheForTenantSwitch(String newTenantId) async {
    debugPrint('🧹 TenantCacheService: Iniciando limpieza de caché...');

    try {
      // 1. Cerrar sesión de Firebase Auth
      await _signOutFirebase();

      // 2. Limpiar SharedPreferences selectivamente
      await _clearSharedPreferences(newTenantId);

      // 3. Limpiar localStorage del navegador (Web)
      if (kIsWeb) {
        _clearWebStorage(newTenantId);
      }

      debugPrint('✅ TenantCacheService: Caché limpiada exitosamente');
    } catch (e) {
      debugPrint('❌ TenantCacheService: Error al limpiar caché - $e');
      rethrow;
    }
  }

  /// Cierra la sesión de Firebase Auth
  Future<void> _signOutFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseAuth.instance.signOut();
        debugPrint('🔐 Firebase Auth: Sesión cerrada');
      }
    } catch (e) {
      debugPrint('⚠️ Error al cerrar sesión de Firebase: $e');
    }
  }

  /// Limpia SharedPreferences preservando claves importantes
  Future<void> _clearSharedPreferences(String newTenantId) async {
    final prefs = await SharedPreferences.getInstance();

    // Guardar valores a preservar (EXCEPTO selected_tenant_id que será el nuevo)
    final Map<String, dynamic> preservedValues = {};
    for (final key in _keysToPreserve) {
      if (key == 'selected_tenant_id') continue; // No preservar el viejo tenant
      final value = prefs.get(key);
      if (value != null) {
        preservedValues[key] = value;
      }
    }

    // Limpiar todo
    await prefs.clear();
    debugPrint('🗑️ SharedPreferences: Limpiado');

    // Restaurar valores preservados
    for (final entry in preservedValues.entries) {
      if (entry.value is String) {
        await prefs.setString(entry.key, entry.value);
      } else if (entry.value is bool) {
        await prefs.setBool(entry.key, entry.value);
      } else if (entry.value is int) {
        await prefs.setInt(entry.key, entry.value);
      } else if (entry.value is double) {
        await prefs.setDouble(entry.key, entry.value);
      }
    }

    // IMPORTANTE: Establecer el NUEVO tenant ID al final
    await prefs.setString('selected_tenant_id', newTenantId);
    // También usar setValue de nb_utils para actualizar su caché interna
    await setValue('selected_tenant_id', newTenantId);

    debugPrint('♻️ Valores preservados restaurados: ${preservedValues.keys.join(', ')}');
    debugPrint('🏢 Nuevo tenant establecido: $newTenantId');
  }

  /// Limpia el almacenamiento web (localStorage/sessionStorage)
  void _clearWebStorage(String newTenantId) {
    try {
      // Guardar valores importantes del localStorage (EXCEPTO selected_tenant_id)
      final preservedLocalStorage = <String, String>{};
      for (final key in _keysToPreserve) {
        if (key == 'selected_tenant_id') continue; // No preservar el viejo tenant
        final value = html.window.localStorage[key];
        if (value != null) {
          preservedLocalStorage[key] = value;
        }
      }

      // Limpiar localStorage
      html.window.localStorage.clear();
      debugPrint('🗑️ localStorage: Limpiado');

      // Restaurar valores preservados
      for (final entry in preservedLocalStorage.entries) {
        html.window.localStorage[entry.key] = entry.value;
      }

      // IMPORTANTE: Establecer el NUEVO tenant ID
      html.window.localStorage['selected_tenant_id'] = newTenantId;
      debugPrint('🏢 localStorage - Nuevo tenant establecido: $newTenantId');

      // Limpiar sessionStorage completamente
      html.window.sessionStorage.clear();
      debugPrint('🗑️ sessionStorage: Limpiado');

    } catch (e) {
      debugPrint('⚠️ Error al limpiar web storage: $e');
    }
  }

  /// Recarga la página web (forzando nueva carga de Firebase)
  void reloadWebPage() {
    if (kIsWeb) {
      debugPrint('🔄 Recargando página web...');
      html.window.location.reload();
    }
  }

  /// Proceso completo de cambio de sucursal
  Future<void> switchTenantComplete(String newTenantId) async {
    // 1. Limpiar caché
    await clearCacheForTenantSwitch(newTenantId);

    // 2. Recargar la página (esto reinicializará Firebase con el nuevo tenant)
    if (kIsWeb) {
      reloadWebPage();
    }
  }
}
