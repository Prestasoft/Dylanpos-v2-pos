import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/services/deletion_password_service.dart';
import '../../Widgets/Constant Data/constant.dart';
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
                      ElevatedButton.icon(
                        onPressed: () => _showAddDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                        style: ElevatedButton.styleFrom(backgroundColor: kMainColor, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: kNeutral300),

                // Buscador
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

                // Tabla
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