import 'package:intl/intl.dart';

class CustomerModel {
  late String customerName, phoneNumber, type, profilePicture, emailAddress, 
              customerAddress, dueAmount, openingBalance, remainedBalance, gst;
  bool? receiveWhatsappUpdates;
  String? createdAt;  // Nuevo campo
  String? updatedAt;  // Nuevo campo

  CustomerModel({
    required this.customerName,
    required this.phoneNumber,
    required this.type,
    required this.profilePicture,
    required this.emailAddress,
    required this.customerAddress,
    required this.dueAmount,
    required this.openingBalance,
    required this.remainedBalance,
    required this.gst,
    this.receiveWhatsappUpdates,
    this.createdAt,
    this.updatedAt,
  });

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
      createdAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      updatedAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );
  }

  factory CustomerModel.fromJson(Map<dynamic, dynamic> json) {
    return CustomerModel(
      customerName: json['customerName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      type: json['type'] as String,
      profilePicture: json['profilePicture'] as String,
      emailAddress: json['emailAddress'] as String,
      customerAddress: json['customerAddress'] as String,
      dueAmount: json['due']?.toString() ?? '0',  // Manejo de null
      openingBalance: json['openingBalance']?.toString() ?? '0',
      remainedBalance: json['remainedBalance']?.toString() ?? '0',
      gst: json['gst']?.toString() ?? '',
      receiveWhatsappUpdates: json['receiveWhatsappUpdates'] ?? false,
      createdAt: json['created_at']?.toString() ?? 
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      updatedAt: json['updated_at']?.toString() ?? 
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );
  }

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
    'customerName': customerName,
    'phoneNumber': phoneNumber,
    'type': type,
    'profilePicture': profilePicture,
    'emailAddress': emailAddress,
    'customerAddress': customerAddress,
    'due': dueAmount,
    'openingBalance': openingBalance,
    'remainedBalance': remainedBalance,
    'gst': gst,
    'receiveWhatsappUpdates': receiveWhatsappUpdates,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}