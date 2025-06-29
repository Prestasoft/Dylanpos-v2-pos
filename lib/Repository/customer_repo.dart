import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';

import '../const.dart';
import '../model/customer_model.dart';
import 'package:intl/intl.dart';

class CustomerRepo {
  Future<List<CustomerModel>> getAllCustomer() async {
    try {
      final userId = await getUserID();
      final ref = FirebaseDatabase.instance.ref('$userId/Customers');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final customersMap = snapshot.value as Map<dynamic, dynamic>;
        final customersList = customersMap.entries.map((entry) {
          final data = jsonDecode(jsonEncode(entry.value)) as Map<String, dynamic>;
          return CustomerModel.fromJson(data);
        }).toList();

        customersList.sort((a, b) {
          final dateA = _parseDate(a.updatedAt ?? '1970-01-01 00:00:00');
          final dateB = _parseDate(b.updatedAt ?? '1970-01-01 00:00:00');
          return dateB.compareTo(dateA);
        });

        return customersList;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr);
    } catch (e) {
      // Si falla el parseo, devolver fecha mínima
      return DateTime(1970);
    }
  }

  Future<List<CustomerModel>> getAllBuyer() async {
    List<CustomerModel> customerList = [];

    await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = CustomerModel.fromJson(jsonDecode(jsonEncode(element.value)));
        if (data.type != "Supplier") {
          customerList.add(data);
        }
      }
    });
    return customerList;
  }

  Future<List<CustomerModel>> getAllSupplier() async {
    List<CustomerModel> supplierList = [];

    await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = CustomerModel.fromJson(jsonDecode(jsonEncode(element.value)));
        if (data.type == "Supplier") {
          supplierList.add(data);
        }
      }
    });
    return supplierList;
  }
}
