// sale_confirmation_model.dart
import 'sale_transaction_model.dart';

class SaleConfirmationModel {
  final String token;
  final String saleId;
  final String userId;
  final bool confirmed;
  final String? confirmationDate;
  final String createdAt;
  final String expiresAt;
  final SaleTransactionModel saleData;
  final bool notified;

  SaleConfirmationModel({
    required this.token,
    required this.saleId,
    required this.userId,
    required this.confirmed,
    required this.createdAt,
    required this.expiresAt,
    required this.saleData,
    this.confirmationDate,
    this.notified = false,
  });

  factory SaleConfirmationModel.fromJson(Map<dynamic, dynamic> json) {
    return SaleConfirmationModel(
      token: json['token'],
      saleId: json['saleId'],
      userId: json['userId'],
      confirmed: json['confirmed'] ?? false,
      confirmationDate: json['confirmationDate'],
      createdAt: json['createdAt'],
      expiresAt: json['expiresAt'],
      saleData: SaleTransactionModel.fromJson(json['saleData']),
      notified: json['notified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'saleId': saleId,
      'userId': userId,
      'confirmed': confirmed,
      'confirmationDate': confirmationDate,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'saleData': saleData.toJson(),
      'notified': notified,
    };
  }

  // Añade este método para permitir copiar con modificaciones
  SaleConfirmationModel copyWith({
    String? token,
    String? saleId,
    String? userId,
    bool? confirmed,
    String? confirmationDate,
    String? createdAt,
    String? expiresAt,
    SaleTransactionModel? saleData,
    bool? notified,
  }) {
    return SaleConfirmationModel(
      token: token ?? this.token,
      saleId: saleId ?? this.saleId,
      userId: userId ?? this.userId,
      confirmed: confirmed ?? this.confirmed,
      confirmationDate: confirmationDate ?? this.confirmationDate,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      saleData: saleData ?? this.saleData,
      notified: notified ?? this.notified,
    );
  }
}