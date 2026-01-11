import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salespro_admin/Provider/servicePackagesProvider.dart';
import 'package:salespro_admin/Provider/transactions_provider.dart';
import 'package:salespro_admin/Provider/branch_provider.dart';

import 'package:salespro_admin/model/FullReservation.dart';
import 'package:salespro_admin/model/customer_model.dart';
import 'package:salespro_admin/services/api_service.dart';

import '../model/reservation_model.dart';
import 'customer_provider.dart';

final _apiService = ApiService();

/// Normaliza un número de teléfono eliminando caracteres no numéricos
/// para permitir comparaciones más flexibles
String _normalizePhone(String phone) {
  // Eliminar todo excepto dígitos
  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
  // Si tiene más de 10 dígitos y empieza con 1 (código de país US), quitar el 1
  if (digits.length > 10 && digits.startsWith('1')) {
    return digits.substring(1);
  }
  return digits;
}

/// Compara dos números de teléfono normalizándolos primero
bool _phonesMatch(String phone1, String phone2) {
  if (phone1.isEmpty || phone2.isEmpty) return false;
  final norm1 = _normalizePhone(phone1);
  final norm2 = _normalizePhone(phone2);
  // Comparar los últimos 10 dígitos para manejar variaciones de código de país
  final len1 = norm1.length;
  final len2 = norm2.length;
  if (len1 >= 10 && len2 >= 10) {
    return norm1.substring(len1 - 10) == norm2.substring(len2 - 10);
  }
  return norm1 == norm2;
}

/// Busca un cliente por ID (UUID) o por número de teléfono (con normalización)
CustomerModel? _findClientByIdOrPhone(List<CustomerModel> customers, String? clientId) {
  if (clientId == null || clientId.isEmpty) return null;

  // Primero intentar búsqueda exacta por ID
  for (final c in customers) {
    if (c.id == clientId) return c;
  }

  // Luego intentar búsqueda exacta por teléfono
  for (final c in customers) {
    if (c.phoneNumber == clientId) return c;
  }

  // Finalmente, intentar búsqueda normalizada por teléfono
  for (final c in customers) {
    if (_phonesMatch(c.phoneNumber, clientId)) return c;
  }

  return null;
}

final reservationsProvider = StreamProvider<List<ReservationModel>>((ref) {
  // ⚠️ CLAVE: Observamos el branchId - esto crea la dependencia reactiva
  // Cuando cambie el branchId, este provider se invalidará automáticamente
  final branchId = ref.watch(branchIdProvider);
  debugPrint('🔄 [reservationsProvider] Cargando reservaciones para branch: $branchId');

  final controller = StreamController<List<ReservationModel>>();

  Future<void> fetchReservations() async {
    try {
      final response = await _apiService.get('reservations', queryParams: {'limit': '5000'});

      if (response.success && response.data != null) {
        final reservationsData = response.data['reservations'] as List<dynamic>? ?? [];

        final reservations = reservationsData
            .where((item) => item is Map && _isValidReservation(item))
            .map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              final id = data['id']?.toString() ?? data['reservation_id']?.toString() ?? '';
              return ReservationModel.fromMap(data, id);
            })
            .where((reservation) => reservation.estado != 'cancelado')
            .toList();

        controller.add(reservations);
      } else {
        controller.add([]);
      }
    } catch (e) {
      log('Error fetching reservations: $e');
      controller.add([]);
    }
  }

  // Initial fetch
  fetchReservations();

  // Periodic refresh every 30 seconds
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchReservations());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

final reservationsFutureProvider =
    FutureProvider<List<ReservationModel>>((ref) async {
  // ⚠️ CLAVE: Observamos el branchId - esto crea la dependencia reactiva
  final branchId = ref.watch(branchIdProvider);
  debugPrint('🔄 [reservationsFutureProvider] Cargando para branch: $branchId');

  try {
    final response = await _apiService.get('reservations', queryParams: {'limit': '5000'});

    if (response.success && response.data != null) {
      final reservationsData = response.data['reservations'] as List<dynamic>? ?? [];

      return reservationsData.where((item) {
        if (item is! Map) return false;
        return item['estado_factura'] == false && item['estado'] != 'cancelado';
      }).map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        final id = data['id']?.toString() ?? data['reservation_id']?.toString() ?? '';
        return ReservationModel.fromMap(data, id);
      }).toList();
    }
  } catch (e) {
    log('Error in reservationsFutureProvider: $e');
  }

  return <ReservationModel>[];
});

// Helper function to check if a map represents a valid reservation
bool _isValidReservation(Map<dynamic, dynamic> map) {
  return map.containsKey('reservation_date') &&
      map['reservation_date'] != null &&
      map['reservation_date'] != "";
}

final reservationsByDateProvider =
    StreamProvider.family<List<ReservationModel>, String>((ref, date) {
  // ⚠️ CLAVE: Observamos el branchId - esto crea la dependencia reactiva
  final branchId = ref.watch(branchIdProvider);
  debugPrint('🔄 [reservationsByDateProvider] Cargando para branch: $branchId, date: $date');

  final controller = StreamController<List<ReservationModel>>();

  Future<void> fetchReservations() async {
    try {
      final response = await _apiService.get('reservations', queryParams: {
        'reservation_date': date,
        'limit': '1000',
      });

      if (response.success && response.data != null) {
        final reservationsData = response.data['reservations'] as List<dynamic>? ?? [];

        final reservations = reservationsData
            .where((item) => item is Map && _isValidReservation(item))
            .map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              final id = data['id']?.toString() ?? data['reservation_id']?.toString() ?? '';
              final reservation = ReservationModel.fromMap(data, id);

              // Check for main date or fiesta date match
              bool matchesMainDate = data['reservation_date'] == date;
              bool matchesFiestaDate = false;
              if (data['session_type'] == 'pre-quince-fiesta') {
                final fiestaDate = data['fiesta_date']?.toString();
                matchesFiestaDate = fiestaDate != null && fiestaDate.isNotEmpty && fiestaDate == date;
              }

              if (matchesMainDate || matchesFiestaDate) {
                return reservation;
              }
              return null;
            })
            .where((r) => r != null)
            .cast<ReservationModel>()
            .toList();

        controller.add(reservations);
      } else {
        controller.add([]);
      }
    } catch (e) {
      controller.add([]);
    }
  }

  fetchReservations();
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchReservations());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

final ActualizarEstadoReservaProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  try {
    final List<String> reservationIds = List<String>.from(params['id']);
    final String newEstado = params['estado'];

    for (final id in reservationIds) {
      await _apiService.put('reservations/$id', {
        'estado_factura': params['estado_factura'],
        'estado': newEstado,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    return true;
  } catch (e) {
    return false;
  }
});

final ReservaPendientProvider =
    StreamProvider.family<List<FullReservation>, String>((ref, clientId) {
  final controller = StreamController<List<FullReservation>>();

  Future<void> fetchReservations() async {
    try {
      final today = DateTime.now();
      final formattedToday =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // Get reservations
      final response = await _apiService.get('reservations', queryParams: {
        'client_id': clientId,
        'estado': 'pendiente',
        'start_date': formattedToday,
        'limit': '1000',
      });

      // Get dresses and services
      final dressesResponse = await _apiService.get('dresses', queryParams: {'limit': '1000'});
      final servicesResponse = await _apiService.get('services', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final reservationsData = response.data['reservations'] as List<dynamic>? ?? [];
        final dressesData = dressesResponse.data?['dresses'] as List<dynamic>? ?? [];
        final servicesData = servicesResponse.data?['services'] as List<dynamic>? ?? [];

        // Build maps - indexar por UUID y firebase_id para compatibilidad
        final dressesMap = <String, Map<String, dynamic>>{};
        for (var d in dressesData) {
          if (d is Map) {
            final dressData = Map<String, dynamic>.from(d);
            final id = d['id']?.toString() ?? d['dress_id']?.toString() ?? '';
            final firebaseId = d['firebase_id']?.toString() ?? '';
            if (id.isNotEmpty) dressesMap[id] = dressData;
            if (firebaseId.isNotEmpty) dressesMap[firebaseId] = dressData;
          }
        }

        final servicesMap = <String, Map<String, dynamic>>{};
        for (var s in servicesData) {
          if (s is Map) {
            final id = s['id']?.toString() ?? s['service_id']?.toString() ?? '';
            servicesMap[id] = Map<String, dynamic>.from(s);
          }
        }

        final fullReservations = reservationsData
            .where((item) => item is Map && _isValidReservation(item))
            .map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              final id = data['id']?.toString() ?? data['reservation_id']?.toString() ?? '';
              final dressId = data['dress_id']?.toString();
              final serviceId = data['service_id']?.toString();

              return FullReservation(
                id: id,
                reservation: data,
                dress: dressId != null ? dressesMap[dressId] : null,
                service: serviceId != null ? servicesMap[serviceId] : null,
                dressIds: dressesMap.keys.toList(),
                serviceIds: servicesMap.keys.toList(),
                // Firebase usa 'multiple_dress', PostgreSQL usa 'dress_ids'
                multipleDress: ((data['multiple_dress'] ?? data['dress_ids']) as List<dynamic>?)
                        ?.map<Map<String, String>>(
                            (item) => Map<String, String>.from(item as Map))
                        .toList() ??
                    [],
                package_price:
                    double.tryParse(data['package_price']?.toString() ?? '0') ?? 0.0,
                reservation_associated: data['reservation_associated'] ?? '',
              );
            })
            .toList()
          ..sort((a, b) {
            final dateA = a.reservation['reservation_date'] ?? '';
            final dateB = b.reservation['reservation_date'] ?? '';
            final timeA = a.reservation['reservation_time'] ?? '';
            final timeB = b.reservation['reservation_time'] ?? '';
            final dateCompare = dateA.compareTo(dateB);
            return dateCompare != 0 ? dateCompare : timeA.compareTo(timeB);
          });

        controller.add(fullReservations);
      } else {
        controller.add([]);
      }
    } catch (e) {
      controller.add([]);
    }
  }

  fetchReservations();
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchReservations());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

final reservationsByClientProvider =
    StreamProvider.family<List<ReservationModel>, String>((ref, clientId) {
  final controller = StreamController<List<ReservationModel>>();

  Future<void> fetchReservations() async {
    try {
      final response = await _apiService.get('reservations', queryParams: {
        'client_id': clientId,
        'limit': '1000',
      });

      if (response.success && response.data != null) {
        final reservationsData = response.data['reservations'] as List<dynamic>? ?? [];

        final reservations = reservationsData
            .where((item) => item is Map && _isValidReservation(item))
            .map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              final id = data['id']?.toString() ?? data['reservation_id']?.toString() ?? '';
              return ReservationModel.fromMap(data, id);
            })
            .toList();

        controller.add(reservations);
      } else {
        controller.add([]);
      }
    } catch (e) {
      controller.add([]);
    }
  }

  fetchReservations();
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchReservations());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

final reservationsByBranchProvider =
    StreamProvider.family<List<ReservationModel>, String>((ref, branchId) {
  final controller = StreamController<List<ReservationModel>>();

  Future<void> fetchReservations() async {
    try {
      final response = await _apiService.get('reservations', queryParams: {
        'branch_id': branchId,
        'limit': '1000',
      });

      if (response.success && response.data != null) {
        final reservationsData = response.data['reservations'] as List<dynamic>? ?? [];

        final reservations = reservationsData
            .where((item) => item is Map && _isValidReservation(item))
            .map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              final id = data['id']?.toString() ?? data['reservation_id']?.toString() ?? '';
              return ReservationModel.fromMap(data, id);
            })
            .toList();

        controller.add(reservations);
      } else {
        controller.add([]);
      }
    } catch (e) {
      controller.add([]);
    }
  }

  fetchReservations();
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchReservations());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

final isDressAvailableForRangeProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final String dressId = params['dressId'];
  final String startDate = params['startDate'];
  final Map<String, dynamic> durationMap = params['duration'];

  try {
    final startDateTime = DateTime.parse(startDate);
    DateTime endDateTime = _calculateEndDateTime(startDateTime, durationMap);

    // Calcular rango de fechas para filtrar (±30 días para ser seguros)
    final searchStart = startDateTime.subtract(const Duration(days: 30));
    final searchEnd = endDateTime.add(const Duration(days: 30));
    final searchStartStr = searchStart.toIso8601String().split('T')[0];
    final searchEndStr = searchEnd.toIso8601String().split('T')[0];

    // Una sola llamada API con filtro de fechas y dress_id
    final response = await _apiService.get('reservations', queryParams: {
      'dress_id': dressId,
      'start_date': searchStartStr,
      'end_date': searchEndStr,
      'limit': '500',
    });

    if (!response.success) return true;

    final reservationsData = response.data?['reservations'] as List<dynamic>? ?? [];

    // Verificar conflictos sin hacer llamadas API adicionales
    for (var item in reservationsData) {
      if (item is! Map) continue;
      final isAvailable = _checkReservationAvailabilityLocal(
        Map<String, dynamic>.from(item),
        startDateTime,
        endDateTime,
      );
      if (!isAvailable) return false;
    }

    // Buscar también en reservaciones que tengan este vestido en multiple_dress/dress_ids
    final allResponse = await _apiService.get('reservations', queryParams: {
      'start_date': searchStartStr,
      'end_date': searchEndStr,
      'limit': '500',
    });
    final allReservationsData = allResponse.data?['reservations'] as List<dynamic>? ?? [];

    for (var item in allReservationsData) {
      if (item is! Map) continue;
      final data = Map<String, dynamic>.from(item);

      // Check multiple_dress (Firebase) or dress_ids (PostgreSQL)
      final dresses = data['multiple_dress'] ?? data['dress_ids'];
      if (dresses is List) {
        bool hasDress = false;
        for (var dress in dresses) {
          if (dress is Map && dress['dress_id'] == dressId) {
            hasDress = true;
            break;
          } else if (dress is String && dress == dressId) {
            hasDress = true;
            break;
          }
        }
        if (hasDress) {
          final isAvailable = _checkReservationAvailabilityLocal(
            data,
            startDateTime,
            endDateTime,
          );
          if (!isAvailable) return false;
        }
      }

      // Check aditionals
      final aditionals = data['aditionals'];
      if (aditionals is List) {
        for (var additional in aditionals) {
          if (additional is Map) {
            if (additional['dress_id'] == dressId) {
              final isAvailable = await _checkAdditionalAvailability(
                additional,
                startDateTime,
                endDateTime,
              );
              if (!isAvailable) return false;
            }

            // Firebase usa 'multiple_dress', PostgreSQL usa 'dress_ids'
            final multipleDress = additional['multiple_dress'] ?? additional['dress_ids'];
            if (multipleDress is List) {
              for (var dress in multipleDress) {
                if (dress is Map && dress['dress_id'] == dressId) {
                  final isAvailable = await _checkAdditionalAvailability(
                    additional,
                    startDateTime,
                    endDateTime,
                  );
                  if (!isAvailable) return false;
                }
              }
            }
          }
        }
      }
    }

    return true;
  } catch (e) {
    return false;
  }
});

DateTime _calculateEndDateTime(DateTime startDateTime, Map<String, dynamic> durationMap) {
  if (durationMap['unit'] == 'days') {
    return startDateTime.add(Duration(days: durationMap['value']));
  } else if (durationMap['unit'] == 'hours') {
    return startDateTime.add(Duration(hours: durationMap['value']));
  }
  return startDateTime.add(Duration(days: 1));
}

Future<bool> _checkAdditionalAvailability(
    Map additional, DateTime startDateTime, DateTime endDateTime) async {
  try {
    final String reservationDateStr = additional['reservation_date'];
    final DateTime reservationStart = DateTime.parse(reservationDateStr);

    final durationMap = {'value': 1, 'unit': 'days'};

    DateTime reservationUseStart = reservationStart;
    DateTime reservationUseEnd = _calculateEndDateTime(reservationStart, durationMap);

    return endDateTime.isBefore(reservationUseStart) || startDateTime.isAfter(reservationUseEnd);
  } catch (e) {
    return false;
  }
}

/// Verifica disponibilidad usando datos locales (sin llamadas API adicionales)
/// Usa la duración del servicio si está incluida en la reservación, o un valor por defecto
bool _checkReservationAvailabilityLocal(
    Map<String, dynamic> reservation, DateTime startDateTime, DateTime endDateTime) {
  try {
    final String? reservationDateStr = reservation['reservation_date'];
    if (reservationDateStr == null) return true;

    final DateTime reservationStart = DateTime.parse(reservationDateStr);

    // Intentar obtener la duración de la reservación existente
    // La API de PostgreSQL incluye service_duration en la respuesta de reservaciones
    Map<String, dynamic> reservationDurationMap;

    if (reservation['service_duration'] is Map) {
      // Si viene la duración del servicio incluida
      reservationDurationMap = Map<String, dynamic>.from(reservation['service_duration']);
    } else if (reservation['duration'] is Map) {
      // Alternativa: duración directa en la reservación
      reservationDurationMap = Map<String, dynamic>.from(reservation['duration']);
    } else {
      // Valor por defecto: 1 día (seguro para la mayoría de reservaciones de vestidos)
      reservationDurationMap = {'value': 1, 'unit': 'days'};
    }

    final reservationUseStart = reservationStart;
    final reservationUseEnd = _calculateEndDateTime(reservationStart, reservationDurationMap);

    // Verificar si hay conflicto de fechas
    // No hay conflicto si: la nueva reservación termina ANTES de que empiece la existente
    // O si la nueva reservación empieza DESPUÉS de que termine la existente
    return endDateTime.isBefore(reservationUseStart) || startDateTime.isAfter(reservationUseEnd);
  } catch (e) {
    // En caso de error, asumimos que está disponible para no bloquear innecesariamente
    return true;
  }
}

final isClothesAvailableForRangeProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final String dressId = params['dressReservation'];
  final String startDate = params['startDate'];
  final bool isAdditional = params['isAdditional'];

  try {
    final response = await _apiService.get('reservations', queryParams: {
      'dress_id': dressId,
      'limit': '1000',
    });

    final allResponse = await _apiService.get('reservations', queryParams: {'limit': '5000'});
    final allReservationsData = allResponse.data?['reservations'] as List<dynamic>? ?? [];

    // Check multiple_dress (Firebase) or dress_ids (PostgreSQL) reservations
    for (var item in allReservationsData) {
      if (item is! Map) continue;
      final data = Map<String, dynamic>.from(item);

      // Firebase usa 'multiple_dress', PostgreSQL usa 'dress_ids'
      final dresses = data['multiple_dress'] ?? data['dress_ids'];
      if (dresses is List) {
        for (var dress in dresses) {
          if (dress is Map && dress['dress_id'] == dressId) {
            final reservationDateStr = startDate;
            final reservationStart = DateTime.parse(reservationDateStr);

            DateTime cloth_reservation_startDate;
            DateTime cloth_reservation_endDate;

            if (isAdditional) {
              cloth_reservation_startDate = DateTime(
                reservationStart.year,
                reservationStart.month,
                reservationStart.day,
                00, 00, 00,
              );
              cloth_reservation_endDate = DateTime(
                reservationStart.year,
                reservationStart.month,
                reservationStart.day,
                23, 59, 59,
              );
            } else {
              cloth_reservation_startDate = reservationStart.subtract(const Duration(days: 1));
              cloth_reservation_endDate = reservationStart.add(const Duration(days: 1));
              cloth_reservation_endDate = DateTime(
                cloth_reservation_endDate.year,
                cloth_reservation_endDate.month,
                cloth_reservation_endDate.day,
                23, 59, 59,
              );
            }

            final rentas = ref
                .read(servicePackagesProvider.notifier)
                .searchPackages("Renta de Vestimenta");
            final String packageRentaId =
                rentas.firstWhere((e) => e.name == "Renta de Vestimenta").id;

            DateTime reservationUseStart;
            DateTime reservationUseEnd;

            if (packageRentaId == data['service_id']) {
              final DateTime reservationDateTime = DateTime.parse(
                  data['reservation_date'] + ' ' + data['reservation_time']);

              reservationUseStart = DateTime(
                  reservationDateTime.year,
                  reservationDateTime.month,
                  reservationDateTime.day - 1,
                  00, 00, 00);

              reservationUseEnd = DateTime(
                  reservationDateTime.year,
                  reservationDateTime.month,
                  reservationDateTime.day + 1,
                  23, 59, 59);
            } else {
              final DateTime reservationDateTime = DateTime.parse(
                  data['reservation_date'] + ' ' + data['reservation_time']);

              reservationUseStart = DateTime(reservationDateTime.year,
                  reservationDateTime.month, reservationDateTime.day, 00, 00, 00);

              reservationUseEnd = DateTime(reservationDateTime.year,
                  reservationDateTime.month, reservationDateTime.day, 23, 59, 59);
            }

            if (!(reservationUseStart.isBefore(cloth_reservation_startDate) ||
                reservationUseStart.isAfter(cloth_reservation_endDate))) {
              return false;
            }
          }
        }
      }
    }

    // Check simple reservations
    if (response.success && response.data != null) {
      final reservationsData = response.data['reservations'] as List<dynamic>? ?? [];

      for (var item in reservationsData) {
        if (item is! Map) continue;
        final reservation = Map<String, dynamic>.from(item);

        final reservationDateStr = startDate;
        final reservationStart = DateTime.parse(reservationDateStr);

        DateTime cloth_reservation_startDate = reservationStart.subtract(const Duration(days: 1));
        DateTime cloth_reservation_endDate = reservationStart.add(const Duration(days: 1));
        cloth_reservation_endDate = DateTime(
          cloth_reservation_endDate.year,
          cloth_reservation_endDate.month,
          cloth_reservation_endDate.day,
          23, 59, 59,
        );

        final DateTime reservationDateTime = DateTime.parse(
            reservation['reservation_date'] + ' ' + reservation['reservation_time']);

        if (!(reservationDateTime.isBefore(cloth_reservation_startDate) ||
            reservationDateTime.isAfter(cloth_reservation_endDate))) {
          return false;
        }
      }
    }

    return true;
  } catch (e) {
    return false;
  }
});

final singleReservationProvider =
    FutureProvider.family<ReservationModel?, String>((ref, reservationId) async {
  try {
    final response = await _apiService.get('reservations/$reservationId');

    if (response.success && response.data != null) {
      final data = response.data['reservation'] ?? response.data;
      if (data is Map && _isValidReservation(data)) {
        return ReservationModel.fromMap(
            Map<String, dynamic>.from(data), reservationId);
      }
    }
  } catch (e) {
    log('Error in singleReservationProvider: $e');
  }
  return null;
});

final updateReservationProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  try {
    final String reservationId = params['reservationId'];
    final Map<String, dynamic> updateData = Map<String, dynamic>.from(params['updateData']);

    updateData['updated_at'] = DateTime.now().toIso8601String();

    final response = await _apiService.put('reservations/$reservationId', updateData);
    return response.success;
  } catch (e) {
    return false;
  }
});

final cancelReservationProvider =
    FutureProvider.family<bool, String>((ref, reservationId) async {
  if (reservationId.trim().isEmpty) {
    return false;
  }

  try {
    final response = await _apiService.delete('reservations/$reservationId');
    return response.success;
  } catch (e) {
    return false;
  }
});

final fullReservationsProvider =
    FutureProvider<List<FullReservation>>((ref) async {
  // ⚠️ CLAVE: Observamos el branchId - esto crea la dependencia reactiva
  final branchId = ref.watch(branchIdProvider);
  debugPrint('🔄 [fullReservationsProvider] Cargando para branch: $branchId');

  try {
    final response = await _apiService.get('reservations', queryParams: {'limit': '5000'});
    final dressesResponse = await _apiService.get('dresses', queryParams: {'limit': '1000'});
    final servicesResponse = await _apiService.get('services', queryParams: {'limit': '1000'});
    final customers = await ref.watch(allCustomerProvider.future);

    if (!response.success) return [];

    final reservationsData = response.data?['reservations'] as List<dynamic>? ?? [];
    final dressesData = dressesResponse.data?['dresses'] as List<dynamic>? ?? [];
    final servicesData = servicesResponse.data?['services'] as List<dynamic>? ?? [];

    // Build maps - indexar por UUID y firebase_id para compatibilidad
    final dressesMap = <String, Map<String, dynamic>>{};
    for (var d in dressesData) {
      if (d is Map) {
        final dressData = Map<String, dynamic>.from(d);
        final id = d['id']?.toString() ?? d['dress_id']?.toString() ?? '';
        final firebaseId = d['firebase_id']?.toString() ?? '';
        if (id.isNotEmpty) dressesMap[id] = dressData;
        if (firebaseId.isNotEmpty) dressesMap[firebaseId] = dressData;
      }
    }

    final servicesMap = <String, Map<String, dynamic>>{};
    for (var s in servicesData) {
      if (s is Map) {
        final serviceData = Map<String, dynamic>.from(s);
        final id = s['id']?.toString() ?? s['service_id']?.toString() ?? '';
        final firebaseId = s['firebase_id']?.toString() ?? '';
        if (id.isNotEmpty) servicesMap[id] = serviceData;
        if (firebaseId.isNotEmpty) servicesMap[firebaseId] = serviceData;
      }
    }

    return reservationsData.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      final id = data['id']?.toString() ?? data['reservation_id']?.toString() ?? '';
      final dressId = data['dress_id']?.toString();
      final serviceId = data['service_id']?.toString();
      final clientId = data['client_id']?.toString();

      // Buscar cliente usando la función que normaliza teléfonos
      final client = _findClientByIdOrPhone(customers, clientId);

      return FullReservation(
        id: id,
        reservation: data,
        dress: dressId != null ? dressesMap[dressId] : null,
        service: serviceId != null ? servicesMap[serviceId] : null,
        client: client,
      );
    }).toList();
  } catch (e) {
    log('Error in fullReservationsProvider: $e');
    return [];
  }
});

final fullReservationByIdProviderVQ =
    FutureProvider.family<FullReservation?, String>((ref, reservationId) async {
  try {
    final response = await _apiService.get('reservations/$reservationId');
    final dressesResponse = await _apiService.get('dresses', queryParams: {'limit': '1000'});
    final servicesResponse = await _apiService.get('services', queryParams: {'limit': '1000'});
    final customerList = await ref.read(allCustomerProvider.future);

    if (!response.success || response.data == null) return null;

    final data = response.data['reservation'] ?? response.data;
    if (data is! Map) return null;

    final reservation = Map<String, dynamic>.from(data);
    final dressId = reservation['dress_id']?.toString();
    final serviceId = reservation['service_id']?.toString();
    final clientId = reservation['client_id']?.toString();

    // Buscar cliente usando la función que normaliza teléfonos
    final client = _findClientByIdOrPhone(customerList, clientId);

    final dressesData = dressesResponse.data?['dresses'] as List<dynamic>? ?? [];
    final servicesData = servicesResponse.data?['services'] as List<dynamic>? ?? [];

    // Indexar por UUID y firebase_id para compatibilidad
    final dressesMap = <String, Map<String, dynamic>>{};
    for (var d in dressesData) {
      if (d is Map) {
        final dressData = Map<String, dynamic>.from(d);
        final id = d['id']?.toString() ?? d['dress_id']?.toString() ?? '';
        final firebaseId = d['firebase_id']?.toString() ?? '';
        if (id.isNotEmpty) dressesMap[id] = dressData;
        if (firebaseId.isNotEmpty) dressesMap[firebaseId] = dressData;
      }
    }

    final servicesMap = <String, Map<String, dynamic>>{};
    for (var s in servicesData) {
      if (s is Map) {
        final serviceData = Map<String, dynamic>.from(s);
        final id = s['id']?.toString() ?? s['service_id']?.toString() ?? '';
        final firebaseId = s['firebase_id']?.toString() ?? '';
        if (id.isNotEmpty) servicesMap[id] = serviceData;
        if (firebaseId.isNotEmpty) servicesMap[firebaseId] = serviceData;
      }
    }

    return FullReservation(
      id: reservationId,
      reservation: reservation,
      dress: dressId != null ? dressesMap[dressId] : null,
      service: serviceId != null ? servicesMap[serviceId] : null,
      client: client,
      dressIds: dressesMap.keys.toList(),
      serviceIds: servicesMap.keys.toList(),
    );
  } catch (e) {
    log('Error in fullReservationByIdProviderVQ: $e');
    return null;
  }
});

final invoiceNumberByReservationProvider =
    FutureProvider.family<String?, String>((ref, reservationId) async {
  try {
    final salesTransactions = await ref.read(transitionProvider.future);

    for (final transaction in salesTransactions) {
      if (transaction.reservationIds.contains(reservationId)) {
        return transaction.invoiceNumber;
      }
    }

    return null;
  } catch (e) {
    print('Error getting invoice number for reservation: $e');
    return null;
  }
});

final fullReservationByIdProvider =
    StreamProvider.family<FullReservation?, String>((ref, reservationId) {
  final controller = StreamController<FullReservation?>();

  Future<void> fetchReservation() async {
    try {
      final response = await _apiService.get('reservations/$reservationId');
      final dressesResponse = await _apiService.get('dresses', queryParams: {'limit': '1000'});
      final servicesResponse = await _apiService.get('services', queryParams: {'limit': '1000'});
      final customerList = await ref.read(allCustomerProvider.future);

      if (!response.success || response.data == null) {
        controller.add(null);
        return;
      }

      final data = response.data['reservation'] ?? response.data;
      if (data is! Map) {
        controller.add(null);
        return;
      }

      final reservation = Map<String, dynamic>.from(data);
      final dressId = reservation['dress_id']?.toString();
      final serviceId = reservation['service_id']?.toString();
      final clientId = reservation['client_id']?.toString();

      // Buscar cliente usando la función que normaliza teléfonos
      final client = _findClientByIdOrPhone(customerList, clientId);

      final dressesData = dressesResponse.data?['dresses'] as List<dynamic>? ?? [];
      final servicesData = servicesResponse.data?['services'] as List<dynamic>? ?? [];

      // Indexar por UUID y firebase_id para compatibilidad
      final dressesMap = <String, Map<String, dynamic>>{};
      for (var d in dressesData) {
        if (d is Map) {
          final dressData = Map<String, dynamic>.from(d);
          final id = d['id']?.toString() ?? d['dress_id']?.toString() ?? '';
          final firebaseId = d['firebase_id']?.toString() ?? '';
          if (id.isNotEmpty) dressesMap[id] = dressData;
          if (firebaseId.isNotEmpty) dressesMap[firebaseId] = dressData;
        }
      }

      final servicesMap = <String, Map<String, dynamic>>{};
      for (var s in servicesData) {
        if (s is Map) {
          final serviceData = Map<String, dynamic>.from(s);
          final id = s['id']?.toString() ?? s['service_id']?.toString() ?? '';
          final firebaseId = s['firebase_id']?.toString() ?? '';
          if (id.isNotEmpty) servicesMap[id] = serviceData;
          if (firebaseId.isNotEmpty) servicesMap[firebaseId] = serviceData;
        }
      }

      controller.add(FullReservation(
        id: reservationId,
        reservation: reservation,
        dress: dressId != null ? dressesMap[dressId] : null,
        service: serviceId != null ? servicesMap[serviceId] : null,
        client: client,
        dressIds: dressesMap.keys.toList(),
        serviceIds: servicesMap.keys.toList(),
      ));
    } catch (e) {
      controller.add(null);
    }
  }

  fetchReservation();
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchReservation());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

final sidebarProvider =
    StateNotifierProvider<SidebarNotifier, SidebarState>((ref) {
  return SidebarNotifier();
});

class SidebarState {
  final String? expandedMenuPath;
  final String? selectedItemPath;

  SidebarState({this.expandedMenuPath, this.selectedItemPath});

  SidebarState copyWith({
    String? expandedMenuPath,
    String? selectedItemPath,
  }) {
    return SidebarState(
      expandedMenuPath: expandedMenuPath ?? this.expandedMenuPath,
      selectedItemPath: selectedItemPath ?? this.selectedItemPath,
    );
  }
}

class SidebarNotifier extends StateNotifier<SidebarState> {
  SidebarNotifier() : super(SidebarState());

  void expandMenu(String path) {
    state = state.copyWith(expandedMenuPath: path);
  }

  void selectItem(String path) {
    state = state.copyWith(selectedItemPath: path);
  }
}

final isDressAvailableProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final String dressId = params['dressId'];
  final String date = params['date'];
  final String time = params['time'];

  try {
    final startDateTime = DateTime.parse(date);

    // Get reservations for this dress
    final response = await _apiService.get('reservations', queryParams: {
      'dress_id': dressId,
      'limit': '1000',
    });

    // Check all reservations for multiple_dress
    final allResponse = await _apiService.get('reservations', queryParams: {'limit': '5000'});
    final allReservationsData = allResponse.data?['reservations'] as List<dynamic>? ?? [];

    // Check in multiple_dress (Firebase) or dress_ids (PostgreSQL)
    for (var item in allReservationsData) {
      if (item is! Map) continue;
      final reservationData = Map<String, dynamic>.from(item);

      // Firebase usa 'multiple_dress', PostgreSQL usa 'dress_ids'
      final dresses = reservationData['multiple_dress'] ?? reservationData['dress_ids'];
      if (dresses is List) {
        for (var dress in dresses) {
          if (dress is Map && dress['dress_id'] == dressId) {
            final reservationDateStr = reservationData['reservation_date'];
            final reservationStart = DateTime.parse(reservationDateStr);
            final serviceId = reservationData['service_id'];

            final serviceResponse = await _apiService.get('services/$serviceId');

            if (serviceResponse.success && serviceResponse.data != null) {
              final serviceData = serviceResponse.data['service'] ?? serviceResponse.data;
              final reservationDurationMap = (serviceData['duration'] is Map)
                  ? Map<String, dynamic>.from(serviceData['duration'])
                  : {'value': 1, 'unit': 'days'};

              final rentas = ref
                  .read(servicePackagesProvider.notifier)
                  .searchPackages("Renta de Vestimenta");
              final String packageRentaId =
                  rentas.firstWhere((e) => e.name == "Renta de Vestimenta").id;

              DateTime reservationUseStart;
              DateTime reservationUseEnd;

              if (packageRentaId == serviceId) {
                reservationUseStart = DateTime(
                    reservationStart.year,
                    reservationStart.month,
                    reservationStart.day - 1,
                    00, 00, 00);

                reservationUseEnd = DateTime(
                    reservationStart.year,
                    reservationStart.month,
                    reservationStart.day + 1,
                    23, 59, 59);
              } else {
                reservationUseStart = reservationStart;

                if (reservationDurationMap['unit'] == 'days') {
                  reservationUseEnd = reservationStart
                      .add(Duration(days: reservationDurationMap['value']));
                } else if (reservationDurationMap['unit'] == 'hours') {
                  reservationUseEnd = reservationStart
                      .add(Duration(hours: reservationDurationMap['value']));
                } else {
                  reservationUseEnd = reservationStart.add(Duration(days: 1));
                }
              }

              if (!(startDateTime.isBefore(reservationUseStart) ||
                  startDateTime.isAfter(reservationUseEnd))) {
                return false;
              }
            }
          }
        }
      }
    }

    // Check simple reservations
    if (response.success && response.data != null) {
      final reservationsData = response.data['reservations'] as List<dynamic>? ?? [];

      for (var item in reservationsData) {
        if (item is! Map) continue;
        final reservation = Map<String, dynamic>.from(item);

        if (reservation['status'] == 'cancelado') continue;

        bool conflictWithMainDate = reservation['reservation_date'] == date &&
            reservation['reservation_time'] == time;

        bool conflictWithFiestaDate = false;
        if (reservation['session_type'] == 'pre-quince-fiesta') {
          final fiestaDate = reservation['fiesta_date']?.toString();
          final fiestaTime = reservation['fiesta_time']?.toString();
          conflictWithFiestaDate = fiestaDate == date && fiestaTime == time;
        }

        if (conflictWithMainDate || conflictWithFiestaDate) {
          return false;
        }
      }
    }

    return true;
  } catch (e) {
    return true;
  }
});

final crearReservaProvider = FutureProvider.family<reservationCreation, Map<String, dynamic>>(
    (ref, params) async {
  try {
    // Si es una reserva adicional, actualizamos la reserva principal
    if (params['isAdditional'] == true && params['reservation_associated'].isNotEmpty) {
      final response = await _apiService.get('reservations/${params['reservation_associated']}');

      if (!response.success) {
        return reservationCreation(statusReservation: false, reservationId: '');
      }

      final currentData = response.data['reservation'] ?? response.data;
      final updatedData = Map<String, dynamic>.from(currentData as Map);

      if (!updatedData.containsKey('aditionals')) {
        updatedData['aditionals'] = [];
      }

      final additionalData = {
        'service_id': params['serviceId'],
        'dress_id': params['dressId'],
        'branch_id': params['branchId'],
        'reservation_date': params['date'],
        'reservation_time': params['time'],
        'created_at': DateTime.now().toIso8601String(),
        'nota': params['note'],
        'multiple_dress': params['multiple_dress'] ?? [],
        'package_price': params['package_price'] ?? 0,
      };

      (updatedData['aditionals'] as List).add(additionalData);

      final updateResponse = await _apiService.put(
        'reservations/${params['reservation_associated']}',
        {
          'aditionals': updatedData['aditionals'],
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (updateResponse.success) {
        return reservationCreation(
          statusReservation: true,
          reservationId: params['reservation_associated'],
        );
      }

      return reservationCreation(statusReservation: false, reservationId: '');
    }
    // Si es una reserva normal, creamos una nueva
    else {
      final reservationData = {
        'service_id': params['serviceId'],
        'client_id': params['clientId'],
        'dress_id': params['dressId'],
        'branch_id': params['branchId'],
        'reservation_date': params['date'],
        'reservation_time': params['time'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'estado_factura': params['estado_factura'],
        'estado': 'pendiente',
        'nota': params['note'],
        'place': params['place'],
        'multiple_dress': params['multiple_dress'] ?? [],
        'notas': params['notas'] ?? '',
        'reservation_associated': params['reservation_associated'] ?? '',
        'package_price': params['package_price'] ?? 0,
        'seller_name': params['seller_name'],
        'session_type': params['session_type'] ?? 'normal',
        'fiesta_date': params['fiesta_date'] ?? '',
        'fiesta_time': params['fiesta_time'] ?? '',
        'aditionals': [],
      };

      final response = await _apiService.post('reservations', reservationData);

      if (response.success) {
        final newId = response.data?['reservation']?['id']?.toString() ??
                      response.data?['id']?.toString() ?? '';

        ref.refresh(reservationsProvider);

        return reservationCreation(
          statusReservation: true,
          reservationId: newId,
        );
      }

      return reservationCreation(statusReservation: false, reservationId: '');
    }
  } catch (e) {
    return reservationCreation(statusReservation: false, reservationId: '');
  }
});

final actualizarReservaAssociatedProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  try {
    final String reservationId = params['reservationId'];
    final String associatedId = params['associatedId'];

    final response = await _apiService.put('reservations/$reservationId', {
      'reservation_associated': associatedId,
      'updated_at': DateTime.now().toIso8601String(),
    });

    return response.success;
  } catch (e) {
    return false;
  }
});

final fullReservationsByDressProvider =
    StreamProvider.family<List<FullReservation>, String>((ref, dressId) {
  final controller = StreamController<List<FullReservation>>();

  Future<void> fetchReservations() async {
    try {
      final today = DateTime.now();
      final formattedToday =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final response = await _apiService.get('reservations', queryParams: {
        'start_date': formattedToday,
        'limit': '1000',
      });
      final dressesResponse = await _apiService.get('dresses', queryParams: {'limit': '1000'});
      final servicesResponse = await _apiService.get('services', queryParams: {'limit': '1000'});

      if (!response.success) {
        controller.add([]);
        return;
      }

      final reservationsData = response.data?['reservations'] as List<dynamic>? ?? [];
      final dressesData = dressesResponse.data?['dresses'] as List<dynamic>? ?? [];
      final servicesData = servicesResponse.data?['services'] as List<dynamic>? ?? [];

      // Indexar por UUID y firebase_id para compatibilidad
      final dressesMap = <String, Map<String, dynamic>>{};
      for (var d in dressesData) {
        if (d is Map) {
          final dressData = Map<String, dynamic>.from(d);
          final id = d['id']?.toString() ?? d['dress_id']?.toString() ?? '';
          final firebaseId = d['firebase_id']?.toString() ?? '';
          if (id.isNotEmpty) dressesMap[id] = dressData;
          if (firebaseId.isNotEmpty) dressesMap[firebaseId] = dressData;
        }
      }

      final servicesMap = <String, Map<String, dynamic>>{};
      for (var s in servicesData) {
        if (s is Map) {
          final serviceData = Map<String, dynamic>.from(s);
          final id = s['id']?.toString() ?? s['service_id']?.toString() ?? '';
          final firebaseId = s['firebase_id']?.toString() ?? '';
          if (id.isNotEmpty) servicesMap[id] = serviceData;
          if (firebaseId.isNotEmpty) servicesMap[firebaseId] = serviceData;
        }
      }

      final filteredReservations = reservationsData.where((item) {
        if (item is! Map) return false;
        // Firebase usa 'multiple_dress', PostgreSQL usa 'dress_ids'
        final multipleDress = item['multiple_dress'] ?? item['dress_ids'];
        if (multipleDress is List) {
          return multipleDress.any((dress) => dress is Map && dress['dress_id'] == dressId);
        }
        return false;
      }).toList();

      final fullReservations = filteredReservations.map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        final id = data['id']?.toString() ?? data['reservation_id']?.toString() ?? '';
        final reservationDressId = data['dress_id']?.toString();
        final serviceId = data['service_id']?.toString();

        return FullReservation(
          id: id,
          reservation: data,
          dress: reservationDressId != null ? dressesMap[reservationDressId] : null,
          service: serviceId != null ? servicesMap[serviceId] : null,
          dressIds: dressesMap.keys.toList(),
          serviceIds: servicesMap.keys.toList(),
        );
      }).toList()
        ..sort((a, b) {
          final dateA = a.reservation['reservation_date'] ?? '';
          final dateB = b.reservation['reservation_date'] ?? '';
          final timeA = a.reservation['reservation_time'] ?? '';
          final timeB = b.reservation['reservation_time'] ?? '';
          final dateCompare = dateA.compareTo(dateB);
          return dateCompare != 0 ? dateCompare : timeA.compareTo(timeB);
        });

      controller.add(fullReservations);
    } catch (e) {
      controller.add([]);
    }
  }

  fetchReservations();
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchReservations());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

final fullReservationsByDressProvider2 =
    StreamProvider.family<List<FullReservation>, String>((ref, dressId) {
  final controller = StreamController<List<FullReservation>>();

  Future<void> fetchReservations() async {
    try {
      final today = DateTime.now();
      final formattedToday =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final customers = await ref.watch(allCustomerProvider.future);

      final response = await _apiService.get('reservations', queryParams: {
        'start_date': formattedToday,
        'limit': '1000',
      });
      final dressesResponse = await _apiService.get('dresses', queryParams: {'limit': '1000'});
      final servicesResponse = await _apiService.get('services', queryParams: {'limit': '1000'});

      if (!response.success) {
        controller.add([]);
        return;
      }

      final reservationsData = response.data?['reservations'] as List<dynamic>? ?? [];
      final dressesData = dressesResponse.data?['dresses'] as List<dynamic>? ?? [];
      final servicesData = servicesResponse.data?['services'] as List<dynamic>? ?? [];

      // Indexar por UUID y firebase_id para compatibilidad
      final dressesMap = <String, Map<String, dynamic>>{};
      for (var d in dressesData) {
        if (d is Map) {
          final dressData = Map<String, dynamic>.from(d);
          final id = d['id']?.toString() ?? d['dress_id']?.toString() ?? '';
          final firebaseId = d['firebase_id']?.toString() ?? '';
          if (id.isNotEmpty) dressesMap[id] = dressData;
          if (firebaseId.isNotEmpty) dressesMap[firebaseId] = dressData;
        }
      }

      final servicesMap = <String, Map<String, dynamic>>{};
      for (var s in servicesData) {
        if (s is Map) {
          final serviceData = Map<String, dynamic>.from(s);
          final id = s['id']?.toString() ?? s['service_id']?.toString() ?? '';
          final firebaseId = s['firebase_id']?.toString() ?? '';
          if (id.isNotEmpty) servicesMap[id] = serviceData;
          if (firebaseId.isNotEmpty) servicesMap[firebaseId] = serviceData;
        }
      }

      final filteredReservations = reservationsData.where((item) {
        if (item is! Map) return false;
        // Firebase usa 'multiple_dress', PostgreSQL usa 'dress_ids'
        final multipleDress = item['multiple_dress'] ?? item['dress_ids'];
        if (multipleDress is List) {
          return multipleDress.any((dress) => dress is Map && dress['dress_id'] == dressId);
        }
        return false;
      }).toList();

      final fullReservations = filteredReservations.map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        final id = data['id']?.toString() ?? data['reservation_id']?.toString() ?? '';
        final reservationDressId = data['dress_id']?.toString();
        final serviceId = data['service_id']?.toString();
        final clientId = data['client_id']?.toString();

        // Buscar cliente usando la función que normaliza teléfonos
        final client = _findClientByIdOrPhone(customers, clientId);

        return FullReservation(
          id: id,
          reservation: data,
          dress: reservationDressId != null ? dressesMap[reservationDressId] : null,
          service: serviceId != null ? servicesMap[serviceId] : null,
          dressIds: dressesMap.keys.toList(),
          serviceIds: servicesMap.keys.toList(),
          client: client,
        );
      }).toList()
        ..sort((a, b) {
          final dateA = a.reservation['reservation_date'] ?? '';
          final dateB = b.reservation['reservation_date'] ?? '';
          final timeA = a.reservation['reservation_time'] ?? '';
          final timeB = b.reservation['reservation_time'] ?? '';
          final dateCompare = dateA.compareTo(dateB);
          return dateCompare != 0 ? dateCompare : timeA.compareTo(timeB);
        });

      controller.add(fullReservations);
    } catch (e) {
      controller.add([]);
    }
  }

  fetchReservations();
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchReservations());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

class reservationCreation {
  final String reservationId;
  final bool statusReservation;

  reservationCreation({
    required this.reservationId,
    required this.statusReservation,
  });
}
