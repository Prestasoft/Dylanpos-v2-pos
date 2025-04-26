class InvoiceModel {
  InvoiceModel({this.phoneNumber, this.companyName, this.pictureUrl, this.emailAddress, this.address, this.description, this.website, this.isRight, this.showInvoice});

  InvoiceModel.fromJson(dynamic json) {
    phoneNumber = json['phoneNumber'] ?? '';
    companyName = json['companyName'] ?? '';
    pictureUrl = json['pictureUrl'] ?? '';
    emailAddress = json['emailAddress'] ?? '';
    address = json['address'] ?? '';
    description = json['description'] ?? '';
    website = json['website'] ?? '';
    isRight = json['isRight'] ?? '';
    showInvoice = json['showInvoice'] ?? '';
  }

  dynamic phoneNumber;
  String? companyName;
  String? pictureUrl;
  String? emailAddress;
  String? address;
  String? description;
  String? website;
  bool? showInvoice;
  bool? isRight;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['phoneNumber'] = phoneNumber;
    map['companyName'] = companyName;
    map['pictureUrl'] = pictureUrl;
    map['emailAddress'] = emailAddress;
    map['address'] = address;
    map['description'] = description;
    map['website'] = website;
    map['showInvoice'] = showInvoice;
    map['isRight'] = isRight;
    return map;
  }
}
