import 'package:salespro_admin/Screen/HRM/salaries%20list/model/pay_salary_model.dart';
import 'package:salespro_admin/model/purchase_transation_model.dart';
import 'package:salespro_admin/model/sale_transaction_model.dart';

import 'due_transaction_model.dart';
import 'expense_model.dart';
import 'income_modle.dart';

class DailyTransactionModel {
  late String name, date, type, id;
  late double total, paymentIn, paymentOut, remainingBalance;

  // Campos directos para mostrar en la UI (extraídos del JSON)
  String? paymentType;      // Tipo de pago (Efectivo, Tarjeta, etc.)
  String? sellerName;       // Usuario/Vendedor que realizó la transacción
  String? invoiceNumber;    // Número de factura
  double? dueAmount;        // Monto pendiente total
  double? dueAmountAfterPay; // Monto pendiente después del pago (para Due Collection)
  String? bankId;           // ID del banco para transferencias
  String? bankName;         // Nombre del banco para transferencias

  // Modelos anidados opcionales (para compatibilidad con datos completos)
  SaleTransactionModel? saleTransactionModel;
  PurchaseTransactionModel? purchaseTransactionModel;
  DueTransactionModel? dueTransactionModel;
  IncomeModel? incomeModel;
  ExpenseModel? expenseModel;
  PaySalaryModel? paySalary;

  DailyTransactionModel({
    required this.name,
    required this.date,
    required this.type,
    required this.total,
    required this.paymentIn,
    required this.paymentOut,
    required this.remainingBalance,
    required this.id,
    this.paymentType,
    this.sellerName,
    this.invoiceNumber,
    this.dueAmount,
    this.dueAmountAfterPay,
    this.bankId,
    this.bankName,
    this.saleTransactionModel,
    this.purchaseTransactionModel,
    this.dueTransactionModel,
    this.incomeModel,
    this.expenseModel,
    this.paySalary,
  });

  DailyTransactionModel.fromJson(Map<String, dynamic> json) {
    // Campos básicos
    name = json['name']?.toString() ?? '';
    date = json['date']?.toString() ?? '';
    type = json['type']?.toString() ?? '';
    total = double.tryParse(json['total']?.toString() ?? '0') ?? 0.0;
    paymentIn = double.tryParse(json['paymentIn']?.toString() ?? json['payment_in']?.toString() ?? '0') ?? 0.0;
    paymentOut = double.tryParse(json['paymentOut']?.toString() ?? json['payment_out']?.toString() ?? '0') ?? 0.0;
    remainingBalance = double.tryParse(json['remainingBalance']?.toString() ?? json['remaining_balance']?.toString() ?? '0') ?? 0.0;
    id = json['id']?.toString() ?? '';

    // Campos directos para la UI (soporte camelCase y snake_case)
    paymentType = json['paymentType']?.toString() ?? json['payment_type']?.toString();
    sellerName = json['sellerName']?.toString() ?? json['seller_name']?.toString() ?? json['userName']?.toString() ?? json['user_name']?.toString();
    invoiceNumber = json['invoiceNumber']?.toString() ?? json['invoice_number']?.toString();
    dueAmount = double.tryParse(json['dueAmount']?.toString() ?? json['due_amount']?.toString() ?? '0');
    dueAmountAfterPay = double.tryParse(json['dueAmountAfterPay']?.toString() ?? json['due_amount_after_pay']?.toString() ?? '0');
    bankId = json['bankId']?.toString() ?? json['bank_id']?.toString();
    bankName = json['bankName']?.toString() ?? json['bank_name']?.toString();

    // Modelos anidados (para compatibilidad con datos completos - soporta camelCase y snake_case)
    // Primero buscar en el nivel superior del JSON
    var saleData = json['saleTransactionModel'] ?? json['sale_transaction_model'];

    // Si no se encuentra y el tipo es 'Deleted', buscar dentro del campo 'data'
    // porque las facturas eliminadas guardan el saleTransactionModel dentro de data
    if (saleData == null && type == 'Deleted') {
      final dataField = json['data'];
      if (dataField != null && dataField is Map) {
        saleData = dataField['saleTransactionModel'] ?? dataField['sale_transaction_model'];
      }
    }

    if (saleData != null) {
      saleTransactionModel = SaleTransactionModel.fromJson(Map<String, dynamic>.from(saleData));
    }
    final purchaseData = json['purchaseTransactionModel'] ?? json['purchase_transaction_model'];
    if (purchaseData != null) {
      purchaseTransactionModel = PurchaseTransactionModel.fromJson(Map<String, dynamic>.from(purchaseData));
    }
    final dueData = json['dueTransactionModel'] ?? json['due_transaction_model'];
    if (dueData != null) {
      dueTransactionModel = DueTransactionModel.fromJson(Map<String, dynamic>.from(dueData));
    }
    final incomeData = json['incomeModel'] ?? json['income_model'];
    if (incomeData != null) {
      incomeModel = IncomeModel.fromJson(Map<String, dynamic>.from(incomeData));
    }
    final expenseData = json['expenseModel'] ?? json['expense_model'];
    if (expenseData != null) {
      expenseModel = ExpenseModel.fromJson(Map<String, dynamic>.from(expenseData));
    }
    final salaryData = json['paySalaryModel'] ?? json['pay_salary_model'];
    if (salaryData != null) {
      paySalary = PaySalaryModel.fromJson(Map<String, dynamic>.from(salaryData));
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'date': date,
        'type': type,
        'total': total,
        'paymentIn': paymentIn,
        'paymentOut': paymentOut,
        'remainingBalance': remainingBalance,
        'id': id,
        // Campos directos para la UI
        'paymentType': paymentType,
        'sellerName': sellerName,
        'invoiceNumber': invoiceNumber,
        'dueAmount': dueAmount,
        'dueAmountAfterPay': dueAmountAfterPay,
        'bankId': bankId,
        'bankName': bankName,
        // Modelos anidados
        'saleTransactionModel': saleTransactionModel?.toJson(),
        'purchaseTransactionModel': purchaseTransactionModel?.toJson(),
        'dueTransactionModel': dueTransactionModel?.toJson(),
        'incomeModel': incomeModel?.toJson(),
        'expenseModel': expenseModel?.toJson(),
        'paySalaryModel': paySalary?.toJson(),
      };
}
