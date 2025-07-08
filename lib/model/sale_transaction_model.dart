import 'add_to_cart_model.dart';

class SaleTransactionModel {
  String? pdfUrl;
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
    this.pdfUrl,
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
          ? List<AddToCartModel>.from((json['productList'] as List).map((v) {
              try {
                // Convertir a Map<String, dynamic> si es necesario
                final Map<String, dynamic> productMap = v is Map<String, dynamic> 
                    ? v 
                    : (v is Map ? Map<String, dynamic>.from(v) : {});
                
                return AddToCartModel.fromMap(productMap);
              } catch (e) {
                print('Error deserializando producto: $e');
                // Objeto mínimo viable
                return AddToCartModel(
                  productId: 'error_id',
                  productName: 'Error de deserialización',
                  unitPrice: '0',
                  quantity: 0,
                  warehouseName: '',
                  warehouseId: '',
                  productPurchasePrice: '0',
                  productImage: 'assets/images/blank_image.svg',
                  taxType: '',
                  margin: 0,
                  excTax: 0,
                  incTax: 0,
                  groupTaxName: '',
                  groupTaxRate: 0,
                  subTaxes: [],
                );
              }
            }))
          : null,
      reservationIds: json['reservationIds'] != null
          ? List<String>.from((json['reservationIds'] as List).map((v) => v?.toString() ?? ''))
          : null,
      pdfUrl: json['pdfUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'customerType': customerType,
      'customerAddress': customerAddress,
      'customerPhone': customerPhone,
      'customerGst': customerGst,
      'customerImage': customerImage,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': purchaseDate,
      'totalAmount': totalAmount,
      'dueAmount': dueAmount,
      'returnAmount': returnAmount,
      'vat': vat,
      'serviceCharge': serviceCharge,
      'discountAmount': discountAmount,
      'isPaid': isPaid,
      'paymentType': paymentType,
      'lossProfit': lossProfit,
      'totalQuantity': totalQuantity,
      'sellerName': sellerName,
      'key': key,
      'productList': productList?.map((item) => item.toJson()).toList(),
      'reservationIds': reservationIds,
      'sendWhatsappMessage': sendWhatsappMessage ?? false,
      'pdfUrl': pdfUrl,
    };
  }
}