import 'dart:async';
// Firebase deshabilitado - Usando PostgreSQL API
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:nb_utils/nb_utils.dart';

import 'tenant_model.dart';

/// Servicio singleton para gestionar la conexión multi-tenant
/// Ahora usa PostgreSQL API en lugar de Firebase
class TenantManager {
  static final TenantManager _instance = TenantManager._internal();
  factory TenantManager() => _instance;
  TenantManager._internal();

  // Clave para persistencia
  static const String _tenantKey = 'selected_tenant_id';

  // Estado actual
  TenantModel? _currentTenant;
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

  // Firebase deshabilitado - Estos getters ya no se usan
  // FirebaseFirestore get firestore => FirebaseFirestore.instance;
  // FirebaseAuth get auth => FirebaseAuth.instance;
  // FirebaseDatabase get database => FirebaseDatabase.instance;
  // FirebaseStorage get storage => FirebaseStorage.instance;

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

      // Firebase deshabilitado - Ya no se inicializa
      // await _initializeFirebaseForTenant(targetTenant);

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
  /// Ahora solo actualiza el estado local, la API usa X-Branch-Id header
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

      // Firebase Auth deshabilitado
      // try {
      //   await FirebaseAuth.instance.signOut();
      // } catch (e) {
      //   debugPrint('⚠️ TenantManager: Error al cerrar sesión - $e');
      // }

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
