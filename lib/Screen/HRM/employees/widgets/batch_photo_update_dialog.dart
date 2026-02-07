import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/services/padron_electoral_service.dart';
import '../model/employee_model.dart';
import '../repo/employee_repo.dart';
import 'employee_photo_widget.dart';

/// Resultado de actualización de un empleado individual
class EmployeePhotoUpdateResult {
  final EmployeeModel employee;
  final String result;
  final String? photoUrl;
  final String message;

  EmployeePhotoUpdateResult({
    required this.employee,
    required this.result,
    this.photoUrl,
    required this.message,
  });

  bool get isSuccess => result == PadronElectoralService.resultSuccess;
}

/// Diálogo para actualizar fotos de empleados en batch desde el Padrón Electoral
class BatchPhotoUpdateDialog extends ConsumerStatefulWidget {
  final List<EmployeeModel> employees;
  final bool forceUpdate;

  const BatchPhotoUpdateDialog({
    super.key,
    required this.employees,
    this.forceUpdate = false,
  });

  @override
  ConsumerState<BatchPhotoUpdateDialog> createState() => _BatchPhotoUpdateDialogState();
}

class _BatchPhotoUpdateDialogState extends ConsumerState<BatchPhotoUpdateDialog> {
  bool _isProcessing = false;
  bool _isCancelled = false;
  int _currentIndex = 0;
  final List<EmployeePhotoUpdateResult> _results = [];

  // Contadores
  int _successCount = 0;
  int _notFoundCount = 0;
  int _noPhotoCount = 0;
  int _errorCount = 0;
  int _skippedCount = 0;
  int _noCedulaCount = 0;

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
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_download,
                    color: theme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actualizar Fotos desde Padrón Electoral',
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
                      // Pre-procesamiento: Mostrar resumen
                      _buildPreProcessSummary(theme),
                    ] else if (_isProcessing) ...[
                      // Durante procesamiento
                      _buildProcessingView(theme),
                    ] else ...[
                      // Post-procesamiento: Mostrar resultados
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
                        backgroundColor: Colors.green,
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
    // Contar empleados por categoría
    int withCedula = 0;
    int withoutCedula = 0;
    int withPhoto = 0;
    int withoutPhoto = 0;

    for (var emp in widget.employees) {
      if (emp.cedula.isNotEmpty) {
        withCedula++;
      } else {
        withoutCedula++;
      }
      if (emp.photoUrl != null && emp.photoUrl!.isNotEmpty) {
        withPhoto++;
      } else {
        withoutPhoto++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
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
                  'Esta función buscará la foto de cada empleado en el Padrón Electoral '
                  'usando su número de cédula y la actualizará automáticamente en el sistema.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Resumen de empleados
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
                _buildStatRow('Total de empleados', widget.employees.length, Colors.blue),
                _buildStatRow('Con cédula registrada', withCedula, Colors.green),
                _buildStatRow('Sin cédula', withoutCedula, Colors.orange),
                const Divider(),
                _buildStatRow('Ya tienen foto', withPhoto, Colors.grey),
                _buildStatRow('Sin foto', withoutPhoto, Colors.purple),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Opciones
        Card(
          color: Colors.amber[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.forceUpdate
                            ? 'Se actualizarán TODOS los empleados (incluso los que ya tienen foto)'
                            : 'Solo se actualizarán empleados SIN foto',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'A procesar: ${widget.forceUpdate ? withCedula : (withCedula - withPhoto).clamp(0, withCedula)} empleados',
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
        // Progreso general
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
                        color: theme.primaryColor,
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
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Empleado actual
        if (currentEmployee != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircularProgressIndicator(),
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

        // Contadores en vivo
        _buildLiveCounters(theme),
      ],
    );
  }

  Widget _buildResultsView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen de resultados
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
                  '$_successCount fotos actualizadas exitosamente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Contadores finales
        _buildLiveCounters(theme),
        const SizedBox(height: 16),

        // Lista de resultados
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
        _buildCounterChip('Sin foto en Padrón', _noPhotoCount, Colors.blue),
        _buildCounterChip('Sin cédula', _noCedulaCount, Colors.grey),
        _buildCounterChip('Ya tienen foto', _skippedCount, Colors.purple),
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

  Widget _buildResultItem(EmployeePhotoUpdateResult result, ThemeData theme) {
    IconData icon;
    Color color;

    switch (result.result) {
      case PadronElectoralService.resultSuccess:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case PadronElectoralService.resultNotFound:
        icon = Icons.search_off;
        color = Colors.orange;
        break;
      case PadronElectoralService.resultNoPhoto:
        icon = Icons.no_photography;
        color = Colors.blue;
        break;
      case PadronElectoralService.resultNoCedula:
        icon = Icons.badge_outlined;
        color = Colors.grey;
        break;
      case PadronElectoralService.resultAlreadyHasPhoto:
        icon = Icons.photo;
        color = Colors.purple;
        break;
      default:
        icon = Icons.error;
        color = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: result.isSuccess && result.photoUrl != null
            ? EmployeePhotoCircle(photoUrl: result.photoUrl, radius: 20)
            : CircleAvatar(
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
        trailing: Icon(icon, color: color),
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
      _noPhotoCount = 0;
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

      final result = await service.actualizarFotoDesdePardon(
        cedula: employee.cedula,
        employeeId: employee.id,
        currentPhotoUrl: employee.photoUrl,
        forceUpdate: widget.forceUpdate,
      );

      final updateResult = EmployeePhotoUpdateResult(
        employee: employee,
        result: result['result'] as String,
        photoUrl: result['photoUrl'] as String?,
        message: result['message'] as String,
      );

      setState(() {
        _results.add(updateResult);

        switch (result['result']) {
          case PadronElectoralService.resultSuccess:
            _successCount++;
            break;
          case PadronElectoralService.resultNotFound:
            _notFoundCount++;
            break;
          case PadronElectoralService.resultNoPhoto:
            _noPhotoCount++;
            break;
          case PadronElectoralService.resultNoCedula:
            _noCedulaCount++;
            break;
          case PadronElectoralService.resultAlreadyHasPhoto:
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

  void _cancelUpdate() {
    setState(() {
      _isCancelled = true;
    });
  }
}

/// Provider de empleados (importado de employee_list)
final employeeProvider = FutureProvider<List<EmployeeModel>>((ref) async {
  return await EmployeeRepository().getAllEmployees();
});

/// Muestra el diálogo de actualización masiva de fotos
Future<bool?> showBatchPhotoUpdateDialog(
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
    builder: (context) => BatchPhotoUpdateDialog(
      employees: employees,
      forceUpdate: forceUpdate,
    ),
  );
}
