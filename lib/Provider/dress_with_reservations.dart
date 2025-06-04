// Provider mejorado
import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../model/args_dress.dart';
import '../model/dress_model.dart';

final dressesByStatusProvider = FutureProvider.family<List<DressModel>, String>(
  (ref, params) async {
    try {
      final dressesResult = await _fetchDresses();
      if (dressesResult.isEmpty) return [];

      switch (params) {
        case 'Todos':
          return dressesResult;
        case 'Lavanderia':
          return dressesResult.where((dress) => !dress.available).toList();
        default:
          final reservedIds = await _getReservedDressIds();
          return _filterByStatus(dressesResult, params, reservedIds);
      }
    } catch (e, stackTrace) {
      //print('Error in dressesByStatusProvider: $e');
      //print('StackTrace: $stackTrace');
      return <DressModel>[];
    }
  },
);

Future<List<DressModel>> _fetchDresses() async {
  try {
    final snapshot = await FirebaseDatabase.instance
        .ref('Admin Panel/dresses')
        .get()
        .timeout(const Duration(seconds: 10));

    final value = snapshot.value;
    if (value == null) return [];

    if (value is! Map) {
      //print('Warning: Expected Map but got ${value.runtimeType}');
      return [];
    }

    final List<DressModel> dresses = [];

    value.forEach((key, data) {
      try {
        if (data is Map && data.containsKey('name')) {
          dresses.add(DressModel.fromRealtimeDB(data, key));
        }
      } catch (e) {
        // print('Error parsing dress $key: $e');
      }
    });

    return dresses;
  } on TimeoutException {
    //print('Timeout fetching dresses');
    throw Exception('Timeout al cargar vestidos');
  } catch (e) {
    //print('Error fetching dresses: $e');
    rethrow;
  }
}

List<DressModel> _filterByName(List<DressModel> dresses, String search) {
  if (search.isEmpty) return dresses;

  return dresses.where((dress) {
    return dress.name.removeAllWhiteSpace().toLowerCase().contains(search);
  }).toList();
}

Future<Set<String>> _getReservedDressIds() async {
  try {
    final now = DateTime.now();
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    final reservationsSnapshot = await FirebaseDatabase.instance
        .ref('Admin Panel/reservations')
        .get()
        .timeout(const Duration(seconds: 10));

    final reservationsData = reservationsSnapshot.value;
    final reservedDressIds = <String>{};

    if (reservationsData is! Map) return reservedDressIds;

    reservationsData.forEach((resId, resData) {
      try {
        if (resData is! Map) return;

        _processSimpleReservation(resData, now, endOfYear, reservedDressIds);

        _processMultipleReservations(resData, now, endOfYear, reservedDressIds);
      } catch (e) {
        //print('Error processing reservation $resId: $e');
      }
    });

    return reservedDressIds;
  } catch (e) {
    //print('Error fetching reservations: $e');
    return <String>{};
  }
}

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

void _processMultipleReservations(
    Map resData, DateTime now, DateTime endOfYear, Set<String> reservedIds) {
  final multiple = resData['multiple_dress'];
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
      return dresses;
  }
}
