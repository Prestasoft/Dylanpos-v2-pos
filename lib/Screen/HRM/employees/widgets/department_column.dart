import 'package:flutter/material.dart';
import '../model/employee_model.dart';
import 'employee_crm_card.dart';

/// Columna de departamento para vista CRM.
/// Muestra header con nombre editable, conteo, y encargado.
/// Acepta drag-and-drop de empleados desde otras columnas.
class DepartmentColumn extends StatefulWidget {
  final String departmentName;
  final int departmentId;
  final Color color;
  final List<EmployeeModel> employees;
  final void Function(EmployeeModel employee) onView;
  final void Function(EmployeeModel employee) onEdit;
  final void Function(EmployeeModel employee, String newDepartment, int newDepartmentId) onDrop;
  final void Function(int departmentId, String oldName, String newName)? onRename;
  final void Function(EmployeeModel employee, String newStatus)? onStatusChange;
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
    this.onRename,
    this.onStatusChange,
    this.width = 240,
  });

  @override
  State<DepartmentColumn> createState() => _DepartmentColumnState();
}

class _DepartmentColumnState extends State<DepartmentColumn> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.departmentName);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant DepartmentColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.departmentName != widget.departmentName) {
      _nameController.text = widget.departmentName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _isEditing = true;
      _nameController.text = widget.departmentName;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      _focusNode.requestFocus();
      _nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _nameController.text.length,
      );
    });
  }

  void _confirmEdit() {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == widget.departmentName) {
      _cancelEdit();
      return;
    }
    setState(() => _isEditing = false);
    widget.onRename?.call(widget.departmentId, widget.departmentName, newName);
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _nameController.text = widget.departmentName;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Separar: encargado primero, luego activos, luego inactivos
    final sorted = List<EmployeeModel>.from(widget.employees)
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
    final activeCount = widget.employees.where((e) => e.status.toLowerCase() == 'activo').length;

    return DragTarget<EmployeeModel>(
      onWillAcceptWithDetails: (details) {
        return details.data.department != widget.departmentName;
      },
      onAcceptWithDetails: (details) {
        widget.onDrop(details.data, widget.departmentName, widget.departmentId);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isHovering
                ? widget.color.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHovering
                  ? widget.color.withValues(alpha: 0.5)
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
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.move_down, size: 14, color: widget.color),
                        const SizedBox(width: 4),
                        Text(
                          'Soltar aqui',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.color,
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
                          width: widget.width - 24,
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
                        onView: () => widget.onView(emp),
                        onEdit: () => widget.onEdit(emp),
                        onStatusChange: widget.onStatusChange != null
                            ? (newStatus) => widget.onStatusChange!(emp, newStatus)
                            : null,
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
        color: widget.color.withValues(alpha: isHovering ? 0.15 : 0.08),
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
              // Drag handle + color dot
              Icon(Icons.drag_indicator, size: 16, color: widget.color.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              // Name — editable on click
              Expanded(
                child: _isEditing
                    ? SizedBox(
                        height: 28,
                        child: TextField(
                          controller: _nameController,
                          focusNode: _focusNode,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: widget.color, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: widget.color, width: 2),
                            ),
                          ),
                          onSubmitted: (_) => _confirmEdit(),
                        ),
                      )
                    : GestureDetector(
                        onTap: widget.onRename != null ? _startEdit : null,
                        child: Tooltip(
                          message: 'Click para renombrar',
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.departmentName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[900],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.onRename != null) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.edit, size: 11, color: Colors.grey[400]),
                              ],
                            ],
                          ),
                        ),
                      ),
              ),
              // Edit actions when editing
              if (_isEditing) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: _confirmEdit,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.green),
                  ),
                ),
                const SizedBox(width: 3),
                InkWell(
                  onTap: _cancelEdit,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.red),
                  ),
                ),
              ],
              // Count badge (only when not editing)
              if (!_isEditing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$activeCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
                ),
            ],
          ),
          if (head != null && !_isEditing) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 11, color: Color(0xFFD4A84B)),
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
