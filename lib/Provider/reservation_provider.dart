import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salespro_admin/Provider/servicePackagesProvider.dart';

import 'package:salespro_admin/model/FullReservation.dart';
import 'package:salespro_admin/model/customer_model.dart';

import '../model/reservation_model.dart';
import 'customer_provider.dart';

final reservationsProvider = StreamProvider<List<ReservationModel>>((ref) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/reservations')
      .orderByChild('reservation_time')  
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      log(data.toString());
      // Filtrar reservaciones que no estén en estado 'cancelado' o 'pendiente'
      return data.entries
          .where(
            (entry) =>
                entry.value is Map && _isValidReservation(entry.value as Map),
          )
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

final reservationsFutureProvider =
    FutureProvider<List<ReservationModel>>((ref) async {
  final snapshot =
      await FirebaseDatabase.instance.ref('Admin Panel/reservations').get();

  if (snapshot.value == null) return [];

  if (snapshot.value is Map) {
    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

    return data.entries.where((entry) {
      final value = entry.value as Map;
      return value['estado_factura'] == false && value['estado'] != 'cancelado';
    }).map((entry) {
      return ReservationModel.fromMap(
        Map<String, dynamic>.from(entry.value as Map),
        entry.key.toString(),
      );
    }).toList();
  }

  return <ReservationModel>[];
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
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .where((entry) {
            if (!(entry.value is Map && _isValidReservation(entry.value as Map))) {
              return false;
            }
            
            final reservation = entry.value as Map;
            
            // Verificar si la fecha solicitada coincide con reservation_date
            bool matchesMainDate = reservation['reservation_date'] == date;
            
            // Verificar si la fecha solicitada coincide con fiesta_date (para planes PRE-QUINCE FIESTA)
            bool matchesFiestaDate = false;
            if (reservation['session_type'] == 'pre-quince-fiesta') {
              final fiestaDate = reservation['fiesta_date']?.toString();
              matchesFiestaDate = fiestaDate != null && fiestaDate.isNotEmpty && fiestaDate == date;
            }
            
            return matchesMainDate || matchesFiestaDate;
          })
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
      'estado_factura': params['estado_factura'],
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

      final multipleDress =
          data['multiple_dress'] != null ? data['multiple_dress'] : [];

      return FullReservation(
        id: id,
        reservation: data,
        dress: dress != null ? Map<String, dynamic>.from(dress) : null,
        service: service != null ? Map<String, dynamic>.from(service) : null,
        dressIds: dressIds.toList(), // Agregar automáticamente los IDs
        serviceIds: serviceIds.toList(), // Agregar automáticamente los IDs

        multipleDress: (data['multiple_dress'] as List<dynamic>?)
                ?.map<Map<String, String>>(
                    (item) => Map<String, String>.from(item as Map))
                .toList() ??
            [],
        package_price:
            double.tryParse(data['package_price']?.toString() ?? '0') ?? 0.0,
        reservation_associated: data['reservation_associated'] ?? '',
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
// final isDressAvailableForRangeProvider =
//     FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
//   final String dressId = params['dressId'];
//   final String startDate =
//       params['startDate']; // Fecha de inicio formato 'YYYY-MM-DD'
//   final Map<String, dynamic> durationMap =
//       params['duration']; // Duración como Map

//   try {
//     // Convertir fecha de inicio a DateTime
//     final startDateTime = DateTime.parse(startDate);

//     // Calcular fecha de fin basada en la duración
//     DateTime endDateTime;
//     if (durationMap['unit'] == 'days') {
//       endDateTime = startDateTime.add(Duration(days: durationMap['value']));
//     } else if (durationMap['unit'] == 'hours') {
//       // Para duraciones cortas en horas, podemos asumir que es el mismo día
//       endDateTime = startDateTime.add(Duration(hours: durationMap['value']));
//     } else {
//       // Valor predeterminado: considerar un día
//       endDateTime = startDateTime.add(Duration(days: 1));
//     }

//     // Obtener todas las reservas para este vestido
//     final DatabaseReference dbRef =
//         FirebaseDatabase.instance.ref('Admin Panel/reservations');
//     final DatabaseEvent event =
//         await dbRef.orderByChild('dress_id').equalTo(dressId).once();

//     // Logica nueva para verificar disponibilidad en Reservas Compuestas
//     final snapshotC = await dbRef.once();
//     final data = snapshotC.snapshot.value;
//     List<Map<String, String>> allDresses = [];
//     List<Map<dynamic, dynamic>> allDressReservation = [];

//     if (data is Map) {
//       data.forEach((reservationId, reservationData) {
//         if (reservationData is Map) {
//           final dresses = reservationData['multiple_dress'];
//           if (dresses is List) {
//             for (var dress in dresses) {
//               if (dress is Map && dress.containsKey('dress_id')) {
//                 allDresses.add({
//                   'dress_id': dress['dress_id'].toString(),
//                   'service_id': reservationData['service_id'].toString(),
//                   'reservation_date': reservationData['reservation_date'],
//                   'reservation_time': reservationData['reservation_time'],
//                 });
//               }
//             }
//           }
//         }
//       });
//     }

//     if (allDresses.isNotEmpty) {
//       for (var dress in allDresses) {
//         if (dress is Map && dress['dress_id'] == dressId) {
//           // Guardamos la reserva entera
//           allDressReservation.add(dress);
//         }
//       }

//       if (allDressReservation.isNotEmpty) {
//         for (var _reservation in allDressReservation) {
//           // Convertir fecha de reserva a DateTime
//           final String reservationDateStr = _reservation['reservation_date'];
//           final DateTime reservationStart = DateTime.parse(reservationDateStr);

//           // Obtener la duración de esa reserva (del paquete asociado)
//           final String serviceId = _reservation['service_id'];

//           // Obtener el paquete directamente
//           final serviceSnapshot = await FirebaseDatabase.instance
//               .ref('Admin Panel/services/$serviceId')
//               .get();

//           if (serviceSnapshot.exists && serviceSnapshot.value is Map) {
//             final Map<dynamic, dynamic> serviceData =
//                 serviceSnapshot.value as Map<dynamic, dynamic>;
//             final Map<String, dynamic> reservationDurationMap =
//                 (serviceData['duration'] is Map)
//                     ? Map<String, dynamic>.from(serviceData['duration'])
//                     : {'value': 1, 'unit': 'days'};

//             final rentas = ref
//                 .read(servicePackagesProvider.notifier)
//                 .searchPackages("Renta de Vestimenta");
//             final String packageRentaId =
//                 rentas.firstWhere((e) => e.name == "Renta de Vestimenta").id;

//             DateTime reservationUseStart;
//             DateTime reservationUseEnd;

//             // Verifico si el vestido es una renta
//             if (packageRentaId == _reservation['service_id']) {
//               reservationUseStart = DateTime(
//                   reservationStart.year,
//                   reservationStart.month,
//                   reservationStart.day - 1, // Día siguiente
//                   00,
//                   00,
//                   00);

//               reservationUseEnd = DateTime(
//                   reservationStart.year,
//                   reservationStart.month,
//                   reservationStart.day + 1, // Día siguiente
//                   23,
//                   59,
//                   59);
//             } else {
//               // Calcular la fecha de fin de la reserva existente

//               reservationUseStart = reservationStart;

//               if (reservationDurationMap['unit'] == 'days') {
//                 reservationUseEnd = reservationStart
//                     .add(Duration(days: reservationDurationMap['value']));
//               } else if (reservationDurationMap['unit'] == 'hours') {
//                 reservationUseEnd = reservationStart
//                     .add(Duration(hours: reservationDurationMap['value']));
//               } else {
//                 reservationUseEnd = reservationStart.add(Duration(days: 1));
//               }
//             }

//             // Verificar superposición
//             if (!(endDateTime.isBefore(reservationUseStart) ||
//                 startDateTime.isAfter(reservationUseEnd))) {
//               return false; // Hay superposición, no está disponible
//             }
//           }
//         }
//       }
//     }

//     // Logica para verificar disponibilidad en Reservas Simples
//     final snapshot = event.snapshot;
//     if (snapshot.value == null)
//       return true; // No hay reservas para este vestido

//     if (snapshot.value is Map) {
//       final Map<dynamic, dynamic> data =
//           snapshot.value as Map<dynamic, dynamic>;

//       // Verificar si alguna reserva existente se superpone con el período deseado
//       for (var reservation in data.values) {
//         if (reservation is Map) {
//           // Convertir fecha de reserva a DateTime
//           final String reservationDateStr = reservation['reservation_date'];
//           final DateTime reservationStart = DateTime.parse(reservationDateStr);

//           // Obtener la duración de esa reserva (del paquete asociado)
//           final String serviceId = reservation['service_id'];

//           // Obtener el paquete directamente
//           final serviceSnapshot = await FirebaseDatabase.instance
//               .ref('Admin Panel/services/$serviceId')
//               .get();

//           if (serviceSnapshot.exists && serviceSnapshot.value is Map) {
//             final Map<dynamic, dynamic> serviceData =
//                 serviceSnapshot.value as Map<dynamic, dynamic>;
//             final Map<String, dynamic> reservationDurationMap =
//                 (serviceData['duration'] is Map)
//                     ? Map<String, dynamic>.from(serviceData['duration'])
//                     : {'value': 1, 'unit': 'days'};

//             final rentas = ref
//                 .read(servicePackagesProvider.notifier)
//                 .searchPackages("Renta de Vestimenta");
//             final String packageRentaId =
//                 rentas.firstWhere((e) => e.name == "Renta de Vestimenta").id;
//             DateTime reservationUseStart;
//             DateTime reservationUseEnd;

//             // Verifico si el vestido es una renta
//             if (packageRentaId == reservation['service_id']) {
//               reservationUseStart = DateTime(
//                   reservationStart.year,
//                   reservationStart.month,
//                   reservationStart.day - 1, // Día siguiente
//                   00,
//                   00,
//                   00);

//               reservationUseEnd = DateTime(
//                   reservationStart.year,
//                   reservationStart.month,
//                   reservationStart.day + 1, // Día siguiente
//                   23,
//                   59,
//                   59);
//             } else {
//               // Calcular la fecha de fin de la reserva existente

//               reservationUseStart = reservationStart;

//               if (reservationDurationMap['unit'] == 'days') {
//                 reservationUseEnd = reservationStart
//                     .add(Duration(days: reservationDurationMap['value']));
//               } else if (reservationDurationMap['unit'] == 'hours') {
//                 reservationUseEnd = reservationStart
//                     .add(Duration(hours: reservationDurationMap['value']));
//               } else {
//                 reservationUseEnd = reservationStart.add(Duration(days: 1));
//               }
//             }

//             // Verificar superposición
//             if (!(endDateTime.isBefore(reservationUseStart) ||
//                 startDateTime.isAfter(reservationUseEnd))) {
//               return false; // Hay superposición, no está disponible
//             }
//           }
//         }
//       }
//     }

//     return true; // Está disponible
//   } catch (e) {
//     return false; // En caso de error, asumimos que no está disponible
//   }
// });
final isDressAvailableForRangeProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final String dressId = params['dressId'];
  final String startDate = params['startDate'];
  final Map<String, dynamic> durationMap = params['duration'];

  try {
    final startDateTime = DateTime.parse(startDate);
    DateTime endDateTime = _calculateEndDateTime(startDateTime, durationMap);

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('Admin Panel/reservations');
    
    // 1. Verificar disponibilidad en reservas principales (dress_id directo)
    final simpleReservations = await dbRef.orderByChild('dress_id').equalTo(dressId).once();
    if (!await _checkSimpleReservations(simpleReservations, startDateTime, endDateTime)) {
      return false;
    }

    // 2. Verificar disponibilidad en multiple_dress de reservas principales
    if (!await _checkMultipleDressInMainReservations(dbRef, dressId, startDateTime, endDateTime)) {
      return false;
    }

    // 3. Verificar disponibilidad en aditionals
    if (!await _checkAditionals(dbRef, dressId, startDateTime, endDateTime)) {
      return false;
    }

    return true;
  } catch (e) {
    return false;
  }
});

// Función auxiliar para calcular fecha final
DateTime _calculateEndDateTime(DateTime startDateTime, Map<String, dynamic> durationMap) {
  if (durationMap['unit'] == 'days') {
    return startDateTime.add(Duration(days: durationMap['value']));
  } else if (durationMap['unit'] == 'hours') {
    return startDateTime.add(Duration(hours: durationMap['value']));
  }
  return startDateTime.add(Duration(days: 1));
}

// Función para verificar reservas simples (modificada)
Future<bool> _checkSimpleReservations(
    DatabaseEvent event, DateTime startDateTime, DateTime endDateTime) async {
  final snapshot = event.snapshot;
  if (snapshot.value == null) return true;

  if (snapshot.value is Map) {
    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    
    for (var reservation in data.values) {
      if (reservation is Map) {
        final isAvailable = await _checkReservationAvailability(
          reservation, 
          startDateTime, 
          endDateTime,
        );
        if (!isAvailable) return false;
      }
    }
  }
  return true;
}

// Función para verificar multiple_dress en reservas principales (modificada)
Future<bool> _checkMultipleDressInMainReservations(
    DatabaseReference dbRef, String dressId, DateTime startDateTime, DateTime endDateTime) async {
  final snapshotC = await dbRef.once();
  final data = snapshotC.snapshot.value;
  
  if (data is Map) {
    for (var reservation in data.values) {
      if (reservation is Map) {
        final dresses = reservation['multiple_dress'];
        if (dresses is List) {
          for (var dress in dresses) {
            if (dress is Map && dress['dress_id'] == dressId) {
              final isAvailable = await _checkReservationAvailability(
                reservation, 
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
  return true;
}

// Función para verificar aditionals (modificada)
Future<bool> _checkAditionals(
    DatabaseReference dbRef, String dressId, DateTime startDateTime, DateTime endDateTime) async {
  final snapshot = await dbRef.once();
  final data = snapshot.snapshot.value;
  
  if (data is Map) {
    for (var reservation in data.values) {
      if (reservation is Map) {
        final aditionals = reservation['aditionals'];
        if (aditionals is List) {
          for (var additional in aditionals) {
            if (additional is Map) {
              // Verificar dress_id directo en adicional
              if (additional['dress_id'] == dressId) {
                final isAvailable = await _checkAdditionalAvailability(
                  additional, 
                  startDateTime, 
                  endDateTime,
                );
                if (!isAvailable) return false;
              }
              
              // Verificar multiple_dress en adicional
              final multipleDress = additional['multiple_dress'];
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
    }
  }
  return true;
}

// Función para verificar disponibilidad de una reserva adicional (modificada)
Future<bool> _checkAdditionalAvailability(
    Map additional, DateTime startDateTime, DateTime endDateTime) async {
  try {
    final String reservationDateStr = additional['reservation_date'];
    final DateTime reservationStart = DateTime.parse(reservationDateStr);
    
    // Duración fija para adicionales (1 día por defecto)
    final durationMap = {'value': 1, 'unit': 'days'};
    
    DateTime reservationUseStart = reservationStart;
    DateTime reservationUseEnd = _calculateEndDateTime(reservationStart, durationMap);
    
    // Verificar superposición
    return endDateTime.isBefore(reservationUseStart) || startDateTime.isAfter(reservationUseEnd);
  } catch (e) {
    return false;
  }
}

// Función para verificar disponibilidad de una reserva (modificada)
Future<bool> _checkReservationAvailability(
    Map reservation, DateTime startDateTime, DateTime endDateTime) async {
  try {
    final String reservationDateStr = reservation['reservation_date'];
    final DateTime reservationStart = DateTime.parse(reservationDateStr);
    final String serviceId = reservation['service_id'];

    final serviceSnapshot = await FirebaseDatabase.instance
        .ref('Admin Panel/services/$serviceId')
        .get();

    if (serviceSnapshot.exists && serviceSnapshot.value is Map) {
      final Map<dynamic, dynamic> serviceData = serviceSnapshot.value as Map<dynamic, dynamic>;
      final Map<String, dynamic> reservationDurationMap = (serviceData['duration'] is Map)
          ? Map<String, dynamic>.from(serviceData['duration'])
          : {'value': 1, 'unit': 'days'};

      // Verificar si es una renta de vestimenta (lógica especial)
      if (serviceId == "ID_DEL_PAQUETE_RENTA") { // Reemplaza con el ID real
        final reservationUseStart = DateTime(
            reservationStart.year,
            reservationStart.month,
            reservationStart.day - 1,
            00, 00, 00);
        final reservationUseEnd = DateTime(
            reservationStart.year,
            reservationStart.month,
            reservationStart.day + 1,
            23, 59, 59);
        
        return endDateTime.isBefore(reservationUseStart) || startDateTime.isAfter(reservationUseEnd);
      } else {
        final reservationUseStart = reservationStart;
        final reservationUseEnd = _calculateEndDateTime(reservationStart, reservationDurationMap);
        return endDateTime.isBefore(reservationUseStart) || startDateTime.isAfter(reservationUseEnd);
      }
    }
    return true;
  } catch (e) {
    return false;
  }
}

final isClothesAvailableForRangeProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final String dressId = params['dressReservation'];
  final String startDate =
      params['startDate']; // Fecha de inicio formato 'YYYY-MM-DD'
  final bool isAdditional =
      params['isAdditional']; // Fecha de inicio formato 'YYYY-MM-DD'
  try {
    // Obtener todas las reservas para este vestido
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('Admin Panel/reservations');
    final DatabaseEvent event =
        await dbRef.orderByChild('dress_id').equalTo(dressId).once();

    // Logica nueva para verificar disponibilidad en Reservas Compuestas
    final snapshotC = await dbRef.once();
    final data = snapshotC.snapshot.value;
    List<Map<String, String>> allDresses = [];
    List<Map<dynamic, dynamic>> allDressReservation = [];

    if (data is Map) {
      data.forEach((reservationId, reservationData) {
        if (reservationData is Map) {
          final dresses = reservationData['multiple_dress'];
          if (dresses is List) {
            for (var dress in dresses) {
              if (dress is Map && dress.containsKey('dress_id')) {
                allDresses.add({
                  'dress_id': dress['dress_id'].toString(),
                  'service_id': reservationData['service_id'].toString(),
                  'reservation_date': reservationData['reservation_date'],
                  'reservation_time': reservationData['reservation_time'],
                });
              }
            }
          }
        }
      });
    }

    if (allDresses.isNotEmpty) {
      for (var dress in allDresses) {
        if (dress is Map && dress['dress_id'] == dressId) {
          // Guardamos la reserva entera
          allDressReservation.add(dress);
        }
      }

      if (allDressReservation.isNotEmpty) {
        for (var _reservation in allDressReservation) {
          // Convertir fecha de reserva a DateTime

          final String reservationDateStr = startDate;
          final DateTime reservationStart = DateTime.parse(reservationDateStr);

          // Calcular la fecha de fin de la reserva existente
          DateTime cloth_reservation_startDate;
          DateTime cloth_reservation_endDate;

          if (isAdditional) {
            // Al ser una renta adicional, asumimos que el inicio es el mismo día
            cloth_reservation_startDate = DateTime(
              reservationStart.year,
              reservationStart.month,
              reservationStart.day,
              00,
              00,
              00,
            );

            cloth_reservation_endDate = DateTime(
              reservationStart.year,
              reservationStart.month,
              reservationStart.day,
              23,
              59,
              59,
            );
          } else {
            // Al ser una renta de vestido, asumimos que el inicio es un día anterior
            cloth_reservation_startDate =
                reservationStart.subtract(const Duration(days: 1));

            // Al ser una renta de vestido, asumimos que el fin es un día posterior con fecha 23:59:59
            cloth_reservation_endDate =
                reservationStart.add(const Duration(days: 1));
            cloth_reservation_endDate = DateTime(
              cloth_reservation_endDate.year,
              cloth_reservation_endDate.month,
              cloth_reservation_endDate.day,
              23,
              59,
              59,
            );
          }

          final rentas = ref
              .read(servicePackagesProvider.notifier)
              .searchPackages("Renta de Vestimenta");
          final String packageRentaId =
              rentas.firstWhere((e) => e.name == "Renta de Vestimenta").id;

          DateTime reservationUseStart;
          DateTime reservationUseEnd;

          // Verifico si el vestido es una renta
          if (packageRentaId == _reservation['service_id']) {
            final DateTime reservationDateTime = DateTime.parse(
                _reservation['reservation_date'] +
                    ' ' +
                    _reservation['reservation_time']);

            reservationUseStart = DateTime(
                reservationDateTime.year,
                reservationDateTime.month,
                reservationDateTime.day - 1, // Día siguiente
                00,
                00,
                00);

            reservationUseEnd = DateTime(
                reservationDateTime.year,
                reservationDateTime.month,
                reservationDateTime.day + 1, // Día siguiente
                23,
                59,
                59);
          } else {
            // Calcular la fecha de fin de la reserva existente
            final DateTime reservationDateTime = DateTime.parse(
                _reservation['reservation_date'] +
                    ' ' +
                    _reservation['reservation_time']);

            reservationUseStart = DateTime(reservationDateTime.year,
                reservationDateTime.month, reservationDateTime.day, 00, 00, 00);

            reservationUseEnd = DateTime(reservationDateTime.year,
                reservationDateTime.month, reservationDateTime.day, 23, 59, 59);
          }

          // Verificar superposición
          if (!(reservationUseStart.isBefore(cloth_reservation_startDate) ||
              reservationUseStart.isAfter(cloth_reservation_endDate))) {
            return false; // Hay superposición, no está disponible
          }
        }
      }
    }

    // Logica para verificar disponibilidad en Reservas Simples

    final snapshot = event.snapshot;
    if (snapshot.value == null) {
      return true; // No hay reservas para este vestido
    }

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;

      // Verificar si alguna reserva existente se superpone con el período deseado
      for (var reservation in data.values) {
        if (reservation is Map) {
          // Convertir fecha de reserva a DateTime
          final String reservationDateStr = startDate;
          final DateTime reservationStart = DateTime.parse(reservationDateStr);

          // Calcular la fecha de fin de la reserva existente

          // Al ser una renta de vestido, asumimos que el inicio es un día anterior
          DateTime cloth_reservation_startDate =
              reservationStart.subtract(const Duration(days: 1));

          // Al ser una renta de vestido, asumimos que el fin es un día posterior con fecha 23:59:59
          DateTime cloth_reservation_endDate =
              reservationStart.add(const Duration(days: 1));
          cloth_reservation_endDate = DateTime(
            cloth_reservation_endDate.year,
            cloth_reservation_endDate.month,
            cloth_reservation_endDate.day,
            23,
            59,
            59,
          );

          // Convertir fecha de reserva a DateTime con Fecha y Hora
          final DateTime reservationDateTime = DateTime.parse(
              reservation['reservation_date'] +
                  ' ' +
                  reservation['reservation_time']);

          // Verificar superposición
          if (!(reservationDateTime.isBefore(cloth_reservation_startDate) ||
              reservationDateTime.isAfter(cloth_reservation_endDate))) {
            return false; // Hay superposición, no está disponible
          }
        }
      }
    }

    return true; // Está disponible
  } catch (e) {
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
    return false;
  }
});

final cancelReservationProvider =
    FutureProvider.family<bool, String>((ref, reservationId) async {
  if (reservationId.trim().isEmpty) {
    return false;
  }

  try {
    await FirebaseDatabase.instance
        .ref('Admin Panel/reservations/$reservationId')
        .remove();
    return true;
  } catch (e) {
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
    //final endDateTime = startDateTime.add(Duration(days: 1));

    final DatabaseReference dbref =
        FirebaseDatabase.instance.ref('Admin Panel/reservations');
    final DatabaseEvent event =
        await dbref.orderByChild('dress_id').equalTo(dressId).once();

    // Verificacion de disponibilidad en Reservas Compuestas
    final snapshotC = await dbref.once();
    final data = snapshotC.snapshot.value;
    List<Map<String, String>> allDresses = [];
    List<Map<dynamic, dynamic>> allDressReservation = [];

    if (data is Map) {
      data.forEach((reservationId, reservationData) {
        if (reservationData is Map) {
          final dresses = reservationData['multiple_dress'];
          if (dresses is List) {
            for (var dress in dresses) {
              if (dress is Map && dress.containsKey('dress_id')) {
                // Agregar entrada para la fecha principal
                allDresses.add({
                  'dress_id': dress['dress_id'].toString(),
                  'service_id': reservationData['service_id'].toString(),
                  'reservation_date': reservationData['reservation_date'],
                  'reservation_time': reservationData['reservation_time'],
                  'session_type': reservationData['session_type']?.toString() ?? 'normal',
                });
                
                // Si es PRE-QUINCE FIESTA, agregar también entrada para la fecha de fiesta
                if (reservationData['session_type'] == 'pre-quince-fiesta') {
                  final fiestaDate = reservationData['fiesta_date']?.toString();
                  final fiestaTime = reservationData['fiesta_time']?.toString();
                  if (fiestaDate != null && fiestaDate.isNotEmpty && 
                      fiestaTime != null && fiestaTime.isNotEmpty) {
                    allDresses.add({
                      'dress_id': dress['dress_id'].toString(),
                      'service_id': reservationData['service_id'].toString(),
                      'reservation_date': fiestaDate,
                      'reservation_time': fiestaTime,
                      'session_type': 'pre-quince-fiesta',
                    });
                  }
                }
              }
            }
          }
        }
      });
    }

    if (allDresses.isNotEmpty) {
      for (var dress in allDresses) {
        if (dress is Map && dress['dress_id'] == dressId) {
          allDressReservation.add(dress);
        }
      }
    }

    if (allDressReservation.isNotEmpty) {
      for (var _reservation in allDressReservation) {
        final String reservationDateStr = _reservation['reservation_date'];
        final DateTime reservationStart = DateTime.parse(reservationDateStr);

        // Obtener la duración de esa reserva (del paquete asociado)
        final String serviceId = _reservation['service_id'];

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

          final rentas = ref
              .read(servicePackagesProvider.notifier)
              .searchPackages("Renta de Vestimenta");
          final String packageRentaId =
              rentas.firstWhere((e) => e.name == "Renta de Vestimenta").id;

          DateTime reservationUseStart;
          DateTime reservationUseEnd;

          // Verifico si el vestido es una renta
          if (packageRentaId == _reservation['service_id']) {
            reservationUseStart = DateTime(
                reservationStart.year,
                reservationStart.month,
                reservationStart.day - 1, // Día siguiente
                00,
                00,
                00);

            reservationUseEnd = DateTime(
                reservationStart.year,
                reservationStart.month,
                reservationStart.day + 1, // Día siguiente
                23,
                59,
                59);
          } else {
            // Calcular la fecha de fin de la reserva existente

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

          final DateTime reservationDateTime = DateTime.parse(
              _reservation['reservation_date'] +
                  ' ' +
                  _reservation['reservation_time']);

          // Verificar superposición
          if (!(startDateTime.isBefore(reservationUseStart) ||
              startDateTime.isAfter(reservationUseEnd))) {
            return false; // Hay superposición, no está disponible
          }
        }
      }
    }

    // Verificacion de disponibilidad en Reservas Simples
    final snapshot = event.snapshot;

    if (snapshot.value == null) return true;

    if (snapshot.value is Map) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;

      return !data.values.any((reservation) {
        if (reservation['status'] == 'cancelado') return false;
        
        // Verificar conflicto con fecha principal de la reserva
        bool conflictWithMainDate = reservation['reservation_date'] == date && 
                                   reservation['reservation_time'] == time;
        
        // Verificar conflicto con fecha de fiesta (para reservas PRE-QUINCE FIESTA)
        bool conflictWithFiestaDate = false;
        if (reservation['session_type'] == 'pre-quince-fiesta') {
          final fiestaDate = reservation['fiesta_date']?.toString();
          final fiestaTime = reservation['fiesta_time']?.toString();
          conflictWithFiestaDate = fiestaDate == date && fiestaTime == time;
        }
        
        return conflictWithMainDate || conflictWithFiestaDate;
      });
    }

    return true;
  } catch (e) {
    return true; // Fallback a disponible en caso de error
  }
});

// final crearReservaProvider =
//     FutureProvider.family<reservationCreation, Map<String, dynamic>>(
//         (ref, params) async {
//   try {
//     final newReservationRef =
//         FirebaseDatabase.instance.ref('Admin Panel/reservations').push();

//     final Map<String, dynamic> reservationData = {
//       'service_id': params['serviceId'],
//       'client_id': params['clientId'],
//       'dress_id': params['dressId'],
//       'branch_id': params['branchId'],
//       'reservation_date': params['date'],
//       'reservation_time': params['time'],
//       'created_at': ServerValue.timestamp,
//       'updated_at': ServerValue.timestamp,
//       'estado_factura': params['estado_factura'],
//       'estado': 'pendiente',
//       'nota': params['note'],
//       'place': params['place'],
//       'multiple_dress': params['multiple_dress'] ?? [],
//       'notas': params['notas'] ?? '', // Guardar notas si existen
//       'reservation_associated': params['reservation_associated'] ?? '',
//       'package_price': params['package_price'] ?? 0,
//       'seller_name': params['seller_name'],
//       'session_type': params['session_type'] ?? 'normal', // Tipo de sesión (normal, pre-quince-fiesta)
//       'fiesta_date': params['fiesta_date'] ?? '', // Fecha de la fiesta (solo para planes PRE-QUINCE FIESTA)
//       'fiesta_time': params['fiesta_time'] ?? '', // Hora de la fiesta (solo para planes PRE-QUINCE FIESTA)
//     };
//     await newReservationRef.set(reservationData);

//     final reservationId = newReservationRef.key;

//     // Refresh the reservations provider
//     final _ = ref.refresh(reservationsProvider);

//     return reservationCreation(
//       statusReservation: true,
//       reservationId: reservationId ?? '',
//     );
//   } catch (e) {
//     return reservationCreation(
//       statusReservation: false,
//       reservationId: '',
//     );
//   }
// });
final crearReservaProvider = FutureProvider.family<reservationCreation, Map<String, dynamic>>(
    (ref, params) async {
  try {
    DatabaseReference newReservationRef;
    
    // Si es una reserva adicional, actualizamos la reserva principal
    if (params['isAdditional'] == true && params['reservation_associated'].isNotEmpty) {
      newReservationRef = FirebaseDatabase.instance.ref('Admin Panel/reservations/${params['reservation_associated']}');
      
      // Obtenemos los datos actuales de la reserva
      final snapshot = await newReservationRef.get();
      final currentData = snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      // Convertimos a Map<String, dynamic> para evitar problemas de tipos
      final Map<String, dynamic> updatedData = Map<String, dynamic>.from(currentData);
      
      // Inicializamos el array de adicionales si no existe
      if (!updatedData.containsKey('aditionals')) {
        updatedData['aditionals'] = [];
      }
      
      // Creamos el objeto adicional
      final Map<String, dynamic> additionalData = {
        'service_id': params['serviceId'],
        'dress_id': params['dressId'],
        'branch_id': params['branchId'],
        'reservation_date': params['date'],
        'reservation_time': params['time'],
        'created_at': ServerValue.timestamp,
        'nota': params['note'],
        'multiple_dress': params['multiple_dress'] ?? [],
        'package_price': params['package_price'] ?? 0,
      };
      
      // Agregamos el adicional
      (updatedData['aditionals'] as List).add(additionalData);
      
      // Actualizamos la reserva principal
      await newReservationRef.update({
        'aditionals': updatedData['aditionals'],
        'updated_at': ServerValue.timestamp,
      });
      
      return reservationCreation(
        statusReservation: true,
        reservationId: params['reservation_associated'],
      );
    } 
    // Si es una reserva normal, creamos una nueva
    else {
      newReservationRef = FirebaseDatabase.instance.ref('Admin Panel/reservations').push();
      
      final Map<String, dynamic> reservationData = {
        'service_id': params['serviceId'],
        'client_id': params['clientId'],
        'dress_id': params['dressId'],
        'branch_id': params['branchId'],
        'reservation_date': params['date'],
        'reservation_time': params['time'],
        'created_at': ServerValue.timestamp,
        'updated_at': ServerValue.timestamp,
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
        'aditionals': [], // Inicializamos el array de adicionales vacío
      };
      
      await newReservationRef.set(reservationData);
      final reservationId = newReservationRef.key;
      
      // Refresh the reservations provider
      final _ = ref.refresh(reservationsProvider);
      
      return reservationCreation(
        statusReservation: true,
        reservationId: reservationId ?? '',
      );
    }
  } catch (e) {
    return reservationCreation(
      statusReservation: false,
      reservationId: '',
    );
  }
});

final actualizarReservaAssociatedProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  try {
    final String reservationId = params['reservationId'];
    final String associatedId = params['associatedId'];
    
    await FirebaseDatabase.instance
        .ref('Admin Panel/reservations/$reservationId')
        .update({
      'reservation_associated': associatedId,
      'updated_at': ServerValue.timestamp,
    });
    
    return true;
  } catch (e) {
    return false;
  }
});

final fullReservationsByDressProvider =
    StreamProvider.family<List<FullReservation>, String>((ref, dressId) {
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

    final reservations = data.entries.where((entry) {
      final value = entry.value;
      return value is Map &&
          value['multiple_dress'] is List &&
          (value['multiple_dress'] as List)
              .any((dress) => dress is Map && dress['dress_id'] == dressId);
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

final fullReservationsByDressProvider2 =
    StreamProvider.family<List<FullReservation>, String>((ref, dressId) async* {
  final today = DateTime.now();
  final formattedToday =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

  final reservationsRef = FirebaseDatabase.instance
      .ref('Admin Panel/reservations')
      .orderByChild('reservation_date')
      .startAt(formattedToday);

  final dressesRef = FirebaseDatabase.instance.ref('Admin Panel/dresses');
  final servicesRef = FirebaseDatabase.instance.ref('Admin Panel/services');

  // Escuchar cambios en las reservas
  await for (final event in reservationsRef.onValue) {
    final customers =
        await ref.watch(allCustomerProvider.future); // dentro del ciclo
    final snapshot = event.snapshot;
    if (snapshot.value == null || snapshot.value is! Map) {
      yield [];
      continue;
    }

    final data = snapshot.value as Map;

    final reservations = data.entries.where((entry) {
      final value = entry.value;
      return value is Map &&
          value['multiple_dress'] is List &&
          (value['multiple_dress'] as List)
              .any((dress) => dress is Map && dress['dress_id'] == dressId);
    }).toList();

    final dressIds = reservations
        .map((e) => e.value['dress_id']?.toString())
        .whereType<String>()
        .toSet();
    final serviceIds = reservations
        .map((e) => e.value['service_id']?.toString())
        .whereType<String>()
        .toSet();

    final dressSnap = await dressesRef.get();
    final serviceSnap = await servicesRef.get();

    final dressesMap = dressSnap.value as Map?;
    final servicesMap = serviceSnap.value as Map?;

    final fullReservations = reservations.map((entry) {
      final id = entry.key.toString();
      final data = Map<String, dynamic>.from(entry.value as Map);
      final dressId = data['dress_id']?.toString();
      final serviceId = data['service_id']?.toString();
      final clientId = data['client_id']?.toString();

      final dress =
          dressId != null && dressesMap != null ? dressesMap[dressId] : null;
      final service = serviceId != null && servicesMap != null
          ? servicesMap[serviceId]
          : null;
      final client = customers.firstWhere(
        (c) => c.phoneNumber == clientId,
        orElse: () => CustomerModel.empty(),
      );

      return FullReservation(
        id: id,
        reservation: data,
        dress: dress != null ? Map<String, dynamic>.from(dress) : null,
        service: service != null ? Map<String, dynamic>.from(service) : null,
        dressIds: dressIds.toList(),
        serviceIds: serviceIds.toList(),
        client: client.phoneNumber.isNotEmpty ? client : null,
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

    yield fullReservations;
  }
});

// final dressesByStatusProvider =
//     FutureProvider.family<List<DressModel>, Map<String, String>>(
//         (ref, params) async {
//   final search = params['search']?.trim().toLowerCase() ?? '';
//   final status = params['status'] ?? 'Todos';

//   final now = DateTime.now();
//   final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

//   // Obtener todos los vestidos
//   final snapshot =
//       await FirebaseDatabase.instance.ref('Admin Panel/dresses').get();
//   final value = snapshot.value;
//   if (value == null || value is! Map) return [];

//   List<DressModel> allDresses = [];
//   (value).forEach((key, data) {
//     if (data is Map && data.containsKey('name')) {
//       allDresses.add(DressModel.fromRealtimeDB(data, key));
//     }
//   });

//   // Filtrar por nombre
//   final filteredByName = allDresses.where((dress) {
//     final matchesSearch =
//         dress.name.toLowerCase().contains(search) || search.isEmpty;
//     return matchesSearch;
//   }).toList();

//   if (status == 'Todos') return filteredByName;

//   if (status == 'Lavanderia') {
//     return filteredByName.where((dress) => dress.available == false).toList();
//   }

//   final reservationsSnapshot =
//       await FirebaseDatabase.instance.ref('Admin Panel/reservations').get();
//   final reservationsData = reservationsSnapshot.value;

//   final reservedDressIds = <String>{};

//   if (reservationsData is Map) {
//     reservationsData.forEach((resId, resData) {
//       if (resData is Map) {
//         // Reservas simples
//         final String? dressId = resData['dress_id'];
//         final String? dateStr = resData['reservation_date'];
//         if (dressId != null && dateStr != null) {
//           final date = DateTime.tryParse(dateStr);
//           if (date != null && date.isAfter(now) && date.isBefore(endOfYear)) {
//             reservedDressIds.add(dressId);
//           }
//         }

//         // Reservas múltiples
//         final multiple = resData['multiple_dress'];
//         final String? resDateStr = resData['reservation_date'];
//         if (multiple is List && resDateStr != null) {
//           final date = DateTime.tryParse(resDateStr);
//           if (date != null && date.isAfter(now) && date.isBefore(endOfYear)) {
//             for (var item in multiple) {
//               if (item is Map && item['dress_id'] != null) {
//                 reservedDressIds.add(item['dress_id'].toString());
//               }
//             }
//           }
//         }
//       }
//     });
//   }

//   if (status == 'Reservados') {
//     return filteredByName
//         .where((dress) => reservedDressIds.contains(dress.id))
//         .toList();
//   } else if (status == 'Disponible') {
//     return filteredByName
//         .where((dress) =>
//             !reservedDressIds.contains(dress.id) && dress.available == true)
//         .toList();
//   }

//   return filteredByName;
// });
class reservationCreation {
  final String reservationId;
  final bool statusReservation;

  reservationCreation({
    required this.reservationId,
    required this.statusReservation,
  });
}
