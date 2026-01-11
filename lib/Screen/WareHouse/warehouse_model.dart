import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/services/api_service.dart';

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
    // Soportar tanto formato Firebase (warehouseName) como PostgreSQL (name)
    warehouseName = json['warehouseName']?.toString() ?? json['name']?.toString() ?? '';
    warehouseAddress = json['address']?.toString() ?? json['city']?.toString() ?? '';
    id = json['id']?.toString() ?? '';
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

    final apiService = ApiService();

    // Intentar primero con /warehouses, si falla usar /auth/branches
    var response = await apiService.get('warehouses');

    if (!response.success || response.data == null) {
      // Fallback a branches (PostgreSQL)
      response = await apiService.get('auth/branches');
    }

    if (response.success && response.data != null) {
      final data = response.data;
      List<dynamic> warehouses = [];

      if (data is Map && data['warehouses'] != null) {
        warehouses = data['warehouses'] as List<dynamic>;
      } else if (data is Map && data['branches'] != null) {
        // Formato PostgreSQL: branches
        warehouses = data['branches'] as List<dynamic>;
      } else if (data is List) {
        warehouses = data;
      }

      for (var element in warehouses) {
        var warehouseData = Map<String, dynamic>.from(element);
        allWarehouseList.add(WareHouseModel.fromJson(warehouseData));
      }
    }

    return allWarehouseList;
  }
}
