import 'package:flutter/foundation.dart';
import 'base_repository.dart';
import '../supabase_auth_service.dart';

/// Modelo de Item de Venta
class SaleItemModel {
  final String? id;
  final String saleId;
  final String? productId;
  final String? serviceId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double total;

  SaleItemModel({
    this.id,
    required this.saleId,
    this.productId,
    this.serviceId,
    required this.name,
    this.quantity = 1,
    required this.unitPrice,
    required this.total,
  });

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id']?.toString(),
      saleId: map['sale_id'] ?? '',
      productId: map['product_id']?.toString(),
      serviceId: map['service_id']?.toString(),
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 1).toInt(),
      unitPrice: (map['unit_price'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'service_id': serviceId,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
    };
  }
}

/// Modelo de Venta para Supabase
class SaleModel {
  final String? id;
  final String branchId;
  final String? customerId;
  final String? invoiceNumber;
  final DateTime date;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double paidAmount;
  final double dueAmount;
  final String? paymentMethod;
  final String status;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final List<SaleItemModel> items;

  SaleModel({
    this.id,
    required this.branchId,
    this.customerId,
    this.invoiceNumber,
    required this.date,
    this.subtotal = 0,
    this.discount = 0,
    this.tax = 0,
    required this.total,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.paymentMethod,
    this.status = 'completed',
    this.notes,
    this.createdBy,
    this.createdAt,
    this.items = const [],
  });

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id']?.toString(),
      branchId: map['branch_id'] ?? '',
      customerId: map['customer_id']?.toString(),
      invoiceNumber: map['invoice_number'],
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      paidAmount: (map['paid_amount'] ?? 0).toDouble(),
      dueAmount: (map['due_amount'] ?? 0).toDouble(),
      paymentMethod: map['payment_method'],
      status: map['status'] ?? 'completed',
      notes: map['notes'],
      createdBy: map['created_by']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'branch_id': branchId,
      'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'date': date.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'payment_method': paymentMethod,
      'status': status,
      'notes': notes,
      'created_by': createdBy,
    };
  }

  SaleModel copyWith({
    String? id,
    String? branchId,
    String? customerId,
    String? invoiceNumber,
    DateTime? date,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    double? paidAmount,
    double? dueAmount,
    String? paymentMethod,
    String? status,
    String? notes,
    List<SaleItemModel>? items,
  }) {
    return SaleModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      customerId: customerId ?? this.customerId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }
}

/// Repositorio de Ventas
class SaleRepository extends BaseRepository<SaleModel> {
  @override
  final String tableName = 'sales';

  @override
  SaleModel fromMap(Map<String, dynamic> map) => SaleModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(SaleModel model) => model.toMap();

  /// Crear una venta completa con items
  Future<SaleModel?> createSale({
    required SaleModel sale,
    required List<SaleItemModel> items,
  }) async {
    try {
      // 1. Insertar la venta
      final saleData = sale.toMap();
      saleData['branch_id'] = currentBranchId;
      saleData['created_by'] = supabaseAuth.currentUserId;
      saleData['created_at'] = DateTime.now().toIso8601String();

      final saleResponse = await client
          .from(tableName)
          .insert(saleData)
          .select()
          .single();

      final createdSale = SaleModel.fromMap(Map<String, dynamic>.from(saleResponse));

      // 2. Insertar los items
      if (items.isNotEmpty && createdSale.id != null) {
        final itemsData = items.map((item) => {
          ...item.toMap(),
          'sale_id': createdSale.id,
        }).toList();

        await client.from('sale_items').insert(itemsData);
      }

      debugPrint('✅ Venta creada: ${createdSale.invoiceNumber}');
      return createdSale;
    } catch (e) {
      debugPrint('❌ Error al crear venta: $e');
      return null;
    }
  }

  /// Obtener venta con sus items
  Future<SaleModel?> getSaleWithItems(String saleId) async {
    try {
      // Obtener venta
      final sale = await getById(saleId);
      if (sale == null) return null;

      // Obtener items
      final itemsResponse = await client
          .from('sale_items')
          .select()
          .eq('sale_id', saleId);

      final items = (itemsResponse as List)
          .map((item) => SaleItemModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      return sale.copyWith(items: items);
    } catch (e) {
      debugPrint('❌ Error al obtener venta con items: $e');
      return null;
    }
  }

  /// Obtener ventas por fecha
  Future<List<SaleModel>> getSalesByDate(DateTime date) async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await client
          .from(tableName)
          .select()
          .eq('branch_id', branchId)
          .gte('date', startOfDay.toIso8601String())
          .lt('date', endOfDay.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((item) => SaleModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener ventas por rango de fechas
  Future<List<SaleModel>> getSalesByDateRange(DateTime start, DateTime end) async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final response = await client
          .from(tableName)
          .select()
          .eq('branch_id', branchId)
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((item) => SaleModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener ventas por cliente
  Future<List<SaleModel>> getSalesByCustomer(String customerId) async {
    return findBy('customer_id', customerId);
  }

  /// Obtener ventas pendientes de pago
  Future<List<SaleModel>> getPendingSales() async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final response = await client
          .from(tableName)
          .select()
          .eq('branch_id', branchId)
          .gt('due_amount', 0)
          .order('date', ascending: false);

      return (response as List)
          .map((item) => SaleModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Generar número de factura
  Future<String> generateInvoiceNumber() async {
    try {
      final branchId = currentBranchId ?? 'XX';
      final now = DateTime.now();
      final prefix = '${branchId.toUpperCase()}-${now.year}${now.month.toString().padLeft(2, '0')}';

      // Obtener el último número de factura del mes
      final response = await client
          .from(tableName)
          .select('invoice_number')
          .eq('branch_id', branchId)
          .ilike('invoice_number', '$prefix%')
          .order('created_at', ascending: false)
          .limit(1);

      int nextNumber = 1;
      if ((response as List).isNotEmpty && response[0]['invoice_number'] != null) {
        final lastNumber = response[0]['invoice_number'] as String;
        final parts = lastNumber.split('-');
        if (parts.length >= 3) {
          nextNumber = (int.tryParse(parts.last) ?? 0) + 1;
        }
      }

      return '$prefix-${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      // Fallback simple
      return 'INV-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Obtener resumen de ventas del día
  Future<Map<String, double>> getDailySummary(DateTime date) async {
    final sales = await getSalesByDate(date);

    double totalSales = 0;
    double totalCash = 0;
    double totalCard = 0;
    double totalTransfer = 0;

    for (final sale in sales) {
      totalSales += sale.total;
      switch (sale.paymentMethod?.toLowerCase()) {
        case 'cash':
        case 'efectivo':
          totalCash += sale.paidAmount;
          break;
        case 'card':
        case 'tarjeta':
          totalCard += sale.paidAmount;
          break;
        case 'transfer':
        case 'transferencia':
          totalTransfer += sale.paidAmount;
          break;
      }
    }

    return {
      'total_sales': totalSales,
      'total_cash': totalCash,
      'total_card': totalCard,
      'total_transfer': totalTransfer,
      'count': sales.length.toDouble(),
    };
  }
}

/// Instancia global del repositorio
final saleRepository = SaleRepository();
