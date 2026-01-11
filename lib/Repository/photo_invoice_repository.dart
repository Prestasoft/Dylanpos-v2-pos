import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:salespro_admin/model/photo_invoice_model.dart';
import '../services/api_service.dart';

/// Repositorio de facturas fotográficas - Usa PostgreSQL API
class PhotoInvoiceRepository {
  final String userId;
  final ApiService _apiService = ApiService();

  PhotoInvoiceRepository({required this.userId}) {
    debugPrint('PhotoInvoiceRepository inicializado con userId: $userId');
  }

  // Guardar una nueva factura en PostgreSQL
  Future<String> saveInvoice(PhotoInvoiceModel invoice) async {
    try {
      debugPrint('Iniciando guardado de factura en PostgreSQL API...');
      debugPrint('userId del repository: $userId');

      final dataToSave = invoice.toMap();
      debugPrint('Estructura de datos a guardar:');
      debugPrint('- invoiceNumber: ${dataToSave['invoiceNumber']}');
      debugPrint('- customer: ${dataToSave['customer']?['customerName'] ?? 'Sin cliente'}');
      debugPrint('- totalAmount: ${dataToSave['totalAmount'] ?? 'calculado'}');
      debugPrint('- products: ${dataToSave['products']?.length ?? 0}');
      debugPrint('- services: ${dataToSave['services']?.length ?? 0}');
      debugPrint('- isPaid: ${dataToSave['isPaid']}');
      debugPrint('- dueAmount: ${dataToSave['dueAmount']}');
      debugPrint('- paymentMethod: ${dataToSave['paymentMethod']}');

      final response = await _apiService.post('photo-invoices', dataToSave);

      if (response.success && response.data != null) {
        final savedInvoice = response.data['photo_invoice'];
        final invoiceId = savedInvoice?['id']?.toString() ?? '';
        debugPrint('Factura guardada exitosamente: $invoiceId');

        // Si el cliente tiene deuda, actualizarla
        if (invoice.dueAmount > 0) {
          debugPrint('Actualizando deuda del cliente: ${invoice.dueAmount}');
          _updateCustomerDue(invoice.customer.phoneNumber, invoice.dueAmount)
            .catchError((e) => debugPrint('Error actualizando deuda del cliente: $e'));
        }

        return invoiceId;
      }

      throw Exception('Error al guardar la factura');
    } catch (e) {
      debugPrint('Error al guardar en PostgreSQL: $e');
      throw Exception('Error al guardar la factura: $e');
    }
  }

  // Obtener todas las facturas de photo-invoice (Stream para compatibilidad)
  Stream<List<PhotoInvoiceModel>> getInvoices() {
    debugPrint('PhotoInvoiceRepository.getInvoices()');
    debugPrint('userId actual: $userId');

    final controller = StreamController<List<PhotoInvoiceModel>>();

    _fetchInvoices().then((invoices) {
      controller.add(invoices);
    }).catchError((e) {
      debugPrint('Error en stream de facturas: $e');
      controller.addError(e);
    });

    return controller.stream;
  }

  // Obtener facturas desde PostgreSQL
  Future<List<PhotoInvoiceModel>> _fetchInvoices() async {
    try {
      final response = await _apiService.get('photo-invoices', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final invoicesData = response.data['photo_invoices'] as List<dynamic>? ?? [];
        debugPrint('Total de Photo Invoices encontradas: ${invoicesData.length}');

        final List<PhotoInvoiceModel> invoices = [];
        int processedCount = 0;
        int errorCount = 0;

        for (var data in invoicesData) {
          try {
            final invoiceData = _convertToStringMap(data);
            invoiceData['invoiceId'] = invoiceData['id']?.toString();

            final photoInvoice = PhotoInvoiceModel.fromMap(invoiceData);
            invoices.add(photoInvoice);

            debugPrint('Photo Invoice cargada exitosamente: ${photoInvoice.invoiceNumber}');
            processedCount++;
          } catch (e) {
            debugPrint('Error procesando factura: $e');
            errorCount++;
          }
        }

        debugPrint('Procesamiento completado: $processedCount exitosas, $errorCount errores');

        // Ordenar por fecha descendente
        invoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        return invoices;
      }

      debugPrint('No se encontraron Photo Invoices en la base de datos');
      return [];
    } catch (e) {
      debugPrint('Error al obtener facturas: $e');
      return [];
    }
  }

  // Obtener facturas por rango de fecha
  Stream<List<PhotoInvoiceModel>> getInvoicesByDateRange(DateTime start, DateTime end) {
    final controller = StreamController<List<PhotoInvoiceModel>>();

    _fetchInvoicesByDateRange(start, end).then((invoices) {
      controller.add(invoices);
    }).catchError((e) {
      controller.addError(e);
    });

    return controller.stream;
  }

  Future<List<PhotoInvoiceModel>> _fetchInvoicesByDateRange(DateTime start, DateTime end) async {
    try {
      final response = await _apiService.get('photo-invoices', queryParams: {
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
        'limit': '1000',
      });

      if (response.success && response.data != null) {
        final invoicesData = response.data['photo_invoices'] as List<dynamic>? ?? [];

        final List<PhotoInvoiceModel> invoices = [];
        for (var data in invoicesData) {
          try {
            final invoiceData = _convertToStringMap(data);
            invoiceData['invoiceId'] = invoiceData['id']?.toString();
            final photoInvoice = PhotoInvoiceModel.fromMap(invoiceData);

            // Filtrar por rango de fecha (doble verificación)
            if (photoInvoice.invoiceDate.isAfter(start.subtract(const Duration(days: 1))) &&
                photoInvoice.invoiceDate.isBefore(end.add(const Duration(days: 1)))) {
              invoices.add(photoInvoice);
            }
          } catch (e) {
            debugPrint('Error procesando factura: $e');
          }
        }

        // Ordenar por fecha descendente
        invoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        return invoices;
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo facturas por fecha: $e');
      return [];
    }
  }

  // Obtener facturas pendientes de pago
  Stream<List<PhotoInvoiceModel>> getPendingInvoices() {
    final controller = StreamController<List<PhotoInvoiceModel>>();

    _fetchPendingInvoices().then((invoices) {
      controller.add(invoices);
    }).catchError((e) {
      controller.addError(e);
    });

    return controller.stream;
  }

  Future<List<PhotoInvoiceModel>> _fetchPendingInvoices() async {
    try {
      final response = await _apiService.get('photo-invoices', queryParams: {
        'is_paid': 'false',
        'limit': '1000',
      });

      if (response.success && response.data != null) {
        final invoicesData = response.data['photo_invoices'] as List<dynamic>? ?? [];

        final List<PhotoInvoiceModel> invoices = [];
        for (var data in invoicesData) {
          try {
            final invoiceData = _convertToStringMap(data);
            invoiceData['invoiceId'] = invoiceData['id']?.toString();
            final photoInvoice = PhotoInvoiceModel.fromMap(invoiceData);

            // Solo agregar facturas pendientes
            if (!photoInvoice.isPaid) {
              invoices.add(photoInvoice);
            }
          } catch (e) {
            debugPrint('Error procesando factura: $e');
          }
        }

        // Ordenar por fecha descendente
        invoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        return invoices;
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo facturas pendientes: $e');
      return [];
    }
  }

  // Obtener facturas por cliente
  Stream<List<PhotoInvoiceModel>> getInvoicesByCustomer(String customerPhone) {
    final controller = StreamController<List<PhotoInvoiceModel>>();

    _fetchInvoicesByCustomer(customerPhone).then((invoices) {
      controller.add(invoices);
    }).catchError((e) {
      controller.addError(e);
    });

    return controller.stream;
  }

  Future<List<PhotoInvoiceModel>> _fetchInvoicesByCustomer(String customerPhone) async {
    try {
      final response = await _apiService.get('photo-invoices', queryParams: {
        'customer_phone': customerPhone,
        'limit': '1000',
      });

      if (response.success && response.data != null) {
        final invoicesData = response.data['photo_invoices'] as List<dynamic>? ?? [];

        final List<PhotoInvoiceModel> invoices = [];
        for (var data in invoicesData) {
          try {
            final invoiceData = _convertToStringMap(data);
            invoiceData['invoiceId'] = invoiceData['id']?.toString();
            final photoInvoice = PhotoInvoiceModel.fromMap(invoiceData);
            invoices.add(photoInvoice);
          } catch (e) {
            debugPrint('Error procesando factura: $e');
          }
        }

        // Ordenar por fecha descendente
        invoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        return invoices;
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo facturas por cliente: $e');
      return [];
    }
  }

  // Obtener una factura específica
  Future<PhotoInvoiceModel?> getInvoiceById(String invoiceId) async {
    try {
      final response = await _apiService.get('photo-invoices/$invoiceId');

      if (response.success && response.data != null) {
        final invoiceData = response.data['photo_invoice'] ?? response.data;
        if (invoiceData != null) {
          final data = _convertToStringMap(invoiceData);
          data['invoiceId'] = invoiceId;
          return PhotoInvoiceModel.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener la factura: $e');
    }
  }

  // Actualizar el estado de pago
  Future<void> updatePaymentStatus(String invoiceId, double paidAmount) async {
    try {
      final invoice = await getInvoiceById(invoiceId);
      if (invoice == null) return;

      final newPaidAmount = invoice.paidAmount + paidAmount;
      final newDueAmount = invoice.totalAmount - newPaidAmount;
      final isPaid = newDueAmount <= 0;

      await _apiService.put('photo-invoices/$invoiceId', {
        'paidAmount': newPaidAmount,
        'dueAmount': newDueAmount,
        'isPaid': isPaid,
        'lastPaymentDate': DateTime.now().toIso8601String(),
      });

      // Actualizar la deuda del cliente
      await _updateCustomerDue(
        invoice.customer.phoneNumber,
        -paidAmount, // Negativo porque se está reduciendo la deuda
      );
    } catch (e) {
      throw Exception('Error al actualizar el pago: $e');
    }
  }

  // Registrar un pago con método y banco
  Future<void> registerPayment({
    required String invoiceId,
    required double paymentAmount,
    required String paymentMethod,
    String? selectedBank,
  }) async {
    try {
      debugPrint('Iniciando registerPayment con invoiceId: $invoiceId');

      // Obtener la factura desde PostgreSQL
      final invoice = await getInvoiceById(invoiceId);

      if (invoice == null) {
        throw Exception('Factura no encontrada');
      }

      debugPrint('Factura encontrada: ${invoice.invoiceNumber}');

      if (paymentAmount <= 0) {
        throw Exception('El monto debe ser mayor a 0');
      }

      final currentDueAmount = invoice.dueAmount;
      if (paymentAmount > currentDueAmount) {
        throw Exception('El monto no puede ser mayor a la deuda pendiente');
      }

      // Calcular nuevos valores
      final newPaidAmount = invoice.paidAmount + paymentAmount;
      final newDueAmount = invoice.totalAmount - newPaidAmount;
      final isPaid = newDueAmount <= 0;

      debugPrint('Calculando nuevos valores:');
      debugPrint('- Monto pagado anterior: ${invoice.paidAmount}');
      debugPrint('- Nuevo monto pagado: $newPaidAmount');
      debugPrint('- Nueva deuda: $newDueAmount');
      debugPrint('- Estado pagado: $isPaid');

      // Preparar los datos de actualización
      final updateData = <String, dynamic>{
        'paidAmount': newPaidAmount,
        'dueAmount': newDueAmount,
        'isPaid': isPaid,
        'paymentMethod': paymentMethod,
        'lastPaymentDate': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (selectedBank != null && selectedBank.isNotEmpty) {
        updateData['bankName'] = selectedBank;
      }

      debugPrint('Actualizando con datos: $updateData');

      // Actualizar en PostgreSQL
      final response = await _apiService.put('photo-invoices/$invoiceId', updateData);

      if (!response.success) {
        throw Exception('No se pudo actualizar la factura');
      }

      debugPrint('Factura actualizada exitosamente');

      // Actualizar la deuda del cliente de forma asíncrona
      if (invoice.customer.phoneNumber.isNotEmpty) {
        // No esperar esta operación, hacerla en background
        Future(() async {
          try {
            await _updateCustomerDue(
              invoice.customer.phoneNumber,
              -paymentAmount,
            );
            debugPrint('Deuda del cliente actualizada exitosamente');
          } catch (e) {
            debugPrint('Error actualizando deuda del cliente: $e');
          }
        });
      }

      debugPrint('Registro de pago completado exitosamente');
    } catch (e) {
      debugPrint('Error en registerPayment: $e');
      throw Exception('Error al registrar el pago: $e');
    }
  }

  // Actualizar la deuda del cliente
  Future<void> _updateCustomerDue(String customerPhone, double amountChange) async {
    try {
      // Buscar el cliente por teléfono
      final response = await _apiService.get('customers', queryParams: {
        'phone': customerPhone,
        'limit': '1',
      });

      if (response.success && response.data != null) {
        final customers = response.data['customers'] as List<dynamic>? ?? [];

        if (customers.isNotEmpty) {
          final customer = customers.first;
          final customerId = customer['id']?.toString();
          final currentDue = (customer['dueAmount'] ?? 0).toDouble();

          if (customerId != null) {
            await _apiService.put('customers/$customerId', {
              'dueAmount': currentDue + amountChange,
            });
          }
        }
      }
    } catch (e) {
      // Si hay error actualizando el cliente, continuamos sin interrumpir
      debugPrint('Error actualizando deuda del cliente: $e');
    }
  }

  // Eliminar una factura
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      final invoice = await getInvoiceById(invoiceId);
      if (invoice == null) return;

      await _apiService.delete('photo-invoices/$invoiceId');

      // Si la factura tenía deuda pendiente, actualizar el cliente
      if (invoice.dueAmount > 0) {
        await _updateCustomerDue(
          invoice.customer.phoneNumber,
          -invoice.dueAmount, // Reducir la deuda del cliente
        );
      }
    } catch (e) {
      throw Exception('Error al eliminar la factura: $e');
    }
  }

  // Obtener estadísticas
  Future<Map<String, dynamic>> getStatistics({DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, String>{'limit': '10000'};

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _apiService.get('photo-invoices', queryParams: queryParams);

      double totalSales = 0;
      double totalPending = 0;
      int totalInvoices = 0;
      int pendingInvoices = 0;

      if (response.success && response.data != null) {
        final invoicesData = response.data['photo_invoices'] as List<dynamic>? ?? [];

        for (var data in invoicesData) {
          try {
            final invoiceData = _convertToStringMap(data);
            invoiceData['invoiceId'] = invoiceData['id']?.toString();
            final invoice = PhotoInvoiceModel.fromMap(invoiceData);

            // Filtrar por fechas si se proporcionan
            bool includeInvoice = true;
            if (startDate != null && invoice.invoiceDate.isBefore(startDate)) {
              includeInvoice = false;
            }
            if (endDate != null && invoice.invoiceDate.isAfter(endDate)) {
              includeInvoice = false;
            }

            if (includeInvoice) {
              totalSales += invoice.totalAmount;
              totalInvoices++;

              if (!invoice.isPaid) {
                totalPending += invoice.dueAmount;
                pendingInvoices++;
              }
            }
          } catch (e) {
            debugPrint('Error procesando factura para estadísticas: $e');
          }
        }
      }

      return {
        'totalSales': totalSales,
        'totalPending': totalPending,
        'totalInvoices': totalInvoices,
        'pendingInvoices': pendingInvoices,
        'paidInvoices': totalInvoices - pendingInvoices,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Método helper para convertir Map<dynamic, dynamic> a Map<String, dynamic> recursivamente
  Map<String, dynamic> _convertToStringMap(dynamic data) {
    if (data is Map) {
      final Map<String, dynamic> result = {};
      data.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] = _convertToStringMap(value);
        } else if (value is List) {
          result[key.toString()] = value.map((item) {
            if (item is Map) {
              return _convertToStringMap(item);
            }
            return item;
          }).toList();
        } else {
          result[key.toString()] = value;
        }
      });
      return result;
    }
    return data as Map<String, dynamic>;
  }
}
