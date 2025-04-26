import 'package:salespro_admin/Screen/HRM/salaries%20list/model/pay_salary_model.dart';
import 'package:salespro_admin/model/purchase_transation_model.dart';
import 'package:salespro_admin/model/sale_transaction_model.dart';

import 'due_transaction_model.dart';
import 'expense_model.dart';
import 'income_modle.dart';

class DailyTransactionModel {
  late String name, date, type, id;
  late double total, paymentIn, paymentOut, remainingBalance;
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
    this.saleTransactionModel,
    this.purchaseTransactionModel,
    this.dueTransactionModel,
    this.incomeModel,
    this.expenseModel,
    this.paySalary,
  });

  DailyTransactionModel.fromJson(Map<String, dynamic> json) {
    name = json['name'].toString();
    date = json['date'].toString();
    type = json['type'].toString();
    total = double.parse(json['total'].toString());
    paymentIn = double.parse(json['paymentIn'].toString());
    paymentOut = double.parse(json['paymentOut'].toString());
    remainingBalance = double.parse(json['remainingBalance'].toString());
    id = json['id'].toString();
    if (json['saleTransactionModel'] != null) {
      saleTransactionModel = SaleTransactionModel.fromJson(json['saleTransactionModel']);
    }
    if (json['purchaseTransactionModel'] != null) {
      purchaseTransactionModel = PurchaseTransactionModel.fromJson(json['purchaseTransactionModel']);
    }
    if (json['dueTransactionModel'] != null) {
      dueTransactionModel = DueTransactionModel.fromJson(json['dueTransactionModel']);
    }
    if (json['incomeModel'] != null) {
      incomeModel = IncomeModel.fromJson(json['incomeModel']);
    }
    if (json['expenseModel'] != null) {
      expenseModel = ExpenseModel.fromJson(json['expenseModel']);
    }
    if (json['paySalaryModel'] != null) {
      paySalary = PaySalaryModel.fromJson(json['paySalaryModel']);
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
        'saleTransactionModel': saleTransactionModel?.toJson(),
        'purchaseTransactionModel': purchaseTransactionModel?.toJson(),
        'dueTransactionModel': dueTransactionModel?.toJson(),
        'incomeModel': incomeModel?.toJson(),
        'expenseModel': expenseModel?.toJson(),
        'paySalaryModel': paySalary?.toJson(),
      };
}
