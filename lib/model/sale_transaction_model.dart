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
    try {
        // Sanitizar fechas para Firebase (que no acepta '.', ' ', etc. en las rutas)
        String safePurchaseDate = purchaseDate;
        if (safePurchaseDate.contains('.') || safePurchaseDate.contains(' ')) {
          try {
            // Para uso en Firebase, necesitamos eliminar caracteres especiales
            // pero mantener el formato para otras partes del código
            DateTime parsedDate = DateTime.parse(safePurchaseDate);
            String isoDate = parsedDate.toIso8601String();
            
            // Crear una versión segura para Firebase
            safePurchaseDate = isoDate;
          } catch (e) {
            // Si falla el parsing, mantener la fecha original
            print('Error al parsear fecha en SaleTransactionModel: $e');
          }
        }

        final result = {
          'customerName': customerName,
          'customerPhone': customerPhone,
          'customerAddress': customerAddress,
          'customerGst': customerGst,
          'customerType': customerType,
          'customerImage': customerImage,
          'invoiceNumber': invoiceNumber,
          'purchaseDate': safePurchaseDate,
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
        'pdfUrl': pdfUrl,
      };
      
      // Manejo especial para productList - esto evita el error de IdentityMap
      if (productList != null) {
        try {
          // Convertir explícitamente a Lista de Mapas
          final List<Map<String, dynamic>> productListJson = productList!.map((item) {
            try {
              return item.toJson(); // Usa el método mejorado que creamos
            } catch (e) {
              print('ERROR serializando producto en transacción: $e');
              // Versión mínima segura
              return {
                "product_id": item.productId.toString(),
                "product_name": item.productName ?? 'Unknown',
                "quantity": item.quantity.toString(),
              };
            }
          }).toList();
          
          result['productList'] = productListJson;
        } catch (e) {
          print('ERROR serializando lista de productos: $e');
          result['productList'] = [];
        }
      } else {
        result['productList'] = [];
      }
      
      // Manejo seguro de reservationIds
      if (reservationIds.isNotEmpty) {
        result['reservationIds'] = reservationIds.map((id) => id.toString()).toList();
      } else {
        result['reservationIds'] = [];
      }
      
      return result;
    } catch (e) {
      print('ERROR en SaleTransactionModel.toJson: $e');
      // Retornar versión mínima segura
      return {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'invoiceNumber': invoiceNumber,
        'purchaseDate': DateTime.now().toIso8601String(),
        'productList': [],
      };
    }
  }
}