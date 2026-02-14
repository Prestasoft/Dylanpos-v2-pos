import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;

/// ============================================================================
/// BRANCH PROVIDER - Solución Reactiva para Cambio de Sucursal
/// ============================================================================
///
/// Este provider es la FUENTE DE VERDAD para el branchId actual.
/// Todos los providers de datos (dresses, services, reservations, etc.)
/// deben usar ref.watch(branchIdProvider) para obtener el branchId.
///
/// CÓMO FUNCIONA:
/// 1. Cuando el usuario cambia de sucursal, se llama:
///    ref.read(branchIdProvider.notifier).setBranch("sde")
///
/// 2. Riverpod detecta el cambio de estado
///
/// 3. TODOS los providers que usan ref.watch(branchIdProvider)
///    se INVALIDAN automáticamente y recargan sus datos
///
/// ESTO GARANTIZA que el cambio de sucursal siempre funcione.
/// ============================================================================

const String _kStorageKey = 'selected_tenant_id';
const String _kDefaultBranch = 'stg';

/// Lee el branch SINCRÓNICAMENTE de localStorage al inicio
/// CRÍTICO: Esto evita race conditions donde los providers cargan datos
/// antes de que el branch se inicialice correctamente
String _getInitialBranchSync() {
  try {
    final storedBranch = html.window.localStorage[_kStorageKey];
    print('🏢 [BranchProvider] _getInitialBranchSync() - localStorage[$_kStorageKey]: $storedBranch');
    if (storedBranch != null && storedBranch.isNotEmpty) {
      print('🏢 [BranchProvider] Usando branch de localStorage: $storedBranch');
      return storedBranch;
    }
  } catch (e) {
    print('❌ [BranchProvider] Error leyendo localStorage: $e');
  }
  print('⚠️ [BranchProvider] Usando branch DEFAULT: $_kDefaultBranch');
  return _kDefaultBranch;
}

/// StateNotifier para manejar el branchId con persistencia
class BranchNotifier extends StateNotifier<String> {
  // CRÍTICO: Inicializar con el valor REAL de localStorage, NO con un default
  // Esto evita que los providers carguen datos del branch incorrecto
  BranchNotifier() : super(_getInitialBranchSync()) {
    // ignore: avoid_print
    print('🏢 [BranchNotifier] Constructor - state inicial: $state');
    // Opcional: cargar de SharedPreferences como backup (si localStorage falló)
    _loadFromSharedPreferencesIfNeeded();
  }

  /// Carga de SharedPreferences solo si el estado actual es el default
  /// (significa que localStorage no tenía valor)
  Future<void> _loadFromSharedPreferencesIfNeeded() async {
    // Si ya tenemos un branch válido de localStorage, no hacer nada
    if (state != _kDefaultBranch) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsBranch = prefs.getString(_kStorageKey);
      if (prefsBranch != null && prefsBranch.isNotEmpty && prefsBranch != state) {
        state = prefsBranch;
      }
    } catch (e) {
      // Si hay error, mantener el estado actual
    }
  }

  /// Carga el branch inicial desde localStorage (para refresh manual)
  Future<void> _loadInitialBranch() async {
    try {
      // Primero intentar desde localStorage (web)
      final storedBranch = html.window.localStorage[_kStorageKey];
      if (storedBranch != null && storedBranch.isNotEmpty) {
        state = storedBranch;
        return;
      }

      // Fallback a SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefsBranch = prefs.getString(_kStorageKey);
      if (prefsBranch != null && prefsBranch.isNotEmpty) {
        state = prefsBranch;
      }
    } catch (e) {
      // Si hay error, mantener el default
      state = _kDefaultBranch;
    }
  }

  /// Cambia la sucursal actual
  /// Este método actualiza el estado Y persiste en localStorage
  Future<void> setBranch(String newBranchId) async {
    if (newBranchId.isEmpty) return;
    if (newBranchId == state) return; // No hacer nada si es el mismo

    // Actualizar estado (esto dispara la invalidación de providers dependientes)
    state = newBranchId;

    // Persistir en localStorage
    try {
      html.window.localStorage[_kStorageKey] = newBranchId;

      // También en SharedPreferences como backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStorageKey, newBranchId);
    } catch (e) {
      // Ignorar errores de persistencia, el estado ya cambió
    }
  }

  /// Fuerza una recarga del branch desde localStorage
  Future<void> refresh() async {
    await _loadInitialBranch();
  }
}

/// ============================================================================
/// PROVIDERS PRINCIPALES
/// ============================================================================

/// Provider principal del branchId - USAR ESTE EN TODOS LOS DATA PROVIDERS
final branchIdProvider = StateNotifierProvider<BranchNotifier, String>((ref) {
  return BranchNotifier();
});

/// Provider de solo lectura para el branchId actual
/// Útil cuando solo necesitas leer sin modificar
final currentBranchProvider = Provider<String>((ref) {
  return ref.watch(branchIdProvider);
});

/// ============================================================================
/// HELPER FUNCTIONS
/// ============================================================================

/// Obtiene el branchId actual de forma síncrona desde localStorage
/// Útil para código que no tiene acceso a ref (como ApiService)
String getCurrentBranchSync() {
  try {
    final branch = html.window.localStorage[_kStorageKey];
    return branch ?? _kDefaultBranch;
  } catch (e) {
    return _kDefaultBranch;
  }
}

/// Lista de branches válidos
const List<String> validBranches = ['stg', 'sde', 'sdo', 'rom'];

/// Verifica si un branchId es válido
bool isValidBranch(String branchId) {
  return validBranches.contains(branchId.toLowerCase());
}

/// Nombres legibles de las sucursales
const Map<String, String> branchNames = {
  'stg': 'Santiago',
  'sde': 'Santo Domingo Este',
  'sdo': 'Santo Domingo Oeste',
  'rom': 'La Romana',
};

/// Obtiene el nombre legible de una sucursal
String getBranchName(String branchId) {
  return branchNames[branchId.toLowerCase()] ?? branchId;
}
