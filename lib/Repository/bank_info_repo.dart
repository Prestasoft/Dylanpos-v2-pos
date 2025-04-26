import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';

import '../model/bank_info_model.dart';

class BankInfoRepo {
  Future<BankInfoModel> getPaypalInfo() async {
    DatabaseReference bankRef = FirebaseDatabase.instance.ref('Admin Panel/Bank Info');
    final bankData = await bankRef.get();
    BankInfoModel bankInfoModel = BankInfoModel.fromJson(jsonDecode(jsonEncode(bankData.value)));

    return bankInfoModel;
  }
}
