import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../const.dart';

//_____________________________________________warehouse_model_____________________

class WareHouseModel {
  late String warehouseName;
  late String warehouseAddress;
  late String id;

  WareHouseModel({
    required this.warehouseName,
    required this.warehouseAddress,
    required this.id,
  });

  WareHouseModel.fromJson(Map<String, dynamic> json) {
    warehouseName = json['warehouseName'];
    warehouseAddress = json['address'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'warehouseName': warehouseName,
        'address': warehouseAddress,
        'id': id,
      };
}

//_____________________________________________warehouse_provider_____________________

WareHouseRepo warehouse = WareHouseRepo();
final warehouseProvider = FutureProvider.autoDispose<List<WareHouseModel>>((ref) => warehouse.getAllWarehouse());

//_____________________________________________warehouse_repo_____________________

class WareHouseRepo {
  Future<List<WareHouseModel>> getAllWarehouse() async {
    List<WareHouseModel> allWarehouseList = [];

    await FirebaseDatabase.instance.ref(await getUserID()).child('Warehouse List').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = WareHouseModel.fromJson(jsonDecode(jsonEncode(element.value)));
        allWarehouseList.add(data);
      }
    });
    return allWarehouseList;
  }
}
