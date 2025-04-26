import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';

import '../const.dart';
import '../model/sale_transaction_model.dart';

class SalesReturnRepo {
  Future<List<SaleTransactionModel>> getAllTransition() async {
    List<SaleTransactionModel> transitionList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Sales Return').orderByKey().get().then((value) {
      for (var element in value.children) {
        transitionList.add(SaleTransactionModel.fromJson(jsonDecode(jsonEncode(element.value))));
      }
    });
    return transitionList;
  }
}
