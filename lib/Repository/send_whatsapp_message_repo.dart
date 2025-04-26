import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

import '../const.dart';
import '../model/whatsapp_marketing_model.dart';

class WhatsappInfoRepo {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Future<WhatsappMarketing> getWhatsappMarketingInfo() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    final model = await ref.child('Admin Panel/Whatsapp Marketing').get();
    var data = jsonDecode(jsonEncode(model.value));
    if (data == null) {
      return WhatsappMarketing(
        twillio: Twillio(
          accountSid: 'Loading...',
          authToken: 'Loading...',
        ),
        ultraMsg: UltraMsg(
          apiKey: 'Loading...',
          apiSecret: 'Loading...',
        ),
      );
    } else {
      isTwillio = data['twillio']['isActive'] ?? true;
      isUltraMsg = data['ultraMsg']['isActive'] ?? true;
      print('isTwillio: $isTwillio');
      print('isUltraMsg: $isUltraMsg');
      return WhatsappMarketing.fromJson(data);
    }
  }

  //api call with basic auth
  Future<bool> sendWhatsappMessage(String phoneNumber, String message, WhatsappMarketing model) async {
    //Basic auth
    String basicAuth = 'Basic ${base64Encode(utf8.encode('${model.twillio?.accountSid}:${model.twillio?.authToken}'))}';
    //API URL
    String url = 'https://api.twilio.com/2010-04-01/Accounts/${model.twillio?.accountSid}/Messages.json';
    //API Body
    Map<String, dynamic> body = {
      'To': 'whatsapp:$phoneNumber',
      'From': 'whatsapp:${model.twillio?.phoneNumber}',
      'Body': message,
    };

    //API Call
    final response = await http.post(Uri.parse(url), body: body, headers: <String, String>{'authorization': basicAuth});
    print('Response: ${response.body} ${response.statusCode}');
    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> sendUltraMsg(String phoneNumber, String message, WhatsappMarketing model) async {
    //String body = message.replaceAll(' ', '+');

    //API URL
    //String apiUrl = "${model.ultraMsg?.apiUrl}/messages/chat?token=${model.ultraMsg?.apiSecret}&to=$phoneNumber&body=$body&priority=10";

    var headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    var bodyData = {'token': model.ultraMsg?.apiSecret, 'to': phoneNumber, 'body': message, 'priority': '10'};
    var response = await http.post(Uri.parse('${model.ultraMsg?.apiUrl}/messages/chat'), headers: headers, body: bodyData);

    print(response.body);
    //var response = await http.get(Uri.parse(apiUrl));
    print('Response: ${response.body} ${response.statusCode}');
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
