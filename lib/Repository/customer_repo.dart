import 'package:intl/intl.dart';

import '../model/customer_model.dart';
import '../services/api_service.dart';

/// Repositorio de clientes - Usa PostgreSQL API
class CustomerRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todos los clientes desde PostgreSQL
  Future<List<CustomerModel>> getAllCustomer() async {
    try {
      final response = await _apiService.getCustomers(limit: 1000);

      if (response.success && response.data != null) {
        final customersData = response.data['customers'] as List<dynamic>? ?? [];

        final customersList = customersData.map((data) {
          return CustomerModel.fromJson(data as Map<String, dynamic>);
        }).toList();

        // Ordenar por fecha de CREACIÓN (más reciente primero)
        customersList.sort((a, b) {
          final dateA = _parseDate(a.createdAt ?? '1970-01-01 00:00:00');
          final dateB = _parseDate(b.createdAt ?? '1970-01-01 00:00:00');
          return dateB.compareTo(dateA); // Descendente: más reciente primero
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
      try {
        // Intentar formato ISO
        return DateTime.parse(dateStr);
      } catch (e2) {
        // Si falla el parseo, devolver fecha mínima
        return DateTime(1970);
      }
    }
  }

  /// Obtener solo compradores (no suppliers)
  Future<List<CustomerModel>> getAllBuyer() async {
    final allCustomers = await getAllCustomer();
    return allCustomers.where((c) => c.type != "Supplier").toList();
  }

  /// Obtener solo proveedores (suppliers)
  Future<List<CustomerModel>> getAllSupplier() async {
    final allCustomers = await getAllCustomer();
    return allCustomers.where((c) => c.type == "Supplier").toList();
  }

  /// Crear un nuevo cliente
  Future<CustomerModel?> createCustomer(CustomerModel customer) async {
    try {
      // Cast Map<dynamic, dynamic> a Map<String, dynamic>
      final customerData = Map<String, dynamic>.from(customer.toJson());
      final response = await _apiService.createCustomer(customerData);

      if (response.success && response.data != null) {
        return CustomerModel.fromJson(response.data['customer']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar un cliente existente
  Future<CustomerModel?> updateCustomer(String id, CustomerModel customer) async {
    try {
      // Cast Map<dynamic, dynamic> a Map<String, dynamic>
      final customerData = Map<String, dynamic>.from(customer.toJson());
      final response = await _apiService.updateCustomer(id, customerData);

      if (response.success && response.data != null) {
        return CustomerModel.fromJson(response.data['customer']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar un cliente
  Future<bool> deleteCustomer(String id) async {
    try {
      final response = await _apiService.deleteCustomer(id);
      return response.success;
    } catch (e) {
      rethrow;
    }
  }

  /// Buscar clientes por nombre o teléfono
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      final response = await _apiService.getCustomers(limit: 100, search: query);

      if (response.success && response.data != null) {
        final customersData = response.data['customers'] as List<dynamic>? ?? [];

        final customersList = customersData.map((data) {
          return CustomerModel.fromJson(data as Map<String, dynamic>);
        }).toList();

        // Ordenar por fecha de CREACIÓN (más reciente primero)
        customersList.sort((a, b) {
          final dateA = _parseDate(a.createdAt ?? '1970-01-01 00:00:00');
          final dateB = _parseDate(b.createdAt ?? '1970-01-01 00:00:00');
          return dateB.compareTo(dateA); // Descendente: más reciente primero
        });

        return customersList;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
