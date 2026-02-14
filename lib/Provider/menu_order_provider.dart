import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../model/menu_order_model.dart';
import '../Route/sidebar_item_model.dart';
import '../services/api_service.dart';
import '../const.dart';

/// Provider que gestiona el orden personalizado del menú del sidebar
final menuOrderProvider = StateNotifierProvider<MenuOrderNotifier, AsyncValue<MenuOrderModel>>((ref) {
  return MenuOrderNotifier();
});

class MenuOrderNotifier extends StateNotifier<AsyncValue<MenuOrderModel>> {
  MenuOrderNotifier() : super(const AsyncValue.loading()) {
    _loadMenuOrder();
  }

  final ApiService _apiService = ApiService();
  static const String _localStorageKey = 'menu_order';

  /// Obtiene el branchId actual
  String get _currentBranchId {
    return html.window.localStorage['selected_tenant_id'] ?? 'stg';
  }

  /// Carga el orden del menú desde SharedPreferences o API
  Future<void> _loadMenuOrder() async {
    try {
      // Primero intentar cargar desde localStorage para respuesta rápida
      final localData = await _loadFromLocal();
      if (localData != null && localData.branchId == _currentBranchId) {
        state = AsyncValue.data(localData);
      }

      // Luego intentar cargar desde API para tener datos actualizados
      final apiData = await _loadFromApi();
      if (apiData != null) {
        state = AsyncValue.data(apiData);
        await _saveToLocal(apiData);
      } else if (localData == null) {
        // Si no hay datos en ningún lado, usar orden vacío
        state = AsyncValue.data(MenuOrderModel.empty(_currentBranchId));
      }
    } catch (e) {
      debugPrint('❌ [MenuOrderProvider] Error cargando orden: $e');
      // En caso de error, usar orden vacío
      state = AsyncValue.data(MenuOrderModel.empty(_currentBranchId));
    }
  }

  /// Carga desde SharedPreferences
  Future<MenuOrderModel?> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('${_localStorageKey}_$_currentBranchId');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr);
        return MenuOrderModel.fromJson(json);
      }
    } catch (e) {
      debugPrint('⚠️ [MenuOrderProvider] Error leyendo local: $e');
    }
    return null;
  }

  /// Guarda en SharedPreferences
  Future<void> _saveToLocal(MenuOrderModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_localStorageKey}_${model.branchId}',
        jsonEncode(model.toJson()),
      );
    } catch (e) {
      debugPrint('⚠️ [MenuOrderProvider] Error guardando local: $e');
    }
  }

  /// Carga desde API
  Future<MenuOrderModel?> _loadFromApi() async {
    try {
      final response = await _apiService.get('menu-order');
      if (response.success && response.data != null) {
        return MenuOrderModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('⚠️ [MenuOrderProvider] API no disponible o error: $e');
    }
    return null;
  }

  /// Guarda el orden en API
  Future<bool> _saveToApi(MenuOrderModel model) async {
    try {
      final response = await _apiService.post('menu-order', model.toJson());
      return response.success;
    } catch (e) {
      debugPrint('⚠️ [MenuOrderProvider] Error guardando en API: $e');
      return false;
    }
  }

  /// Actualiza el orden del menú
  Future<void> updateMenuOrder(List<String> newOrder, {String? updatedBy}) async {
    final model = MenuOrderModel(
      branchId: _currentBranchId,
      menuOrder: newOrder,
      updatedAt: DateTime.now(),
      updatedBy: updatedBy,
    );

    state = AsyncValue.data(model);

    // Guardar en local inmediatamente
    await _saveToLocal(model);

    // Intentar guardar en API (no bloqueante)
    _saveToApi(model);

    debugPrint('✅ [MenuOrderProvider] Orden actualizado: ${newOrder.length} items');
  }

  /// Refresca los datos desde la fuente
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadMenuOrder();
  }

  /// Obtiene el orden actual o lista vacía
  List<String> get currentOrder {
    return state.valueOrNull?.menuOrder ?? [];
  }

  /// Aplica el orden personalizado a una lista de menús
  /// Usa una clave única (type + navigationPath) para manejar menús con type duplicado
  List<SidebarItemModel> applyOrder(List<SidebarItemModel> menus) {
    final order = currentOrder;

    if (order.isEmpty) {
      return menus; // Sin orden personalizado, retornar original
    }

    // Crear clave única para cada menú: type|navigationPath
    String getMenuKey(SidebarItemModel m) => '${m.type}|${m.navigationPath}';

    // Crear un mapa para acceso rápido usando clave única
    final menuMap = {for (var m in menus) getMenuKey(m): m};

    // Ordenar según la lista personalizada
    final ordered = <SidebarItemModel>[];
    final usedKeys = <String>{};

    // Primero agregar los que están en el orden personalizado
    for (final key in order) {
      if (menuMap.containsKey(key) && !usedKeys.contains(key)) {
        ordered.add(menuMap[key]!);
        usedKeys.add(key);
      }
    }

    // Luego agregar los que no están en el orden (nuevos menús)
    for (final menu in menus) {
      final key = getMenuKey(menu);
      if (!usedKeys.contains(key)) {
        ordered.add(menu);
        usedKeys.add(key);
      }
    }

    return ordered;
  }
}

/// Provider helper que retorna los menús ordenados según preferencia del usuario
final orderedMenusProvider = Provider<List<SidebarItemModel>>((ref) {
  final menuOrderState = ref.watch(menuOrderProvider);
  final baseMenus = getTopMenusForUser(finalUserRoleModel);

  return menuOrderState.when(
    data: (menuOrder) {
      if (menuOrder.menuOrder.isEmpty) {
        return baseMenus;
      }
      return ref.read(menuOrderProvider.notifier).applyOrder(baseMenus);
    },
    loading: () => baseMenus,
    error: (_, __) => baseMenus,
  );
});
