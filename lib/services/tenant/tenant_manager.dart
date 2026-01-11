import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:nb_utils/nb_utils.dart';

import 'tenant_model.dart';

/// Servicio singleton para gestionar la conexión multi-tenant
/// Permite cambiar dinámicamente entre diferentes sucursales/bases de datos Firebase
class TenantManager {
  static final TenantManager _instance = TenantManager._internal();
  factory TenantManager() => _instance;
  TenantManager._internal();

  // Clave para persistencia
  static const String _tenantKey = 'selected_tenant_id';
  static const String _defaultAppName = '[DEFAULT]';

  // Estado actual
  TenantModel? _currentTenant;
  FirebaseApp? _currentApp;
  bool _isInitialized = false;
  bool _isSwitching = false;

  // Stream controller para notificar cambios de tenant
  final _tenantChangeController = StreamController<TenantModel>.broadcast();
  Stream<TenantModel> get onTenantChange => _tenantChangeController.stream;

  // Getters
  TenantModel? get currentTenant => _currentTenant;
  bool get isInitialized => _isInitialized;
  bool get isSwitching => _isSwitching;
  String get currentTenantId => _currentTenant?.id ?? '';
  String get currentTenantName => _currentTenant?.displayName ?? 'Sin sucursal';

  // Instancias de Firebase para el tenant actual
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseDatabase get database => FirebaseDatabase.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// Inicializa el sistema de tenants
  /// Carga el último tenant seleccionado o usa el por defecto
  Future<TenantModel> initialize() async {
    if (_isInitialized && _currentTenant != null) {
      return _currentTenant!;
    }

    try {
      // Obtener tenant guardado
      final savedTenantId = getStringAsync(_tenantKey);

      TenantModel targetTenant;
      if (savedTenantId.isNotEmpty) {
        targetTenant = TenantConfig.getTenantById(savedTenantId) ??
                       TenantConfig.defaultTenant;
      } else {
        targetTenant = TenantConfig.defaultTenant;
      }

      // Inicializar Firebase con el tenant
      await _initializeFirebaseForTenant(targetTenant);

      _currentTenant = targetTenant;
      _isInitialized = true;

      debugPrint('🏢 TenantManager: Inicializado con ${targetTenant.displayName}');

      return targetTenant;
    } catch (e) {
      debugPrint('❌ TenantManager: Error al inicializar - $e');
      rethrow;
    }
  }

  /// Cambia a una sucursal diferente
  /// Esto reinicializa Firebase con la nueva configuración
  Future<bool> switchTenant(TenantModel newTenant) async {
    if (_isSwitching) {
      debugPrint('⚠️ TenantManager: Ya hay un cambio de tenant en progreso');
      return false;
    }

    if (_currentTenant?.id == newTenant.id) {
      debugPrint('ℹ️ TenantManager: Ya estás en ${newTenant.displayName}');
      return true;
    }

    _isSwitching = true;

    try {
      debugPrint('🔄 TenantManager: Cambiando a ${newTenant.displayName}...');

      // Cerrar sesión del usuario actual si existe
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('⚠️ TenantManager: Error al cerrar sesión - $e');
      }

      // Eliminar la app actual si no es la default
      if (_currentApp != null && _currentApp!.name != _defaultAppName) {
        try {
          await _currentApp!.delete();
        } catch (e) {
          debugPrint('⚠️ TenantManager: Error al eliminar app anterior - $e');
        }
      }

      // Inicializar con el nuevo tenant
      await _initializeFirebaseForTenant(newTenant);

      // Guardar preferencia
      await setValue(_tenantKey, newTenant.id);

      _currentTenant = newTenant;
      _tenantChangeController.add(newTenant);

      debugPrint('✅ TenantManager: Cambiado exitosamente a ${newTenant.displayName}');

      _isSwitching = false;
      return true;
    } catch (e) {
      debugPrint('❌ TenantManager: Error al cambiar tenant - $e');
      _isSwitching = false;
      return false;
    }
  }

  /// Inicializa Firebase para un tenant específico
  Future<void> _initializeFirebaseForTenant(TenantModel tenant) async {
    try {
      // Para web, usamos la app default y reconfiguramos
      // Firebase Web no soporta múltiples apps de la misma manera que mobile
      if (kIsWeb) {
        // En web, necesitamos reiniciar la aplicación para cambiar la configuración
        // Por ahora, usamos la app default
        final apps = Firebase.apps;

        if (apps.isEmpty) {
          _currentApp = await Firebase.initializeApp(
            options: tenant.firebaseOptions,
          );
        } else {
          // La app ya está inicializada, usamos la existente
          _currentApp = Firebase.app();

          // En producción, para cambiar de tenant en web,
          // se recomienda recargar la página con un parámetro de tenant
        }
      } else {
        // Para mobile, podemos usar apps secundarias
        final appName = 'tenant_${tenant.id}';

        try {
          _currentApp = Firebase.app(appName);
        } catch (e) {
          _currentApp = await Firebase.initializeApp(
            name: appName,
            options: tenant.firebaseOptions,
          );
        }
      }

      debugPrint('🔥 Firebase inicializado para: ${tenant.city}');
    } catch (e) {
      debugPrint('❌ Error inicializando Firebase: $e');
      rethrow;
    }
  }

  /// Obtiene el tenant guardado sin inicializar Firebase
  Future<TenantModel?> getSavedTenant() async {
    try {
      final savedTenantId = getStringAsync(_tenantKey);
      if (savedTenantId.isNotEmpty) {
        return TenantConfig.getTenantById(savedTenantId);
      }
    } catch (e) {
      debugPrint('Error obteniendo tenant guardado: $e');
    }
    return null;
  }

  /// Guarda el tenant seleccionado
  Future<void> saveTenant(TenantModel tenant) async {
    await setValue(_tenantKey, tenant.id);
  }

  /// Limpia el tenant guardado (para logout completo)
  Future<void> clearSavedTenant() async {
    await removeKey(_tenantKey);
  }

  /// Verifica si hay un tenant guardado
  Future<bool> hasSavedTenant() async {
    final savedId = getStringAsync(_tenantKey);
    return savedId.isNotEmpty;
  }

  /// Lista todas las sucursales disponibles
  List<TenantModel> getAllTenants() {
    return TenantConfig.allTenants;
  }

  /// Dispose del manager
  void dispose() {
    _tenantChangeController.close();
  }
}
