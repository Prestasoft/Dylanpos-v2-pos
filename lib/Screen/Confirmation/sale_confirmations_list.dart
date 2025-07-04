import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../Provider/general_setting_provider.dart';
import '../../Provider/sale_confirmation_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../PDF/print_pdf.dart';
import '../../model/sale_confirmation_model.dart';
import '../../model/reservation_model.dart';

import '../Widgets/Constant Data/constant.dart';


class SaleConfirmationsScreen extends ConsumerStatefulWidget {
  const SaleConfirmationsScreen({super.key});

  @override
  ConsumerState<SaleConfirmationsScreen> createState() => _SaleConfirmationsScreenState();
}

class _SaleConfirmationsScreenState extends ConsumerState<SaleConfirmationsScreen> {
  int _itemsPerPage = 10;
  int _currentPage = 1;
  String _searchQuery = '';
  bool? _confirmedFilter;
  DateTimeRange? _dateRange;
  final ScrollController _scrollController = ScrollController();
  final Map<String, String> _reservationDates = {};

  @override
  void initState() {
    super.initState();
    // Refrescar los datos cuando se entra a la vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(saleConfirmationsProvider.notifier).refreshConfirmations();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = _dateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _currentPage = 1;
      });
    }
  }

  Future<String> _getReservationDate(String reservationId) async {
    if (_reservationDates.containsKey(reservationId)) {
      return _reservationDates[reservationId]!;
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('Admin Panel/reservations')
          .child(reservationId)
          .get();

      if (snapshot.exists) {
        final reservation = ReservationModel.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map), 
          reservationId
        );
        final date = reservation.reservationDate;
        _reservationDates[reservationId] = date;
        return date;
      }
      return 'No encontrada';
    } catch (e) {
      debugPrint('Error al obtener reservación: $e');
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kDarkWhite,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sección de Filtros
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: kWhite,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '📋 Lista de Confirmaciones',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: kMainColor,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  ref.read(saleConfirmationsProvider.notifier).refreshConfirmations();
                                  setState(() {
                                    _reservationDates.clear();
                                  });
                                },
                                tooltip: 'Refrescar datos',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Dropdown de items por página
                              Container(
                                width: 150,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: kBorderColorTextField),
                                ),
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  value: _itemsPerPage,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  items: [
                                    DropdownMenuItem(value: 10, child: Text('${lang.S.of(context).show} 10')),
                                    DropdownMenuItem(value: 20, child: Text('${lang.S.of(context).show} 20')),
                                    DropdownMenuItem(value: 50, child: Text('${lang.S.of(context).show} 50')),
                                    DropdownMenuItem(value: 100, child: Text('${lang.S.of(context).show} 100')),
                                    DropdownMenuItem(value: -1, child: Text(lang.S.of(context).all)),
                                  ],
                                  onChanged: (int? newValue) {
                                    setState(() {
                                      _itemsPerPage = newValue ?? 10;
                                      _currentPage = 1;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Campo de búsqueda
                              Expanded(
                                child: TextFormField(
                                  showCursor: true,
                                  cursorColor: kTitleColor,
                                  onChanged: (value) => setState(() => _searchQuery = value),
                                  keyboardType: TextInputType.name,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(10.0),
                                    hintText: lang.S.of(context).searchByName,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(color: kBorderColorTextField),
                                    ),
                                    suffixIcon: const Icon(FeatherIcons.search, color: kTitleColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Filtro por estado de confirmación
                              SizedBox(
                                width: 180,
                                child: DropdownButtonFormField<bool?>(
                                  value: _confirmedFilter,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(10.0),
                                    hintText: 'Filtrar por estado',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(color: kBorderColorTextField),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('Todas')),
                                    DropdownMenuItem(value: true, child: Text('Confirmadas')),
                                    DropdownMenuItem(value: false, child: Text('No confirmadas')),
                                  ],
                                  onChanged: (value) => setState(() {
                                    _confirmedFilter = value;
                                    _currentPage = 1;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Selector de rango de fechas
                              ElevatedButton.icon(
                                onPressed: () => _selectDateRange(context),
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  _dateRange == null 
                                    ? 'Rango de fechas'
                                    : '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kMainColor,
                                  minimumSize: const Size(180, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ]
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sección de la lista
                    Container(
                      constraints: BoxConstraints(
                        minHeight: screenSize.height * 0.7,
                        maxHeight: screenSize.height * 0.9,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: kWhite,
                      ),
                      child: _buildConfirmationsList(theme, screenSize),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmationsList(ThemeData theme, Size screenSize) {
    final confirmationsAsync = ref.watch(saleConfirmationsProvider);

    return confirmationsAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      error: (error, stack) {
        debugPrint('Error al cargar confirmaciones: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              Text('Error al cargar datos', style: theme.textTheme.titleMedium?.copyWith(color: Colors.red)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(error.toString(), textAlign: TextAlign.center),
              ),
              ElevatedButton(
                onPressed: () => ref.invalidate(saleConfirmationsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      },
      data: (confirmations) {
        // Aplicar filtros
        var filtered = confirmations.where((c) {
          final matchesSearch = _searchQuery.isEmpty ||
              c.saleData.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.saleId.toLowerCase().contains(_searchQuery.toLowerCase());

          final matchesStatus = _confirmedFilter == null || c.confirmed == _confirmedFilter;

          final matchesDate = _dateRange == null ||
              (DateTime.parse(c.createdAt).isAfter(_dateRange!.start) &&
                  DateTime.parse(c.createdAt).isBefore(_dateRange!.end));

          return matchesSearch && matchesStatus && matchesDate;
        }).toList();

        filtered.sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));

        final totalPages = (_itemsPerPage == -1) ? 1 : (filtered.length / _itemsPerPage).ceil();
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = _itemsPerPage == -1
            ? filtered.length
            : (startIndex + _itemsPerPage).clamp(0, filtered.length);
        final paginated = filtered.sublist(startIndex, endIndex);

        if (filtered.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt, size: 50, color: Colors.grey),
                SizedBox(height: 20),
                Text('No hay confirmaciones disponibles'),
                Text('Ajusta los filtros o crea nuevas confirmaciones'),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith(
                              (states) => kMainColor.withValues(alpha: 0.95)),
                          headingTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                          dataRowColor: MaterialStateColor.resolveWith((states) => Colors.white),
                          columnSpacing: 30,
                          horizontalMargin: 16,
                          columns: const [
                            DataColumn(label: Text('N°')),
                            DataColumn(label: Text('Cliente')),
                            DataColumn(label: Text('Factura N°')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('F. Facturación')),
                            DataColumn(label: Text('F. Reserva')),
                            DataColumn(label: Text('Estado')),
                          ],
                          rows: List.generate(paginated.length, (index) {
                            final confirmation = paginated[index];
                            final sale = confirmation.saleData;
                            final createdAt = DateTime.parse(confirmation.createdAt);
                            final expiresAt = DateTime.parse(confirmation.expiresAt);
                            final isExpired = expiresAt.isBefore(DateTime.now());

                            Color statusColor = confirmation.confirmed
                                ? Colors.green
                                : isExpired
                                    ? Colors.red
                                    : const Color(0xFFD59345);

                            String statusText = confirmation.confirmed
                                ? 'Confirmada'
                                : isExpired
                                    ? 'Expirada'
                                    : 'Pendiente';

                            // Obtener el primer ID de reservación si existe
                            final reservationId = sale.reservationIds.isNotEmpty 
                                ? sale.reservationIds.first 
                                : null;

                            return DataRow(cells: [
                              DataCell(Text('${startIndex + index + 1}')),
                              DataCell(Text(sale.customerName)),
                              (() {
                                bool isHovering = false;
                                return DataCell(
                                  StatefulBuilder(
                                    builder: (context, setState) => MouseRegion(
                                      onEnter: (_) => setState(() => isHovering = true),
                                      onExit: (_) => setState(() => isHovering = false),
                                      cursor: SystemMouseCursors.click,
                                      child: Tooltip(
                                        message: 'Ver factura',
                                        waitDuration: Duration(milliseconds: 200),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(4),
                                          onTap: () async {
                                            final ref = ProviderScope.containerOf(context);
                                            final setting = await ref.read(generalSettingProvider.future);
                                            final profileInfo = await ref.read(profileDetailsProvider.future);
                                            final saleData = sale;
                                            try {
                                              EasyLoading.show(status: 'Preparando vista previa...');
                                              await GeneratePdfAndPrint().printSaleInvoice(
                                                setting: setting,
                                                personalInformationModel: profileInfo,
                                                saleTransactionModel: saleData,
                                                context: context,
                                                printType: 'normal',
                                                fromSaleReports: true,
                                                post: saleData,
                                              );
                                              EasyLoading.dismiss();
                                            } catch (e) {
                                              EasyLoading.dismiss();
                                              EasyLoading.showError('No se pudo generar el PDF: \n${e.toString()}');
                                            }
                                          },
                                          child: AnimatedContainer(
                                            duration: Duration(milliseconds: 150),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isHovering ? kMainColor.withValues(alpha: 0.25) : kMainColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : 'N/A',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: kMainColor,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              })(),
                              DataCell(Text(myFormat.format(sale.totalAmount))),
                              DataCell(Text(DateFormat('dd/MM/yyyy').format(createdAt))),
                              DataCell(
                                reservationId != null
                                    ? FutureBuilder<String>(
                                        future: _getReservationDate(reservationId),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            );
                                          }
                                          
                                          if (snapshot.hasError || snapshot.data == 'Error') {
                                            return Text(
                                              'Error',
                                              style: TextStyle(color: Colors.red),
                                            );
                                          }
                                          
                                          final dateString = snapshot.data;
                                          if (dateString == null || dateString.isEmpty || dateString == 'No encontrada') {
                                            return const Text('Sin reserva');
                                          }
                                          
                                          try {
                                            // Parsear la fecha y formatearla
                                            final dateTime = DateTime.parse(dateString);
                                            final formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
                                            return Text(
                                              formattedDate,
                                              style: TextStyle(color: kTitleColor),
                                            );
                                          } catch (e) {
                                            // Si hay error al parsear, mostrar el valor original
                                            debugPrint('Error formateando fecha: $e');
                                            return Text(
                                              dateString,
                                              style: TextStyle(color: Colors.orange),
                                            );
                                          }
                                        },
                                      )
                                    : const Text('Sin reserva'),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ]);
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            if (filtered.isNotEmpty) _buildPaginationControls(filtered.length, totalPages),
          ],
        );
      },
    );
  }

  Future<void> _confirmChangeStatus(SaleConfirmationModel confirmation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Venta'),
        content: const Text('¿Marcar esta venta como confirmada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final updated = confirmation.copyWith(
          confirmed: true,
          confirmationDate: DateTime.now().toIso8601String(),
        );
        await ref.read(saleConfirmationsProvider.notifier).updateConfirmation(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta confirmada exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(String token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Confirmación'),
        content: const Text('¿Estás seguro de eliminar esta confirmación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(saleConfirmationsProvider.notifier).deleteConfirmation(token);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirmación eliminada exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  Widget _buildPaginationControls(int totalItems, int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Mostrando ${((_currentPage - 1) * _itemsPerPage + 1)} hasta ${((_currentPage - 1) * _itemsPerPage + _itemsPerPage).clamp(0, totalItems)} de $totalItems registros',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                child: Container(
                  height: 32,
                  width: 90,
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColorTextField),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4.0),
                      topLeft: Radius.circular(4.0),
                    ),
                  ),
                  child: const Center(child: Text('Anterior')),
                ),
              ),
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: kBorderColorTextField),
                  color: kMainColor,
                ),
                child: Center(
                  child: Text(
                    '$_currentPage',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              if (totalPages > 1)
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColorTextField),
                  ),
                  child: Center(
                    child: Text('$totalPages'),
                  ),
                ),
              InkWell(
                onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                child: Container(
                  height: 32,
                  width: 90,
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColorTextField),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(4.0),
                      topRight: Radius.circular(4.0),
                    ),
                  ),
                  child: const Center(child: Text('Siguiente')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}