class SellerInfoModel {
  SellerInfoModel({
    this.phoneNumber,
    this.companyName,
    this.pictureUrl,
    this.businessCategory,
    this.language,
    this.countryName,
    this.userID,
    this.subscriptionName,
    this.userRegistrationDate,
    this.subscriptionDate,
    this.subscriptionMethod,
    this.email,
    required this.gst,
  });

  SellerInfoModel.fromJson(dynamic json) {
    phoneNumber = json['phoneNumber'];
    companyName = json['companyName'];
    pictureUrl = json['pictureUrl'];
    businessCategory = json['businessCategory'];
    language = json['language'];
    countryName = json['countryName'];
    userID = json['userId'];
    userRegistrationDate = json['userRegistrationDate'];
    subscriptionName = json['subscriptionName'];
    subscriptionDate = json['subscriptionDate'];
    subscriptionMethod = json['subscriptionMethod'];
    email = json['email'];
    gst = json['gst'];
  }

  dynamic phoneNumber;
  String? companyName;
  String? pictureUrl;
  String? businessCategory;
  String? language;
  String? countryName;
  String? userID;
  String? subscriptionName;
  String? subscriptionDate;
  String? subscriptionMethod;
  String? email;
  String? userRegistrationDate;
  late String gst;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['phoneNumber'] = phoneNumber;
    map['companyName'] = companyName;
    map['pictureUrl'] = pictureUrl;
    map['businessCategory'] = businessCategory;
    map['language'] = language;
    map['countryName'] = countryName;
    map['userId'] = userID;
    map['userRegistrationDate'] = userRegistrationDate;
    map['subscriptionName'] = subscriptionName;
    map['subscriptionDate'] = subscriptionDate;
    map['subscriptionMethod'] = subscriptionMethod;
    map['email'] = email;
    map['gst'] = gst;
    return map;
  }
}
