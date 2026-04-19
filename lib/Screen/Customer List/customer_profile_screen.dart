import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../model/reservation_model.dart';
import '../../services/api_service.dart';
import '../Widgets/customer_avatar.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../PDF/print_pdf.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/general_setting_provider.dart';
import '../../Provider/dress_with_reservations.dart';
import '../../Provider/reservation_provider.dart';
import '../../services/deletion_password_service.dart';
import '../../model/sale_transaction_model.dart';
import '../../model/FullReservation.dart';
import '../../model/dress_model.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String? customerName;

  const CustomerProfileScreen({
    super.key,
    required this.customerId,
    this.customerName,
  });

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  // Datos del perfil
  Map<String, dynamic>? _customer;
  Map<String, dynamic>? _summary;
  List<dynamic> _invoices = [];
  List<dynamic> _payments = [];
  List<dynamic> _reservations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.get('customer-profile/${widget.customerId}');

      if (response.success && response.data != null) {
        // DEBUG: Ver estructura completa de reservaciones
        final reservationsData = response.data['reservations'] ?? [];
        if (reservationsData.isNotEmpty) {
          debugPrint('🔍 [CustomerProfile] Primera reservación COMPLETA:');
          debugPrint('🔍 ${reservationsData[0]}');
          debugPrint('🔍 [CustomerProfile] Keys de reservación: ${(reservationsData[0] as Map).keys.toList()}');
        }

        setState(() {
          _customer = response.data['customer'];
          _summary = response.data['financialSummary'];
          _invoices = response.data['invoices'] ?? [];
          _payments = response.data['payments'] ?? [];
          _reservations = reservationsData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar el perfil del cliente';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  /// Genera e imprime el PDF de una factura específica
  Future<void> _printInvoice(Map<String, dynamic> invoice) async {
    final invoiceNumber = invoice['invoiceNumber']?.toString();
    final saleId = invoice['id']?.toString();

    if (invoiceNumber == null && saleId == null) {
      EasyLoading.showError('No se pudo identificar la factura');
      return;
    }

    try {
      EasyLoading.show(status: 'Cargando factura...');

      // Obtener la venta completa desde el API
      final apiService = ApiService();
      final response = await apiService.get('sales/$saleId');

      if (!response.success || response.data == null) {
        EasyLoading.dismiss();
        EasyLoading.showError('No se pudo cargar la factura');
        return;
      }

      final saleData = response.data['sale'] ?? response.data;

      // Crear el modelo de transacción de venta
      final saleTransaction = SaleTransactionModel.fromJson(saleData);

      // Obtener configuración y perfil
      final setting = ref.read(generalSettingProvider).valueOrNull;
      final profile = ref.read(profileDetailsProvider).valueOrNull;

      if (setting == null || profile == null) {
        EasyLoading.dismiss();
        EasyLoading.showError('No se pudo cargar la configuración');
        return;
      }

      // Calcular pérdida/ganancia
      SaleTransactionModel post = checkLossProfit(transitionModel: saleTransaction);

      EasyLoading.show(status: 'Generando PDF...');

      // Verificar que el widget sigue montado antes de usar context
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }

      // Generar e imprimir el PDF
      await GeneratePdfAndPrint().printSaleInvoice(
        setting: setting,
        personalInformationModel: profile,
        saleTransactionModel: saleTransaction,
        context: context,
        printType: 'normal',
        fromSaleReports: true,
        post: post,
      );

      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error al generar PDF: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/customer-list');
            }
          },
        ),
        title: Text(
          widget.customerName ?? 'Perfil del Cliente',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadProfile,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con información del cliente
          _buildCustomerHeader(),

          // Resumen financiero
          _buildFinancialSummary(),

          // Tabs de contenido
          _buildTabSection(),
        ],
      ),
    );
  }

  Widget _buildCustomerHeader() {
    final customer = _customer!;
    final createdAt = customer['createdAt'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(customer['createdAt']))
        : 'N/A';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar/Foto
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100, width: 2),
            ),
            child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomerAvatar(
                      imageUrl: customer['profilePicture']?.toString(),
                      size: 100,
                    ),
                  ),
          ),
          const SizedBox(width: 20),

          // Información del cliente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer['name'] ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.phone, customer['phone'] ?? 'Sin teléfono'),
                if (customer['gst'] != null && customer['gst'].toString().isNotEmpty)
                  _buildInfoRow(Icons.badge, customer['gst']),
                if (customer['email'] != null && customer['email'].toString().isNotEmpty)
                  _buildInfoRow(Icons.email, customer['email']),
                if (customer['address'] != null && customer['address'].toString().isNotEmpty)
                  _buildInfoRow(Icons.location_on, customer['address']),
                _buildInfoRow(Icons.calendar_today, 'Cliente desde: $createdAt'),
                if (customer['birthDate'] != null)
                  _buildInfoRow(
                    Icons.cake,
                    'Cumpleaños: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(customer['birthDate']))}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Icon(
        Icons.person,
        size: 50,
        color: Colors.blue.shade300,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final summary = _summary ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMEN FINANCIERO',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryCard(
                'Total Facturado',
                'RD\$${myFormat.format(summary['totalInvoiced'] ?? 0)}',
                Icons.receipt_long,
                Colors.white,
              ),
              _buildSummaryCard(
                'Total Pagado',
                'RD\$${myFormat.format(summary['totalPaid'] ?? 0)}',
                Icons.check_circle,
                Colors.green.shade300,
              ),
              _buildSummaryCard(
                'Pendiente',
                'RD\$${myFormat.format(summary['totalPending'] ?? 0)}',
                Icons.pending,
                (summary['totalPending'] ?? 0) > 0 ? Colors.orange.shade300 : Colors.green.shade300,
              ),
              _buildSummaryCard(
                'Facturas',
                '${summary['invoiceCount'] ?? 0}',
                Icons.description,
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color valueColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: valueColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade700,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt, size: 18),
                      const SizedBox(width: 6),
                      Text('Facturas (${_invoices.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payments, size: 18),
                      const SizedBox(width: 6),
                      Text('Pagos (${_payments.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event, size: 18),
                      const SizedBox(width: 6),
                      Text('Reservas (${_reservations.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoicesTab(),
                _buildPaymentsTab(),
                _buildReservationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    if (_invoices.isEmpty) {
      return _buildEmptyState('No hay facturas', Icons.receipt_long);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _invoices.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        final dueAmount = (invoice['dueAmount'] ?? 0).toDouble();
        final isPaid = invoice['isPaid'] == true || dueAmount <= 0;
        final isPartial = !isPaid && (invoice['paidAmount'] ?? 0) > 0;

        String statusLabel;
        Color statusColor;
        IconData statusIcon;
        if (isPaid) {
          statusLabel = 'Pagado';
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else if (isPartial) {
          statusLabel = 'Parcial';
          statusColor = Colors.orange;
          statusIcon = Icons.timelapse;
        } else {
          statusLabel = 'Pendiente';
          statusColor = Colors.red;
          statusIcon = Icons.pending;
        }

        final date = invoice['saleDate'] != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(invoice['saleDate']))
            : invoice['createdAt'] != null
                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(invoice['createdAt']))
                : 'N/A';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: InkWell(
            onTap: () => _printInvoice(invoice),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '#${invoice['invoiceNumber']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  invoice['paymentMethod'] ?? 'Venta',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(date, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const Spacer(),
                Text(
                  'Total: RD\$${myFormat.format(invoice['total'] ?? 0)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                if (dueAmount > 0)
                  Text(
                    'Pend: RD\$${myFormat.format(dueAmount)}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return _buildEmptyState('No hay pagos registrados', Icons.payments);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final date = payment['createdAt'] != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(payment['createdAt']))
            : 'N/A';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.payment, color: Colors.green.shade700, size: 20),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Eliminar pago',
            onPressed: () {
              _confirmarEliminarPago(context, payment, () {
                _loadProfile(); // Recargar el perfil después de eliminar
              });
            },
          ),
          title: Row(
            children: [
              Text(
                'Factura #${payment['invoiceNumber']}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                'RD\$${myFormat.format(payment['paidAmount'] ?? 0)}',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(date, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment['paymentType'] ?? 'N/A',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
                if (payment['bankName'] != null && payment['bankName'].toString().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    payment['bankName'],
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
                const Spacer(),
                Text(
                  payment['sellerName'] ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReservationsTab() {
    if (_reservations.isEmpty) {
      return _buildEmptyState('No hay reservas', Icons.event);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];
        final reservationId = reservation['id']?.toString() ?? '';

        // Usar Consumer para obtener datos completos de la reservación
        return Consumer(
          builder: (context, ref, _) {
            final fullReservationAsync = ref.watch(fullReservationByIdProviderVQ(reservationId));

            return fullReservationAsync.when(
              loading: () => _buildReservationCardSkeleton(),
              error: (_, __) => _buildReservationCard(reservation, reservationId, null, null),
              data: (fullReservation) {
                // Combinar datos del API customer-profile con datos completos del provider
                final mergedReservation = Map<String, dynamic>.from(reservation);
                if (fullReservation != null) {
                  // Agregar datos del provider que no vengan del API
                  final providerData = fullReservation.reservation;
                  mergedReservation['dresses_data'] = providerData['dresses_data'] ?? providerData['multiple_dress'] ?? providerData['dress_ids'];
                  mergedReservation['service_name'] = providerData['service_name'] ?? fullReservation.service?['name'];
                }
                return _buildReservationCard(mergedReservation, reservationId, fullReservation, ref);
              },
            );
          },
        );
      },
    );
  }

  /// Skeleton mientras carga la card
  Widget _buildReservationCardSkeleton() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 20, width: 150, color: Colors.grey[200]),
            const SizedBox(height: 12),
            Container(height: 16, width: 200, color: Colors.grey[200]),
            const SizedBox(height: 8),
            Container(height: 16, width: 180, color: Colors.grey[200]),
          ],
        ),
      ),
    );
  }

  /// Helper para obtener valor de múltiples posibles claves (snake_case y camelCase)
  String _getField(Map<String, dynamic> map, List<String> keys, [String defaultValue = '']) {
    for (final key in keys) {
      if (map[key] != null && map[key].toString().isNotEmpty) {
        return map[key].toString();
      }
    }
    return defaultValue;
  }

  /// Construye una card de reservación estilo calendario
  Widget _buildReservationCard(Map<String, dynamic> reservation, String reservationId, FullReservation? fullReservation, WidgetRef? ref) {
    // Formatear fecha - buscar en múltiples claves
    String formattedDate = 'N/A';
    final dateStr = _getField(reservation, ['reservation_date', 'reservationDate']);
    try {
      if (dateStr.isNotEmpty) {
        formattedDate = dateStr.split('T')[0];
      }
    } catch (_) {}

    // Hora - buscar en múltiples fuentes y formatear a 12 horas
    var rawTime = _getField(reservation, ['reservation_time', 'startTime']);
    // Si no hay hora en reservation, buscar en fullReservation
    if (rawTime.isEmpty && fullReservation != null) {
      rawTime = fullReservation.reservation['reservation_time']?.toString() ?? '';
    }
    String startTime = rawTime;
    if (rawTime.isNotEmpty) {
      try {
        // Intentar parsear formato 24h (ej: "14:00" o "14:00:00")
        final parts = rawTime.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          final minute = parts[1];
          final period = hour >= 12 ? 'PM' : 'AM';
          if (hour > 12) hour -= 12;
          if (hour == 0) hour = 12;
          startTime = '$hour:$minute $period';
        }
      } catch (_) {
        // Si falla el parseo, usar el valor original
      }
    }

    // Servicio/Paquete
    final serviceName = _getField(reservation, ['service_name', 'serviceName', 'packageType', 'tipoSesion'], 'Sesión');
    final lowerName = serviceName.toLowerCase();

    // Determinar tipo de reservación para colores
    final isPreQuinceFiesta = lowerName.contains('pre-quince') && lowerName.contains('fiesta');
    final isFiestaDate = reservation['is_fiesta_date'] == true || reservation['isFiestaDate'] == true;
    final isFiesta = isPreQuinceFiesta ? isFiestaDate : lowerName.contains('fiesta');
    final isEstudio = isPreQuinceFiesta ? !isFiestaDate : lowerName.contains('estudio');
    final isExterior = lowerName.contains('exterior');
    final isRenta = lowerName.contains('renta') || lowerName.contains('vestimenta');

    // Determinar estado (pasado, próximo, por vencer)
    final now = DateTime.now();
    DateTime? reservationDateTime;
    try {
      if (dateStr.isNotEmpty) {
        reservationDateTime = DateTime.parse(dateStr.split('T')[0]);
      }
    } catch (_) {}

    bool isPast = reservationDateTime != null && reservationDateTime.isBefore(DateTime(now.year, now.month, now.day));
    bool isAboutToExpire = reservationDateTime != null &&
        reservationDateTime.isAfter(DateTime(now.year, now.month, now.day - 1)) &&
        reservationDateTime.isBefore(DateTime(now.year, now.month, now.day + 3));

    // Colores y texto según tipo y estado
    Color statusColor;
    IconData statusIcon;
    String statusText;
    Color? cardBgColor;

    if (isPast) {
      if (isFiesta) {
        statusColor = Colors.amber;
        statusIcon = Icons.celebration;
        statusText = 'Fiesta pasada';
        cardBgColor = Colors.amber.withValues(alpha: 0.10);
      } else if (isEstudio) {
        statusColor = Colors.blue;
        statusIcon = Icons.camera_alt;
        statusText = 'Estudio pasado';
        cardBgColor = Colors.blue.withValues(alpha: 0.10);
      } else if (isExterior) {
        statusColor = Colors.purple;
        statusIcon = Icons.landscape;
        statusText = 'Exterior pasado';
        cardBgColor = Colors.purple.withValues(alpha: 0.10);
      } else if (isRenta) {
        statusColor = const Color(0xFF4CAF50).withValues(alpha: 0.7);
        statusIcon = Icons.checkroom;
        statusText = 'Renta pasada';
        cardBgColor = const Color(0xFF4CAF50).withValues(alpha: 0.05);
      } else {
        statusColor = Colors.grey;
        statusIcon = Icons.history;
        statusText = 'Pasada';
        cardBgColor = Colors.grey.withValues(alpha: 0.08);
      }
    } else if (isAboutToExpire) {
      if (isFiesta) {
        statusColor = Colors.amber;
        statusIcon = Icons.celebration;
        statusText = 'Fiesta próxima';
        cardBgColor = Colors.amber.withValues(alpha: 0.15);
      } else if (isEstudio) {
        statusColor = Colors.blue;
        statusIcon = Icons.camera_alt;
        statusText = 'Estudio próximo';
        cardBgColor = Colors.blue.withValues(alpha: 0.15);
      } else if (isExterior) {
        statusColor = Colors.purple;
        statusIcon = Icons.landscape;
        statusText = 'Exterior próximo';
        cardBgColor = Colors.purple.withValues(alpha: 0.15);
      } else if (isRenta) {
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.checkroom;
        statusText = 'Renta próxima';
        cardBgColor = const Color(0xFF4CAF50).withValues(alpha: 0.15);
      } else {
        statusColor = Colors.orange;
        statusIcon = Icons.event_available;
        statusText = 'Próxima';
        cardBgColor = Colors.orange.withValues(alpha: 0.10);
      }
    } else {
      if (isFiesta) {
        statusColor = Colors.amber;
        statusIcon = Icons.celebration;
        statusText = 'Fiesta';
        cardBgColor = Colors.amber.withValues(alpha: 0.10);
      } else if (isEstudio) {
        statusColor = Colors.blue;
        statusIcon = Icons.camera_alt;
        statusText = 'Estudio';
        cardBgColor = Colors.blue.withValues(alpha: 0.10);
      } else if (isExterior) {
        statusColor = Colors.purple;
        statusIcon = Icons.landscape;
        statusText = 'Exterior';
        cardBgColor = Colors.purple.withValues(alpha: 0.10);
      } else if (isRenta) {
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.checkroom;
        statusText = 'Renta';
        cardBgColor = const Color(0xFF4CAF50).withValues(alpha: 0.12);
      } else {
        statusColor = Colors.green;
        statusIcon = Icons.event_available;
        statusText = 'Próxima';
        cardBgColor = Colors.green.withValues(alpha: 0.10);
      }
    }

    // Vestidos - buscar en múltiples claves (primero en fullReservation si está disponible)
    List<Map<String, dynamic>> dressComposite = [];
    var dressesRaw = fullReservation?.reservation['dresses_data'] ?? fullReservation?.reservation['multiple_dress'] ?? [];
    if (dressesRaw is! List || dressesRaw.isEmpty) {
      dressesRaw = reservation['dresses_data'] ?? reservation['dressesData'] ?? reservation['multiple_dress'] ?? [];
    }
    if (dressesRaw is List && dressesRaw.isNotEmpty) {
      dressComposite = List<Map<String, dynamic>>.from(
        dressesRaw.map((d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{})
      );
    }
    final vestido = _getField(reservation, ['vestido', 'dress_name']);

    // Lugar y nota (limpiar JSON de asignaciones)
    final place = _getField(reservation, ['place', 'ubicacion']);
    final nota = ReservationModel.cleanNotaText(_getField(reservation, ['nota', 'notes']));

    // Precio del paquete
    final packagePrice = _getField(reservation, ['package_price', 'packagePrice']);

    // Número de factura y saldo - obtener desde provider si está disponible
    String invoiceNumber = _getField(reservation, ['invoice_number', 'invoiceNumber']);
    double dueAmount = double.tryParse(_getField(reservation, ['due_amount', 'dueAmount'], '0')) ?? 0;

    // Intentar obtener datos frescos del provider si está disponible
    if (ref != null) {
      final saleAsync = ref.watch(saleTransactionByReservationProvider(reservationId));
      if (saleAsync.hasValue && saleAsync.value != null) {
        final sale = saleAsync.value!;
        final saleInvoice = sale.invoiceNumber;
        final saleDue = sale.dueAmount;
        if (saleInvoice != null && saleInvoice.isNotEmpty) {
          invoiceNumber = saleInvoice;
        }
        if (saleDue != null && saleDue > 0) {
          dueAmount = saleDue;
        }
      }
    }
    final hasDueAmount = dueAmount > 0;

    // Vendedor - buscar en reservation o en fullReservation
    var sellerName = _getField(reservation, ['seller_name', 'sellerName']);
    if (sellerName.isEmpty && fullReservation != null) {
      sellerName = fullReservation.reservation['seller_name']?.toString() ?? '';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: cardBgColor,
      child: InkWell(
        onTap: () => _showReservationDetailsModal(reservationId, reservation),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila 1: Fecha/Hora + Badge de estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$formattedDate${startTime.isNotEmpty ? ' - $startTime' : ''}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (isFiestaDate)
                                Text(
                                  '(Fecha de fiesta)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color.fromARGB(255, 73, 47, 1),
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              // Badge de factura
                              if (invoiceNumber.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: hasDueAmount
                                          ? [const Color(0xFFE57373), const Color(0xFFEF5350)]
                                          : [const Color(0xFF66BB6A), const Color(0xFF4CAF50)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (hasDueAmount
                                            ? const Color(0xFFE57373)
                                            : const Color(0xFF66BB6A)).withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        hasDueAmount ? Icons.payment : Icons.check_circle,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Factura: $invoiceNumber',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (hasDueAmount)
                                            Text(
                                              'Saldo: \$${myFormat.format(dueAmount)}',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(statusText),
                    avatar: Icon(statusIcon, size: 16, color: Colors.white),
                    backgroundColor: statusColor,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Vestidos
              if (dressComposite.isNotEmpty)
                _buildDressesInfo(dressComposite)
              else if (vestido.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.checkroom, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Vestido: $vestido', style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Servicio
              Row(
                children: [
                  Icon(Icons.engineering, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Servicio: $serviceName', style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),

              // Lugar
              if (place.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.place, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Lugar: $place', style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ],

              // Nota
              if (nota.isNotEmpty && nota != 'Sin notas') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.textsms_outlined, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Nota: $nota', style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ],

              // Precio y vendedor en fila inferior
              if (packagePrice.isNotEmpty && packagePrice != '0' || sellerName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (packagePrice.isNotEmpty && packagePrice != '0') ...[
                      Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text('RD\$$packagePrice', style: TextStyle(fontSize: 13, color: Colors.green[700], fontWeight: FontWeight.w500)),
                    ],
                    const Spacer(),
                    if (sellerName.isNotEmpty) ...[
                      Icon(Icons.person_outline, size: 14, color: Colors.grey[800]),
                      const SizedBox(width: 4),
                      Text(sellerName, style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la información de vestidos como en el calendario
  Widget _buildDressesInfo(List<Map<String, dynamic>> dressComposite) {
    final dressNames = dressComposite.map((d) {
      return d['dress_name']?.toString() ?? d['name']?.toString() ?? '';
    }).where((name) => name.isNotEmpty).toList();

    if (dressNames.isEmpty) {
      return const SizedBox.shrink();
    }

    if (dressNames.length == 1) {
      return Row(
        children: [
          Icon(Icons.checkroom, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Vestido: ${dressNames.first}', style: const TextStyle(fontSize: 14)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checkroom, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text('Vestidos (${dressNames.length}):',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        ...dressNames.map((name) => Padding(
          padding: const EdgeInsets.only(left: 24, top: 4),
          child: Text('• $name', style: const TextStyle(fontSize: 13)),
        )),
      ],
    );
  }

  /// Modal flotante de detalles de la reservación con los datos ya cargados
  void _showReservationDetailsModal(String reservationId, Map<String, dynamic> reservationData) {
    debugPrint('📋 [_showReservationDetailsModal] reservationId: "$reservationId"');
    debugPrint('📋 [_showReservationDetailsModal] reservationData keys: ${reservationData.keys.toList()}');

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: _ReservationDetailContent(
          reservationId: reservationId,
          reservationData: reservationData,
          customer: _customer,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmar eliminación de pago con clave de autorización
  void _confirmarEliminarPago(
    BuildContext context,
    Map<String, dynamic> pago,
    VoidCallback onSuccess,
  ) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              const Text('Eliminar Pago'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Está seguro de eliminar este pago?',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                    ),
                    const SizedBox(height: 8),
                    Text('Factura: #${pago['invoiceNumber']}'),
                    Text('Monto: RD\$${myFormat.format(pago['paidAmount'] ?? 0)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Esta acción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• Revertirá el saldo del cliente'),
              const Text('• Actualizará la factura como pendiente'),
              const Text('• Esta acción NO se puede deshacer'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Clave de eliminación',
                  hintText: 'Ingrese la clave de autorización',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  EasyLoading.showError('Ingrese la clave de autorización');
                  return;
                }

                // Validar clave
                final isValid = await DeletionPasswordService.validatePassword(password);

                if (isValid) {
                  Navigator.of(dialogContext).pop();
                  _ejecutarEliminarPago(context, pago, onSuccess);
                } else {
                  EasyLoading.showError('Clave incorrecta');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar Pago'),
            ),
          ],
        );
      },
    );
  }

  /// Ejecutar la eliminación del pago
  void _ejecutarEliminarPago(
    BuildContext context,
    Map<String, dynamic> pago,
    VoidCallback onSuccess,
  ) async {
    try {
      EasyLoading.show(status: 'Eliminando pago...');

      final apiService = ApiService();
      final montoRevertir = double.tryParse(pago['paidAmount']?.toString() ?? '0') ?? 0;
      final pagoId = pago['id']?.toString() ?? '';
      final invoiceNumber = pago['invoiceNumber']?.toString() ?? '';
      final clientePhone = _customer?['phone']?.toString() ?? '';

      // 1. Eliminar el registro de due_transactions
      if (pagoId.isNotEmpty) {
        final deleteResponse = await apiService.delete('due-transactions/$pagoId');
        if (!deleteResponse.success) {
          throw Exception('Error al eliminar el pago: ${deleteResponse.message}');
        }
      }

      // 2. Eliminar el registro de daily_transactions asociado
      try {
        final dailyResponse = await apiService.get('daily-transactions', queryParams: {
          'invoiceNumber': invoiceNumber,
        });

        if (dailyResponse.success && dailyResponse.data != null) {
          final transactions = dailyResponse.data['dailyTransactions'] as List<dynamic>? ?? 
                               dailyResponse.data['daily_transactions'] as List<dynamic>? ?? [];
                               
          for (var tx in transactions) {
            final txId = tx['id']?.toString();
            final type = tx['type']?.toString();
            final paymentIn = double.tryParse(tx['paymentIn']?.toString() ?? tx['payment_in']?.toString() ?? '0') ?? 0;
            final paymentOut = double.tryParse(tx['paymentOut']?.toString() ?? tx['payment_out']?.toString() ?? '0') ?? 0;
            
            bool isMatch = false;
            // Para clientes, buscar en paymentIn
            if (type == 'Due Collection' && paymentIn == montoRevertir) {
              isMatch = true;
            } 
            // Para proveedores, buscar en paymentOut
            else if (type == 'Due Payment' && paymentOut == montoRevertir) {
              isMatch = true;
            }

            if (txId != null && txId.isNotEmpty && isMatch) {
              await apiService.delete('daily-transactions/$txId');
              break; // IMPORTANTE: Solo borrar un registro
            }
          }
        }
      } catch (e) {
        debugPrint('Warning: No se pudo eliminar daily_transaction: $e');
      }

      // 3. Actualizar el due_amount de la factura original
      try {
        final salesResponse = await apiService.get('sales', queryParams: {
          'invoiceNumber': invoiceNumber,
        });

        if (salesResponse.success && salesResponse.data != null) {
          final sales = salesResponse.data['sales'] as List<dynamic>? ?? [];
          if (sales.isNotEmpty) {
            final sale = sales.first;
            final saleId = sale['id']?.toString();
            final currentDueAmount = double.tryParse(sale['due_amount']?.toString() ?? '0') ?? 0;
            final currentPaidAmount = double.tryParse(sale['paid_amount']?.toString() ?? '0') ?? 0;
            final newDueAmount = currentDueAmount + montoRevertir;
            final newPaidAmount = currentPaidAmount - montoRevertir;

            if (saleId != null && saleId.isNotEmpty) {
              await apiService.put('sales/$saleId', {
                'due_amount': newDueAmount,
                'paid_amount': newPaidAmount,
                'is_paid': newDueAmount <= 0,
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Warning: No se pudo actualizar due_amount de la factura: $e');
      }

      // 4. Actualizar el saldo del cliente
      try {
        if (clientePhone.isNotEmpty) {
          final customerResponse = await apiService.get('customers', queryParams: {
            'phone': clientePhone,
          });

          if (customerResponse.success && customerResponse.data != null) {
            final customers = customerResponse.data['customers'] as List<dynamic>? ?? [];
            if (customers.isNotEmpty) {
              final customer = customers.first;
              final customerId = customer['id']?.toString();
              final currentDue = double.tryParse(customer['due']?.toString() ?? '0') ?? 0;
              final newDue = currentDue + montoRevertir;

              if (customerId != null && customerId.isNotEmpty) {
                await apiService.put('customers/$customerId', {
                  'due': newDue,
                });
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Warning: No se pudo actualizar saldo del cliente: $e');
      }

      EasyLoading.dismiss();
      EasyLoading.showSuccess('Pago eliminado correctamente');

      // Llamar callback para refrescar la lista
      onSuccess();

    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error: $e');
      debugPrint('Error al eliminar pago: $e');
    }
  }
}

/// Widget que muestra los detalles de una reservación usando el provider del calendario
class _ReservationDetailContent extends ConsumerWidget {
  final String reservationId;
  final Map<String, dynamic> reservationData; // Datos básicos como fallback
  final Map<String, dynamic>? customer;
  final VoidCallback onClose;

  const _ReservationDetailContent({
    required this.reservationId,
    required this.reservationData,
    required this.customer,
    required this.onClose,
  });

  /// Helper para obtener valor de múltiples posibles claves
  String _getField(Map<String, dynamic> map, List<String> keys, [String defaultValue = '']) {
    for (final key in keys) {
      if (map[key] != null && map[key].toString().isNotEmpty) {
        return map[key].toString();
      }
    }
    return defaultValue;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🔍 [_ReservationDetailContent] reservationId: $reservationId');

    // Usar el provider del calendario para obtener datos completos
    final fullReservationAsync = ref.watch(fullReservationByIdProviderVQ(reservationId));

    // Balance pendiente del cliente
    final dueAmount = double.tryParse(customer?['due_amount']?.toString() ?? customer?['dueAmount']?.toString() ?? '0') ?? 0;

    return Container(
      constraints: BoxConstraints(
        maxWidth: 650,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con botón cerrar
          _buildHeader(context),

          // Alerta de balance pendiente
          if (dueAmount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Balance pendiente: RD\$${myFormat.format(dueAmount)}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Contenido principal con datos del provider
          Expanded(
            child: fullReservationAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                debugPrint('❌ Error cargando reservación: $error');
                // En caso de error, mostrar datos básicos del reservationData
                return _buildContentFromBasicData(context);
              },
              data: (fullReservation) {
                if (fullReservation == null) {
                  debugPrint('⚠️ fullReservation es null, usando datos básicos');
                  return _buildContentFromBasicData(context);
                }

                debugPrint('✅ fullReservation cargado correctamente');
                debugPrint('📋 Reservation keys: ${fullReservation.reservation.keys.toList()}');
                debugPrint('👗 Dress: ${fullReservation.dress}');
                debugPrint('📸 Service: ${fullReservation.service}');
                debugPrint('👤 Client: ${fullReservation.client?.customerName}');

                return _buildContentFromFullReservation(context, fullReservation);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Header del modal
  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Detalles de la Reservación',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            icon: const Icon(Icons.close, size: 28, color: Colors.grey),
            onPressed: onClose,
          ),
        ),
      ],
    );
  }

  /// Construir contenido desde datos completos del provider (calendario)
  Widget _buildContentFromFullReservation(BuildContext context, FullReservation fullRes) {
    final res = fullRes.reservation;
    final dress = fullRes.dress;
    final service = fullRes.service;
    final client = fullRes.client;

    // Extraer campos
    final dateStr = _getField(res, ['reservation_date', 'reservationDate'], '');
    String formattedDate = dateStr;
    try {
      if (dateStr.isNotEmpty) {
        final date = DateFormat('yyyy-MM-dd').parse(dateStr.split('T')[0]);
        formattedDate = DateFormat.yMMMMd('es').format(date);
      }
    } catch (_) {}

    final reservationTime = _getField(res, ['reservation_time', 'reservationTime'], '');
    final branchId = _getField(res, ['branch_id', 'branchId'], '');
    final place = _getField(res, ['place', 'lugar'], 'Sin lugar');
    final notaRaw = _getField(res, ['nota', 'notes'], '');
    final nota = ReservationModel.cleanNotaText(notaRaw).isEmpty ? 'Sin notas' : ReservationModel.cleanNotaText(notaRaw);
    final packagePrice = _getField(res, ['package_price', 'packagePrice'], '0');

    // Servicio
    final serviceName = service?['name'] ?? service?['serviceName'] ?? _getField(res, ['service_name', 'serviceName'], '');
    final serviceCategory = service?['category'] ?? '';
    final serviceDescription = service?['description'] ?? '';

    // Vestidos
    // Vestidos - buscar en múltiples campos posibles
    var dressComposite = res['multiple_dress'] ?? [];
    if (dressComposite is! List || dressComposite.isEmpty) {
      dressComposite = res['dresses_data'] ?? [];
    }
    if (dressComposite is! List || dressComposite.isEmpty) {
      dressComposite = res['dress_ids'] ?? [];
    }

    // DEBUG: Ver qué campos tienen datos
    debugPrint('🔍 [_buildContentFromFullReservation] res keys: ${res.keys.toList()}');
    debugPrint('🔍 [_buildContentFromFullReservation] multiple_dress: ${res['multiple_dress']}');
    debugPrint('🔍 [_buildContentFromFullReservation] dresses_data: ${res['dresses_data']}');
    debugPrint('🔍 [_buildContentFromFullReservation] dress_ids: ${res['dress_ids']}');
    debugPrint('🔍 [_buildContentFromFullReservation] dressComposite final: $dressComposite');

    // Adicionales
    final aditionals = res['aditionals'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Imagen del vestido principal
          if (dress != null && dress['images'] != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildDressImage(dress['images']),
            ),
            const SizedBox(height: 16),
          ],

          // Sección: Información de la Reservación
          _buildSection(context, title: 'Información de la Reservación', children: [
            _buildDetailItem(Icons.calendar_today, 'Fecha', formattedDate),
            _buildDetailItem(Icons.access_time, 'Hora', _formatReservationTime(reservationTime)),
            _buildDetailItem(Icons.business, 'Sucursal', branchId),
            _buildDetailItem(Icons.place, 'Lugar', place),
            _buildDetailItem(Icons.textsms_outlined, 'Notas', nota),
            if (packagePrice != '0')
              _buildDetailItem(Icons.attach_money, 'Precio Paquete', 'RD\$${myFormat.format(double.tryParse(packagePrice) ?? 0)}'),
          ]),

          // Sección: Información del Cliente
          _buildSection(context, title: 'Información del Cliente', children: [
            _buildDetailItem(Icons.person, 'Nombre', client?.customerName ?? customer?['customer_name']?.toString() ?? 'N/A'),
            _buildDetailItem(Icons.phone, 'Teléfono', client?.phoneNumber ?? customer?['phone_number']?.toString() ?? 'N/A'),
            if (client?.emailAddress.isNotEmpty == true)
              _buildDetailItem(Icons.email, 'Email', client!.emailAddress),
          ]),

          // Sección: Vestimenta y Paquete
          if (serviceName.isNotEmpty || (dressComposite is List && dressComposite.isNotEmpty))
            _buildSection(context, title: 'Información de Vestimenta y Paquete', children: [
              if (serviceName.isNotEmpty)
                _buildDetailItem(Icons.photo_camera, 'Paquete/Servicio', serviceName),
              if (serviceCategory.isNotEmpty)
                _buildDetailItem(Icons.category, 'Categoría', serviceCategory),
              if (dressComposite is List && dressComposite.isNotEmpty)
                _buildDressList(context, dressComposite),
            ]),

          // Sección: Información del Servicio
          if (service != null && serviceDescription.isNotEmpty)
            _buildSection(context, title: 'Descripción del Servicio', children: [
              _buildDetailItem(Icons.description, 'Descripción', serviceDescription),
            ]),

          // Sección: Adicionales
          if (aditionals.isNotEmpty)
            _buildSection(context, title: 'Adicionales (${aditionals.length})', children: [
              ...aditionals.map((aditional) => _buildAditionalItem(context, aditional)),
            ]),
        ],
      ),
    );
  }

  /// Construir contenido desde datos básicos (fallback)
  Widget _buildContentFromBasicData(BuildContext context) {
    final dateStr = _getField(reservationData, ['reservation_date', 'reservationDate'], '');
    String formattedDate = dateStr;
    try {
      if (dateStr.isNotEmpty) {
        final date = DateFormat('yyyy-MM-dd').parse(dateStr.split('T')[0]);
        formattedDate = DateFormat.yMMMMd('es').format(date);
      }
    } catch (_) {}

    final reservationTime = _getField(reservationData, ['reservation_time', 'reservationTime'], '');
    final branchId = _getField(reservationData, ['branch_id', 'branchId'], '');
    final place = _getField(reservationData, ['place', 'lugar'], 'Sin lugar');
    final notaRaw2 = _getField(reservationData, ['nota', 'notes'], '');
    final nota = ReservationModel.cleanNotaText(notaRaw2).isEmpty ? 'Sin notas' : ReservationModel.cleanNotaText(notaRaw2);
    final serviceName = _getField(reservationData, ['service_name', 'serviceName'], '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection(context, title: 'Información de la Reservación', children: [
            _buildDetailItem(Icons.calendar_today, 'Fecha', formattedDate),
            _buildDetailItem(Icons.access_time, 'Hora', _formatReservationTime(reservationTime)),
            _buildDetailItem(Icons.business, 'Sucursal', branchId),
            _buildDetailItem(Icons.place, 'Lugar', place),
            _buildDetailItem(Icons.textsms_outlined, 'Notas', nota),
          ]),
          _buildSection(context, title: 'Información del Cliente', children: [
            _buildDetailItem(Icons.person, 'Nombre', customer?['customer_name']?.toString() ?? 'N/A'),
            _buildDetailItem(Icons.phone, 'Teléfono', customer?['phone_number']?.toString() ?? 'N/A'),
          ]),
          if (serviceName.isNotEmpty)
            _buildSection(context, title: 'Servicio', children: [
              _buildDetailItem(Icons.photo_camera, 'Paquete/Servicio', serviceName),
            ]),
        ],
      ),
    );
  }

  /// Construir item de adicional
  Widget _buildAditionalItem(BuildContext context, Map<String, dynamic> aditional) {
    final adicNota = ReservationModel.cleanNotaText(aditional['nota']?.toString());
    final adicPrice = aditional['package_price']?.toString() ?? '0';
    final adicDate = aditional['reservation_date']?.toString() ?? '';
    final adicTime = aditional['reservation_time']?.toString() ?? '';

    var adicDresses = aditional['multiple_dress'] as List<dynamic>? ?? [];
    if (adicDresses.isEmpty) adicDresses = aditional['dresses_data'] as List<dynamic>? ?? [];
    if (adicDresses.isEmpty) adicDresses = aditional['dress_ids'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_circle_outline, size: 22, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicional - RD\$${myFormat.format(double.tryParse(adicPrice) ?? 0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (adicDate.isNotEmpty)
                      Text(
                        'Fecha: ${adicDate.split('T')[0]} ${adicTime.isNotEmpty ? '- ${_formatReservationTime(adicTime)}' : ''}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    if (adicNota.isNotEmpty)
                      Text(
                        'Nota: $adicNota',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (adicDresses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 34),
              child: _buildDressList(context, adicDresses),
            ),
          const Divider(height: 20),
        ],
      ),
    );
  }

  /// Construye la imagen del vestido
  Widget _buildDressImage(dynamic images) {
    String imageUrl = '';
    if (images is List && images.isNotEmpty) {
      imageUrl = images.first.toString();
    } else if (images is String && images.isNotEmpty) {
      imageUrl = images;
    }

    if (imageUrl.isEmpty) return const SizedBox.shrink();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 200,
      height: 200,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Icon(Icons.image_not_supported, color: Colors.grey[400], size: 50),
    );
  }

  /// Construye la lista de vestidos de forma simple
  /// Construye la lista de vestidos usando Consumer para buscar imágenes del provider
  Widget _buildDressList(BuildContext context, List<dynamic> dresses) {
    return Consumer(
      builder: (context, ref, _) {
        final dressesAsync = ref.watch(dressesByStatusProvider('Todos'));
        return dressesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
          data: (dressesList) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: dresses.map<Widget>((item) {
                final dressName = (item['dress_name'] ?? item['name'] ?? 'Sin nombre').toString();
                final branchId = (item['branch_id'] ?? '').toString();

                // Buscar el vestido por nombre y sucursal para obtener la imagen
                DressModel? match;
                try {
                  match = dressesList.firstWhere(
                    (d) => d.name.toString().removeAllWhiteSpace().toLowerCase() ==
                           dressName.removeAllWhiteSpace().toLowerCase() &&
                           d.branchId.toString() == branchId,
                  );
                } catch (_) {
                  // Intentar solo por nombre si no hay match por sucursal
                  try {
                    match = dressesList.firstWhere(
                      (d) => d.name.toString().removeAllWhiteSpace().toLowerCase() ==
                             dressName.removeAllWhiteSpace().toLowerCase(),
                    );
                  } catch (_) {
                    match = null;
                  }
                }

                // Obtener imagen - primero del match, luego del item
                String imageUrl = '';
                if (match != null && match.images.isNotEmpty) {
                  imageUrl = match.images.first.toString();
                } else if (item['image'] != null && item['image'].toString().isNotEmpty) {
                  imageUrl = item['image'].toString();
                } else if (item['images'] != null) {
                  if (item['images'] is List && (item['images'] as List).isNotEmpty) {
                    imageUrl = item['images'][0].toString();
                  } else if (item['images'] is String && item['images'].toString().isNotEmpty) {
                    imageUrl = item['images'].toString().split(',').first.trim().replaceAll(RegExp(r'[\[\]"]'), '');
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.checkroom, size: 22, color: Colors.grey[700]),
                      const SizedBox(width: 12),
                      if (imageUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showImageDialog(context, imageUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[200],
                                child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 24),
                              ),
                            ),
                          ),
                        ),
                      if (imageUrl.isNotEmpty) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dressName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            if (branchId.isNotEmpty)
                              Text(branchId, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  /// Construye una sección con título y contenido
  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Construye un item de detalle con icono, título y valor
  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la lista de vestidos con imágenes
  Widget _buildDressCompositeItem(BuildContext context, WidgetRef ref, List<dynamic> dressComposite) {
    final dressesAsync = ref.watch(dressesByStatusProvider('Todos'));

    return dressesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error al cargar vestidos: $e'),
      data: (dressesList) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: dressComposite.map<Widget>((item) {
            final dressName = (item['dress_name'] ?? item['name'] ?? 'Sin nombre').toString();
            final branchId = (item['branch_id'] ?? '').toString();

            // Buscar imagen del vestido
            DressModel? match;
            try {
              match = dressesList.firstWhere(
                (d) => d.name.toString().removeAllWhiteSpace().toLowerCase() == dressName.removeAllWhiteSpace().toLowerCase() &&
                    d.branchId.toString() == branchId,
              );
            } catch (_) {
              match = null;
            }

            String imageUrl = '';
            if (match != null && match.images.isNotEmpty) {
              imageUrl = match.images.first.toString();
            } else if (item['image'] != null && item['image'].toString().isNotEmpty) {
              imageUrl = item['image'].toString();
            } else if (item['images'] != null) {
              if (item['images'] is List && (item['images'] as List).isNotEmpty) {
                imageUrl = item['images'][0].toString();
              } else if (item['images'] is String && item['images'].toString().isNotEmpty) {
                imageUrl = item['images'].toString().split(',').first.trim().replaceAll(RegExp(r'[\[\]"]'), '');
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.checkroom, size: 22, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  if (imageUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showImageDialog(context, imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(Icons.image_not_supported, color: Colors.grey[400], size: 24),
                        ),
                      ),
                    ),
                  if (imageUrl.isNotEmpty) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dressName, style: const TextStyle(fontSize: 16)),
                        Text(branchId, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Muestra un diálogo con la imagen ampliada
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  /// Formatea la hora de reservación
  String _formatReservationTime(String time) {
    if (time.isEmpty) return time;
    try {
      // Formato esperado: "HH:mm" o "HH:mm:ss"
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$hour12:$minute $period';
      }
      return time;
    } catch (e) {
      return time;
    }
  }
}
