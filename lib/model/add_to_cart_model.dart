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
    this.descricpion, // NUEVO CAMPO
  });

  // Campos del modelo
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

  // NUEVO CAMPO
  String? descricpion;

  // Campos de reserva
  bool? isReservation;
  String? reservationId;
  String? dressId;
  String? serviceId;

  factory AddToCartModel.fromJson(String str) =>
      AddToCartModel.fromMap(json.decode(str));

  // Convertir a String JSON
  String toJsonString() => json.encode(toMap());
  
  // Sobrecarga de método para SaleTransactionModel
  Map<String, dynamic> toJson() {
    // Método más seguro para serialización
    try {
      return {
        "uuid": uuid,
        "product_id": productId,
        "product_name": productName,
        "warehouseName": warehouseName,
        "warehouseId": warehouseId,
        "unit_price": unitPrice,
        "sub_total": subTotal,
        "unique_check": uniqueCheck,
        "quantity": quantity == 0 ? 0 : quantity,
        "item_cart_index": itemCartIndex,
        "stock": stock,
        "productPurchasePrice": productPurchasePrice,
        // Manejo seguro de productDetails
        "product_details": _safeSerialize(productDetails),
        'serialNumber': serialNumber?.map((e) => _safeSerialize(e)).toList(),
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
        'reservationId': reservationId != null ? reservationId!.replaceAll(RegExp(r'[.#$\[\]]'), '_') : null,
        "dressId": dressId != null ? dressId!.replaceAll(RegExp(r'[.#$\[\]]'), '_') : null,
        "serviceId": serviceId != null ? serviceId!.replaceAll(RegExp(r'[.#$\[\]]'), '_') : null,
        "descricpion": descricpion,
      };
    } catch (e) {
      print('ERROR en AddToCartModel.toJson: $e');
      // Retornar versión mínima segura
      return {
        "product_id": productId.toString(),
        "product_name": productName ?? 'Unknown',
        "warehouseName": warehouseName ?? 'Unknown',
        "warehouseId": warehouseId ?? 'Unknown',
        "unit_price": unitPrice.toString(),
        "quantity": quantity.toString(),
      };
    }
  }
  
  // Método auxiliar para serialización segura
  dynamic _safeSerialize(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is Map) return value;
      if (value is String) return value;
      if (value is num) return value;
      if (value is bool) return value;
      if (value is List) return value.map((e) => _safeSerialize(e)).toList();
      
      // Si tiene método toJson, úsalo
      if (value.toJson is Function) return value.toJson();
      
      // De lo contrario, conviértelo a String
      return value.toString();
    } catch (e) {
      return value.toString();
    }
  }

  factory AddToCartModel.fromMap(Map<String, dynamic> json) {
    try {
      return AddToCartModel(
        uuid: json["uuid"],
        productId: json["product_id"],
        productName: json["product_name"]?.toString(),
        warehouseName: json["warehouseName"]?.toString() ?? '',
        warehouseId: json["warehouseId"]?.toString() ?? '',
        productBrandName: json["product_brand_name"],
        unitPrice: json["unit_price"],
        subTotal: json["sub_total"],
        uniqueCheck: json["unique_check"],
        quantity: json["quantity"] is num ? json["quantity"] : (json["quantity"] != null ? num.tryParse(json["quantity"].toString()) ?? 1 : 1),
        productDetails: json["product_details"],
        itemCartIndex: json["item_cart_index"] is num ? json["item_cart_index"] : -1,
        stock: json["stock"] is num ? json["stock"] : (json["stock"] != null ? num.tryParse(json["stock"].toString()) : null),
        productImage: json["productImage"]?.toString() ?? 'assets/images/blank_image.svg',
        productPurchasePrice: json["productPurchasePrice"] ?? '0',
        serialNumber: json["serialNumber"] is List ? json["serialNumber"] : null,
        productWarranty: json['productWarranty']?.toString(),
        taxType: json['taxType']?.toString() ?? '',
        margin: json['margin'] is num ? json['margin'] : 0,
        excTax: json['excTax'] is num ? json['excTax'] : 0,
        incTax: json['incTax'] is num ? json['incTax'] : 0,
        groupTaxName: json['groupTaxName']?.toString() ?? '',
        groupTaxRate: json['groupTaxRate'] is num ? json['groupTaxRate'] : 0,
        subTaxes: json['subTax'] != null && json['subTax'] is List
            ? List<TaxModel>.from(
                (json['subTax'] as List).map((x) {
                  try {
                    // Si x es un Map, convertirlo a TaxModel
                    if (x is Map) {
                      final map = Map<String, dynamic>.from(x);
                      return TaxModel.fromJson(map);
                    }
                    // Si x es un String, intentar parsearlo como JSON
                    else if (x is String) {
                      try {
                        return TaxModel.fromJson(jsonDecode(x));
                      } catch (_) {
                        // Si falla, crear un TaxModel predeterminado
                        return TaxModel(name: x.toString(), taxRate: 0, id: '0');
                      }
                    }
                    // En cualquier otro caso, crear un TaxModel predeterminado
                    return TaxModel(name: 'Default', taxRate: 0, id: '0');
                  } catch (e) {
                    print('Error al convertir subTax: $e');
                    return TaxModel(name: 'Error', taxRate: 0, id: '0');
                  }
                })
              )
            : [],
        isReservation: json["isReservation"] is bool ? json["isReservation"] : null,
        reservationId: json['reservationId']?.toString(),
        dressId: json["dressId"]?.toString(),
        serviceId: json["serviceId"]?.toString(),
        descricpion: json['descricpion']?.toString(),
      );
    } catch (e) {
      print('Error creando AddToCartModel desde Map: $e');
      // Retornar un objeto mínimo viable
      return AddToCartModel(
        productId: 'error_id',
        productName: 'Error parsing product',
        unitPrice: '0',
        quantity: 1,
        warehouseName: '',
        warehouseId: '',
        productPurchasePrice: '0',
        productImage: 'assets/images/blank_image.svg',
        taxType: '',
        margin: 0,
        excTax: 0, 
        incTax: 0,
        groupTaxName: '',
        groupTaxRate: 0,
        subTaxes: [],
      );
    }
  }

  // Este método se usa para toJson
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
        "product_details": productDetails == null ? null : 
          (productDetails is Map<String, dynamic>) ? productDetails : 
          (productDetails.toJson is Function) ? productDetails.toJson() : 
          productDetails.toString(),
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
        'reservationId': reservationId != null ? reservationId!.replaceAll(RegExp(r'[.#$\[\]]'), '_') : null,
        "dressId": dressId != null ? dressId!.replaceAll(RegExp(r'[.#$\[\]]'), '_') : null,
        "serviceId": serviceId != null ? serviceId!.replaceAll(RegExp(r'[.#$\[\]]'), '_') : null,
        "descricpion": descricpion, // NUEVO CAMPO
      };
}
