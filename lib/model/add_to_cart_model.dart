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
    this.isReservation,
    this.reservationId,
    this.dressId,
    this.serviceId,
  });

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

  // Nuevos campos opcionales
  final bool? isReservation;
  final String? reservationId;
  final String? dressId;
  final String? serviceId;

  factory AddToCartModel.fromJson(String str) => AddToCartModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AddToCartModel.fromMap(Map<String, dynamic> json) => AddToCartModel(
    uuid: json["uuid"],
    productId: json["product_id"],
    productName: json["product_name"],
    warehouseName: json["warehouseName"],
    warehouseId: json["warehouseId"],
    productBrandName: json["product_brand_name"],
    unitPrice: json["unit_price"],
    subTotal: json["sub_total"],
    uniqueCheck: json["unique_check"],
    quantity: json["quantity"],
    productDetails: json["product_details"],
    itemCartIndex: json["item_cart_index"],
    stock: json["stock"],
    productImage: json["productImage"] ?? 'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Product%20No%20Image%2Fno-image-found-360x250.png?alt=media&token=9299964e-22b3-4d88-924e-5eeb285ae672',
    productPurchasePrice: json["productPurchasePrice"],
    serialNumber: json["serialNumber"],
    productWarranty: json['productWarranty'],
    taxType: json['taxType'] ?? '',
    margin: json['margin'] ?? 0,
    excTax: json['excTax'] ?? 0,
    incTax: json['incTax'] ?? 0,
    groupTaxName: json['groupTaxName'] ?? '',
    groupTaxRate: json['groupTaxRate'] ?? 0,
    subTaxes: json['subTax'] != null ? List<TaxModel>.from(json['subTax'].map((x) => TaxModel.fromJson(x))) : [],
    isReservation: json["isReservation"],  // Campo opcional
    reservationId: json["reservationId"],  // Campo opcional
    dressId: json["dressId"],  // Campo opcional
    serviceId: json["serviceId"],  // Campo opcional
  );

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
    "product_details": productDetails == null ? null : productDetails.toJson(),
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
    "isReservation": isReservation,  // Campo opcional
    "reservationId": reservationId,  // Campo opcional
    "dressId": dressId,  // Campo opcional
    "serviceId": serviceId,  // Campo opcional
  };
}
