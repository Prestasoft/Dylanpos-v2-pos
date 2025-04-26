import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:salespro_admin/Screen/WareHouse/warehouse_model.dart';
import 'package:salespro_admin/model/category_model.dart';

import '../const.dart';
import '../model/brands_model.dart';
import '../model/product_model.dart';
import '../model/unit_model.dart';

class ProductRepo {
  Future<List<ProductModel>> getAllProduct() async {
    List<ProductModel> productList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Products').orderByKey().get().then((value) {
      for (var element in value.children) {
        productList.add(ProductModel.fromJson(jsonDecode(jsonEncode(element.value))));
      }
    });
    return productList;
  }

  Future<List<dynamic>> getAllProductByJson({required String searchData}) async {
    List<dynamic> productList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Products').orderByKey().get().then((value) {
      for (var element in value.children) {
        if (jsonDecode(jsonEncode(element.value))['productName'].toString().toLowerCase().contains(searchData.toLowerCase())) {
          productList.add(element.value);
        }
      }
    });
    return productList;
  }

  Future<List<dynamic>> getAllProductByJsonWarehouse({required String searchData, required WareHouseModel warehouseId}) async {
    List<dynamic> productList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Products').orderByKey().get().then((value) {
      for (var element in value.children) {
        if (jsonDecode(jsonEncode(element.value))['productName'].toString().toLowerCase().contains(searchData.toLowerCase()) && ((jsonDecode(jsonEncode(element.value))['warehouseId'] == '' && warehouseId.warehouseName == 'InHouse') ? true : jsonDecode(jsonEncode(element.value))['warehouseId'].toString() == warehouseId.id)) {
          productList.add(element.value);
        }
      }
    });
    return productList;
  }

  Future<List<CategoryModel>> getAllCategory() async {
    List<CategoryModel> categoryList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Categories').orderByKey().get().then((value) {
      for (var element in value.children) {
        categoryList.add(CategoryModel.fromJson(jsonDecode(jsonEncode(element.value))));
      }
    });
    return categoryList;
  }

  Future<List<BrandsModel>> getAllBrands() async {
    List<BrandsModel> brandList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Brands').orderByKey().get().then((value) {
      for (var element in value.children) {
        brandList.add(BrandsModel.fromJson(jsonDecode(jsonEncode(element.value))));
      }
    });
    return brandList;
  }

  Future<List<UnitModel>> getAllUnits() async {
    List<UnitModel> unitList = [];
    await FirebaseDatabase.instance.ref(await getUserID()).child('Units').orderByKey().get().then((value) {
      for (var element in value.children) {
        unitList.add(UnitModel.fromJson(jsonDecode(jsonEncode(element.value))));
      }
    });
    return unitList;
  }
}
