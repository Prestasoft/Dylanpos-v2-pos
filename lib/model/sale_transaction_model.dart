import 'add_to_cart_model.dart';

class SaleTransactionModel {
  late String customerName, customerPhone, customerAddress, customerGst, customerType, customerImage, purchaseDate, invoiceNumber;
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
  });

  SaleTransactionModel.fromJson(Map<dynamic, dynamic> json) {
    customerName = json['customerName'] as String;
    customerPhone = json['customerPhone'].toString();
    customerAddress = json['customerAddress'] ?? '';
    customerGst = json['customerGst'] ?? '';
    customerImage = json['customerImage'] ?? 'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Profile%20Picture%2Fblank-profile-picture-973460_1280.webp?alt=media&token=3578c1e0-7278-4c03-8b56-dd007a9befd3';
    invoiceNumber = json['invoiceNumber'].toString();
    customerType = json['customerType'].toString();
    purchaseDate = json['purchaseDate'].toString();
    totalAmount = double.parse(json['totalAmount'].toString());
    discountAmount = double.parse(json['discountAmount'].toString());
    serviceCharge = double.parse(json['serviceCharge'].toString());
    vat = double.parse(json['vat'].toString());
    lossProfit = double.parse(json['lossProfit'].toString());
    totalQuantity = json['totalQuantity'];
    sellerName = json['sellerName'];
    dueAmount = double.parse(json['dueAmount'].toString());
    returnAmount = double.parse(json['returnAmount'].toString());
    isPaid = json['isPaid'];
    paymentType = json['paymentType'].toString();
    sendWhatsappMessage = json['sendWhatsappMessage'] ?? false;
    if (json['productList'] != null) {
      productList = <AddToCartModel>[];
      json['productList'].forEach((v) {
        productList!.add(AddToCartModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
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
      };
}
