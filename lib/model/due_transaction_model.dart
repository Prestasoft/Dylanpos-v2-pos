class DueTransactionModel {
  String? id; // ID de la base de datos para operaciones CRUD
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
    this.id,
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

    id = json['id']?.toString();
    customerName = json['customerName']?.toString() ?? json['customer_name']?.toString() ?? '';
    customerPhone = json['customerPhone']?.toString() ?? json['customer_phone']?.toString() ?? '';
    invoiceNumber = json['invoiceNumber']?.toString() ?? json['invoice_number']?.toString() ?? '';
    customerAddress = json['customerAddress']?.toString() ?? json['customer_address']?.toString() ?? '';
    customerGst = json['customerGst']?.toString() ?? json['customer_gst']?.toString() ?? '';
    customerType = json['customerType']?.toString() ?? json['customer_type']?.toString() ?? '';
    sellerName = json['sellerName']?.toString() ?? json['seller_name']?.toString() ?? '';
    purchaseDate = json['purchaseDate']?.toString() ?? json['purchase_date']?.toString() ?? json['created_at']?.toString() ?? '';
    totalDue = parseDouble(json['totalDue'] ?? json['total_due']);
    dueAmountAfterPay = parseDouble(json['dueAmountAfterPay'] ?? json['due_amount_after_pay'] ?? json['remaining_due']);
    payDueAmount = parseDouble(json['payDueAmount'] ?? json['pay_due_amount'] ?? json['paid_amount']);
    isPaid = json['isPaid'] == true || json['is_paid'] == true;
    paymentType = json['paymentType']?.toString() ?? json['payment_type']?.toString() ?? '';
    sendWhatsappMessage = json['sendWhatsappMessage'] == true || json['send_whatsapp_message'] == true;
    bankId = json['bankId']?.toString() ?? json['bank_id']?.toString();
    bankName = json['bankName']?.toString() ?? json['bank_name']?.toString();
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
