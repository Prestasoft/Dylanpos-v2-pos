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
    final result = await FirebaseDatabase.instance.ref(await getUserID()).child('Products').orderByKey().get();
    for (var element in result.children) {
      print(element.value);
      productList.add(ProductModel.fromJson(jsonDecode(jsonEncode(element.value))));
    }
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

  // Future<List<dynamic>> getAllProductByJsonWarehouse(
  //     {required String searchData, required WareHouseModel warehouseId}) async {
  //   List<dynamic> productList = [];
  //   await FirebaseDatabase.instance
  //       .ref(await getUserID())
  //       .child('Products')
  //       .orderByKey()
  //       .get()
  //       .then((value) {
  //     for (var element in value.children) {
  //       if (jsonDecode(jsonEncode(element.value))['productName']
  //               .toString()
  //               .toLowerCase()
  //               .contains(searchData.toLowerCase()) &&
  //           ((jsonDecode(jsonEncode(element.value))['warehouseId'] == '' &&
  //                   warehouseId.warehouseName == 'InHouse')
  //               ? true
  //               : jsonDecode(jsonEncode(element.value))['warehouseId']
  //                       .toString() ==
  //                   warehouseId.id)) {
  //         productList.add(element.value);
  //       }
  //     }
  //   });
  //   return productList;
  // }

  Future<List<dynamic>> getAllProductByJsonWarehouse({
    required String searchData,
    required WareHouseModel warehouseId,
  }) async {
    List<dynamic> productList = [];
    final snapshot = await FirebaseDatabase.instance.ref(await getUserID()).child('Products').orderByKey().get();

    for (var element in snapshot.children) {
      final product = jsonDecode(jsonEncode(element.value));
      final name = product['productName'].toString().toLowerCase();
      final matchesName = searchData.isEmpty || name.contains(searchData.toLowerCase());
      //final matchesWarehouse = (product['warehouseId'] == '' && warehouseId.warehouseName == 'InHouse') || product['warehouseId'].toString() == warehouseId.id;

      if (matchesName) {
        // && matchesWarehouse) {
        productList.add(product);
      }
    }

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

    try {
      final snapshot = await FirebaseDatabase.instance.ref('Admin Panel/Bank Info').orderByKey().get();

      if (snapshot.exists) {
        print('Datos encontrados: ${snapshot.children.length}');

        for (var element in snapshot.children) {
          print('Elemento: ${element.value}');

          if (element.value is Map<dynamic, dynamic>) {
            final mapValue = element.value as Map<dynamic, dynamic>;

            if (mapValue.containsKey('accountName') && mapValue.containsKey('bankName')) {
              brandList.add(BrandsModel.fromJson(mapValue));
            } else {
              print('Elemento no tiene las claves necesarias: $mapValue');
            }
          } else if (element.value == null || (element.value is Map && (element.value as Map).isEmpty) || (element.value is String && (element.value as String).isEmpty) || (element.value is List && (element.value as List).isEmpty)) {
            print('Elemento vacío o inesperado: ${element.value}');
          } else {
            print('Elemento no es un mapa válido: ${element.value}');
          }
        }
      } else {
        print('No se encontraron datos en la ruta especificada.');
      }
    } catch (e) {
      print('Error al obtener datos: $e');
    }

    return brandList;
  }

  // Future<List<BrandsModel>> getAllBrandss(s) async {
  //   List<BrandsModel> brandList = [];
  //   await FirebaseDatabase.instance.ref('Admin Panel').child('Bank Info').orderByKey().get().then((value) {
  //     for (var element in value.children) {
  //       brandList.add(BrandsModel.fromJson(jsonDecode(jsonEncode(element.value))));
  //     }
  //   });
  //   return brandList;
  // }

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
