import 'add_to_cart_model.dart';

class SaleTransactionModel {
  late String customerName, customerPhone, customerAddress, customerGst,
      customerType, customerImage, purchaseDate, invoiceNumber;
  double? totalAmount;
  double? dueAmount;
  double? returnAmount;
  double? serviceCharge;
  double? vat;
  double? discountAmount;
  double? lossProfit;
  num? totalQuantity;
  bool? isPaid;
  String? paymentType;
  List<AddToCartModel>? productList;
  String? sellerName;
  String? key;
  bool? sendWhatsappMessage;
  List<String> reservationIds = []; // Inicialización directa

  SaleTransactionModel({
    required this.customerName,
    required this.customerType,
    required this.customerPhone,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.customerAddress,
    required this.customerImage,
    required this.customerGst,
    this.dueAmount,
    this.totalAmount,
    this.returnAmount,
    this.vat,
    this.serviceCharge,
    this.discountAmount,
    this.isPaid,
    this.paymentType,
    this.productList,
    this.lossProfit,
    this.totalQuantity,
    this.sellerName,
    this.key,
    this.sendWhatsappMessage,
    List<String>? reservationIds, // Parámetro opcional
  }) : reservationIds = reservationIds ?? []; // Asignación segura

  factory SaleTransactionModel.fromJson(Map<dynamic, dynamic> json) {
    return SaleTransactionModel(
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone']?.toString() ?? '',
      customerAddress: json['customerAddress'] ?? '',
      customerGst: json['customerGst'] ?? '',
      customerImage: json['customerImage'] ?? 'https://default-image-url.com',
      invoiceNumber: json['invoiceNumber'].toString(),
      customerType: json['customerType']?.toString() ?? 'Unknown',
      purchaseDate: json['purchaseDate']?.toString() ?? '',
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0'),
      discountAmount: double.tryParse(json['discountAmount']?.toString() ?? '0'),
      serviceCharge: double.tryParse(json['serviceCharge']?.toString() ?? '0'),
      vat: double.tryParse(json['vat']?.toString() ?? '0'),
      lossProfit: double.tryParse(json['lossProfit']?.toString() ?? '0'),
      totalQuantity: json['totalQuantity'],
      sellerName: json['sellerName'],
      dueAmount: double.tryParse(json['dueAmount']?.toString() ?? '0'),
      returnAmount: double.tryParse(json['returnAmount']?.toString() ?? '0'),
      isPaid: json['isPaid'],
      paymentType: json['paymentType']?.toString() ?? 'Unknown',
      sendWhatsappMessage: json['sendWhatsappMessage'] ?? false,
      productList: json['productList'] != null
          ? (json['productList'] as List).map((v) => AddToCartModel.fromJson(v)).toList()
          : null,
      reservationIds: json['reservationIds'] != null
          ? List<String>.from(json['reservationIds'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerGst': customerGst,
      'customerType': customerType,
      'customerImage': customerImage,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': purchaseDate,
      'discountAmount': discountAmount,
      'vat': vat,
      'serviceCharge': serviceCharge,
      'totalAmount': totalAmount,
      'dueAmount': dueAmount,
      'sellerName': sellerName,
      'returnAmount': returnAmount,
      'lossProfit': lossProfit,
      'totalQuantity': totalQuantity,
      'isPaid': isPaid,
      'paymentType': paymentType,
      'sendWhatsappMessage': sendWhatsappMessage ?? false,
      'productList': productList?.map((e) => e.toJson()).toList(),
      'reservationIds': reservationIds,
    };
  }
}