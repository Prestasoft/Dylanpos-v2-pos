import 'add_to_cart_model.dart';

class ReservationProductModel {
  final String id;
  final String serviceId;
  final String serviceName;
  final String clientId;
  final String dressId;
  final String dressName;
  final String branchId;
  final String reservationDate;
  final String reservationTime;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> duration; // Duración del servicio
  final String descricpion;
  final double packagePrice; // Opcional, si se usa un paquete de precios
  
  ReservationProductModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.clientId,
    required this.dressId,
    required this.dressName,
    required this.branchId,
    required this.reservationDate,
    required this.reservationTime,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    required this.duration,
    required this.descricpion,
    required this.packagePrice
    });

  // Corrected fromMap factory constructor for ReservationProductModel
  factory ReservationProductModel.fromMap(Map<String, dynamic> map) {
    // Helper function to safely parse timestamps that could be in different formats
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          // Try to parse as milliseconds if it's a numeric string
          if (int.tryParse(value) != null) {
            return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
          }
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return ReservationProductModel(
      id: map['id'] ?? '',
      serviceId: map['service_id'] ?? '',
      serviceName: map['service_name'] ?? '',
      clientId: map['client_id'] ?? '',
      dressId: map['dress_id'] ?? '',
      dressName: map['dress_name'] ?? '',
      branchId: map['branch_id'] ?? '',
      reservationDate: map['reservation_date'] ?? '',
      reservationTime: map['reservation_time'] ?? '',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      createdAt: parseTimestamp(map['created_at']),
      updatedAt: parseTimestamp(map['updated_at']),
      duration: map['duration'] is Map<String, dynamic>
          ? map['duration'] as Map<String, dynamic>
          : {},
      descricpion: map['description'] ?? '',
      packagePrice: (map['package_price'] is num) ? (map['package_price'] as num).toDouble() : 0.0,
      );

  }

  // Convertir a AddToCartModel para el carrito de compras
  AddToCartModel toCartItem() {
    return AddToCartModel(
      productName: '$serviceName - $dressName',
      productId: id,
      quantity: 1,
      subTotal: packagePrice > 0 ? packagePrice.toString() : price.toString(),
      productPurchasePrice: 0,
      warehouseName: descricpion,
      warehouseId: 'reserva-warehouse',
      unitPrice: packagePrice > 0 ? packagePrice : price,
      productImage: 'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Product%20No%20Image%2Fno-image-found-360x250.png?alt=media&token=9299964e-22b3-4d88-924e-5eeb285ae672',
      taxType: 'none',
      margin: 0,
      excTax: 0,
      incTax: 0,
      groupTaxName: 'Sin impuesto',
      groupTaxRate: 0,
      subTaxes: [],
      isReservation: true,
      reservationId: id,
      dressId: dressId,
      serviceId: serviceId,

    );
  }

  // Optional: Add a toMap method for serialization if needed
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_id': serviceId,
      'service_name': serviceName,
      'client_id': clientId,
      'dress_id': dressId,
      'dress_name': dressName,
      'branch_id': branchId,
      'reservation_date': reservationDate,
      'reservation_time': reservationTime,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'duration': duration,
    };
  }
}

// class DressList
class ReservationProductCompositeModel {
  final String id;
  final String serviceId;
  final String serviceName;
  final String clientId;
  final List<DressList> dressInfo;
  final String reservationDate;
  final String reservationTime;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> duration; // Duración del servicio
  final String descricpion;
  final double packagePrice; // Opcional, si se usa un paquete de precios

  ReservationProductCompositeModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.clientId,
    required this.reservationDate,
    required this.reservationTime,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    required this.duration,
    required this.descricpion,
    required this.dressInfo,
    required this.packagePrice,
  });

  // Corrected fromMap factory constructor for ReservationProductModel
  factory ReservationProductCompositeModel.fromMap(Map<String, dynamic> map) {
    // Helper function to safely parse timestamps that could be in different formats
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          // Try to parse as milliseconds if it's a numeric string
          if (int.tryParse(value) != null) {
            return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
          }
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return ReservationProductCompositeModel(
      id: map['id'] ?? '',
      serviceId: map['service_id'] ?? '',
      serviceName: map['service_name'] ?? '',
      clientId: map['client_id'] ?? '',
      dressInfo: (map['dress_info'] as List<dynamic>?)
              ?.map((e) => DressList(
                    dressId: e['dress_id'] ?? '',
                    dressName: e['dress_name'] ?? '',
                    branchId: e['branch_id'] ?? '',
                    categoryId: e['category_id'] ?? '',
                    categoryName: e['category_name'] ?? '',
                  ))
              .toList() ??
          [],
      reservationDate: map['reservation_date'] ?? '',
      reservationTime: map['reservation_time'] ?? '',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      createdAt: parseTimestamp(map['created_at']),
      updatedAt: parseTimestamp(map['updated_at']),
      duration: map['duration'] is Map<String, dynamic>
          ? map['duration'] as Map<String, dynamic>
          : {},
      descricpion: map['description'] ?? '',
      packagePrice: (map['package_price'] is num) ? (map['package_price'] as num).toDouble() : 0.0,
      );
  }




   // Convertir a AddToCartModel para el carrito de compras
  AddToCartModel toCartCompositeItem() {
    return AddToCartModel(
      productName: '$serviceName - ${dressInfo.map((e) => e.dressName).join(', ')}',
      productId: id,
      quantity: 1,
      subTotal:  packagePrice > 0 ? packagePrice.toString() : price.toString(),
      productPurchasePrice: 0,
      warehouseName: descricpion,
      warehouseId: 'reserva-warehouse',
      unitPrice: packagePrice > 0 ? packagePrice : price,
      productImage: 'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Product%20No%20Image%2Fno-image-found-360x250.png?alt=media&token=9299964e-22b3-4d88-924e-5eeb285ae672',
      taxType: 'none',
      margin: 0,
      excTax: 0,
      incTax: 0,
      groupTaxName: 'Sin impuesto',
      groupTaxRate: 0,
      subTaxes: [],
      isReservation: true,
      reservationId: id,
      dressId: '${dressInfo.map((e) => e.dressName).join(', ')}',
      serviceId: serviceId,
    );
  }


}

class DressList {
  final String dressId;
  final String dressName;
  final String branchId;
  final String categoryId;
  final String categoryName;
  

  DressList({
    required this.dressId,
    required this.dressName,
    required this.branchId,
    required this.categoryId,
    required this.categoryName,
  });
}