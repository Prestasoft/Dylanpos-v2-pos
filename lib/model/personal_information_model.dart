class PersonalInformationModel {
  PersonalInformationModel({
    required this.phoneNumber,
    required this.companyName,
    required this.pictureUrl,
    required this.businessCategory,
    required this.language,
    required this.countryName,
    required this.saleInvoiceCounter,
    required this.purchaseInvoiceCounter,
    required this.dueInvoiceCounter,
    required this.shopOpeningBalance,
    required this.remainingShopBalance,
    required this.currency,
    required this.currentLocale,
    required this.gst,
  });

  PersonalInformationModel.fromJson(dynamic json) {
    // Helper para convertir a int de forma segura
    int parseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper para convertir a num de forma segura
    num parseNum(dynamic value, [num defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    phoneNumber = json['phoneNumber']?.toString() ?? '';
    companyName = json['companyName']?.toString() ?? '';
    pictureUrl = json['pictureUrl']?.toString() ?? '';
    businessCategory = json['businessCategory']?.toString() ?? '';
    language = json['language']?.toString() ?? 'en';
    countryName = json['countryName']?.toString() ?? '';
    saleInvoiceCounter = parseInt(json['saleInvoiceCounter'], 1);
    purchaseInvoiceCounter = parseInt(json['purchaseInvoiceCounter'], 1);
    dueInvoiceCounter = parseInt(json['dueInvoiceCounter'], 1);
    shopOpeningBalance = parseNum(json['shopOpeningBalance'], 0);
    remainingShopBalance = parseNum(json['remainingShopBalance'], 0);
    currency = json['currency']?.toString() ?? '\$';
    currentLocale = json['currentLocale']?.toString() ?? 'en';
    gst = json['gst']?.toString() ?? '';
  }

  late dynamic phoneNumber;
  late String companyName;
  late String pictureUrl;
  late String businessCategory;
  late String language;
  late String countryName;
  late int dueInvoiceCounter;
  late int saleInvoiceCounter;
  late int purchaseInvoiceCounter;
  late num shopOpeningBalance;
  late num remainingShopBalance;
  late String currency;
  late String currentLocale;
  late String gst;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['phoneNumber'] = phoneNumber;
    map['companyName'] = companyName;
    map['pictureUrl'] = pictureUrl;
    map['businessCategory'] = businessCategory;
    map['language'] = language;
    map['countryName'] = countryName;
    map['saleInvoiceCounter'] = saleInvoiceCounter;
    map['purchaseInvoiceCounter'] = purchaseInvoiceCounter;
    map['dueInvoiceCounter'] = dueInvoiceCounter;
    map['shopOpeningBalance'] = shopOpeningBalance;
    map['remainingShopBalance'] = remainingShopBalance;
    map['currency'] = currency;
    map['currentLocale'] = currentLocale;
    map['gst'] = gst;
    return map;
  }
}
