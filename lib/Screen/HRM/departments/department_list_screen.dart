import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/services/deletion_password_service.dart';
import '../../Widgets/Constant Data/constant.dart';
import '../employees/repo/employee_repo.dart';
import 'department_model.dart';
import 'department_provider.dart';
import 'department_repo.dart';

class DepartmentListScreen extends ConsumerStatefulWidget {
  const DepartmentListScreen({super.key});

  @override
  ConsumerState<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends ConsumerState<DepartmentListScreen> {
  String _search = '';
  bool _reordering = false;
  List<DepartmentModel>? _localOrder; // Lista local para reordenar

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deptsAsync = ref.watch(departmentProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: kWhite,
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Departamentos', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      if (_reordering) ...[
                        TextButton(
                          onPressed: _cancelReorder,
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _saveOrder,
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Guardar orden'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: () => _startReorder(deptsAsync),
                          icon: const Icon(Icons.swap_vert, size: 18),
                          label: const Text('Ordenar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(backgroundColor: kMainColor, foregroundColor: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1, color: kNeutral300),

                // Buscador (solo si no está reordenando)
                if (!_reordering)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Buscar departamento...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                // Contenido
                if (_reordering && _localOrder != null)
                  _buildReorderList()
                else
                  deptsAsync.when(
                    loading: () => const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                    error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Text('Error: $e')),
                    data: (departments) {
                      final filtered = _search.isEmpty
                          ? departments
                          : departments.where((d) => d.name.toLowerCase().contains(_search.toLowerCase())).toList();

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.business, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('No hay departamentos', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        );
                      }

                      return DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('SL')),
                          DataColumn(label: Text('Departamento')),
                          DataColumn(label: Text('Acción')),
                        ],
                        rows: List.generate(filtered.length, (i) {
                          final dept = filtered[i];
                          return DataRow(cells: [
                            DataCell(Text('${i + 1}')),
                            DataCell(Text(dept.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: kMainColor, size: 20),
                                    tooltip: 'Editar',
                                    onPressed: () => _showEditDialog(dept),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    tooltip: 'Eliminar',
                                    onPressed: () => _showDeleteDialog(dept),
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }),
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Lista reordenable con drag & drop
  Widget _buildReorderList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Arrastra los departamentos para cambiar el orden. Presiona "Guardar orden" al terminar.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _localOrder!.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _localOrder!.removeAt(oldIndex);
                _localOrder!.insert(newIndex, item);
              });
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(10),
                  shadowColor: kMainColor.withValues(alpha: 0.3),
                  child: child,
                ),
                child: child,
              );
            },
            itemBuilder: (context, i) {
              final dept = _localOrder![i];
              return Container(
                key: ValueKey(dept.id),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kNeutral300),
                ),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kMainColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kMainColor),
                    ),
                  ),
                  title: Text(dept.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  trailing: ReorderableDragStartListener(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle, color: Colors.grey[400]),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startReorder(AsyncValue<List<DepartmentModel>> deptsAsync) async {
    deptsAsync.whenData((departments) async {
      // Cargar empleados activos para obtener departamentos en uso
      final allEmployees = await EmployeeRepository().getAllEmployees();
      final usedDeptNames = <String>{};
      for (final e in allEmployees) {
        if (e.status == 'Activo' && e.department.isNotEmpty && e.department != 'General') {
          usedDeptNames.add(e.department);
        }
      }
      // Filtrar solo departamentos con empleados
      final usedDepts = departments.where((d) => usedDeptNames.contains(d.name)).toList();
      // Agregar departamentos que tienen empleados pero no están en la tabla departments
      for (final name in usedDeptNames) {
        if (!usedDepts.any((d) => d.name == name)) {
          usedDepts.add(DepartmentModel(id: 0, name: name, displayOrder: 999));
        }
      }
      usedDepts.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      if (!mounted) return;
      setState(() {
        _reordering = true;
        _localOrder = usedDepts;
      });
    });
  }

  void _cancelReorder() {
    setState(() {
      _reordering = false;
      _localOrder = null;
    });
  }

  Future<void> _saveOrder() async {
    if (_localOrder == null) return;
    EasyLoading.show(status: 'Guardando orden...');
    // Crear departamentos que no existen en la tabla (id == 0)
    final repo = DepartmentRepository();
    for (int i = 0; i < _localOrder!.length; i++) {
      if (_localOrder![i].id == 0) {
        final created = await repo.create(_localOrder![i].name);
        if (created != null) {
          _localOrder![i] = DepartmentModel(id: created.id, name: created.name, displayOrder: i);
        }
      }
    }
    final success = await repo.reorder(_localOrder!);
    EasyLoading.dismiss();
    if (success) {
      EasyLoading.showSuccess('Orden guardado');
      setState(() {
        _reordering = false;
        _localOrder = null;
      });
      ref.invalidate(departmentProvider);
    } else {
      EasyLoading.showError('Error al guardar orden');
    }
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Departamento'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Producción',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      final dept = await DepartmentRepository().create(result);
      if (dept != null) ref.invalidate(departmentProvider);
    }
  }

  Future<void> _showEditDialog(DepartmentModel dept) async {
    final controller = TextEditingController(text: dept.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Departamento'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty && result != dept.name) {
      final success = await DepartmentRepository().update(dept.id, result);
      if (success) {
        EasyLoading.showSuccess('Departamento actualizado');
        ref.invalidate(departmentProvider);
      }
    }
  }

  Future<void> _showDeleteDialog(DepartmentModel dept) async {
    final passwordCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text('Eliminar "${dept.name}"'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción eliminará el departamento permanentemente.\nIngrese la contraseña de eliminación para confirmar.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña de eliminación',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final isValid = await DeletionPasswordService.validatePassword(passwordCtrl.text);
              if (isValid) {
                Navigator.pop(ctx, true);
              } else {
                EasyLoading.showError('Contraseña incorrecta');
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    passwordCtrl.dispose();

    if (confirmed == true) {
      final success = await DepartmentRepository().delete(dept.id);
      if (success) {
        EasyLoading.showSuccess('Departamento eliminado');
        ref.invalidate(departmentProvider);
      } else {
        EasyLoading.showError('Error al eliminar');
      }
    }
  }
}
