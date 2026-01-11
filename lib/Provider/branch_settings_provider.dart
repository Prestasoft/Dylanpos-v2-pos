import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/model/branch_settings_model.dart';
import 'package:salespro_admin/Repository/branch_settings_repo.dart';

/// Repositorio singleton
final branchSettingsRepoProvider = Provider<BranchSettingsRepo>((ref) {
  return BranchSettingsRepo();
});

/// Provider para obtener la configuración de la sucursal actual
final branchSettingsProvider = FutureProvider.autoDispose<BranchSettingsModel>((ref) async {
  final repo = ref.watch(branchSettingsRepoProvider);
  return await repo.getBranchSettings();
});

/// Provider para obtener configuración de una sucursal específica
final branchSettingsByIdProvider = FutureProvider.autoDispose.family<BranchSettingsModel?, String>((ref, branchId) async {
  final repo = ref.watch(branchSettingsRepoProvider);
  return await repo.getBranchSettingsById(branchId);
});

/// Provider para obtener todas las configuraciones de sucursales
final allBranchSettingsProvider = FutureProvider.autoDispose<List<BranchSettingsModel>>((ref) async {
  final repo = ref.watch(branchSettingsRepoProvider);
  return await repo.getAllBranchSettings();
});

/// StateNotifier para gestionar el estado de edición de la configuración
class BranchSettingsNotifier extends StateNotifier<AsyncValue<BranchSettingsModel?>> {
  final BranchSettingsRepo _repo;
  final Ref _ref;

  BranchSettingsNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  /// Cargar configuración actual
  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repo.getBranchSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Guardar configuración
  Future<bool> saveSettings(BranchSettingsModel settings) async {
    try {
      final success = await _repo.saveBranchSettings(settings);
      if (success) {
        state = AsyncValue.data(settings);
        // Invalidar el provider de lectura para que se refresque
        _ref.invalidate(branchSettingsProvider);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar un campo específico
  void updateField(BranchSettingsModel Function(BranchSettingsModel) updater) {
    state.whenData((settings) {
      if (settings != null) {
        state = AsyncValue.data(updater(settings));
      }
    });
  }
}

/// Provider del notifier para edición
final branchSettingsNotifierProvider = StateNotifierProvider.autoDispose<BranchSettingsNotifier, AsyncValue<BranchSettingsModel?>>((ref) {
  final repo = ref.watch(branchSettingsRepoProvider);
  return BranchSettingsNotifier(repo, ref);
});

/// Provider simple para verificar si los datos de factura están completos
final hasCompleteInvoiceDataProvider = FutureProvider.autoDispose<bool>((ref) async {
  final settings = await ref.watch(branchSettingsProvider.future);
  return settings.hasCompleteInvoiceData;
});
