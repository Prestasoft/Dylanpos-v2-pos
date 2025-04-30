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
  });

  // Convertir a AddToCartModel para el carrito de compras
  AddToCartModel toCartItem() {
    return AddToCartModel(
      productName: 'Reserva: $serviceName - $dressName',
      productId: id,
      quantity: 1,
      subTotal: price.toString(),
      productPurchasePrice: 0,
      warehouseName: 'Reservas',
      warehouseId: 'reserva-warehouse',
      unitPrice: price,
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


// Métodos fromMap/toMap similares a los que ya tienes
}