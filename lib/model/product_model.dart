import 'package:salespro_admin/Screen/tax%20rates/tax_model.dart';

class ProductModel {
  late String productName, productCategory, size, color, weight, capacity, type, warranty, brandName, productCode, productStock, productUnit, productSalePrice, productPurchasePrice, productDiscount, productWholeSalePrice, productDealerPrice, productManufacturer, warehouseName, warehouseId, productPicture;
  String? expiringDate, manufacturingDate;
  late num lowerStockAlert;
  List<String> serialNumber = [];
  late String taxType;
  late num margin;
  late num excTax;
  late num incTax;
  late String groupTaxName;
  late num groupTaxRate;
  late List<TaxModel> subTaxes;

  ProductModel(
    this.productName,
    this.productCategory,
    this.size,
    this.color,
    this.weight,
    this.capacity,
    this.type,
    this.warranty,
    this.brandName,
    this.productCode,
    this.productStock,
    this.productUnit,
    this.productSalePrice,
    this.productPurchasePrice,
    this.productDiscount,
    this.productWholeSalePrice,
    this.productDealerPrice,
    this.productManufacturer,
    this.warehouseName,
    this.warehouseId,
    this.productPicture,
    this.serialNumber, {
    this.expiringDate,
    required this.lowerStockAlert,
    this.manufacturingDate,
    required this.taxType,
    required this.margin,
    required this.excTax,
    required this.incTax,
    required this.groupTaxName,
    required this.groupTaxRate,
    required this.subTaxes,
  });

  ProductModel.fromJson(Map<dynamic, dynamic> json) {
    productName = json['productName'] as String;
    productCategory = json['productCategory'].toString();
    size = json['size'].toString();
    color = json['color'].toString();
    weight = json['weight'].toString();
    capacity = json['capacity'].toString();
    type = json['type'].toString();
    warranty = json['warranty'].toString();
    brandName = json['brandName'].toString();
    productCode = json['productCode'].toString();
    productStock = json['productStock'].toString();
    productUnit = json['productUnit'].toString();
    productSalePrice = json['productSalePrice'].toString();
    productPurchasePrice = json['productPurchasePrice'].toString();
    productDiscount = json['productDiscount'].toString();
    productWholeSalePrice = json['productWholeSalePrice'].toString();
    productDealerPrice = json['productDealerPrice'].toString();
    productManufacturer = json['productManufacturer'].toString();
    warehouseName = json['warehouseName'].toString();
    warehouseId = json['warehouseId'].toString();
    productPicture = json['productPicture'].toString();
    if (json['serialNumber'] != null) {
      serialNumber = <String>[];
      json['serialNumber'].forEach((v) {
        serialNumber.add(v);
      });
    }
    expiringDate = json['expiringDate'];
    manufacturingDate = json['manufacturingDate'];
    lowerStockAlert = json['lowerStockAlert'] ?? 5;
    taxType = json['taxType'] ?? '';
    margin = json['margin'] ?? '';
    excTax = json['excTax'] ?? '';
    incTax = json['incTax'] ?? '';
    groupTaxName = json['groupTaxName'] ?? '';
    groupTaxRate = json['groupTaxRate'] ?? '';
    if (json['subTax'] != null) {
      subTaxes = <TaxModel>[];
      json['subTax'].forEach((v) {
        subTaxes.add(TaxModel.fromJson(v));
      });
    } else {
      subTaxes = [];
    }
  }

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'productName': productName,
        'productCategory': productCategory,
        'size': size,
        'color': color,
        'weight': weight,
        'capacity': capacity,
        'type': type,
        'warranty': warranty,
        'brandName': brandName,
        'productCode': productCode,
        'productStock': productStock,
        'productUnit': productUnit,
        'productSalePrice': productSalePrice,
        'productPurchasePrice': productPurchasePrice,
        'productDiscount': productDiscount,
        'productWholeSalePrice': productWholeSalePrice,
        'productDealerPrice': productDealerPrice,
        'productManufacturer': productManufacturer,
        'warehouseName': warehouseName,
        'warehouseId': warehouseId,
        'productPicture': productPicture,
        'serialNumber': serialNumber.map((e) => e).toList(),
        'manufacturingDate': manufacturingDate,
        'expiringDate': expiringDate,
        'lowerStockAlert': lowerStockAlert,
        'taxType': taxType,
        'margin': margin,
        'excTax': excTax,
        'incTax': incTax,
        'groupTaxName': groupTaxName,
        'groupTaxRate': groupTaxRate,
        'subTax': subTaxes.map((e) => e.toJson()).toList(),
      };
}
