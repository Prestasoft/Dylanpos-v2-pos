import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:salespro_admin/model/invoice_model.dart';

import '../const.dart';

class InvoiceSettingsRepo {
  DatabaseReference ref = FirebaseDatabase.instance.ref();

  Future<InvoiceModel> getDetails() async {
    InvoiceModel personalInfo = InvoiceModel(phoneNumber: FirebaseAuth.instance.currentUser!.phoneNumber, companyName: 'Not Defined', pictureUrl: 'https://i.imgur.com/jlyGd1j.jpg', emailAddress: 'Not Defined', address: 'Not Defined', description: 'Not Defined', website: 'Not Defined', isRight: true, showInvoice: true);
    final model = await ref.child('${await getUserID()}/Personal Information').get();
    var data = jsonDecode(jsonEncode(model.value));
    if (data == null) {
      return personalInfo;
    } else {
      return InvoiceModel.fromJson(data);
    }
  }
}
