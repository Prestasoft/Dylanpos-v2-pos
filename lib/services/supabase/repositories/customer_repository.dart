import 'base_repository.dart';

/// Modelo de Cliente para Supabase
class CustomerModel {
  final String? id;
  final String branchId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double dueAmount;
  final double previousDue;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerModel({
    this.id,
    required this.branchId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.dueAmount = 0,
    this.previousDue = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id']?.toString(),
      branchId: map['branch_id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      dueAmount: (map['due_amount'] ?? 0).toDouble(),
      previousDue: (map['previous_due'] ?? 0).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'branch_id': branchId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'due_amount': dueAmount,
      'previous_due': previousDue,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? branchId,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? dueAmount,
    double? previousDue,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      dueAmount: dueAmount ?? this.dueAmount,
      previousDue: previousDue ?? this.previousDue,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Repositorio de Clientes
class CustomerRepository extends BaseRepository<CustomerModel> {
  @override
  final String tableName = 'customers';

  @override
  CustomerModel fromMap(Map<String, dynamic> map) => CustomerModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(CustomerModel model) => model.toMap();

  /// Buscar clientes por nombre
  Future<List<CustomerModel>> searchByName(String query) async {
    return search('name', query);
  }

  /// Buscar clientes por teléfono
  Future<List<CustomerModel>> searchByPhone(String phone) async {
    return search('phone', phone);
  }

  /// Obtener clientes con deuda
  Future<List<CustomerModel>> getCustomersWithDue() async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final response = await client
          .from(tableName)
          .select()
          .eq('branch_id', branchId)
          .gt('due_amount', 0)
          .order('due_amount', ascending: false);

      return (response as List)
          .map((item) => CustomerModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Actualizar deuda del cliente
  Future<bool> updateDueAmount(String customerId, double newDueAmount) async {
    return update(customerId, {'due_amount': newDueAmount});
  }

  /// Agregar a la deuda del cliente
  Future<bool> addToDue(String customerId, double amount) async {
    try {
      final customer = await getById(customerId);
      if (customer == null) return false;

      final newDue = customer.dueAmount + amount;
      return updateDueAmount(customerId, newDue);
    } catch (e) {
      return false;
    }
  }

  /// Reducir deuda del cliente
  Future<bool> reduceDue(String customerId, double amount) async {
    try {
      final customer = await getById(customerId);
      if (customer == null) return false;

      final newDue = (customer.dueAmount - amount).clamp(0.0, double.infinity);
      return updateDueAmount(customerId, newDue);
    } catch (e) {
      return false;
    }
  }
}

/// Instancia global del repositorio
final customerRepository = CustomerRepository();
