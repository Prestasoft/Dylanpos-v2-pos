import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Provider/servicePackagesProvider.dart';
import 'package:salespro_admin/model/dress_model.dart';
import '../model/reservation_model.dart';

final reservationsProvider = StreamProvider<List<ReservationModel>>((ref) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/reservations')
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

      // Filter out invalid entries (like the empty string entries at root level)
      return data.entries
          .where((entry) => entry.value is Map && _isValidReservation(entry.value as Map))
          .map((entry) {
        return ReservationModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString()
        );
      }).toList();
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

final reservationsByDateProvider = StreamProvider.family<List<ReservationModel>, String>((ref, date) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/reservations')
      .orderByChild('reservation_date')
      .equalTo(date)
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .where((entry) => entry.value is Map && _isValidReservation(entry.value as Map))
          .map((entry) {
        return ReservationModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString()
        );
      }).toList();
    }
    return <ReservationModel>[];
  });
});

final reservationsByClientProvider = StreamProvider.family<List<ReservationModel>, String>((ref, clientId) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/reservations')
      .orderByChild('client_id')
      .equalTo(clientId)
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .where((entry) => entry.value is Map && _isValidReservation(entry.value as Map))
          .map((entry) {
        return ReservationModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString()
        );
      }).toList();
    }
    return <ReservationModel>[];
  });
});

final reservationsByBranchProvider = StreamProvider.family<List<ReservationModel>, String>((ref, branchId) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/reservations')
      .orderByChild('branch_id')
      .equalTo(branchId)
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .where((entry) => entry.value is Map && _isValidReservation(entry.value as Map))
          .map((entry) {
        return ReservationModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString()
        );
      }).toList();
    }
    return <ReservationModel>[];
  });
});




// Provider actualizado


// En tu provider de reservaciones, añade un método para verificar disponibilidad
final isDressAvailableForRangeProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final String dressId = params['dressId'];
  final String startDate = params['startDate']; // Fecha de inicio formato 'YYYY-MM-DD'
  final Map<String, dynamic> durationMap = params['duration']; // Duración como Map

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
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('Admin Panel/reservations');
    final DatabaseEvent event = await dbRef
        .orderByChild('dress_id')
        .equalTo(dressId)
        .once();

    final snapshot = event.snapshot;
    if (snapshot.value == null) return true; // No hay reservas para este vestido

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

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
            final Map<dynamic, dynamic> serviceData = serviceSnapshot.value as Map<dynamic, dynamic>;
            final Map<String, dynamic> reservationDurationMap =
            (serviceData['duration'] is Map)
                ? Map<String, dynamic>.from(serviceData['duration'])
                : {'value': 1, 'unit': 'days'};

            // Calcular la fecha de fin de la reserva existente
            DateTime reservationEnd;
            if (reservationDurationMap['unit'] == 'days') {
              reservationEnd = reservationStart.add(Duration(days: reservationDurationMap['value']));
            } else if (reservationDurationMap['unit'] == 'hours') {
              reservationEnd = reservationStart.add(Duration(hours: reservationDurationMap['value']));
            } else {
              reservationEnd = reservationStart.add(Duration(days: 1));
            }

            // Verificar superposición
            if (!(endDateTime.isBefore(reservationStart) || startDateTime.isAfter(reservationEnd))) {
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

final singleReservationProvider = FutureProvider.family<ReservationModel?, String>((ref, reservationId) async {
  final snapshot = await FirebaseDatabase.instance
      .ref('Admin Panel/reservations/$reservationId')
      .get();

  if (snapshot.exists && snapshot.value is Map) {
    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    if (_isValidReservation(data)) {
      return ReservationModel.fromMap(
          Map<String, dynamic>.from(data),
          reservationId
      );
    }
  }
  return null;
});

final updateReservationProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
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

final cancelReservationProvider = FutureProvider.family<bool, String>((ref, reservationId) async {
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

final upcomingReservationsProvider = StreamProvider<List<ReservationModel>>((ref) {
  final today = DateTime.now();
  final formattedToday = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

  return FirebaseDatabase.instance
      .ref('Admin Panel/reservations')
      .orderByChild('reservation_date')
      .startAt(formattedToday)
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      final reservations = data.entries
          .where((entry) => entry.value is Map && _isValidReservation(entry.value as Map))
          .map((entry) {
        return ReservationModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString()
        );
      }).toList();

      reservations.sort((a, b) {
        int dateCompare = a.reservationDate.compareTo(b.reservationDate);
        if (dateCompare != 0) return dateCompare;
        return a.reservationTime.compareTo(b.reservationTime);
      });

      return reservations;
    }
    return <ReservationModel>[];
  });
});




final isDressAvailableProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final String dressId = params['dressId'];
  final String date = params['date'];
  final String time = params['time'];

  try {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('Admin Panel/reservations');
    final DatabaseEvent event = await ref
        .orderByChild('dress_id')
        .equalTo(dressId)
        .once();

    final snapshot = event.snapshot;

    if (snapshot.value == null) return true;

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      return !data.values.any((reservation) =>
      reservation['reservation_date'] == date &&
          reservation['reservation_time'] == time);
    }

    return true;
  } catch (e) {
    print('Error checking dress availability: $e');
    // Return true by default to prevent blocking the user
    // but you might want to handle errors differently
    return true;
  }
});

final createReservationProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  try {
    final newReservationRef = FirebaseDatabase.instance
        .ref('Admin Panel/reservations')
        .push();

    final Map<String, dynamic> reservationData = {
      'service_id': params['serviceId'],
      'client_id': params['clientId'],
      'dress_id': params['dressId'],
      'branch_id': params['branchId'],
      'reservation_date': params['date'],
      'reservation_time': params['time'],
      'created_at': ServerValue.timestamp,
      'updated_at': ServerValue.timestamp,
    };

    await newReservationRef.set(reservationData);

    // Refresh the reservations provider
    ref.refresh(reservationsProvider);
    return true;
  } catch (e) {
    print('Error creating reservation: $e');
    return false;
  }
});