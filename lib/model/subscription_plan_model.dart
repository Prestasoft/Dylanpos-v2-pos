class SubscriptionPlanModel {
  SubscriptionPlanModel({
    required this.subscriptionName,
    required this.saleNumber,
    required this.purchaseNumber,
    required this.partiesNumber,
    required this.dueNumber,
    required this.duration,
    required this.products,
    required this.subscriptionPrice,
    required this.offerPrice,
    this.whatsappMarketingEnabled = false,
  });

  String subscriptionName;
  bool whatsappMarketingEnabled;
  int saleNumber, purchaseNumber, partiesNumber, dueNumber, duration, products;
  int subscriptionPrice, offerPrice;

  SubscriptionPlanModel.fromJson(Map<dynamic, dynamic> json)
      : subscriptionName = json['subscriptionName']?.toString() ?? '',
        saleNumber = _parseInt(json['saleNumber']),
        purchaseNumber = _parseInt(json['purchaseNumber']),
        partiesNumber = _parseInt(json['partiesNumber']),
        subscriptionPrice = _parseInt(json['subscriptionPrice']),
        dueNumber = _parseInt(json['dueNumber']),
        duration = _parseInt(json['duration']),
        products = _parseInt(json['products']),
        whatsappMarketingEnabled = json['whatsappMarketingEnabled'] == true,
        offerPrice = _parseInt(json['offerPrice']);

  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'subscriptionName': subscriptionName,
        'subscriptionPrice': subscriptionPrice,
        'saleNumber': saleNumber,
        'purchaseNumber': purchaseNumber,
        'partiesNumber': partiesNumber,
        'dueNumber': dueNumber,
        'duration': duration,
        'products': products,
        'whatsappMarketingEnabled': whatsappMarketingEnabled,
        'offerPrice': offerPrice,
      };
}
