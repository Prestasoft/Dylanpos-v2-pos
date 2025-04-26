import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../../const.dart';
import '../model/designation_model.dart';

class DesignationRepository {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<List<DesignationModel>> getAllDesignation() async {
    List<DesignationModel> designations = [];

    try {
      final userID = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref(userID).child('Designation').orderByKey().get();

      for (var element in snapshot.children) {
        var data = DesignationModel.fromJson(jsonDecode(jsonEncode(element.value)));
        designations.add(data);
      }
    } catch (e) {
      print('Error fetching expense categories: $e');
    }

    print(designations);

    return designations;
  }

  // Method to save designation
  Future<bool> addDesignation({required DesignationModel designation}) async {
    try {
      EasyLoading.show(status: 'Loading...', dismissOnTap: false);

      final userID = await getUserID();
      final DatabaseReference productInformationRef = _dbRef.child(userID).child('Designation').child(designation.id.toString());

      await productInformationRef.set(designation.toJson());

      EasyLoading.showSuccess('Added Successfully', duration: const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Failed to add designation: ${e.toString()}');
    }
  }

  Future<bool> updateDesignation({required DesignationModel designation}) async {
    try {
      EasyLoading.show(status: 'Loading...', dismissOnTap: false);

      final userID = await getUserID();
      final DatabaseReference productInformationRef = _dbRef.child(userID).child('Designation').child(designation.id.toString());

      await productInformationRef.update({
        'designation': designation.designation,
        'designationDescription': designation.designationDescription,
      });

      EasyLoading.showSuccess('Updated Successfully', duration: const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Failed to Updated designation: ${e.toString()}');
    }
  }

  Future<bool> deleteDesignation({required num id}) async {
    try {
      EasyLoading.show(status: 'Deleting...');

      final String userId = await getUserID();
      final DatabaseReference productInformationRef = _dbRef.child(userId).child('Designation').child(id.toString());

      await productInformationRef.remove();

      EasyLoading.showSuccess('Deleted Successfully');
      return true;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }
}
