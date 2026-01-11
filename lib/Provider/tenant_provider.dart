import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/services/tenant/tenant_manager.dart';
import 'package:salespro_admin/services/tenant/tenant_model.dart';

/// Estado del tenant actual
class TenantState {
  final TenantModel? currentTenant;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const TenantState({
    this.currentTenant,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  TenantState copyWith({
    TenantModel? currentTenant,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return TenantState(
      currentTenant: currentTenant ?? this.currentTenant,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }

  /// Si se ha seleccionado una sucursal
  bool get hasTenant => currentTenant != null;

  /// Nombre de la sucursal actual para mostrar
  String get tenantDisplayName => currentTenant?.displayName ?? 'Sin sucursal';

  /// Ciudad de la sucursal actual
  String get tenantCity => currentTenant?.city ?? '';
}

/// Notifier para manejar el estado del tenant
class TenantNotifier extends StateNotifier<TenantState> {
  final TenantManager _tenantManager = TenantManager();

  TenantNotifier() : super(const TenantState());

  /// Inicializa el tenant al cargar la app
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tenant = await _tenantManager.initialize();
      state = state.copyWith(
        currentTenant: tenant,
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Cambia la sucursal actual
  Future<bool> switchTenant(TenantModel newTenant) async {
    if (state.currentTenant?.id == newTenant.id) {
      return true; // Ya es el mismo tenant
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _tenantManager.switchTenant(newTenant);
      if (success) {
        state = state.copyWith(
          currentTenant: newTenant,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'No se pudo cambiar de sucursal',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Selecciona una sucursal (sin cambiar Firebase aún)
  void selectTenant(TenantModel tenant) {
    state = state.copyWith(currentTenant: tenant);
  }

  /// Guarda la selección actual
  Future<void> saveSelection() async {
    if (state.currentTenant != null) {
      await _tenantManager.saveTenant(state.currentTenant!);
    }
  }

  /// Obtiene todas las sucursales disponibles
  List<TenantModel> getAllTenants() {
    return _tenantManager.getAllTenants();
  }

  /// Limpia la selección guardada (logout)
  Future<void> clearSelection() async {
    await _tenantManager.clearSavedTenant();
    state = const TenantState();
  }

  /// Verifica si hay un tenant guardado
  Future<bool> hasSavedTenant() async {
    return await _tenantManager.hasSavedTenant();
  }
}

/// Provider principal del tenant
final tenantProvider = StateNotifierProvider<TenantNotifier, TenantState>((ref) {
  return TenantNotifier();
});

/// Provider para obtener la lista de todos los tenants
final allTenantsProvider = Provider<List<TenantModel>>((ref) {
  return TenantConfig.allTenants;
});

/// Provider para verificar si hay un tenant guardado
final hasSavedTenantProvider = FutureProvider<bool>((ref) async {
  final tenantManager = TenantManager();
  return await tenantManager.hasSavedTenant();
});

/// Provider para obtener el tenant guardado
final savedTenantProvider = FutureProvider<TenantModel?>((ref) async {
  final tenantManager = TenantManager();
  return await tenantManager.getSavedTenant();
});
