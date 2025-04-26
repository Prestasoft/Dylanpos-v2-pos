import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';

import '../../../../const.dart';

class EmployeeRepository {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<List<EmployeeModel>> getAllEmployees() async {
    List<EmployeeModel> employees = [];

    try {
      final userID = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref(userID).child('Employee').orderByKey().get();

      for (var element in snapshot.children) {
        var data = EmployeeModel.fromJson(jsonDecode(jsonEncode(element.value)));
        employees.add(data);
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }

    return employees;
  }

  // Method to save designation
  Future<bool> addEmployee({required EmployeeModel employee}) async {
    try {
      EasyLoading.show(status: 'Loading...', dismissOnTap: false);

      final userID = await getUserID();
      final DatabaseReference productInformationRef = _dbRef.child(userID).child('Employee').child(employee.id.toString());

      await productInformationRef.set(employee.toJson());

      EasyLoading.showSuccess('Added Successfully', duration: const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Failed to add employee: ${e.toString()}');
    }
  }

  Future<bool> updateEmployee({required EmployeeModel employee}) async {
    try {
      EasyLoading.show(status: 'Loading...', dismissOnTap: false);

      final userID = await getUserID();
      final DatabaseReference productInformationRef = _dbRef.child(userID).child('Employee').child(employee.id.toString());

      await productInformationRef.update({
        'name': employee.name,
        'phoneNumber': employee.phoneNumber,
        'email': employee.email,
        'address': employee.address,
        'gender': employee.gender,
        'employmentType': employee.employmentType,
        'designationId': employee.designationId,
        'designation': employee.designation,
        'birthDate': employee.birthDate.toIso8601String(),
        'joiningDate': employee.joiningDate.toIso8601String(),
        'salary': employee.salary,
      });

      EasyLoading.showSuccess('Updated Successfully');
      return true;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Failed to Updated employee: ${e.toString()}');
    }
  }

  Future<bool> deleteEmployee({required num id}) async {
    try {
      EasyLoading.show(status: 'Deleting...');

      final String userId = await getUserID();
      final DatabaseReference productInformationRef = _dbRef.child(userId).child('Employee').child(id.toString());

      await productInformationRef.remove();

      EasyLoading.showSuccess('Deleted Successfully');
      return true;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }
}
