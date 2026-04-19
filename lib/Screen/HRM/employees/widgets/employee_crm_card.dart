import 'package:flutter/material.dart';
import 'package:salespro_admin/commas.dart';
import '../model/employee_model.dart';
import 'employee_photo_widget.dart';

/// Card compacta de empleado para vista CRM por columnas.
/// Muestra foto, nombre, cargo, salario, estado y acciones.
/// Soporta drag-and-drop para mover entre departamentos.
class EmployeeCrmCard extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final bool isDragging;

  const EmployeeCrmCard({
    super.key,
    required this.employee,
    this.onView,
    this.onEdit,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHead = employee.isDepartmentHead;
    final isActive = employee.status.toLowerCase() == 'activo';
    final goldColor = const Color(0xFFD4A84B);

    return Opacity(
      opacity: isActive ? 1.0 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDragging
              ? Colors.blue.withValues(alpha: 0.08)
              : isHead
                  ? goldColor.withValues(alpha: 0.06)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDragging
                ? Colors.blue.withValues(alpha: 0.4)
                : isHead
                    ? goldColor.withValues(alpha: 0.35)
                    : Colors.grey.withValues(alpha: 0.2),
            width: isDragging ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDragging ? 0.12 : 0.04),
              blurRadius: isDragging ? 12 : 4,
              offset: Offset(0, isDragging ? 4 : 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Foto + Nombre + Encargado badge
            Row(
              children: [
                // Foto
                Stack(
                  children: [
                    EmployeePhotoCircle(
                      photoUrl: employee.photoUrl,
                      radius: 20,
                      employeeName: employee.fullName,
                      showBadge: false,
                    ),
                    if (isHead)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: goldColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.star, size: 8, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                // Nombre y cargo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isHead ? FontWeight.w700 : FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        employee.designation,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Info: Telefono + Salario
            Row(
              children: [
                if (employee.phoneNumber.isNotEmpty) ...[
                  Icon(Icons.phone, size: 11, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Text(
                    employee.phoneNumber,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                ],
                if (employee.phoneNumber.isEmpty) const Spacer(),
                // Salario
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '\$${myFormat.format(employee.salary)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Footer: Estado + Acciones
            Row(
              children: [
                // Estado badge
                _StatusDot(status: employee.status),
                const Spacer(),
                // Acciones
                if (onView != null)
                  _MiniAction(
                    icon: Icons.visibility,
                    color: Colors.blue,
                    onTap: onView!,
                    tooltip: 'Ver perfil',
                  ),
                if (onEdit != null) ...[
                  const SizedBox(width: 4),
                  _MiniAction(
                    icon: Icons.edit,
                    color: Colors.orange,
                    onTap: onEdit!,
                    tooltip: 'Editar',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'activo':
        color = Colors.green;
        break;
      case 'inactivo':
        color = Colors.grey;
        break;
      case 'suspendido':
        color = Colors.orange;
        break;
      case 'vacaciones':
        color = Colors.teal;
        break;
      case 'licencia':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _MiniAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}
