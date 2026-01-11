import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Provider/branch_provider.dart';

import '../Repository/customer_repo.dart';
import '../model/customer_model.dart';

CustomerRepo customerRepo = CustomerRepo();

/// ⚠️ CLAVE: Todos los providers de clientes observan el branchId
/// para crear la dependencia reactiva y recargar cuando cambie la sucursal
final buyerCustomerProvider = FutureProvider.autoDispose<List<CustomerModel>>((ref) {
  final branchId = ref.watch(branchIdProvider);
  debugPrint('🔄 [buyerCustomerProvider] Cargando para branch: $branchId');
  return customerRepo.getAllBuyer();
});

final allCustomerProvider = FutureProvider.autoDispose<List<CustomerModel>>((ref) {
  final branchId = ref.watch(branchIdProvider);
  debugPrint('🔄 [allCustomerProvider] Cargando para branch: $branchId');
  return customerRepo.getAllCustomer();
});

final supplierProvider = FutureProvider.autoDispose<List<CustomerModel>>((ref) {
  final branchId = ref.watch(branchIdProvider);
  debugPrint('🔄 [supplierProvider] Cargando para branch: $branchId');
  return customerRepo.getAllSupplier();
});

/// Provider para búsqueda de clientes via API
/// Recibe el término de búsqueda como parámetro
final searchCustomerProvider = FutureProvider.autoDispose.family<List<CustomerModel>, String>((ref, searchQuery) async {
  final branchId = ref.watch(branchIdProvider);
  debugPrint('🔍 [searchCustomerProvider] Buscando "$searchQuery" en branch: $branchId');

  if (searchQuery.isEmpty) {
    // Si no hay búsqueda, retornar todos los clientes
    return customerRepo.getAllCustomer();
  }

  // Usar búsqueda por API
  return customerRepo.searchCustomers(searchQuery);
});
