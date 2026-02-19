import 'package:intl/intl.dart';

class CustomerModel {
  String? id;  // ID del cliente en PostgreSQL (UUID)
  late String customerName, phoneNumber, type, profilePicture, emailAddress,
              customerAddress, dueAmount, openingBalance, remainedBalance, gst;
  bool? receiveWhatsappUpdates;
  String? createdAt;
  String? updatedAt;
  DateTime? birthDate;  // Fecha de nacimiento del cliente

  CustomerModel({
    this.id,
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
    this.birthDate,
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

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    // Helper para convertir fechas desde int (milliseconds), String, o null
    String parseDateTime(dynamic value) {
      if (value == null) {
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      }
      if (value is int) {
        return DateFormat('yyyy-MM-dd HH:mm:ss')
            .format(DateTime.fromMillisecondsSinceEpoch(value));
      }
      return value.toString();
    }

    // Helper para parsear fecha de nacimiento
    DateTime? parseBirthDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return CustomerModel(
      id: json['id']?.toString(),  // UUID del cliente en PostgreSQL
      customerName: json['customerName']?.toString() ?? json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone']?.toString() ?? '',
      type: json['type']?.toString() ?? json['customer_type']?.toString() ?? 'Customer',
      profilePicture: json['profilePicture']?.toString() ?? json['profile_picture']?.toString() ?? '',
      emailAddress: json['emailAddress']?.toString() ?? json['email']?.toString() ?? '',
      customerAddress: json['customerAddress']?.toString() ?? json['address']?.toString() ?? '',
      dueAmount: json['due']?.toString() ?? json['dueAmount']?.toString() ?? json['due_amount']?.toString() ?? '0',
      openingBalance: json['openingBalance']?.toString() ?? json['opening_balance']?.toString() ?? '0',
      remainedBalance: json['remainedBalance']?.toString() ?? json['remained_balance']?.toString() ?? '0',
      gst: json['gst']?.toString() ?? '',
      receiveWhatsappUpdates: json['receiveWhatsappUpdates'] ?? json['receive_whatsapp_updates'] ?? false,
      createdAt: parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDateTime(json['updated_at'] ?? json['updatedAt']),
      birthDate: parseBirthDate(json['birthDate'] ?? json['birth_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null && id!.isNotEmpty) 'id': id,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'type': type,
      'profilePicture': profilePicture,
      'emailAddress': emailAddress,
      'customerAddress': customerAddress,
      'dueAmount': dueAmount,
      'due': dueAmount, // Mantener ambos para compatibilidad
      'openingBalance': openingBalance,
      'remainedBalance': remainedBalance,
      'gst': gst,
      'receiveWhatsappUpdates': receiveWhatsappUpdates ?? false,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
    };
  }
}