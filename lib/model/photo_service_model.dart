class PhotoServiceModel {
  String? serviceId;
  String serviceName;
  String serviceType; // 'impresion', 'revelado', 'digitalización', etc.
  double servicePrice;
  int quantity;
  String? description;
  double? discount;
  String? size; // Para tamaño de impresión: '4x6', '8x10', etc.
  
  PhotoServiceModel({
    this.serviceId,
    required this.serviceName,
    required this.serviceType,
    required this.servicePrice,
    this.quantity = 1,
    this.description,
    this.discount,
    this.size,
  });

  double get subtotal => (servicePrice * quantity) - (discount ?? 0);

  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'serviceName': serviceName,
    'serviceType': serviceType,
    'servicePrice': servicePrice,
    'quantity': quantity,
    'description': description,
    'discount': discount,
    'size': size,
  };

  factory PhotoServiceModel.fromJson(Map<String, dynamic> json) => PhotoServiceModel(
    serviceId: json['serviceId'],
    serviceName: json['serviceName'],
    serviceType: json['serviceType'],
    servicePrice: json['servicePrice']?.toDouble() ?? 0.0,
    quantity: json['quantity'] ?? 1,
    description: json['description'],
    discount: json['discount']?.toDouble(),
    size: json['size'],
  );
  
  Map<String, dynamic> toMap() => toJson();
  
  factory PhotoServiceModel.fromMap(Map<String, dynamic> map) => PhotoServiceModel.fromJson(map);
}