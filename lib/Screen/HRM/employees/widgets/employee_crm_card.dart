import 'package:flutter/material.dart';
import 'package:salespro_admin/commas.dart';
import '../model/employee_model.dart';
import 'employee_photo_widget.dart';

/// Datos de cada estado para uso global en CRM
class EmployeeStatusInfo {
  final String key;
  final String label;
  final Color color;
  final IconData icon;

  const EmployeeStatusInfo(this.key, this.label, this.color, this.icon);

  static const all = [
    EmployeeStatusInfo('Activo', 'Activo', Colors.green, Icons.check_circle),
    EmployeeStatusInfo('Inactivo', 'Inactivo', Colors.grey, Icons.cancel),
    EmployeeStatusInfo('Suspendido', 'Suspendido', Colors.orange, Icons.pause_circle),
    EmployeeStatusInfo('Vacaciones', 'Vacaciones', Colors.teal, Icons.beach_access),
    EmployeeStatusInfo('Licencia', 'Licencia', Colors.blue, Icons.medical_services),
  ];

  static EmployeeStatusInfo fromStatus(String status) {
    return all.firstWhere(
      (s) => s.key.toLowerCase() == status.toLowerCase(),
      orElse: () => all.first,
    );
  }
}

/// Card compacta de empleado para vista CRM por columnas.
/// Soporta drag-and-drop y cambio de estado inline.
class EmployeeCrmCard extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final void Function(String newStatus)? onStatusChange;
  final bool isDragging;

  const EmployeeCrmCard({
    super.key,
    required this.employee,
    this.onView,
    this.onEdit,
    this.onStatusChange,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHead = employee.isDepartmentHead;
    final isActive = employee.status.toLowerCase() == 'activo';
    final goldColor = const Color(0xFFD4A84B);
    final statusInfo = EmployeeStatusInfo.fromStatus(employee.status);

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

            // Footer: Estado clickeable + Acciones
            Row(
              children: [
                // Estado — clickeable con popup
                _StatusBadge(
                  status: employee.status,
                  statusInfo: statusInfo,
                  onStatusChange: onStatusChange,
                ),
                const Spacer(),
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

/// Badge de estado clickeable con popup menu
class _StatusBadge extends StatelessWidget {
  final String status;
  final EmployeeStatusInfo statusInfo;
  final void Function(String newStatus)? onStatusChange;

  const _StatusBadge({
    required this.status,
    required this.statusInfo,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusInfo.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, size: 11, color: statusInfo.color),
          const SizedBox(width: 3),
          Text(
            statusInfo.label,
            style: TextStyle(
              fontSize: 10,
              color: statusInfo.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onStatusChange != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: statusInfo.color),
          ],
        ],
      ),
    );

    if (onStatusChange == null) return badge;

    return PopupMenuButton<String>(
      onSelected: (newStatus) {
        if (newStatus != status) {
          onStatusChange!(newStatus);
        }
      },
      offset: const Offset(0, 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      itemBuilder: (context) => EmployeeStatusInfo.all.map((s) {
        final isSelected = s.key.toLowerCase() == status.toLowerCase();
        return PopupMenuItem<String>(
          value: s.key,
          height: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? s.color.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(s.icon, size: 16, color: s.color),
                const SizedBox(width: 10),
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? s.color : Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check, size: 16, color: s.color),
              ],
            ),
          ),
        );
      }).toList(),
      child: badge,
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
