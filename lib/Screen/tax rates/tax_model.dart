import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../const.dart';

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

    await FirebaseDatabase.instance.ref(await getUserID()).child('Tax List').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = TaxModel.fromJson(jsonDecode(jsonEncode(element.value)));
        allWarehouseList.add(data);
      }
    });
    return allWarehouseList;
  }

  //_________________________________________________________Group_Tax_____________________
  Future<List<GroupTaxModel>> getAllGroupTaxList() async {
    List<GroupTaxModel> groupTaxList = [];

    await FirebaseDatabase.instance.ref(await getUserID()).child('Group Tax List').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = GroupTaxModel.fromJson(jsonDecode(jsonEncode(element.value)));
        groupTaxList.add(data);
      }
    });
    return groupTaxList;
  }
}
