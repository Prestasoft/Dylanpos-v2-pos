import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/services/padron_electoral_service.dart';
import 'package:salespro_admin/services/api_service.dart';
import '../model/employee_model.dart';
import '../repo/employee_repo.dart';

/// Resultado de actualización de fecha de nacimiento de un empleado
class EmployeeBirthDateUpdateResult {
  final EmployeeModel employee;
  final String result;
  final DateTime? birthDate;
  final String message;

  EmployeeBirthDateUpdateResult({
    required this.employee,
    required this.result,
    this.birthDate,
    required this.message,
  });

  bool get isSuccess => result == 'success';
}

/// Diálogo para actualizar fechas de nacimiento de empleados en batch desde el Padrón Electoral
class BatchBirthDateUpdateDialog extends ConsumerStatefulWidget {
  final List<EmployeeModel> employees;
  final bool forceUpdate;

  const BatchBirthDateUpdateDialog({
    super.key,
    required this.employees,
    this.forceUpdate = false,
  });

  @override
  ConsumerState<BatchBirthDateUpdateDialog> createState() => _BatchBirthDateUpdateDialogState();
}

class _BatchBirthDateUpdateDialogState extends ConsumerState<BatchBirthDateUpdateDialog> {
  bool _isProcessing = false;
  bool _isCancelled = false;
  int _currentIndex = 0;
  final List<EmployeeBirthDateUpdateResult> _results = [];

  // Contadores
  int _successCount = 0;
  int _notFoundCount = 0;
  int _noBirthDateCount = 0;
  int _errorCount = 0;
  int _skippedCount = 0;
  int _noCedulaCount = 0;

  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 800 ? 700.0 : screenWidth * 0.9;

    return Dialog(
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cake,
                    color: Colors.purple,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actualizar Fechas de Nacimiento',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.employees.length} empleados a procesar',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isProcessing)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isProcessing && _results.isEmpty) ...[
                      _buildPreProcessSummary(theme),
                    ] else if (_isProcessing) ...[
                      _buildProcessingView(theme),
                    ] else ...[
                      _buildResultsView(theme),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isProcessing && _results.isEmpty) ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _startBatchUpdate,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar Actualización'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else if (_isProcessing) ...[
                    ElevatedButton.icon(
                      onPressed: _cancelUpdate,
                      icon: const Icon(Icons.stop),
                      label: const Text('Detener'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreProcessSummary(ThemeData theme) {
    int withCedula = 0;
    int withoutCedula = 0;
    int withBirthDate = 0;
    int withoutBirthDate = 0;

    for (var emp in widget.employees) {
      if (emp.cedula.isNotEmpty) {
        withCedula++;
      } else {
        withoutCedula++;
      }
      if (emp.birthDate != null) {
        withBirthDate++;
      } else {
        withoutBirthDate++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.purple[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Información',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Esta función buscará la fecha de nacimiento de cada empleado en el Padrón Electoral '
                  'usando su número de cédula y la actualizará automáticamente en el sistema.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de Empleados',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatRow('Total de empleados', widget.employees.length, Colors.purple),
                _buildStatRow('Con cédula registrada', withCedula, Colors.green),
                _buildStatRow('Sin cédula', withoutCedula, Colors.orange),
                const Divider(),
                _buildStatRow('Ya tienen fecha de nacimiento', withBirthDate, Colors.grey),
                _buildStatRow('Sin fecha de nacimiento', withoutBirthDate, Colors.blue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          color: Colors.purple[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.purple[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.forceUpdate
                            ? 'Se actualizarán TODOS los empleados (incluso los que ya tienen fecha)'
                            : 'Solo se actualizarán empleados SIN fecha de nacimiento',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'A procesar: ${widget.forceUpdate ? withCedula : (withCedula - withBirthDate).clamp(0, withCedula)} empleados',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView(ThemeData theme) {
    final progress = widget.employees.isEmpty
        ? 0.0
        : _currentIndex / widget.employees.length;
    final currentEmployee = _currentIndex < widget.employees.length
        ? widget.employees[_currentIndex]
        : null;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso: $_currentIndex / ${widget.employees.length}',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (currentEmployee != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircularProgressIndicator(color: Colors.purple),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Procesando:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          currentEmployee.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Cédula: ${currentEmployee.cedula.isEmpty ? "No registrada" : currentEmployee.cedula}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        _buildLiveCounters(theme),
      ],
    );
  }

  Widget _buildResultsView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: _successCount > 0 ? Colors.green[50] : Colors.orange[50],
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  _successCount > 0 ? Icons.check_circle : Icons.info,
                  size: 48,
                  color: _successCount > 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 12),
                Text(
                  _isCancelled ? 'Proceso Cancelado' : 'Proceso Completado',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_successCount fechas de nacimiento actualizadas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildLiveCounters(theme),
        const SizedBox(height: 16),

        if (_results.isNotEmpty) ...[
          Text(
            'Detalle por empleado:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return _buildResultItem(result, theme);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveCounters(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildCounterChip('Actualizados', _successCount, Colors.green),
        _buildCounterChip('No encontrados', _notFoundCount, Colors.orange),
        _buildCounterChip('Sin fecha en Padrón', _noBirthDateCount, Colors.blue),
        _buildCounterChip('Sin cédula', _noCedulaCount, Colors.grey),
        _buildCounterChip('Ya tienen fecha', _skippedCount, Colors.purple),
        _buildCounterChip('Errores', _errorCount, Colors.red),
      ],
    );
  }

  Widget _buildCounterChip(String label, int count, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(EmployeeBirthDateUpdateResult result, ThemeData theme) {
    IconData icon;
    Color color;

    switch (result.result) {
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'not_found':
        icon = Icons.search_off;
        color = Colors.orange;
        break;
      case 'no_birthdate':
        icon = Icons.event_busy;
        color = Colors.blue;
        break;
      case 'no_cedula':
        icon = Icons.badge_outlined;
        color = Colors.grey;
        break;
      case 'already_has_birthdate':
        icon = Icons.cake;
        color = Colors.purple;
        break;
      default:
        icon = Icons.error;
        color = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          result.employee.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          result.message,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
        trailing: result.isSuccess && result.birthDate != null
            ? Text(
                DateFormat('dd/MM/yyyy').format(result.birthDate!),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : Icon(icon, color: color),
      ),
    );
  }

  Future<void> _startBatchUpdate() async {
    setState(() {
      _isProcessing = true;
      _isCancelled = false;
      _currentIndex = 0;
      _results.clear();
      _successCount = 0;
      _notFoundCount = 0;
      _noBirthDateCount = 0;
      _errorCount = 0;
      _skippedCount = 0;
      _noCedulaCount = 0;
    });

    final service = PadronElectoralService();

    for (int i = 0; i < widget.employees.length && !_isCancelled; i++) {
      final employee = widget.employees[i];

      setState(() {
        _currentIndex = i;
      });

      // Pequeña pausa para no saturar la API
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final result = await _updateBirthDateFromPadron(
        service,
        employee,
        forceUpdate: widget.forceUpdate,
      );

      setState(() {
        _results.add(result);

        switch (result.result) {
          case 'success':
            _successCount++;
            break;
          case 'not_found':
            _notFoundCount++;
            break;
          case 'no_birthdate':
            _noBirthDateCount++;
            break;
          case 'no_cedula':
            _noCedulaCount++;
            break;
          case 'already_has_birthdate':
            _skippedCount++;
            break;
          default:
            _errorCount++;
        }
      });
    }

    setState(() {
      _isProcessing = false;
      _currentIndex = widget.employees.length;
    });

    // Refrescar lista de empleados si hubo cambios
    if (_successCount > 0) {
      ref.invalidate(employeeProvider);
    }
  }

  Future<EmployeeBirthDateUpdateResult> _updateBirthDateFromPadron(
    PadronElectoralService service,
    EmployeeModel employee, {
    bool forceUpdate = false,
  }) async {
    // Verificar si ya tiene fecha de nacimiento y no se fuerza actualización
    if (!forceUpdate && employee.birthDate != null) {
      return EmployeeBirthDateUpdateResult(
        employee: employee,
        result: 'already_has_birthdate',
        message: 'Ya tiene fecha: ${DateFormat('dd/MM/yyyy').format(employee.birthDate!)}',
      );
    }

    // Verificar que tenga cédula
    if (employee.cedula.isEmpty) {
      return EmployeeBirthDateUpdateResult(
        employee: employee,
        result: 'no_cedula',
        message: 'El empleado no tiene cédula registrada',
      );
    }

    try {
      // Consultar Padrón Electoral
      final response = await service.consultarCedula(employee.cedula);

      if (!response.success || response.data == null) {
        return EmployeeBirthDateUpdateResult(
          employee: employee,
          result: 'not_found',
          message: response.message ?? 'No encontrado en Padrón Electoral',
        );
      }

      // Verificar si tiene fecha de nacimiento
      final birthDate = response.data!.fechaNacimientoParsed;
      if (birthDate == null) {
        return EmployeeBirthDateUpdateResult(
          employee: employee,
          result: 'no_birthdate',
          message: 'No hay fecha de nacimiento en el Padrón Electoral',
        );
      }

      // Actualizar en la base de datos
      final updateResponse = await _apiService.put(
        'hrm/employees/${employee.id}',
        {'birth_date': birthDate.toIso8601String()},
      );

      if (updateResponse.success) {
        return EmployeeBirthDateUpdateResult(
          employee: employee,
          result: 'success',
          birthDate: birthDate,
          message: 'Fecha actualizada: ${DateFormat('dd/MM/yyyy').format(birthDate)}',
        );
      } else {
        return EmployeeBirthDateUpdateResult(
          employee: employee,
          result: 'error',
          message: updateResponse.message ?? 'Error al actualizar en base de datos',
        );
      }
    } catch (e) {
      return EmployeeBirthDateUpdateResult(
        employee: employee,
        result: 'error',
        message: 'Error: ${e.toString()}',
      );
    }
  }

  void _cancelUpdate() {
    setState(() {
      _isCancelled = true;
    });
  }
}

/// Provider de empleados
final employeeProvider = FutureProvider<List<EmployeeModel>>((ref) async {
  return await EmployeeRepository().getAllEmployees();
});

/// Muestra el diálogo de actualización masiva de fechas de nacimiento
Future<bool?> showBatchBirthDateUpdateDialog(
  BuildContext context,
  WidgetRef ref, {
  bool forceUpdate = false,
}) async {
  // Obtener empleados
  final employees = await EmployeeRepository().getAllEmployees();

  if (employees.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay empleados registrados'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return false;
  }

  if (!context.mounted) return false;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => BatchBirthDateUpdateDialog(
      employees: employees,
      forceUpdate: forceUpdate,
    ),
  );
}
