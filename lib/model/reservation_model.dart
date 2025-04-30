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

  ReservationModel({
    required this.id,
    required this.serviceId,
    required this.clientId,
    required this.dressId,
    required this.branchId,
    required this.reservationDate,
    required this.reservationTime,
    required this.createdAt,
    required this.updatedAt
  });

  factory ReservationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReservationModel(
      id: documentId,
      serviceId: map['service_id'] ?? '',
      clientId: map['client_id'] ?? '',
      dressId: map['dress_id'] ?? '',
      branchId: map['branch_id'] ?? '',
      reservationDate: map['reservation_date'] ?? '',
      reservationTime: map['reservation_time'] ?? '',
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at'])
    );
  }

  // Helper function to safely parse timestamps from different formats
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp == '') {
      return DateTime.now();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      // Try to parse as int first
      try {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      } catch (_) {
        // If not an int string, try to parse as datetime string
        try {
          return DateTime.parse(timestamp);
        } catch (_) {
          // Default to now if parsing fails
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
    };
  }
}