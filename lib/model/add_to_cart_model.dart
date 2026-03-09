import 'dart:convert';
import '../Screen/tax rates/tax_model.dart';

class AddToCartModel {
  AddToCartModel({
    this.uuid,
    this.productId,
    this.productName,
    required this.warehouseName,
    required this.warehouseId,
    this.unitPrice,
    this.subTotal,
    this.quantity = 1,
    this.productDetails,
    this.itemCartIndex = -1,
    this.uniqueCheck,
    this.productBrandName,
    this.stock,
    required this.productPurchasePrice,
    this.serialNumber,
    this.productWarranty,
    required this.productImage,
    required this.taxType,
    required this.margin,
    required this.excTax,
    required this.incTax,
    required this.groupTaxName,
    required this.groupTaxRate,
    required this.subTaxes,
    this.isReservation = false,
    this.reservationId,
    this.dressId,
    this.serviceId,
    this.descricpion,
    this.isAdditional = false,
    this.mainReservationId,
    this.isDress = false,
    this.dressState,
    this.dressAvailable,
    this.dressCategory,
  });

  // Campos base del modelo
  dynamic uuid;
  dynamic productId;
  String? productName;
  String? warehouseName;
  String? warehouseId;
  dynamic unitPrice;
  dynamic subTotal;
  dynamic productPurchasePrice;
  dynamic uniqueCheck;
  num quantity = 1;
  dynamic productDetails;
  dynamic productBrandName;
  late int itemCartIndex;
  num? stock;
  late String productImage;
  List<dynamic>? serialNumber;
  String? productWarranty;
  late String taxType;
  late num margin;
  late num excTax;
  late num incTax;
  late String groupTaxName;
  late num groupTaxRate;
  late List<TaxModel> subTaxes;

  // Campos de descripción
  String? descricpion;

  // Campos de reserva
  bool isReservation;
  String? reservationId;
  String? dressId;
  String? serviceId;
  
  // Campos para adicionales
  bool isAdditional;
  String? mainReservationId;

  // Campos específicos para vestidos
  bool isDress;
  String? dressState;
  bool? dressAvailable;
  String? dressCategory;

  factory AddToCartModel.fromJson(String str) =>
      AddToCartModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AddToCartModel.fromMap(Map<String, dynamic> json) {
    // Helper para convertir a num de forma segura
    num parseNum(dynamic value, [num defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper para convertir a int de forma segura
    int parseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return AddToCartModel(
      uuid: json["uuid"]?.toString(),
      productId: json["product_id"]?.toString(),
      productName: json["product_name"]?.toString(),
      warehouseName: json["warehouseName"]?.toString() ?? '',
      warehouseId: json["warehouseId"]?.toString() ?? '',
      productBrandName: json["product_brand_name"]?.toString(),
      unitPrice: json["unit_price"],
      subTotal: json["sub_total"]?.toString(),
      uniqueCheck: json["unique_check"]?.toString(),
      quantity: parseNum(json["quantity"], 1),
      productDetails: json["product_details"],
      itemCartIndex: parseInt(json["item_cart_index"], -1),
      stock: parseNum(json["stock"]),
      productImage: json["productImage"]?.toString() ??
          'https://sistema.victorguzmanfotografia.com/assets/images/no-image-found.png',
      productPurchasePrice: parseNum(json["productPurchasePrice"]),
      serialNumber: json["serialNumber"],
      productWarranty: json['productWarranty']?.toString(),
      taxType: json['taxType']?.toString() ?? '',
      margin: parseNum(json['margin']),
      excTax: parseNum(json['excTax']),
      incTax: parseNum(json['incTax']),
      groupTaxName: json['groupTaxName']?.toString() ?? '',
      groupTaxRate: parseNum(json['groupTaxRate']),
      subTaxes: json['subTax'] != null && json['subTax'] is List
          ? List<TaxModel>.from(
              (json['subTax'] as List).map((x) => TaxModel.fromJson(x)))
          : [],
      isReservation: json["isReservation"] == true || json["isReservation"] == 'true',
      reservationId: json['reservationId']?.toString(),
      dressId: json["dressId"]?.toString(),
      serviceId: json["serviceId"]?.toString(),
      descricpion: json['descricpion']?.toString(),
      isAdditional: json['isAdditional'] == true || json['isAdditional'] == 'true',
      mainReservationId: json['mainReservationId']?.toString(),
      isDress: json['isDress'] == true || json['isDress'] == 'true',
      dressState: json['dressState']?.toString(),
      dressAvailable: json['dressAvailable'] == true || json['dressAvailable'] == 'true',
      dressCategory: json['dressCategory']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        "uuid": uuid,
        "product_id": productId,
        "product_name": productName,
        "warehouseName": warehouseName,
        "warehouseId": warehouseId,
        "unit_price": unitPrice,
        "sub_total": subTotal,
        "unique_check": uniqueCheck,
        "quantity": quantity == 0 ? null : quantity,
        "item_cart_index": itemCartIndex,
        "stock": stock,
        "productPurchasePrice": productPurchasePrice,
        "product_details": _serializeProductDetails(productDetails),
        'serialNumber': serialNumber?.map((e) => e).toList(),
        'productWarranty': productWarranty,
        'productImage': productImage,
        'taxType': taxType,
        'margin': margin,
        'excTax': excTax,
        'incTax': incTax,
        'groupTaxName': groupTaxName,
        'groupTaxRate': groupTaxRate,
        'subTax': subTaxes.map((e) => e.toJson()).toList(),
        "isReservation": isReservation,
        'reservationId': reservationId,
        "dressId": dressId,
        "serviceId": serviceId,
        "descricpion": descricpion,
        "isAdditional": isAdditional,
        "mainReservationId": mainReservationId,
        "isDress": isDress,
        "dressState": dressState,
        "dressAvailable": dressAvailable,
        "dressCategory": dressCategory,
      };

  /// Serializa productDetails de forma segura
  /// Maneja casos donde puede ser Map, String, o un objeto con toJson()
  dynamic _serializeProductDetails(dynamic details) {
    if (details == null) return null;

    // Si ya es un Map, retornarlo directamente
    if (details is Map) return details;

    // Si es un String, retornarlo directamente
    if (details is String) return details;

    // Intentar llamar toJson() si existe
    try {
      return details.toJson();
    } catch (e) {
      // Si falla, intentar convertir a String
      return details.toString();
    }
  }
}