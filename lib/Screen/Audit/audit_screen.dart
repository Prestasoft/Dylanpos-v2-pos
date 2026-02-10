import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// import 'package:hugeicons/hugeicons.dart'; // Eliminado
import '../../model/audit_model.dart';
import '../../services/audit_service.dart';
import '../Widgets/Constant Data/constant.dart';

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  final AuditService _auditService = AuditService();
  
  // Controladores de filtros
  String? selectedUserId;
  String? selectedAction;
  String? selectedModule;
  DateTime? startDate;
  DateTime? endDate;
  
  // Datos
  List<AuditModel> audits = [];
  Map<String, dynamic> stats = {};
  bool isLoading = true;
  Map<String, String> uniqueUsers = {}; // userId -> userName
  
  // Controladores de UI
  final ScrollController _horizontalScrollController = ScrollController();
  int currentPage = 1;
  final int itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadAllSystemUsers();
    _loadAuditData();
    _loadStats();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAllSystemUsers() async {
    try {
      final systemUsers = await _auditService.getAllSystemUsers();
      setState(() {
        uniqueUsers = systemUsers;
      });
    } catch (e) {
      debugPrint('Error cargando usuarios del sistema: $e');
    }
  }

  Future<void> _loadAuditData() async {
    setState(() => isLoading = true);
    
    try {
      final result = await _auditService.getAuditLogs(
        userId: selectedUserId,
        action: selectedAction,
        module: selectedModule,
        startDate: startDate,
        endDate: endDate,
        limit: 500,
      );
      
      setState(() {
        audits = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando auditoría: $e')),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final result = await _auditService.getAuditStats();
      setState(() {
        stats = result;
        // Ya no extraemos usuarios de las estadísticas, 
        // porque ahora los obtenemos directamente del sistema
      });
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  List<AuditModel> get paginatedAudits {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    
    if (startIndex >= audits.length) return [];
    
    return audits.sublist(
      startIndex,
      endIndex > audits.length ? audits.length : endIndex,
    );
  }

  int get totalPages => (audits.length / itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(theme),
            const SizedBox(height: 20),
            
            // Estadísticas
            _buildStatsCards(),
            const SizedBox(height: 20),
            
            // Filtros
            _buildFilters(theme),
            const SizedBox(height: 20),
            
            // Tabla de auditoría
            _buildAuditTable(theme, screenWidth),
            const SizedBox(height: 20),
            
            // Paginación
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kMainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fact_check,
              color: kMainColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auditoría del Sistema',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kTitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitoreo completo de todas las actividades del sistema',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: kGreyTextColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _loadAuditData();
              _loadStats();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Registros',
            stats['totalLogs']?.toString() ?? '0',
            Icons.analytics,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Usuarios Activos',
            (stats['userCounts'] as Map?)?.length.toString() ?? '0',
            Icons.people,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Módulos',
            (stats['moduleCounts'] as Map?)?.length.toString() ?? '0',
            Icons.apps,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Última Actividad',
            stats['lastActivity'] != null 
                ? _formatDate(stats['lastActivity'])
                : 'N/A',
            Icons.schedule,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTitleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: kGreyTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Primera fila de filtros
          Row(
            children: [
              // Filtro por Usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Usuario', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: selectedUserId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Todos los usuarios'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos los usuarios'),
                        ),
                        ...uniqueUsers.entries.map((entry) {
                          return DropdownMenuItem<String?>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => selectedUserId = value);
                        _loadAuditData();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Filtro por Acción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Acción', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedAction,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Todas las acciones'),
                      items: AuditAction.values.map((action) {
                        return DropdownMenuItem(
                          value: action.value,
                          child: Text(action.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedAction = value);
                        _loadAuditData();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Filtro por Módulo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Módulo', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedModule,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Todos los módulos'),
                      items: AuditModule.values.map((module) {
                        return DropdownMenuItem(
                          value: module.value,
                          child: Text(module.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedModule = value);
                        _loadAuditData();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Segunda fila de filtros
          Row(
            children: [
              
              // Filtro por Fecha Inicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fecha Inicio', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectStartDate(),
                      controller: TextEditingController(
                        text: startDate != null 
                            ? DateFormat('dd/MM/yyyy').format(startDate!)
                            : '',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Filtro por Fecha Fin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fecha Fin', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectEndDate(),
                      controller: TextEditingController(
                        text: endDate != null 
                            ? DateFormat('dd/MM/yyyy').format(endDate!)
                            : '',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Botón Limpiar
              Column(
                children: [
                  const SizedBox(height: 23),
                  ElevatedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTable(ThemeData theme, double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Registros de Auditoría',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${audits.length} registros encontrados',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: kGreyTextColor,
                  ),
                ),
              ],
            ),
          ),
          
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (audits.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No se encontraron registros'),
              ),
            )
          else
            Scrollbar(
              controller: _horizontalScrollController,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _horizontalScrollController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: screenWidth - 32,
                  ),
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: WidgetStateProperty.all(kMainColor.withValues(alpha: 0.1)),
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTitleColor,
                    ),
                    dataTextStyle: const TextStyle(
                      color: kTitleColor,
                    ),
                    columns: const [
                      DataColumn(label: Text('Fecha/Hora')),
                      DataColumn(label: Text('Usuario')),
                      DataColumn(label: Text('Acción')),
                      DataColumn(label: Text('Módulo')),
                      DataColumn(label: Text('Descripción')),
                      DataColumn(label: Text('IP')),
                      DataColumn(label: Text('Detalles')),
                    ],
                    rows: paginatedAudits.map((audit) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatDate(audit.createdAt),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  _formatTime(audit.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kGreyTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  audit.userName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  audit.userEmail,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kGreyTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getActionColor(audit.action).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getActionName(audit.action),
                                style: TextStyle(
                                  color: _getActionColor(audit.action),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kMainColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getModuleName(audit.module),
                                style: const TextStyle(
                                  color: kMainColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Text(
                                audit.description,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          DataCell(Text(audit.ipAddress)),
                          DataCell(
                            IconButton(
                              onPressed: () => _showAuditDetails(audit),
                              icon: const Icon(Icons.visibility),
                              tooltip: 'Ver detalles',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1 ? () {
              setState(() => currentPage--);
            } : null,
            icon: const Icon(Icons.chevron_left),
          ),
          
          ...List.generate(
            totalPages > 5 ? 5 : totalPages,
            (index) {
              int pageNumber;
              if (totalPages <= 5) {
                pageNumber = index + 1;
              } else {
                if (currentPage <= 3) {
                  pageNumber = index + 1;
                } else if (currentPage >= totalPages - 2) {
                  pageNumber = totalPages - 4 + index;
                } else {
                  pageNumber = currentPage - 2 + index;
                }
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => currentPage = pageNumber);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentPage == pageNumber ? kMainColor : Colors.grey[200],
                    foregroundColor: currentPage == pageNumber ? Colors.white : Colors.black87,
                    minimumSize: const Size(40, 40),
                  ),
                  child: Text('$pageNumber'),
                ),
              );
            },
          ),
          
          IconButton(
            onPressed: currentPage < totalPages ? () {
              setState(() => currentPage++);
            } : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() => startDate = date);
      _loadAuditData();
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() => endDate = date);
      _loadAuditData();
    }
  }

  void _clearFilters() {
    setState(() {
      selectedUserId = null;
      selectedAction = null;
      selectedModule = null;
      startDate = null;
      endDate = null;
      currentPage = 1;
    });
    _loadAuditData();
  }

  void _showAuditDetails(AuditModel audit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Auditoría'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Fecha:', _formatDateTime(audit.createdAt)),
              _buildDetailRow('Usuario:', '${audit.userName} (${audit.userEmail})'),
              _buildDetailRow('Acción:', _getActionName(audit.action)),
              _buildDetailRow('Módulo:', _getModuleName(audit.module)),
              _buildDetailRow('Descripción:', audit.description),
              _buildDetailRow('IP:', audit.ipAddress),
              _buildDetailRow('User Agent:', audit.userAgent),
              
              if (audit.beforeData != null) ...[
                const SizedBox(height: 16),
                const Text('Datos Anteriores:', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatJson(audit.beforeData!),
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
              
              if (audit.afterData != null) ...[
                const SizedBox(height: 16),
                const Text('Datos Nuevos:', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatJson(audit.afterData!),
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
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
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('HH:mm:ss').format(date);
    } catch (e) {
      return '';
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getActionName(String action) {
    for (final enumAction in AuditAction.values) {
      if (enumAction.value == action) {
        return enumAction.name;
      }
    }
    return action;
  }

  String _getModuleName(String module) {
    for (final enumModule in AuditModule.values) {
      if (enumModule.value == module) {
        return enumModule.name;
      }
    }
    return module;
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'login':
        return Colors.purple;
      case 'logout':
        return Colors.orange;
      case 'view':
        return Colors.teal;
      case 'print':
        return Colors.indigo;
      case 'export':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  String _formatJson(Map<String, dynamic> json) {
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}