import 'package:salespro_admin/Screen/HRM/salaries%20list/model/pay_salary_model.dart';
import 'package:salespro_admin/model/purchase_transation_model.dart';
import 'package:salespro_admin/model/sale_transaction_model.dart';

import 'due_transaction_model.dart';
import 'expense_model.dart';
import 'income_modle.dart';

class DailyTransactionModel {
  late String name, type, id;
  late String date; // Marcar como late
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
    name = json['name']?.toString() ?? '';
    date = json['date']?.toString() ?? '';
    type = json['type']?.toString() ?? '';
    total = double.tryParse(json['total']?.toString() ?? '0') ?? 0.0;
    paymentIn = double.tryParse(json['paymentIn']?.toString() ?? '0') ?? 0.0;
    paymentOut = double.tryParse(json['paymentOut']?.toString() ?? '0') ?? 0.0;
    remainingBalance = double.tryParse(json['remainingBalance']?.toString() ?? '0') ?? 0.0;
    id = json['id']?.toString() ?? '';
    if (json['saleTransactionModel'] != null) {
      try {
        saleTransactionModel = SaleTransactionModel.fromJson(json['saleTransactionModel']);
      } catch (e) {
        print('Error al parsear saleTransactionModel: $e');
      }
    }
    if (json['purchaseTransactionModel'] != null) {
      try {
        purchaseTransactionModel = PurchaseTransactionModel.fromJson(json['purchaseTransactionModel']);
      } catch (e) {
        print('Error al parsear purchaseTransactionModel: $e');
      }
    }
    if (json['dueTransactionModel'] != null) {
      try {
        dueTransactionModel = DueTransactionModel.fromJson(json['dueTransactionModel']);
      } catch (e) {
        print('Error al parsear dueTransactionModel: $e');
      }
    }
    if (json['incomeModel'] != null) {
      try {
        incomeModel = IncomeModel.fromJson(json['incomeModel']);
      } catch (e) {
        print('Error al parsear incomeModel: $e');
      }
    }
    if (json['expenseModel'] != null) {
      try {
        expenseModel = ExpenseModel.fromJson(json['expenseModel']);
      } catch (e) {
        print('Error al parsear expenseModel: $e');
      }
    }
    if (json['paySalaryModel'] != null) {
      try {
        paySalary = PaySalaryModel.fromJson(json['paySalaryModel']);
      } catch (e) {
        print('Error al parsear paySalaryModel: $e');
      }
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
