// Provider mejorado - Migrado a PostgreSQL API
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../model/dress_model.dart';
import '../services/api_service.dart';
import 'branch_provider.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

/// Provider de vestidos por estado - Usa PostgreSQL API
/// ⚠️ CLAVE: Observa branchIdProvider para ser reactivo a cambios de sucursal
final dressesByStatusProvider = FutureProvider.family<List<DressModel>, String>(
  (ref, params) async {
    // ⚠️ CRÍTICO: Observar branchId para que el provider se invalide cuando cambie la sucursal
    final branchId = ref.watch(branchIdProvider);
    debugPrint('🔍 [dressesByStatusProvider] Iniciando con params: $params, branch: $branchId');

    try {
      final dressesResult = await _fetchDresses();
      debugPrint('🔍 [dressesByStatusProvider] _fetchDresses retornó: ${dressesResult.length} vestidos para branch: $branchId');
      if (dressesResult.isEmpty) {
        debugPrint('⚠️ [dressesByStatusProvider] Lista de vestidos vacía para branch: $branchId');
        return [];
      }

      switch (params) {
        case 'Todos':
          debugPrint('✅ [dressesByStatusProvider] Retornando todos: ${dressesResult.length}');
          return dressesResult;
        case 'Lavanderia':
          final filtered = dressesResult.where((dress) => !dress.available).toList();
          debugPrint('✅ [dressesByStatusProvider] Lavanderia: ${filtered.length}');
          return filtered;
        default:
          final reservedIds = await _getReservedDressIds();
          final filtered = _filterByStatus(dressesResult, params, reservedIds);
          debugPrint('✅ [dressesByStatusProvider] Filtrado por $params: ${filtered.length}');
          return filtered;
      }
    } catch (e) {
      debugPrint('❌ [dressesByStatusProvider] Error: $e');
      return <DressModel>[];
    }
  },
);

/// Obtener todos los vestidos desde PostgreSQL
Future<List<DressModel>> _fetchDresses() async {
  try {
    debugPrint('📡 [_fetchDresses] Llamando API dresses...');
    final response = await _apiService.get('dresses', queryParams: {'limit': '5000'});
    debugPrint('📡 [_fetchDresses] Respuesta success: ${response.success}, data: ${response.data != null}');

    if (!response.success || response.data == null) {
      debugPrint('⚠️ [_fetchDresses] Respuesta fallida o sin datos');
      return [];
    }

    debugPrint('📡 [_fetchDresses] response.data keys: ${response.data.keys.toList()}');

    // El API puede devolver 'dresses' (formato completo) o 'd' (formato compacto)
    final dressesData = response.data['dresses'] as List<dynamic>? ??
                        response.data['d'] as List<dynamic>? ?? [];
    debugPrint('📡 [_fetchDresses] dressesData.length: ${dressesData.length}');
    final List<DressModel> dresses = [];

    for (var item in dressesData) {
      try {
        if (item is Map) {
          final data = Map<String, dynamic>.from(item);

          // Soportar formato compacto (i=id, n=name, c=category, etc) y completo
          // Convertir thumbnail URL a imagen original (thumbnails no preservan orientación EXIF)
          String? thumbnailUrl = data['t']?.toString();
          String? originalUrl = thumbnailUrl?.replaceAll('/thumbnails/', '/');

          final Map<String, dynamic> normalizedData = {
            'id': data['id'] ?? data['i'] ?? '',
            'name': data['name'] ?? data['n'] ?? '',
            'category': data['category'] ?? data['c'] ?? '',
            'subcategory': data['subcategory'] ?? '',
            'branch_id': data['branch_id'] ?? data['b'] ?? '',
            'available': data['available'] ?? (data['a'] == 1 ? true : data['a'] == 0 ? false : true),
            'state': data['state'] ?? data['s'] ?? 'available',
            'images': data['images'] ?? (originalUrl != null ? [originalUrl] : []),
            'price': data['price'] ?? data['p'] ?? 0,
            'rental_price': data['rental_price'] ?? data['p'] ?? 0,
          };

          // Verificar campos mínimos
          if (normalizedData['name'] != null && normalizedData['name'].toString().isNotEmpty) {
            final id = normalizedData['id']?.toString() ?? '';
            dresses.add(DressModel.fromMap(normalizedData, id));
          }
        }
      } catch (e) {
        debugPrint('⚠️ [_fetchDresses] Error parseando item: $e');
      }
    }

    debugPrint('✅ [_fetchDresses] Vestidos parseados: ${dresses.length}');
    return dresses;
  } on TimeoutException {
    debugPrint('❌ [_fetchDresses] Timeout');
    throw Exception('Timeout al cargar vestidos');
  } catch (e) {
    debugPrint('❌ [_fetchDresses] Error: $e');
    rethrow;
  }
}

/// Filtrar vestidos por nombre
List<DressModel> _filterByName(List<DressModel> dresses, String search) {
  if (search.isEmpty) return dresses;

  return dresses.where((dress) {
    return dress.name.removeAllWhiteSpace().toLowerCase().contains(search);
  }).toList();
}

/// Obtener IDs de vestidos reservados desde PostgreSQL
Future<Set<String>> _getReservedDressIds() async {
  try {
    final now = DateTime.now();
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    final response = await _apiService.get('reservations', queryParams: {'limit': '5000'});

    if (!response.success || response.data == null) {
      return <String>{};
    }

    final reservationsData = response.data['reservations'] as List<dynamic>? ?? [];
    final reservedDressIds = <String>{};

    for (var resData in reservationsData) {
      try {
        if (resData is! Map) continue;

        _processSimpleReservation(Map<String, dynamic>.from(resData), now, endOfYear, reservedDressIds);
        _processMultipleReservations(Map<String, dynamic>.from(resData), now, endOfYear, reservedDressIds);
      } catch (e) {
        // Error silencioso
      }
    }

    return reservedDressIds;
  } catch (e) {
    return <String>{};
  }
}

/// Procesar reservación simple
void _processSimpleReservation(
    Map resData, DateTime now, DateTime endOfYear, Set<String> reservedIds) {
  final String? dressId = resData['dress_id']?.toString();
  final String? dateStr = resData['reservation_date']?.toString();

  if (dressId == null || dateStr == null) return;

  final date = DateTime.tryParse(dateStr);
  if (date != null && date.isAfter(now) && date.isBefore(endOfYear)) {
    reservedIds.add(dressId);
  }
}

/// Procesar reservaciones múltiples
void _processMultipleReservations(
    Map resData, DateTime now, DateTime endOfYear, Set<String> reservedIds) {
  // Firebase usa 'multiple_dress', PostgreSQL usa 'dress_ids'
  final multiple = resData['multiple_dress'] ?? resData['dress_ids'];
  final String? resDateStr = resData['reservation_date']?.toString();

  if (multiple is! List || resDateStr == null) return;

  final date = DateTime.tryParse(resDateStr);
  if (date == null || !date.isAfter(now) || !date.isBefore(endOfYear)) return;

  for (var item in multiple) {
    if (item is Map && item['dress_id'] != null) {
      reservedIds.add(item['dress_id'].toString());
    }
  }
}

/// Filtrar vestidos por estado
List<DressModel> _filterByStatus(
    List<DressModel> dresses, String status, Set<String> reservedIds) {
  switch (status) {
    case 'Reservados':
      return dresses.where((dress) => reservedIds.contains(dress.id)).toList();
    case 'Disponibles':
      return dresses
          .where((dress) => !reservedIds.contains(dress.id) && dress.available)
          .toList();
    default:
      // Filtrado flexible: coincidencia parcial y normalización
      String normalize(String s) {
        s = s.toLowerCase().trim();
        if (s.startsWith('en ')) s = s.substring(3);
        // Quitar tildes
        s = s
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u')
            .replaceAll('ü', 'u')
            .replaceAll('ñ', 'n');
        s = s.replaceAll(RegExp(r'[^a-z0-9]'), ''); // quita espacios y símbolos
        return s;
      }
      final normalizedStatus = normalize(status);
      return dresses.where((dress) {
        final normalizedState = normalize(dress.state);
        return normalizedState.contains(normalizedStatus) || normalizedStatus.contains(normalizedState);
      }).toList();
  }
}
