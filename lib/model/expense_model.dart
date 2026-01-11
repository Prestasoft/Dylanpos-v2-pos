class ExpenseModel {
  String? id;
  late String expenseDate, category, expanseFor, paymentType, account, amount, referenceNo, note;
  late String? userId, userName;
  late String? customerId, customerName, customerPhone;

  ExpenseModel({
    this.id,
    required this.expenseDate,
    required this.category,
    required this.account,
    required this.amount,
    required this.expanseFor,
    required this.paymentType,
    required this.referenceNo,
    required this.note,
    this.userId,
    this.userName,
    this.customerId,
    this.customerName,
    this.customerPhone,
  });

  ExpenseModel.fromJson(Map<dynamic, dynamic> json) {
    // Soporta tanto snake_case (PostgreSQL) como camelCase (Firebase legacy)
    id = json['id']?.toString();
    // expense_date (API) o expenseDate (legacy)
    expenseDate = (json['expense_date'] ?? json['expenseDate'] ?? '').toString();
    category = (json['category'] ?? '').toString();
    // description (API) o expanseFor (legacy)
    expanseFor = (json['description'] ?? json['expanseFor'] ?? '').toString();
    // payment_method (API) o paymentType/account (legacy)
    paymentType = (json['payment_method'] ?? json['paymentType'] ?? '').toString();
    account = (json['payment_method'] ?? json['account'] ?? '').toString();
    amount = (json['amount'] ?? '0').toString();
    // referenceNo y note pueden estar embebidos en description
    referenceNo = (json['referenceNo'] ?? json['reference_no'] ?? '').toString();
    note = (json['note'] ?? json['receipt_url'] ?? '').toString();
    userId = json['user_id']?.toString() ?? json['userId']?.toString();
    userName = json['user_name']?.toString() ?? json['userName']?.toString();
    customerId = json['customer_id']?.toString() ?? json['customerId']?.toString();
    customerName = json['customer_name']?.toString() ?? json['customerName']?.toString();
    customerPhone = json['customer_phone']?.toString() ?? json['customerPhone']?.toString();
  }

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'expense_date': expenseDate,
        'category': category,
        'description': expanseFor,
        'payment_method': paymentType.isNotEmpty ? paymentType : account,
        'amount': amount,
        'referenceNo': referenceNo,
        'note': note,
        'user_id': userId,
        'user_name': userName,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
      };
}
