import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salespro_admin/model/customer_model.dart';
import 'package:salespro_admin/model/frame_product_model.dart';
import 'package:salespro_admin/model/photo_service_model.dart';

class PhotoInvoiceModel {
  String? invoiceId;
  String invoiceNumber;
  DateTime invoiceDate;
  CustomerModel customer;
  List<FrameProductModel> products;
  List<PhotoServiceModel> services;
  double discountAmount;
  double taxRate;
  double taxAmount;
  String? notes;
  String paymentMethod;
  String? selectedBank;
  String paymentStatus;
  double paidAmount;
  double dueAmount;
  String? pdfUrl;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  PhotoInvoiceModel({
    this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customer,
    this.products = const [],
    this.services = const [],
    this.discountAmount = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.notes,
    this.paymentMethod = 'Cash',
    this.selectedBank,
    this.paymentStatus = 'Paid',
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.pdfUrl,
    this.createdAt,
    this.updatedAt,
  });

  double get productSubtotal => products.fold(0, (sum, item) => sum + item.subtotal);
  
  double get serviceSubtotal => services.fold(0, (sum, item) => sum + item.subtotal);
  
  double get subtotal => productSubtotal + serviceSubtotal;
  
  double get totalAmount => subtotal - discountAmount + taxAmount;
  
  bool get isPaid => dueAmount == 0;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'customer': customer.toJson(),
      'products': products.map((p) => p.toJson()).toList(),
      'services': services.map((s) => s.toJson()).toList(),
      'productSubtotal': productSubtotal,
      'serviceSubtotal': serviceSubtotal,
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'dueAmount': dueAmount,
      'isPaid': isPaid,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
    
    // Solo agregar campos opcionales si tienen valor
    if (notes != null && notes!.isNotEmpty) {
      json['notes'] = notes;
    }
    if (selectedBank != null && selectedBank!.isNotEmpty) {
      json['selectedBank'] = selectedBank;
    }
    if (pdfUrl != null && pdfUrl!.isNotEmpty) {
      json['pdfUrl'] = pdfUrl;
    }
    
    return json;
  }
  
  Map<String, dynamic> toMap() => toJson();
  
  factory PhotoInvoiceModel.fromMap(Map<String, dynamic> map) => PhotoInvoiceModel.fromJson(map);

  factory PhotoInvoiceModel.fromJson(Map<String, dynamic> json) {
    // Función helper para convertir fechas desde Firebase Timestamp, int (milisegundos), o String
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;

      // Si es un int (milisegundos desde epoch - formato de la API PostgreSQL)
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }

      if (value is String) {
        return DateTime.tryParse(value);
      }

      if (value is Timestamp) {
        return value.toDate();
      }

      // Si es un mapa con seconds y nanoseconds (Timestamp serializado)
      if (value is Map && value.containsKey('seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          value['seconds'] * 1000 + (value['nanoseconds'] ?? 0) ~/ 1000000,
        );
      }
      return null;
    }
    
    return PhotoInvoiceModel(
      invoiceId: json['invoiceId'],
      invoiceNumber: json['invoiceNumber'],
      invoiceDate: parseDateTime(json['invoiceDate']) ?? DateTime.now(),
      customer: CustomerModel.fromJson(Map<String, dynamic>.from(json['customer'] ?? {})),
      products: (json['products'] as List?)?.map((p) => FrameProductModel.fromJson(Map<String, dynamic>.from(p))).toList() ?? [],
      services: (json['services'] as List?)?.map((s) => PhotoServiceModel.fromJson(Map<String, dynamic>.from(s))).toList() ?? [],
      discountAmount: json['discountAmount']?.toDouble() ?? 0,
      taxRate: json['taxRate']?.toDouble() ?? 0,
      taxAmount: json['taxAmount']?.toDouble() ?? 0,
      notes: json['notes'],
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      selectedBank: json['selectedBank'],
      paymentStatus: json['paymentStatus'] ?? 'Paid',
      paidAmount: json['paidAmount']?.toDouble() ?? 0,
      dueAmount: json['dueAmount']?.toDouble() ?? 0,
      pdfUrl: json['pdfUrl'],
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }
}