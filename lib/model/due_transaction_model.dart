class DueTransactionModel {
  late String customerName, customerPhone, customerAddress, customerType, invoiceNumber, purchaseDate, customerGst;
  double? totalDue;
  double? dueAmountAfterPay;
  double? payDueAmount;
  bool? isPaid;
  String? paymentType;
  String? sellerName;
  bool? sendWhatsappMessage;
  String? bankId;
  String? bankName;

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
    this.bankId,
    this.bankName,
  });

  DueTransactionModel.fromJson(Map<dynamic, dynamic> json) {
    // Helper para convertir a double de forma segura
    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    customerName = json['customerName']?.toString() ?? '';
    customerPhone = json['customerPhone']?.toString() ?? '';
    invoiceNumber = json['invoiceNumber']?.toString() ?? '';
    customerAddress = json['customerAddress']?.toString() ?? '';
    customerGst = json['customerGst']?.toString() ?? '';
    customerType = json['customerType']?.toString() ?? '';
    sellerName = json['sellerName']?.toString() ?? '';
    purchaseDate = json['purchaseDate']?.toString() ?? '';
    totalDue = parseDouble(json['totalDue']);
    dueAmountAfterPay = parseDouble(json['dueAmountAfterPay']);
    payDueAmount = parseDouble(json['payDueAmount']);
    isPaid = json['isPaid'] == true;
    paymentType = json['paymentType']?.toString() ?? '';
    sendWhatsappMessage = json['sendWhatsappMessage'] == true;
    bankId = json['bankId']?.toString();
    bankName = json['bankName']?.toString();
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
        'bankId': bankId,
        'bankName': bankName,
      };
}
