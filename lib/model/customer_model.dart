class CustomerModel {
  late String customerName, phoneNumber, type, profilePicture, emailAddress, customerAddress, dueAmount, openingBalance, remainedBalance, gst;
  bool? receiveWhatsappUpdates;

  CustomerModel({required this.customerName, required this.phoneNumber, required this.type, required this.profilePicture, required this.emailAddress, required this.customerAddress, required this.dueAmount, required this.openingBalance, required this.remainedBalance, required this.gst, this.receiveWhatsappUpdates});
  factory CustomerModel.empty() {
    return CustomerModel(
      customerName: '',
      phoneNumber: '',
      type: '',
      profilePicture: '',
      emailAddress: '',
      customerAddress: '',
      dueAmount: '',
      openingBalance: '',
      remainedBalance: '',
      gst: '',
      receiveWhatsappUpdates: false,
    );
  }

  CustomerModel.fromJson(Map<dynamic, dynamic> json)
      : customerName = json['customerName'] as String,
        phoneNumber = json['phoneNumber'] as String,
        type = json['type'] as String,
        profilePicture = json['profilePicture'] as String,
        emailAddress = json['emailAddress'] as String,
        customerAddress = json['customerAddress'] as String,
        dueAmount = json['due'] as String,
        openingBalance = json['openingBalance'] as String,
        remainedBalance = json['remainedBalance'] as String,
        gst = json['gst'] ?? '',
        receiveWhatsappUpdates = json['receiveWhatsappUpdates'] ?? false;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{'customerName': customerName, 'phoneNumber': phoneNumber, 'type': type, 'profilePicture': profilePicture, 'emailAddress': emailAddress, 'customerAddress': customerAddress, 'due': dueAmount, 'openingBalance': openingBalance, 'remainedBalance': remainedBalance, 'gst': gst, 'receiveWhatsappUpdates': receiveWhatsappUpdates};
}
