import 'customer_model.dart';

class FullReservation {
  final String id;
  final Map<String, dynamic> reservation;
  final Map<String, dynamic>? dress;
  final Map<String, dynamic>? service;
  final CustomerModel? client;  // Cambié esto de Map<String, dynamic>? a CustomerModel?
  final List<String> dressIds;
  final List<String> serviceIds;
  final List<Map<String, String>> multipleDress;
  final String reservation_associated;
  final double package_price;

  FullReservation({
    required this.id,
    required this.reservation,
    this.dress,
    this.service,
    this.client,  // Se espera un CustomerModel
    this.dressIds = const [],
    this.serviceIds = const [],
    this.multipleDress = const [],
    this.reservation_associated = '',
    this.package_price = 0.0,
  });
}
