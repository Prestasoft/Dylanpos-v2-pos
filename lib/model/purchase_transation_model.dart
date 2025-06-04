import 'package:salespro_admin/model/product_model.dart';

class PurchaseTransactionModel {
  late String customerName, customerPhone, customerAddress, customerGst, customerType, invoiceNumber, purchaseDate;
  double? totalAmount;
  double? dueAmount;
  double? returnAmount;
  double? discountAmount;

  String? key;

  bool? isPaid;
  String? paymentType;
  bool? sendWhatsappMessage;
  List<ProductModel>? productList;
  String? sellerName;

  PurchaseTransactionModel({
    required this.customerName,
    required this.customerType,
    required this.customerPhone,
    required this.customerAddress,
    required this.customerGst,
    required this.invoiceNumber,
    required this.purchaseDate,
    this.dueAmount,
    this.totalAmount,
    this.returnAmount,
    this.discountAmount,
    this.isPaid,
    this.paymentType,
    this.productList,
    this.key,
    this.sendWhatsappMessage,
    this.sellerName,
  });

  PurchaseTransactionModel.fromJson(Map<dynamic, dynamic> json) {
    customerName = json['customerName'] as String;
    customerPhone = json['customerPhone'].toString();
    invoiceNumber = json['invoiceNumber'].toString();
    customerAddress = json['customerAddress'] ?? '';
    customerGst = json['customerGst'] ?? '';
    customerType = json['customerType'].toString();
    purchaseDate = json['purchaseDate'].toString();
    totalAmount = double.parse(json['totalAmount'].toString());
    discountAmount = double.parse(json['discountAmount'].toString());
    dueAmount = double.parse(json['dueAmount'].toString());
    returnAmount = double.parse(json['returnAmount'].toString());
    isPaid = json['isPaid'];
    sendWhatsappMessage = json['sendWhatsappMessage'] ?? false;
    paymentType = json['paymentType'].toString();
    sellerName = json['sellerName'];
    if (json['productList'] != null) {
      productList = <ProductModel>[];
      json['productList'].forEach((v) {
        productList!.add(ProductModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerAddress': customerAddress,
        'customerType': customerType,
        'customerGst': customerGst,
        'invoiceNumber': invoiceNumber,
        'purchaseDate': purchaseDate,
        'discountAmount': discountAmount,
        'totalAmount': totalAmount,
        'dueAmount': dueAmount,
        'returnAmount': returnAmount,
        'isPaid': isPaid,
        'paymentType': paymentType,
        'sendWhatsappMessage': sendWhatsappMessage ?? false,
        'productList': productList?.map((e) => e.toJson()).toList(),
        'sellerName': sellerName,
      };
}
