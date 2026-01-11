import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../supabase_service.dart';

/// Servicio para migrar datos de Firebase a Supabase
/// Ejecutar una sola vez para cada sucursal
class FirebaseToSupabaseMigration {
  final String branchId;
  final SupabaseService _supabase = supabaseService;

  // Referencias Firebase
  late final DatabaseReference _realtimeDb;
  late final FirebaseFirestore _firestore;

  // Estadísticas de migración
  int _customersCreated = 0;
  int _productsCreated = 0;
  int _servicesCreated = 0;
  int _salesCreated = 0;
  int _expensesCreated = 0;
  int _reservationsCreated = 0;
  int _errors = 0;

  FirebaseToSupabaseMigration({required this.branchId}) {
    _realtimeDb = FirebaseDatabase.instance.ref();
    _firestore = FirebaseFirestore.instance;
  }

  /// Ejecutar migración completa
  Future<Map<String, dynamic>> runFullMigration() async {
    debugPrint('🚀 Iniciando migración para sucursal: $branchId');
    final startTime = DateTime.now();

    try {
      // Migrar en orden (respetando foreign keys)
      await migrateCustomers();
      await migrateProducts();
      await migrateServices();
      await migrateSales();
      await migrateExpenses();
      await migrateReservations();

      final duration = DateTime.now().difference(startTime);

      debugPrint('✅ Migración completada en ${duration.inSeconds}s');

      return {
        'success': true,
        'branch_id': branchId,
        'duration_seconds': duration.inSeconds,
        'customers_created': _customersCreated,
        'products_created': _productsCreated,
        'services_created': _servicesCreated,
        'sales_created': _salesCreated,
        'expenses_created': _expensesCreated,
        'reservations_created': _reservationsCreated,
        'errors': _errors,
      };
    } catch (e) {
      debugPrint('❌ Error en migración: $e');
      return {
        'success': false,
        'error': e.toString(),
        'branch_id': branchId,
      };
    }
  }

  /// Migrar clientes
  Future<void> migrateCustomers() async {
    debugPrint('📦 Migrando clientes...');

    try {
      // Intentar desde Realtime Database primero
      final snapshot = await _realtimeDb.child('Customers List').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (final entry in data.entries) {
          try {
            final customer = Map<String, dynamic>.from(entry.value as Map);

            await _supabase.client.from('customers').insert({
              'branch_id': branchId,
              'name': customer['customerName'] ?? customer['name'] ?? 'Sin nombre',
              'phone': customer['phoneNumber'] ?? customer['phone'],
              'email': customer['emailAddress'] ?? customer['email'],
              'address': customer['customerAddress'] ?? customer['address'],
              'due_amount': _parseDouble(customer['dueAmount'] ?? customer['due'] ?? 0),
              'previous_due': _parseDouble(customer['previousDue'] ?? 0),
              'created_at': DateTime.now().toIso8601String(),
            });

            _customersCreated++;
          } catch (e) {
            debugPrint('⚠️ Error migrando cliente ${entry.key}: $e');
            _errors++;
          }
        }
      }

      debugPrint('✅ Clientes migrados: $_customersCreated');
    } catch (e) {
      debugPrint('❌ Error migrando clientes: $e');
      _errors++;
    }
  }

  /// Migrar productos
  Future<void> migrateProducts() async {
    debugPrint('📦 Migrando productos...');

    try {
      final snapshot = await _realtimeDb.child('Products').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (final entry in data.entries) {
          try {
            final product = Map<String, dynamic>.from(entry.value as Map);

            await _supabase.client.from('products').insert({
              'branch_id': branchId,
              'name': product['productName'] ?? product['name'] ?? 'Sin nombre',
              'description': product['productDescription'] ?? product['description'],
              'barcode': product['productCode'] ?? product['barcode'],
              'price': _parseDouble(product['productSalePrice'] ?? product['price'] ?? 0),
              'purchase_price': _parseDouble(product['productPurchasePrice'] ?? product['purchasePrice'] ?? 0),
              'stock': _parseInt(product['productStock'] ?? product['stock'] ?? 0),
              'image_url': product['productPicture'] ?? product['image'],
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
            });

            _productsCreated++;
          } catch (e) {
            debugPrint('⚠️ Error migrando producto ${entry.key}: $e');
            _errors++;
          }
        }
      }

      debugPrint('✅ Productos migrados: $_productsCreated');
    } catch (e) {
      debugPrint('❌ Error migrando productos: $e');
      _errors++;
    }
  }

  /// Migrar servicios/paquetes
  Future<void> migrateServices() async {
    debugPrint('📦 Migrando servicios...');

    try {
      // Desde Realtime Database
      final snapshot = await _realtimeDb.child('Admin Panel/services').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (final entry in data.entries) {
          try {
            final service = Map<String, dynamic>.from(entry.value as Map);

            await _supabase.client.from('services').insert({
              'branch_id': branchId,
              'type': service['type'],
              'name': service['name'] ?? 'Sin nombre',
              'category': service['category'] ?? 'General',
              'subcategory': service['subcategory'],
              'description': service['description'],
              'price': _parseDouble(service['price'] ?? 0),
              'duration': _parseInt(service['duration']),
              'components': service['components'] ?? [],
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
            });

            _servicesCreated++;
          } catch (e) {
            debugPrint('⚠️ Error migrando servicio ${entry.key}: $e');
            _errors++;
          }
        }
      }

      // También intentar desde Firestore
      try {
        final firestoreServices = await _firestore.collection('services').get();

        for (final doc in firestoreServices.docs) {
          try {
            final service = doc.data();

            await _supabase.client.from('services').insert({
              'branch_id': branchId,
              'type': service['type'],
              'name': service['name'] ?? 'Sin nombre',
              'category': service['category'] ?? 'General',
              'subcategory': service['subcategory'],
              'description': service['description'],
              'price': _parseDouble(service['price'] ?? 0),
              'duration': _parseInt(service['duration']),
              'components': service['components'] ?? [],
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
            });

            _servicesCreated++;
          } catch (e) {
            // Ignorar duplicados
          }
        }
      } catch (e) {
        // Firestore puede no tener datos
      }

      debugPrint('✅ Servicios migrados: $_servicesCreated');
    } catch (e) {
      debugPrint('❌ Error migrando servicios: $e');
      _errors++;
    }
  }

  /// Migrar ventas
  Future<void> migrateSales() async {
    debugPrint('📦 Migrando ventas...');

    try {
      final snapshot = await _realtimeDb.child('Sales Transactions').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (final entry in data.entries) {
          try {
            final sale = Map<String, dynamic>.from(entry.value as Map);

            // Insertar venta principal
            final saleResponse = await _supabase.client.from('sales').insert({
              'branch_id': branchId,
              'invoice_number': sale['invoiceNumber'] ?? entry.key,
              'date': _parseDate(sale['purchaseDate'] ?? sale['date']),
              'subtotal': _parseDouble(sale['subTotal'] ?? sale['subtotal'] ?? 0),
              'discount': _parseDouble(sale['discountAmount'] ?? sale['discount'] ?? 0),
              'tax': _parseDouble(sale['taxAmount'] ?? sale['tax'] ?? 0),
              'total': _parseDouble(sale['totalAmount'] ?? sale['total'] ?? 0),
              'paid_amount': _parseDouble(sale['paidAmount'] ?? 0),
              'due_amount': _parseDouble(sale['dueAmount'] ?? 0),
              'payment_method': sale['paymentType'] ?? sale['paymentMethod'],
              'status': 'completed',
              'notes': sale['description'],
              'created_at': DateTime.now().toIso8601String(),
            }).select().single();

            final saleId = saleResponse['id'];

            // Insertar items de venta
            if (sale['productList'] != null) {
              final products = sale['productList'] as List;
              for (final product in products) {
                final p = Map<String, dynamic>.from(product as Map);
                await _supabase.client.from('sale_items').insert({
                  'sale_id': saleId,
                  'name': p['productName'] ?? p['name'] ?? 'Item',
                  'quantity': _parseInt(p['productStock'] ?? p['quantity'] ?? 1),
                  'unit_price': _parseDouble(p['productSalePrice'] ?? p['price'] ?? 0),
                  'total': _parseDouble(p['subTotal'] ?? p['total'] ?? 0),
                });
              }
            }

            _salesCreated++;
          } catch (e) {
            debugPrint('⚠️ Error migrando venta ${entry.key}: $e');
            _errors++;
          }
        }
      }

      debugPrint('✅ Ventas migradas: $_salesCreated');
    } catch (e) {
      debugPrint('❌ Error migrando ventas: $e');
      _errors++;
    }
  }

  /// Migrar gastos
  Future<void> migrateExpenses() async {
    debugPrint('📦 Migrando gastos...');

    try {
      final snapshot = await _realtimeDb.child('Expenses').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (final entry in data.entries) {
          try {
            final expense = Map<String, dynamic>.from(entry.value as Map);

            await _supabase.client.from('expenses').insert({
              'branch_id': branchId,
              'category': expense['expenseCategory'] ?? expense['category'] ?? 'General',
              'description': expense['expenseFor'] ?? expense['description'],
              'amount': _parseDouble(expense['amount'] ?? 0),
              'date': _parseDate(expense['expenseDate'] ?? expense['date']),
              'payment_method': expense['paymentMethod'],
              'created_at': DateTime.now().toIso8601String(),
            });

            _expensesCreated++;
          } catch (e) {
            debugPrint('⚠️ Error migrando gasto ${entry.key}: $e');
            _errors++;
          }
        }
      }

      debugPrint('✅ Gastos migrados: $_expensesCreated');
    } catch (e) {
      debugPrint('❌ Error migrando gastos: $e');
      _errors++;
    }
  }

  /// Migrar reservaciones
  Future<void> migrateReservations() async {
    debugPrint('📦 Migrando reservaciones...');

    try {
      final snapshot = await _realtimeDb.child('Reservations').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (final entry in data.entries) {
          try {
            final reservation = Map<String, dynamic>.from(entry.value as Map);

            await _supabase.client.from('reservations').insert({
              'branch_id': branchId,
              'date': _parseDate(reservation['date'] ?? reservation['reservationDate']),
              'time': reservation['time'] ?? reservation['reservationTime'],
              'status': reservation['status'] ?? 'pending',
              'notes': reservation['notes'] ?? reservation['description'],
              'total': _parseDouble(reservation['total'] ?? reservation['totalAmount'] ?? 0),
              'deposit': _parseDouble(reservation['deposit'] ?? reservation['abono'] ?? 0),
              'created_at': DateTime.now().toIso8601String(),
            });

            _reservationsCreated++;
          } catch (e) {
            debugPrint('⚠️ Error migrando reservación ${entry.key}: $e');
            _errors++;
          }
        }
      }

      debugPrint('✅ Reservaciones migradas: $_reservationsCreated');
    } catch (e) {
      debugPrint('❌ Error migrando reservaciones: $e');
      _errors++;
    }
  }

  // =========================================
  // HELPERS
  // =========================================

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _parseDate(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String().split('T')[0];

    if (value is String) {
      // Intentar parsear diferentes formatos
      try {
        return DateTime.parse(value).toIso8601String().split('T')[0];
      } catch (_) {
        // Formato dd/MM/yyyy o similar
        final parts = value.split(RegExp(r'[/\-]'));
        if (parts.length == 3) {
          try {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day).toIso8601String().split('T')[0];
          } catch (_) {}
        }
      }
    }

    if (value is int) {
      // Timestamp en milisegundos
      return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String().split('T')[0];
    }

    return DateTime.now().toIso8601String().split('T')[0];
  }
}

/// Función helper para ejecutar migración desde UI
Future<Map<String, dynamic>> runMigration(String branchId) async {
  final migration = FirebaseToSupabaseMigration(branchId: branchId);
  return await migration.runFullMigration();
}
