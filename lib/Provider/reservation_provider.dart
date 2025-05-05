import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/model/FullReservation.dart';
import 'package:salespro_admin/model/customer_model.dart';
import '../model/reservation_model.dart';
import 'customer_provider.dart';

final reservationsProvider = StreamProvider<List<ReservationModel>>((ref) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/reservations')
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;

      // Filtrar reservaciones que no estén en estado 'cancelado' o 'pendiente'
      return data.entries
          .where((entry) =>
              entry.value is Map && _isValidReservation(entry.value as Map))
          .map((entry) {
            final reservation = ReservationModel.fromMap(
              Map<String, dynamic>.from(entry.value as Map),
              entry.key.toString(),
            );

            // Retornar la reservación solo si el estado es diferente a 'cancelado' y 'pendiente'
            if (reservation.estado != 'cancelado') {
              return reservation;
            }
            return null; // Si el estado es 'cancelado' o 'pendiente', retornamos null
          })
          .where((reservation) =>
              reservation != null) // Eliminar los valores nulos
          .toList() // Convertimos el resultado a una lista de no nulos
          .cast<ReservationModel>(); // Hacemos el cast a List<ReservationModel>
    }
    return <ReservationModel>[];
  });
});

// Helper function to check if a map represents a valid reservation
bool _isValidReservation(Map<dynamic, dynamic> map) {
  // Check if essential fields exist and are not empty strings
  return map.containsKey('reservation_date') &&
      map['reservation_date'] != null &&
      map['reservation_date'] != "";
}

final reservationsByDateProvider =
    StreamProvider.family<List<ReservationModel>, String>((ref, date) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/reservations')
      .orderByChild('reservation_date')
      .equalTo(date)
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .where((entry) =>
              entry.value is Map && _isValidReservation(entry.value as Map))
          .map((entry) {
        return ReservationModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString());
      }).toList();
    }
    return <ReservationModel>[];
  });
});

final ActualizarEstadoReservaProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  try {
    final List<String> reservationIds = List<String>.from(params['id']);
    final String newEstado = params['estado'];
    final updateData = <String, dynamic>{
      'estado': newEstado,
      'updated_at': ServerValue.timestamp,
    };
    for (final id in reservationIds) {
      await FirebaseDatabase.instance
          .ref('Admin Panel/reservations/$id')
          .update(updateData);
    }
    return true;
  } catch (e) {
    print('Error al actualizar estado de múltiples reservas: $e');
    return false;
  }
});

final ReservaPendientProvider =
    StreamProvider.family<List<FullReservation>, String>((ref, clientId) {
  final today = DateTime.now();
  final formattedToday =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

  final reservationsRef =
      FirebaseDatabase.instance.ref('Admin Panel/reservations');
  final dressesRef = FirebaseDatabase.instance.ref('Admin Panel/dresses');
  final servicesRef = FirebaseDatabase.instance.ref('Admin Panel/services');

  return reservationsRef
      .orderByChild('reservation_date')
      .startAt(formattedToday)
      .onValue
      .asyncMap((event) async {
    final snapshot = event.snapshot;
    if (snapshot.value == null || snapshot.value is! Map) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;

    // Filtrar las reservas para el cliente específico y con estado "pendiente"
    final reservations = data.entries.where((entry) {
      final value = entry.value;
      return value is Map &&
          _isValidReservation(value) &&
          value['client_id'] == clientId &&
          value['estado'] == 'pendiente'; // Aquí se agrega el filtro de estado
    }).toList();

    // Obtener los IDs únicos de vestidos y servicios
    final dressIds = reservations
        .map((e) => e.value['dress_id']?.toString())
        .whereType<String>()
        .toSet();
    final serviceIds = reservations
        .map((e) => e.value['service_id']?.toString())
        .whereType<String>()
        .toSet();

    // Obtener todos los vestidos y servicios
    final dressSnap = await dressesRef.get();
    final serviceSnap = await servicesRef.get();

    final dressesMap = dressSnap.value as Map?;
    final servicesMap = serviceSnap.value as Map?;

    // Construir las reservas completas y agregar automáticamente los IDs de vestidos y servicios
    final fullReservations = reservations.map((entry) {
      final id = entry.key.toString();
      final data = Map<String, dynamic>.from(entry.value as Map);
      final dressId = data['dress_id']?.toString();
      final serviceId = data['service_id']?.toString();

      final dress =
          dressId != null && dressesMap != null ? dressesMap[dressId] : null;
      final service = serviceId != null && servicesMap != null
          ? servicesMap[serviceId]
          : null;

      return FullReservation(
        id: id,
        reservation: data,
        dress: dress != null ? Map<String, dynamic>.from(dress) : null,
        service: service != null ? Map<String, dynamic>.from(service) : null,
        dressIds: dressIds.toList(), // Agregar automáticamente los IDs
        serviceIds: serviceIds.toList(), // Agregar automáticamente los IDs
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

    return fullReservations;
  });
});

final reservationsByClientProvider =
    StreamProvider.family<List<ReservationModel>, String>((ref, clientId) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/reservations')
      .orderByChild('client_id')
      .equalTo(clientId)
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .where((entry) =>
              entry.value is Map && _isValidReservation(entry.value as Map))
          .map((entry) {
        return ReservationModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString());
      }).toList();
    }
    return <ReservationModel>[];
  });
});

final reservationsByBranchProvider =
    StreamProvider.family<List<ReservationModel>, String>((ref, branchId) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/reservations')
      .orderByChild('branch_id')
      .equalTo(branchId)
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .where((entry) =>
              entry.value is Map && _isValidReservation(entry.value as Map))
          .map((entry) {
        return ReservationModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString());
      }).toList();
    }
    return <ReservationModel>[];
  });
});

// Provider actualizado

// En tu provider de reservaciones, añade un método para verificar disponibilidad
final isDressAvailableForRangeProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final String dressId = params['dressId'];
  final String startDate =
      params['startDate']; // Fecha de inicio formato 'YYYY-MM-DD'
  final Map<String, dynamic> durationMap =
      params['duration']; // Duración como Map

  try {
    // Convertir fecha de inicio a DateTime
    final startDateTime = DateTime.parse(startDate);

    // Calcular fecha de fin basada en la duración
    DateTime endDateTime;
    if (durationMap['unit'] == 'days') {
      endDateTime = startDateTime.add(Duration(days: durationMap['value']));
    } else if (durationMap['unit'] == 'hours') {
      // Para duraciones cortas en horas, podemos asumir que es el mismo día
      endDateTime = startDateTime.add(Duration(hours: durationMap['value']));
    } else {
      // Valor predeterminado: considerar un día
      endDateTime = startDateTime.add(Duration(days: 1));
    }

    // Obtener todas las reservas para este vestido
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('Admin Panel/reservations');
    final DatabaseEvent event =
        await dbRef.orderByChild('dress_id').equalTo(dressId).once();

    final snapshot = event.snapshot;
    if (snapshot.value == null)
      return true; // No hay reservas para este vestido

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;

      // Verificar si alguna reserva existente se superpone con el período deseado
      for (var reservation in data.values) {
        if (reservation is Map) {
          // Convertir fecha de reserva a DateTime
          final String reservationDateStr = reservation['reservation_date'];
          final DateTime reservationStart = DateTime.parse(reservationDateStr);

          // Obtener la duración de esa reserva (del paquete asociado)
          final String serviceId = reservation['service_id'];

          // Obtener el paquete directamente
          final serviceSnapshot = await FirebaseDatabase.instance
              .ref('Admin Panel/services/$serviceId')
              .get();

          if (serviceSnapshot.exists && serviceSnapshot.value is Map) {
            final Map<dynamic, dynamic> serviceData =
                serviceSnapshot.value as Map<dynamic, dynamic>;
            final Map<String, dynamic> reservationDurationMap =
                (serviceData['duration'] is Map)
                    ? Map<String, dynamic>.from(serviceData['duration'])
                    : {'value': 1, 'unit': 'days'};

            // Calcular la fecha de fin de la reserva existente
            DateTime reservationEnd;
            if (reservationDurationMap['unit'] == 'days') {
              reservationEnd = reservationStart
                  .add(Duration(days: reservationDurationMap['value']));
            } else if (reservationDurationMap['unit'] == 'hours') {
              reservationEnd = reservationStart
                  .add(Duration(hours: reservationDurationMap['value']));
            } else {
              reservationEnd = reservationStart.add(Duration(days: 1));
            }

            // Verificar superposición
            if (!(endDateTime.isBefore(reservationStart) ||
                startDateTime.isAfter(reservationEnd))) {
              return false; // Hay superposición, no está disponible
            }
          }
        }
      }
    }

    return true; // Está disponible
  } catch (e) {
    print('Error verificando disponibilidad del vestido: $e');
    return false; // En caso de error, asumimos que no está disponible
  }
});

final singleReservationProvider =
    FutureProvider.family<ReservationModel?, String>(
        (ref, reservationId) async {
  final snapshot = await FirebaseDatabase.instance
      .ref('Admin Panel/reservations/$reservationId')
      .get();

  if (snapshot.exists && snapshot.value is Map) {
    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    if (_isValidReservation(data)) {
      return ReservationModel.fromMap(
          Map<String, dynamic>.from(data), reservationId);
    }
  }
  return null;
});

final updateReservationProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  try {
    final String reservationId = params['reservationId'];
    final Map<String, dynamic> updateData = params['updateData'];

    updateData['updated_at'] = ServerValue.timestamp;

    await FirebaseDatabase.instance
        .ref('Admin Panel/reservations/$reservationId')
        .update(updateData);

    return true;
  } catch (e) {
    print('Error updating reservation: $e');
    return false;
  }
});

final cancelReservationProvider =
    FutureProvider.family<bool, String>((ref, reservationId) async {
  try {
    await FirebaseDatabase.instance
        .ref('Admin Panel/reservations/$reservationId')
        .remove();

    return true;
  } catch (e) {
    print('Error canceling reservation: $e');
    return false;
  }
});

final fullReservationsProvider =
    FutureProvider<List<FullReservation>>((ref) async {
  final reservationsRef =
      FirebaseDatabase.instance.ref('Admin Panel/reservations');
  final dressesRef = FirebaseDatabase.instance.ref('Admin Panel/dresses');
  final servicesRef = FirebaseDatabase.instance.ref('Admin Panel/services');

  // Obtener todos los datos necesarios
  final reservationsSnapshot = await reservationsRef.get();
  final dressesSnapshot = await dressesRef.get();
  final servicesSnapshot = await servicesRef.get();
  final customers = await ref.watch(allCustomerProvider.future);

  // Convertir a mapas
  final reservationsMap = reservationsSnapshot.value as Map? ?? {};
  final dressesMap = dressesSnapshot.value as Map? ?? {};
  final servicesMap = servicesSnapshot.value as Map? ?? {};

  // Procesar todas las reservaciones
  return reservationsMap.entries.map((entry) {
    final reservation = Map<String, dynamic>.from(entry.value as Map);
    final dressId = reservation['dress_id']?.toString();
    final serviceId = reservation['service_id']?.toString();
    final clientId = reservation['client_id']?.toString();

    // Buscar información relacionada
    final dress = dressId != null ? dressesMap[dressId] : null;
    final service = serviceId != null ? servicesMap[serviceId] : null;
    final client = customers.firstWhere(
      (c) => c.phoneNumber == clientId,
      orElse: () => CustomerModel.empty(),
    );

    return FullReservation(
      id: entry.key,
      reservation: reservation,
      dress: dress != null ? Map<String, dynamic>.from(dress) : null,
      service: service != null ? Map<String, dynamic>.from(service) : null,
      client: client.phoneNumber.isNotEmpty ? client : null,
    );
  }).toList();
});

final fullReservationByIdProviderVQ =
    FutureProvider.family<FullReservation?, String>(
  (ref, reservationId) async {
    final reservationsRef =
        FirebaseDatabase.instance.ref('Admin Panel/reservations');
    final dressesRef = FirebaseDatabase.instance.ref('Admin Panel/dresses');
    final servicesRef = FirebaseDatabase.instance.ref('Admin Panel/services');

    // Obtener la lista de clientes
    final customerList = await ref.read(allCustomerProvider.future);

    // Obtener la reservación
    final reservationSnapshot =
        await reservationsRef.child(reservationId).get();
    final snapshot = reservationSnapshot.value;
    if (snapshot == null || snapshot is! Map) return null;

    final reservation = Map<String, dynamic>.from(snapshot);
    final dressId = reservation['dress_id']?.toString();
    final serviceId = reservation['service_id']?.toString();
    final clientId = reservation['client_id']?.toString();

    // Buscar el cliente por ID
    final client = customerList.firstWhere(
      (c) => c.phoneNumber == clientId,
      orElse: () => CustomerModel.empty(),
    );

    // Obtener datos de vestido y servicio
    final dressSnap = await dressesRef.get();
    final serviceSnap = await servicesRef.get();

    final dressesMap = dressSnap.value as Map?;
    final servicesMap = serviceSnap.value as Map?;

    final dress =
        dressId != null && dressesMap != null ? dressesMap[dressId] : null;
    final service = serviceId != null && servicesMap != null
        ? servicesMap[serviceId]
        : null;

    // Devolver el objeto FullReservation con todos los datos
    return FullReservation(
      id: reservationId,
      reservation: reservation,
      dress: dress != null ? Map<String, dynamic>.from(dress) : null,
      service: service != null ? Map<String, dynamic>.from(service) : null,
      client: client.phoneNumber.isEmpty ? null : client,
      dressIds: dressesMap?.keys.map((e) => e.toString()).toList() ?? [],
      serviceIds: servicesMap?.keys.map((e) => e.toString()).toList() ?? [],
    );
  },
);

final fullReservationByIdProvider =
    StreamProvider.family<FullReservation?, String>((ref, reservationId) {
  final reservationsRef =
      FirebaseDatabase.instance.ref('Admin Panel/reservations');
  final dressesRef = FirebaseDatabase.instance.ref('Admin Panel/dresses');
  final servicesRef = FirebaseDatabase.instance.ref('Admin Panel/services');

  final customerFuture = ref.read(allCustomerProvider.future);

  return reservationsRef.child(reservationId).onValue.asyncMap((event) async {
    final snapshot = event.snapshot.value;
    if (snapshot == null || snapshot is! Map) return null;

    final reservation = Map<String, dynamic>.from(snapshot);
    final dressId = reservation['dress_id']?.toString();
    final serviceId = reservation['service_id']?.toString();
    final clientId = reservation['client_id']?.toString();

    final customerList = await customerFuture;
    final client = customerList.firstWhere(
      (c) => c.phoneNumber == clientId,
      orElse: () => CustomerModel.empty(),
    );

    final dressSnap = await dressesRef.get();
    final serviceSnap = await servicesRef.get();

    final dressesMap = dressSnap.value as Map?;
    final servicesMap = serviceSnap.value as Map?;

    final dress =
        dressId != null && dressesMap != null ? dressesMap[dressId] : null;
    final service = serviceId != null && servicesMap != null
        ? servicesMap[serviceId]
        : null;

    return FullReservation(
      id: reservationId,
      reservation: reservation,
      dress: dress != null ? Map<String, dynamic>.from(dress) : null,
      service: service != null ? Map<String, dynamic>.from(service) : null,
      client: client.phoneNumber.isEmpty
          ? null
          : client, // Ahora asignas el cliente completo
      dressIds: dressesMap?.keys.map((e) => e.toString()).toList() ?? [],
      serviceIds: servicesMap?.keys.map((e) => e.toString()).toList() ?? [],
    );
  });
});

final fullReservationsByClientProvider =
    StreamProvider.family<List<FullReservation>, String>((ref, clientId) {
  final today = DateTime.now();
  final formattedToday =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

  final reservationsRef =
      FirebaseDatabase.instance.ref('Admin Panel/reservations');
  final dressesRef = FirebaseDatabase.instance.ref('Admin Panel/dresses');
  final servicesRef = FirebaseDatabase.instance.ref('Admin Panel/services');

  return reservationsRef
      .orderByChild('reservation_date')
      .startAt(formattedToday)
      .onValue
      .asyncMap((event) async {
    final snapshot = event.snapshot;
    if (snapshot.value == null || snapshot.value is! Map) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;

    // Filtrar las reservas para el cliente específico
    final reservations = data.entries.where((entry) {
      final value = entry.value;
      return value is Map &&
          _isValidReservation(value) &&
          value['client_id'] == clientId;
    }).toList();

    // Obtener los IDs únicos de vestidos y servicios
    final dressIds = reservations
        .map((e) => e.value['dress_id']?.toString())
        .whereType<String>()
        .toSet();
    final serviceIds = reservations
        .map((e) => e.value['service_id']?.toString())
        .whereType<String>()
        .toSet();

    // Obtener todos los vestidos y servicios
    final dressSnap = await dressesRef.get();
    final serviceSnap = await servicesRef.get();

    final dressesMap = dressSnap.value as Map?;
    final servicesMap = serviceSnap.value as Map?;

    // Construir las reservas completas y agregar automáticamente los IDs de vestidos y servicios
    final fullReservations = reservations.map((entry) {
      final id = entry.key.toString();
      final data = Map<String, dynamic>.from(entry.value as Map);
      final dressId = data['dress_id']?.toString();
      final serviceId = data['service_id']?.toString();

      final dress =
          dressId != null && dressesMap != null ? dressesMap[dressId] : null;
      final service = serviceId != null && servicesMap != null
          ? servicesMap[serviceId]
          : null;

      return FullReservation(
        id: id,
        reservation: data,
        dress: dress != null ? Map<String, dynamic>.from(dress) : null,
        service: service != null ? Map<String, dynamic>.from(service) : null,
        dressIds: dressIds.toList(), // Agregar automáticamente los IDs
        serviceIds: serviceIds.toList(), // Agregar automáticamente los IDs
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

    return fullReservations;
  });
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
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref('Admin Panel/reservations');
    final DatabaseEvent event =
        await ref.orderByChild('dress_id').equalTo(dressId).once();

    final snapshot = event.snapshot;

    if (snapshot.value == null) return true;

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;

      return !data.values.any((reservation) =>
          reservation['reservation_date'] == date &&
          reservation['reservation_time'] == time &&
          reservation['status'] != 'cancelado');
    }

    return true;
  } catch (e) {
    print('Error checking dress availability: $e');
    return true; // Fallback a disponible en caso de error
  }
});

final crearReservaProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  try {
    final newReservationRef =
        FirebaseDatabase.instance.ref('Admin Panel/reservations').push();

    final Map<String, dynamic> reservationData = {
      'service_id': params['serviceId'],
      'client_id': params['clientId'],
      'dress_id': params['dressId'],
      'branch_id': params['branchId'],
      'reservation_date': params['date'],
      'reservation_time': params['time'],
      'created_at': ServerValue.timestamp,
      'updated_at': ServerValue.timestamp,
      'estado': 'pendiente',
    };
    await newReservationRef.set(reservationData);
    // Refresh the reservations provider
    // ignore: unused_result
    ref.refresh(reservationsProvider);
    return true;
  } catch (e) {
    print('Error creating reservation: $e');
    return false;
  }
});
