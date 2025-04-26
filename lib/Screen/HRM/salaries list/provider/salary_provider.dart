import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/model/pay_salary_model.dart';

import '../repo/salary_repo.dart';

SalaryRepository salary = SalaryRepository();
final salaryProvider = FutureProvider<List<PaySalaryModel>>((ref) => salary.getAllPaidSalary());
