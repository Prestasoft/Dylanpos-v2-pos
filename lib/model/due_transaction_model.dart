class DueTransactionModel {
  late String customerName, customerPhone, customerAddress, customerType, invoiceNumber, purchaseDate, customerGst;
  double? totalDue;
  double? dueAmountAfterPay;
  double? payDueAmount;
  bool? isPaid;
  String? paymentType;
  String? sellerName;
  bool? sendWhatsappMessage;

  DueTransactionModel({
    required this.customerName,
    required this.customerType,
    required this.customerAddress,
    required this.customerPhone,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.customerGst,
    this.dueAmountAfterPay,
    this.totalDue,
    this.payDueAmount,
    this.isPaid,
    this.paymentType,
    this.sellerName,
    this.sendWhatsappMessage,
  });

  DueTransactionModel.fromJson(Map<dynamic, dynamic> json) {
    customerName = json['customerName'] as String;
    customerPhone = json['customerPhone'].toString();
    invoiceNumber = json['invoiceNumber'].toString();
    customerAddress = json['customerAddress'] ?? '';
    customerGst = json['customerGst'] ?? '';
    customerType = json['customerType'].toString();
    sellerName = json['sellerName'].toString();
    purchaseDate = json['purchaseDate'].toString();
    totalDue = double.parse(json['totalDue'].toString());
    dueAmountAfterPay = double.parse(json['dueAmountAfterPay'].toString());
    payDueAmount = double.parse(json['payDueAmount'].toString());
    isPaid = json['isPaid'];
    paymentType = json['paymentType'].toString();
    sendWhatsappMessage = json['sendWhatsappMessage'] ?? false;
  }

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerAddress': customerAddress,
        'customerType': customerType,
        'customerGst': customerGst,
        'invoiceNumber': invoiceNumber,
        'purchaseDate': purchaseDate,
        'sellerName': sellerName,
        'totalDue': totalDue,
        'dueAmountAfterPay': dueAmountAfterPay,
        'payDueAmount': payDueAmount,
        'isPaid': isPaid,
        'paymentType': paymentType,
        'sendWhatsappMessage': sendWhatsappMessage,
      };
}
