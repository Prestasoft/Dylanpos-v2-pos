import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';

import '../const.dart';
import '../model/due_transaction_model.dart';
import '../model/purchase_transation_model.dart';
import '../model/sale_transaction_model.dart';

class TransitionRepo {
  Future<List<SaleTransactionModel>> getAllTransition() async {
    List<SaleTransactionModel> transitionList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Sales Transition').orderByKey().get().then((value) {
      for (var element in value.children) {
        SaleTransactionModel data = SaleTransactionModel.fromJson(jsonDecode(jsonEncode(element.value)));
        data.key = element.key;
        transitionList.add(data);
      }
    });
    return transitionList;
  }
}

class PurchaseTransitionRepo {
  Future<List<dynamic>> getAllTransition() async {
    List<dynamic> transitionList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Purchase Transition').orderByKey().get().then((value) {
      for (var element in value.children) {
        PurchaseTransactionModel data = PurchaseTransactionModel.fromJson(jsonDecode(jsonEncode(element.value)));
        data.key = element.key;
        transitionList.add(data);
      }
    });
    return transitionList;
  }

  Future<List<PurchaseTransactionModel>> getAllTransitionSingle() async {
    List<PurchaseTransactionModel> transitionList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Purchase Transition').orderByKey().get().then((value) {
      for (var element in value.children) {
        transitionList.add(PurchaseTransactionModel.fromJson(jsonDecode(jsonEncode(element.value))));
      }
    });
    return transitionList;
  }
}

class DueTransitionRepo {
  Future<List<DueTransactionModel>> getAllTransition() async {
    List<DueTransactionModel> transitionList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Due Transaction').orderByKey().get().then((value) {
      for (var element in value.children) {
        transitionList.add(DueTransactionModel.fromJson(jsonDecode(jsonEncode(element.value))));
      }
    });
    return transitionList;
  }
}

class QuotationRepo {
  Future<List<SaleTransactionModel>> getAllQuotation() async {
    List<SaleTransactionModel> transitionList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Sales Quotation').orderByKey().get().then((value) {
      for (var element in value.children) {
        transitionList.add(SaleTransactionModel.fromJson(jsonDecode(jsonEncode(element.value))));
      }
    });
    return transitionList;
  }
}

class QuotationHistoryRepo {
  Future<List<SaleTransactionModel>> getAllQuotationHistory() async {
    List<SaleTransactionModel> transitionList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Quotation Convert History').orderByKey().get().then((value) {
      for (var element in value.children) {
        transitionList.add(SaleTransactionModel.fromJson(jsonDecode(jsonEncode(element.value))));
      }
    });
    return transitionList;
  }
}
