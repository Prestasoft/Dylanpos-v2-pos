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
    //required this.nota,
    this.nota = '',
    this.place = '',
  })  : id = id ?? '',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ReservationModel.fromMap(Map<String, dynamic> map, String id) {
    return ReservationModel(
      id: id,
      serviceId: map['service_id'] ?? '',
      clientId: map['client_id'] ?? '',
      dressId: map['dress_id'] ?? '',
      branchId: map['branch_id'] ?? '',
      reservationDate: map['reservation_date'] ?? '',
      reservationTime: map['reservation_time'] ?? '',
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at']),
      estadoFactura: map['estado_factura'],
      estado: map['estado'],
      nota: map['nota'] ?? '',
      place: map['place'] ?? '',
      multipleDress: List<Map<String, String>>.from(
        (map['dress_ids'] ?? []).map((x) => {
              'dress_id': x['dress_id'] ?? '',
              'branch_id': x['branch_id'] ?? '',
            }),
      ),
      reservation_associated: map['reservation_associated'] ?? '',
      package_price: map['package_price'] ?? '',
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
    };
  }
}
