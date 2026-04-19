import 'package:flutter/material.dart';
import '../model/employee_model.dart';
import 'employee_crm_card.dart';

/// Columna de departamento para vista CRM.
/// Muestra header con nombre, conteo, y encargado.
/// Acepta drag-and-drop de empleados desde otras columnas.
class DepartmentColumn extends StatelessWidget {
  final String departmentName;
  final int departmentId;
  final Color color;
  final List<EmployeeModel> employees;
  final void Function(EmployeeModel employee) onView;
  final void Function(EmployeeModel employee) onEdit;
  final void Function(EmployeeModel employee, String newDepartment, int newDepartmentId) onDrop;
  final double width;

  const DepartmentColumn({
    super.key,
    required this.departmentName,
    required this.departmentId,
    required this.color,
    required this.employees,
    required this.onView,
    required this.onEdit,
    required this.onDrop,
    this.width = 240,
  });

  @override
  Widget build(BuildContext context) {
    // Separar: encargado primero, luego activos, luego inactivos
    final sorted = List<EmployeeModel>.from(employees)
      ..sort((a, b) {
        if (a.isDepartmentHead && !b.isDepartmentHead) return -1;
        if (!a.isDepartmentHead && b.isDepartmentHead) return 1;
        final aActive = a.status.toLowerCase() == 'activo';
        final bActive = b.status.toLowerCase() == 'activo';
        if (aActive && !bActive) return -1;
        if (!aActive && bActive) return 1;
        return a.fullName.compareTo(b.fullName);
      });

    final head = sorted.where((e) => e.isDepartmentHead).firstOrNull;
    final activeCount = employees.where((e) => e.status.toLowerCase() == 'activo').length;

    return DragTarget<EmployeeModel>(
      onWillAcceptWithDetails: (details) {
        // Aceptar si el empleado viene de otro departamento
        return details.data.department != departmentName;
      },
      onAcceptWithDetails: (details) {
        onDrop(details.data, departmentName, departmentId);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isHovering
                ? color.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHovering
                  ? color.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.15),
              width: isHovering ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(head, activeCount, isHovering),

              // Drop hint
              if (isHovering)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.move_down, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          'Soltar aqui',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Employee cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final emp = sorted[index];
                    return LongPressDraggable<EmployeeModel>(
                      data: emp,
                      delay: const Duration(milliseconds: 150),
                      feedback: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: width - 24,
                          child: EmployeeCrmCard(
                            employee: emp,
                            isDragging: true,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: EmployeeCrmCard(employee: emp),
                      ),
                      child: EmployeeCrmCard(
                        employee: emp,
                        onView: () => onView(emp),
                        onEdit: () => onEdit(emp),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(EmployeeModel? head, int activeCount, bool isHovering) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isHovering ? 0.15 : 0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(13),
          topRight: Radius.circular(13),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Color dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              // Name
              Expanded(
                child: Text(
                  departmentName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (head != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 11, color: const Color(0xFFD4A84B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    head.fullName,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
