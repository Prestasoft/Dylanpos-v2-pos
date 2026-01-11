import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';

//_______________________________Single_Tax_Model_________________
class TaxModel {
  late String name;
  late num taxRate;
  late String id;

  TaxModel({
    required this.name,
    required this.taxRate,
    required this.id,
  });

  TaxModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    taxRate = json['rate'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'rate': taxRate,
        'id': id,
      };
}

//_______________________________Group_Tax_Model_________________
class GroupTaxModel {
  late String name;
  late num taxRate;
  late String id;
  List<TaxModel>? subTaxes;

  GroupTaxModel({
    required this.name,
    required this.taxRate,
    required this.id,
    required this.subTaxes,
  });

  GroupTaxModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    taxRate = json['rate'];
    id = json['id'];
    if (json['subTax'] != null) {
      subTaxes = <TaxModel>[];
      json['subTax'].forEach((v) {
        subTaxes!.add(TaxModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'rate': taxRate,
        'id': id,
        'subTax': subTaxes?.map((e) => e.toJson()).toList(),
      };
}

//_____________________________________________Tax_provider_____________________
TaxRepo taxRepo = TaxRepo();
final taxProvider = FutureProvider.autoDispose<List<TaxModel>>((ref) => taxRepo.getAllSingleTaxList());

//_____________________________________________Group_Tax_provider_____________________

TaxRepo groupTaxRepo = TaxRepo();
final groupTaxProvider = FutureProvider.autoDispose<List<GroupTaxModel>>((ref) => groupTaxRepo.getAllGroupTaxList());

//_____________________________________________Tax_repo_____________________

class TaxRepo {
  //_________________________________________________________single_____________________
  Future<List<TaxModel>> getAllSingleTaxList() async {
    List<TaxModel> allWarehouseList = [];

    try {
      final apiService = ApiService();
      final response = await apiService.get('taxes');
      if (response.success && response.data != null) {
        final data = response.data;
        List<dynamic> taxes = [];
        if (data is Map && data['taxes'] != null) {
          taxes = data['taxes'] as List<dynamic>;
        } else if (data is List) {
          taxes = data;
        }
        for (var element in taxes) {
          var taxData = Map<String, dynamic>.from(element);
          allWarehouseList.add(TaxModel.fromJson(taxData));
        }
      }
    } catch (e) {
      debugPrint('Error getting taxes: $e');
    }
    return allWarehouseList;
  }

  //_________________________________________________________Group_Tax_____________________
  Future<List<GroupTaxModel>> getAllGroupTaxList() async {
    List<GroupTaxModel> groupTaxList = [];

    try {
      final apiService = ApiService();
      final response = await apiService.get('group-taxes');
      if (response.success && response.data != null) {
        final data = response.data;
        List<dynamic> groupTaxes = [];
        if (data is Map && data['groupTaxes'] != null) {
          groupTaxes = data['groupTaxes'] as List<dynamic>;
        } else if (data is List) {
          groupTaxes = data;
        }
        for (var element in groupTaxes) {
          var taxData = Map<String, dynamic>.from(element);
          groupTaxList.add(GroupTaxModel.fromJson(taxData));
        }
      }
    } catch (e) {
      debugPrint('Error getting group taxes: $e');
    }
    return groupTaxList;
  }
}
