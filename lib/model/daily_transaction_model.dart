import 'package:salespro_admin/Screen/HRM/salaries%20list/model/pay_salary_model.dart';
import 'package:salespro_admin/model/purchase_transation_model.dart';
import 'package:salespro_admin/model/sale_transaction_model.dart';
import 'package:salespro_admin/utils/firebase_key_util.dart';

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
    required String date, // Cambiar a String para poder sanitizar
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
  }) {
    // Sanitizar la fecha en el constructor para garantizar que siempre sea segura
    this.date = _sanitizeDate(date);
  }

  DailyTransactionModel.fromJson(Map<String, dynamic> json) {
    name = json['name'].toString();
    // Sanitizar fecha al deserializar
    date = _sanitizeDate(json['date'].toString());
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
        'date': _sanitizeDate(date), // Sanitizar nuevamente al serializar
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
      
  // Método privado para sanitizar fechas
  String _sanitizeDate(String dateStr) {
    // Verificar si la fecha contiene caracteres no permitidos
    if (dateStr.contains('.') || dateStr.contains('#') || 
        dateStr.contains('\$') || dateStr.contains('[') || 
        dateStr.contains(']') || dateStr.contains(' ')) {
      
      // Intentar parsear como DateTime si tiene formato de fecha
      try {
        final DateTime parsedDate = DateTime.parse(dateStr);
        return FirebaseKeyUtil.dateToSafeKey(parsedDate);
      } catch (e) {
        // Si no se puede parsear, sanitizar manualmente
        return FirebaseKeyUtil.sanitizeKey(dateStr);
      }
    }
    
    // Si ya está sanitizada, devolverla tal cual
    return dateStr;
  }
}
