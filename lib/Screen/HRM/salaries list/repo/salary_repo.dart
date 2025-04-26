import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/model/pay_salary_model.dart';

import '../../../../const.dart';
import '../../../../model/daily_transaction_model.dart';
import '../../../Widgets/Constant Data/constant.dart';

class SalaryRepository {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<List<PaySalaryModel>> getAllPaidSalary() async {
    List<PaySalaryModel> salaries = [];

    try {
      final userID = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref(userID).child('Paid Salary').orderByKey().get();

      for (var element in snapshot.children) {
        var data = PaySalaryModel.fromJson(jsonDecode(jsonEncode(element.value)));
        salaries.add(data);
      }
    } catch (e) {
      print('Error fetching paid Salary: $e');
    }

    return salaries;
  }

  // Method to save designation
  Future<bool> paySalary({required PaySalaryModel salary}) async {
    try {
      EasyLoading.show(status: 'Loading...', dismissOnTap: false);

      final userID = await getUserID();
      final DatabaseReference productInformationRef = _dbRef.child(userID).child('Paid Salary').child(salary.id.toString());

      await productInformationRef.set(salary.toJson());

      ///________daily_transactionModel_________________________________________________________________________

      DailyTransactionModel dailyTransaction = DailyTransactionModel(
        name: salary.employeeName,
        date: salary.payingDate.toString(),
        type: 'Pay Salary',
        total: double.parse(salary.paySalary.toString()),
        paymentIn: 0,
        paymentOut: double.parse(salary.paySalary.toString()),
        remainingBalance: salary.netSalary - double.parse(salary.paySalary.toString()),
        id: salary.id.toString(),
        paySalary: salary,
      );
      await postDailyTransaction(dailyTransactionModel: dailyTransaction);

      EasyLoading.showSuccess('Added Successfully');
      return true;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Failed to pay salary: ${e.toString()}');
    }
  }

  Future<bool> updateSalary({required PaySalaryModel salary}) async {
    try {
      EasyLoading.show(status: 'Loading...', dismissOnTap: false);

      final userID = await getUserID();
      final DatabaseReference productInformationRef = _dbRef.child(userID).child('Paid Salary').child(salary.id.toString());

      await productInformationRef.update({
        'employeeName': salary.employeeName,
        'employmentId': salary.employmentId,
        'designation': salary.designation,
        'designationId': salary.designationId,
        'paySalary': salary.paySalary,
        'netSalary': salary.netSalary,
        'year': salary.year,
        'month': salary.month,
        'paymentType': salary.paymentType,
        'note': salary.note,
      });

      EasyLoading.showSuccess('Updated Successfully');
      return true;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Failed to Updated employee: ${e.toString()}');
    }
  }

  Future<bool> deletePaidSalary({required num id}) async {
    try {
      EasyLoading.show(status: 'Deleting...');

      final String userId = await getUserID();
      final DatabaseReference productInformationRef = _dbRef.child(userId).child('Paid Salary').child(id.toString());

      await productInformationRef.remove();

      EasyLoading.showSuccess('Deleted Successfully');
      return true;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }
}
