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
  String? saleType; // NUEVO: 'normal', 'adicionales'
  List<String> reservationIds = []; // Inicialización directa
  String? bankId; // ID del banco para transferencias
  String? bankName; // Nombre del banco para transferencias

  // Campos DGII / NCF
  String? ncfType; // Tipo de comprobante (SIN, B01, B02, B04, B14, B15)
  String? ncfNumber; // Número de comprobante fiscal
  String? ncfExpirationDate; // Fecha de vencimiento del NCF (formato: YYYY-MM-DD)
  String? customerRnc; // RNC o Cédula del cliente
  double? itbisAmount; // Monto del ITBIS (18%)
  double? subtotalBeforeTax; // Subtotal antes de impuestos

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
    this.saleType, // NUEVO: tipo de venta
    List<String>? reservationIds, // Parámetro opcional
    this.pdfUrl,
    this.bankId,
    this.bankName,
    this.ncfType,
    this.ncfNumber,
    this.ncfExpirationDate,
    this.customerRnc,
    this.itbisAmount,
    this.subtotalBeforeTax,
  }) : reservationIds = reservationIds ?? []; // Asignación segura

  factory SaleTransactionModel.fromJson(Map<dynamic, dynamic> json) {
    // Soporte para camelCase (Firebase) y snake_case (PostgreSQL)
    final customerName = json['customerName'] ?? json['customer_name'] ?? 'Cliente';
    final customerPhone = json['customerPhone'] ?? json['customer_phone'] ?? '';
    final customerAddress = json['customerAddress'] ?? json['customer_address'] ?? '';
    final invoiceNumber = json['invoiceNumber'] ?? json['invoice_number'] ?? '';
    final purchaseDate = json['purchaseDate'] ?? json['sale_date'] ?? json['purchase_date'] ?? '';
    final totalAmount = json['totalAmount'] ?? json['total_amount'] ?? json['total'] ?? 0;
    final discountAmount = json['discountAmount'] ?? json['discount_amount'] ?? json['discount'] ?? 0;
    final serviceCharge = json['serviceCharge'] ?? json['service_charge'] ?? 0;
    final dueAmount = json['dueAmount'] ?? json['due_amount'] ?? 0;
    final lossProfit = json['lossProfit'] ?? json['loss_profit'] ?? 0;
    final sellerName = json['sellerName'] ?? json['seller_name'] ?? '';
    final paymentType = json['paymentType'] ?? json['payment_method'] ?? json['payment_type'] ?? 'Unknown';
    final isPaid = json['isPaid'] ?? json['is_paid'] ?? false;

    // Para productList, puede venir como lista de strings JSON o como lista de objetos
    List<AddToCartModel>? productList;
    final rawProductList = json['productList'] ?? json['product_list'];
    if (rawProductList != null && rawProductList is List) {
      productList = rawProductList.map((v) {
        if (v is String) {
          // Si es un string JSON, usar fromJson que acepta String
          try {
            return AddToCartModel.fromJson(v);
          } catch (e) {
            // Error parsing JSON string
          }
          return AddToCartModel.fromMap({'warehouseName': '', 'warehouseId': '', 'productPurchasePrice': 0, 'productImage': '', 'taxType': '', 'margin': 0, 'excTax': 0, 'incTax': 0, 'groupTaxName': '', 'groupTaxRate': 0, 'subTaxes': []});
        } else if (v is Map) {
          // Si es un Map, usar fromMap que acepta Map
          return AddToCartModel.fromMap(Map<String, dynamic>.from(v));
        }
        return AddToCartModel.fromMap({'warehouseName': '', 'warehouseId': '', 'productPurchasePrice': 0, 'productImage': '', 'taxType': '', 'margin': 0, 'excTax': 0, 'incTax': 0, 'groupTaxName': '', 'groupTaxRate': 0, 'subTaxes': []});
      }).toList();
    }

    // Para reservationIds
    List<String>? reservationIds;
    final rawReservationIds = json['reservationIds'] ?? json['reservation_ids'];
    if (rawReservationIds != null && rawReservationIds is List) {
      reservationIds = List<String>.from(rawReservationIds.map((e) => e.toString()));
    }

    return SaleTransactionModel(
      customerName: customerName?.toString() ?? 'Cliente',
      customerPhone: customerPhone?.toString() ?? '',
      customerAddress: customerAddress?.toString() ?? '',
      customerGst: json['customerGst']?.toString() ?? json['customer_gst']?.toString() ?? '',
      customerImage: json['customerImage']?.toString() ?? json['customer_image']?.toString() ?? 'https://default-image-url.com',
      invoiceNumber: invoiceNumber.toString(),
      customerType: json['customerType']?.toString() ?? json['customer_type']?.toString() ?? 'Unknown',
      purchaseDate: purchaseDate?.toString() ?? '',
      totalAmount: double.tryParse(totalAmount?.toString() ?? '0'),
      discountAmount: double.tryParse(discountAmount?.toString() ?? '0'),
      serviceCharge: double.tryParse(serviceCharge?.toString() ?? '0'),
      vat: double.tryParse(json['vat']?.toString() ?? '0'),
      lossProfit: double.tryParse(lossProfit?.toString() ?? '0'),
      totalQuantity: json['totalQuantity'] ?? json['total_quantity'],
      sellerName: sellerName?.toString(),
      dueAmount: double.tryParse(dueAmount?.toString() ?? '0'),
      returnAmount: double.tryParse(json['returnAmount']?.toString() ?? json['return_amount']?.toString() ?? '0'),
      isPaid: isPaid is bool ? isPaid : (isPaid?.toString().toLowerCase() == 'true'),
      paymentType: paymentType?.toString() ?? 'Unknown',
      sendWhatsappMessage: json['sendWhatsappMessage'] ?? json['send_whatsapp_message'] ?? false,
      saleType: json['saleType'] ?? json['sale_type'] ?? 'normal',
      productList: productList,
      reservationIds: reservationIds,
      pdfUrl: json['pdfUrl']?.toString() ?? json['pdf_url']?.toString(),
      bankId: json['bankId']?.toString() ?? json['bank_id']?.toString(),
      bankName: json['bankName']?.toString() ?? json['bank_name']?.toString(),
      // Campos DGII / NCF
      ncfType: json['ncfType']?.toString() ?? json['ncf_type']?.toString() ?? 'SIN',
      ncfNumber: json['ncfNumber']?.toString() ?? json['ncf_number']?.toString(),
      ncfExpirationDate: json['ncfExpirationDate']?.toString() ?? json['ncf_expiration_date']?.toString(),
      customerRnc: json['customerRnc']?.toString() ?? json['customer_rnc']?.toString(),
      itbisAmount: double.tryParse(json['itbisAmount']?.toString() ?? json['itbis_amount']?.toString() ?? '0'),
      subtotalBeforeTax: double.tryParse(json['subtotalBeforeTax']?.toString() ?? json['subtotal_before_tax']?.toString() ?? '0'),
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
      'saleType': saleType ?? 'normal', // NUEVO: tipo de venta
      'productList': productList?.map((e) => e.toJson()).toList(),
      'reservationIds': reservationIds,
      'pdfUrl': pdfUrl,
      'bankId': bankId,
      'bankName': bankName,
      // Campos DGII / NCF
      'ncfType': ncfType ?? 'SIN',
      'ncfNumber': ncfNumber,
      'ncfExpirationDate': ncfExpirationDate,
      'customerRnc': customerRnc,
      'itbisAmount': itbisAmount ?? 0.0,
      'subtotalBeforeTax': subtotalBeforeTax,
    };
  }
}