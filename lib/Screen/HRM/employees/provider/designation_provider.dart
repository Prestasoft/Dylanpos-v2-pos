import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';

EmployeeRepository employeeRepo = EmployeeRepository();
final employeeProvider = FutureProvider<List<EmployeeModel>>((ref) => employeeRepo.getAllEmployees());
