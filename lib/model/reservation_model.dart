import 'dart:convert';

class ReservationModel {
  final String id;
  final String serviceId;
  final String clientId;
  final String dressId;
  final String branchId;
  final String reservationDate;
  final String reservationTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool estadoFactura;
  final String? estado;
  final String? nota;
  final String? place;
  final List<Map<String, String>> multipleDress;
  final String reservation_associated;
  final String package_price;
  final String sellerName;
  final String? fiestaDate;
  final String? fiestaTime;
  final bool isFiestaDate;
  // Campos adicionales para mostrar nombres
  final String? customerName;
  final String? customerPhone;
  final String? serviceName;
  final String? vestido;
  final List<Map<String, dynamic>> dressesData;
  final int rescheduleCount;
  final String? sessionType;

  ReservationAssignments get assignments {
    if (nota == null || !nota!.contains('|||')) {
      return ReservationAssignments.empty();
    }
    try {
      final parts = nota!.split('|||');
      if (parts.length < 2) return ReservationAssignments.empty();
      final jsonStr = parts[1].trim();
      if (jsonStr.isEmpty || !jsonStr.startsWith('{')) return ReservationAssignments.empty();
      final map = jsonDecode(jsonStr);
      return ReservationAssignments.fromJson(map);
    } catch (_) {
      return ReservationAssignments.empty();
    }
  }

  String get cleanNota {
    if (nota == null) return '';
    if (!nota!.contains('|||')) return nota!;
    return nota!.split('|||')[0].trim();
  }

  ReservationModel({
    String? id,
    required this.serviceId,
    required this.clientId,
    required this.dressId,
    required this.branchId,
    required this.reservationDate,
    required this.reservationTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.multipleDress,
    required this.estadoFactura,
    this.estado = "pendiente",
    required this.reservation_associated,
    required this.package_price,
    this.nota = '',
    this.place = '',
    this.sellerName = '',
    this.fiestaDate,
    this.fiestaTime,
    this.isFiestaDate = false,
    this.customerName,
    this.customerPhone,
    this.serviceName,
    this.vestido,
    this.rescheduleCount = 0,
    this.sessionType,
    List<Map<String, dynamic>>? dressesData,
  })  : id = id ?? '',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        dressesData = dressesData ?? [];

  factory ReservationModel.fromMap(Map<String, dynamic> map, String id) {
    // Procesar dress_ids de forma segura
    List<Map<String, String>> parsedDressIds = [];
    final dressIdsRaw = map['dress_ids'];
    if (dressIdsRaw != null && dressIdsRaw is List) {
      for (final item in dressIdsRaw) {
        if (item is Map) {
          parsedDressIds.add({
            'dress_id': item['dress_id']?.toString() ?? '',
            'branch_id': item['branch_id']?.toString() ?? '',
          });
        } else if (item is String) {
          // Si es solo un string (dress_id), usarlo directamente
          parsedDressIds.add({
            'dress_id': item,
            'branch_id': '',
          });
        }
      }
    }

    // Parsear dresses_data si existe
    List<Map<String, dynamic>> parsedDressesData = [];
    final dressesDataRaw = map['dresses_data'];
    if (dressesDataRaw != null && dressesDataRaw is List) {
      for (final item in dressesDataRaw) {
        if (item is Map) {
          parsedDressesData.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return ReservationModel(
      id: id,
      serviceId: map['service_id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      dressId: map['dress_id']?.toString() ?? '',
      branchId: map['branch_id']?.toString() ?? '',
      reservationDate: map['reservation_date']?.toString() ?? '',
      reservationTime: map['reservation_time']?.toString() ?? '',
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at']),
      estadoFactura: map['estado_factura'] == true || map['estado_factura'] == 'true',
      estado: map['estado']?.toString(),
      nota: map['nota']?.toString() ?? '',
      place: map['place']?.toString() ?? '',
      multipleDress: parsedDressIds,
      reservation_associated: map['reservation_associated']?.toString() ?? '',
      package_price: map['package_price']?.toString() ?? '',
      sellerName: map['seller_name']?.toString() ?? '',
      fiestaDate: map['fiesta_date']?.toString() ?? '',
      fiestaTime: map['fiesta_time']?.toString() ?? '',
      customerName: map['customer_name']?.toString(),
      customerPhone: map['customer_phone']?.toString(),
      serviceName: map['service_name']?.toString(),
      vestido: map['vestido']?.toString(),
      dressesData: parsedDressesData,
      rescheduleCount: map['reschedule_count'] is int 
          ? map['reschedule_count'] 
          : int.tryParse(map['reschedule_count']?.toString() ?? '0') ?? 0,
      sessionType: map['session_type']?.toString(),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp == '') {
      return DateTime.now();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      } catch (_) {
        try {
          return DateTime.parse(timestamp);
        } catch (_) {
          return DateTime.now();
        }
      }
    }
    return DateTime.now();
  }

  ReservationModel copyWith({
    String? reservationDate,
    String? reservationTime,
    bool? isFiestaDate,
    String? fiestaDate,
    String? fiestaTime,
    int? rescheduleCount,
    String? sessionType,
  }) {
    return ReservationModel(
      id: id,
      serviceId: serviceId,
      clientId: clientId,
      dressId: dressId,
      branchId: branchId,
      reservationDate: reservationDate ?? this.reservationDate,
      reservationTime: reservationTime ?? this.reservationTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
      multipleDress: multipleDress,
      estadoFactura: estadoFactura,
      estado: estado,
      reservation_associated: reservation_associated,
      package_price: package_price,
      nota: nota,
      place: place,
      sellerName: sellerName,
      fiestaDate: fiestaDate ?? this.fiestaDate,
      fiestaTime: fiestaTime ?? this.fiestaTime,
      isFiestaDate: isFiestaDate ?? this.isFiestaDate,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      sessionType: sessionType ?? this.sessionType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service_id': serviceId,
      'client_id': clientId,
      'dress_id': dressId,
      'branch_id': branchId,
      'reservation_date': reservationDate,
      'reservation_time': reservationTime,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'estado_factura': estadoFactura,
      'estado': estado,
      'nota': nota,
      'place': place,
      'dress_ids': multipleDress.map((dress) {
        return {
          'dress_id': dress['dress_id'],
          'branch_id': dress['branch_id'],
        };
      }).toList(),
      'reservation_associated': reservation_associated,
      'package_price': package_price,
      'seller_name': sellerName,
      'fiesta_date': fiestaDate,
      'fiesta_time': fiestaTime,
      'reschedule_count': rescheduleCount,
    };
  }
}

class ReservationAssignments {
  final String? fotografoId;
  final String? maquillistaId;
  final String? editorId;
  final String? bookedById;
  final String? contactChannel;
  final String? socialNetwork;

  ReservationAssignments({
    this.fotografoId,
    this.maquillistaId,
    this.editorId,
    this.bookedById,
    this.contactChannel,
    this.socialNetwork,
  });

  factory ReservationAssignments.empty() {
    return ReservationAssignments();
  }

  factory ReservationAssignments.fromJson(Map<String, dynamic> json) {
    return ReservationAssignments(
      fotografoId: json['f'],
      maquillistaId: json['m'],
      editorId: json['e'],
      bookedById: json['b'],
      contactChannel: json['c'],
      socialNetwork: json['s'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fotografoId != null) 'f': fotografoId,
      if (maquillistaId != null) 'm': maquillistaId,
      if (editorId != null) 'e': editorId,
      if (bookedById != null) 'b': bookedById,
      if (contactChannel != null) 'c': contactChannel,
      if (socialNetwork != null) 's': socialNetwork,
    };
  }
}