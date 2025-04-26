class WhatsappMarketing {
  Twillio? twillio;
  UltraMsg? ultraMsg;

  WhatsappMarketing({this.twillio, this.ultraMsg});

  WhatsappMarketing.fromJson(dynamic json) {
    twillio = json['twillio'] != null ? Twillio.fromJson(json['twillio']) : null;
    ultraMsg = json['ultraMsg'] != null ? UltraMsg.fromJson(json['ultraMsg']) : null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (twillio != null) {
      map['twillio'] = twillio?.toJson();
    }
    if (ultraMsg != null) {
      map['ultraMsg'] = ultraMsg?.toJson();
    }
    return map;
  }
}

class Twillio {
  String? phoneNumber;
  String? apiUrl;
  String? accountSid;
  String? authToken;
  bool? isActive;

  Twillio({this.phoneNumber, this.apiUrl, this.accountSid, this.authToken, this.isActive});

  Twillio.fromJson(dynamic json) {
    phoneNumber = json['phoneNumber'];
    apiUrl = json['apiUrl'];
    accountSid = json['accountSid'];
    authToken = json['authToken'];
    isActive = json['isActive'];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['phoneNumber'] = phoneNumber;
    map['apiUrl'] = apiUrl;
    map['accountSid'] = accountSid;
    map['authToken'] = authToken;
    map['isActive'] = isActive;
    return map;
  }
}

class UltraMsg {
  String? phoneNumber;
  String? apiUrl;
  String? apiKey;
  String? apiSecret;
  bool? isActive;

  UltraMsg({this.phoneNumber, this.apiUrl, this.apiKey, this.apiSecret, this.isActive});

  UltraMsg.fromJson(dynamic json) {
    phoneNumber = json['phoneNumber'];
    apiUrl = json['apiUrl'];
    apiKey = json['apiKey'];
    apiSecret = json['apiSecret'];
    isActive = json['isActive'];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['phoneNumber'] = phoneNumber;
    map['apiUrl'] = apiUrl;
    map['apiKey'] = apiKey;
    map['apiSecret'] = apiSecret;
    map['isActive'] = isActive;
    return map;
  }
}
