import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../PDF/print_pdf.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/general_setting_provider.dart';
import '../../model/sale_transaction_model.dart';

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
        setState(() {
          _customer = response.data['customer'];
          _summary = response.data['financialSummary'];
          _invoices = response.data['invoices'] ?? [];
          _payments = response.data['payments'] ?? [];
          _reservations = response.data['reservations'] ?? [];
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
            child: customer['profilePicture'] != null && customer['profilePicture'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      customer['profilePicture'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                    ),
                  )
                : _buildAvatarPlaceholder(),
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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _reservations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final reservation = _reservations[index];
        final serviceDate = reservation['serviceDate'] != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(reservation['serviceDate']))
            : 'N/A';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.event, color: Colors.purple.shade700, size: 20),
          ),
          title: Text(
            reservation['packageName'] ?? 'Reserva',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Row(
            children: [
              Text('Fecha: $serviceDate'),
              if (reservation['sessionTime'] != null) ...[
                const SizedBox(width: 8),
                Text('- ${reservation['sessionTime']}'),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RD\$${myFormat.format(reservation['totalAmount'] ?? 0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                reservation['status'] ?? 'N/A',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
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
}
