// deleted_items_screen.dart - Pantalla de elementos eliminados
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../Provider/deleted_items_provider.dart';
import '../../model/audit_model.dart';
import '../Widgets/Constant Data/constant.dart';

class DeletedItemsScreen extends StatefulWidget {
  const DeletedItemsScreen({super.key});

  static const String route = '/deleted-items';

  @override
  State<DeletedItemsScreen> createState() => _DeletedItemsScreenState();
}

class _DeletedItemsScreenState extends State<DeletedItemsScreen> {
  DateTime? startDate;
  DateTime? endDate;
  String? selectedModule;
  int currentPage = 0;
  final int itemsPerPage = 50;

  final List<String> modules = [
    'Todos',
    'sales',
    'products',
    'customers',
    'expenses',
    'purchases',
    'inventory',
    'reservations',
    'users',
    'suppliers',
  ];

  String getModuleName(String module) {
    switch (module) {
      case 'sales':
        return 'Ventas';
      case 'products':
        return 'Productos';
      case 'customers':
        return 'Clientes';
      case 'expenses':
        return 'Gastos';
      case 'purchases':
        return 'Compras';
      case 'inventory':
        return 'Inventario';
      case 'reservations':
        return 'Reservas';
      case 'users':
        return 'Usuarios';
      case 'suppliers':
        return 'Proveedores';
      default:
        return module;
    }
  }

  DeletedItemsFilters _buildFilters() {
    return DeletedItemsFilters(
      startDate: startDate?.toIso8601String(),
      endDate: endDate?.toIso8601String(),
      module: selectedModule == 'Todos' ? null : selectedModule,
      limit: itemsPerPage,
      offset: currentPage * itemsPerPage,
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kMainColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        currentPage = 0;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      startDate = null;
      endDate = null;
      selectedModule = null;
      currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        title: const Text(
          'Elementos Eliminados',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtros
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list, color: kMainColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Selector de módulo
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Módulo',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          initialValue: selectedModule ?? 'Todos',
                          items: modules.map((module) {
                            return DropdownMenuItem(
                              value: module,
                              child: Text(getModuleName(module)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedModule = value == 'Todos' ? null : value;
                              currentPage = 0;
                            });
                          },
                        ),
                      ),
                      // Selector de fecha
                      ElevatedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          startDate != null && endDate != null
                              ? '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                              : 'Seleccionar rango de fechas',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kMainColor.withValues(alpha: 0.1),
                          foregroundColor: kMainColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      // Limpiar filtros
                      if (startDate != null || endDate != null || selectedModule != null)
                        ElevatedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear),
                          label: const Text('Limpiar filtros'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Lista de eliminados
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final deletedItems = ref.watch(deletedItemsProvider(_buildFilters()));

                  return deletedItems.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay elementos eliminados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // Contador
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red.shade400, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${items.length} elementos eliminados',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Lista
                          Expanded(
                            child: ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return _buildDeletedItemCard(item);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar elementos eliminados',
                            style: TextStyle(color: Colors.red.shade400),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedItemCard(AuditModel item) {
    final dateTime = DateTime.tryParse(item.createdAt);
    final formattedDate = dateTime != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dateTime)
        : item.createdAt;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.delete_forever,
            color: Colors.red.shade400,
          ),
        ),
        title: Text(
          item.description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  item.userName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Usuario', item.userName),
                _buildDetailRow('Email', item.userEmail),
                _buildDetailRow('Acción', item.action),
                _buildDetailRow('Módulo', getModuleName(item.module)),
                _buildDetailRow('Fecha', formattedDate),
                _buildDetailRow('IP', item.ipAddress),
                if (item.beforeData != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Datos eliminados:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _formatJson(item.beforeData!),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    json.forEach((key, value) {
      buffer.writeln('$key: ${value.toString()}');
    });
    return buffer.toString();
  }
}
