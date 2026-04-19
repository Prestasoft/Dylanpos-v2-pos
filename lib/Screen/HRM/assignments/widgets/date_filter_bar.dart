import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_theme.dart';

/// Barra de filtro de fechas reutilizable: Hoy | Semana | Rango personalizado
class DateFilterBar extends StatelessWidget {
  final DateTime dateFrom;
  final DateTime dateTo;
  final String activeFilter;
  final ValueChanged<DateFilterResult> onChanged;

  const DateFilterBar({
    super.key,
    required this.dateFrom,
    required this.dateTo,
    required this.activeFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tc = TaskColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(context, 'Hoy', 'hoy', Icons.today, tc),
          const SizedBox(width: 6),
          _buildChip(context, 'Semana', 'semana', Icons.date_range, tc),
          const SizedBox(width: 6),
          _buildRangeChip(context, tc),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, String key, IconData icon, TaskColors tc) {
    final isActive = activeFilter == key;
    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        if (key == 'hoy') {
          onChanged(DateFilterResult(
            filter: 'hoy',
            from: today,
            to: today.add(const Duration(hours: 23, minutes: 59)),
          ));
        } else if (key == 'semana') {
          final monday = today.subtract(Duration(days: today.weekday - 1));
          final sunday = monday.add(const Duration(days: 6));
          onChanged(DateFilterResult(filter: 'semana', from: monday, to: sunday));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4A84B) : tc.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? const Color(0xFFD4A84B) : tc.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : tc.textHint),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? Colors.white : tc.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeChip(BuildContext context, TaskColors tc) {
    final isActive = activeFilter == 'rango';
    final label = '${DateFormat('dd MMM').format(dateFrom)} - ${DateFormat('dd MMM').format(dateTo)}';

    return GestureDetector(
      onTap: () => _showCompactRangePicker(context, tc),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4A84B) : tc.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? const Color(0xFFD4A84B) : tc.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 14, color: isActive ? Colors.white : tc.textHint),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? Colors.white : tc.textSecondary)),
          ],
        ),
      ),
    );
  }

  Future<void> _showCompactRangePicker(BuildContext context, TaskColors tc) async {
    DateTime tempFrom = dateFrom;
    DateTime tempTo = dateTo;

    final result = await showDialog<DateFilterResult>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: tc.card,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.calendar_month, color: const Color(0xFFD4A84B), size: 22),
                          const SizedBox(width: 10),
                          Text('Seleccionar Período', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tc.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Desde / Hasta
                      Row(
                        children: [
                          Expanded(
                            child: _dateField(ctx, tc, 'Desde', tempFrom, (date) {
                              setDialogState(() => tempFrom = date);
                            }),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.arrow_forward, size: 16, color: tc.textHint),
                          ),
                          Expanded(
                            child: _dateField(ctx, tc, 'Hasta', tempTo, (date) {
                              setDialogState(() => tempTo = date);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Accesos rápidos
                      Text('Accesos rápidos', style: TextStyle(fontSize: 11, color: tc.textHint)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _quickButton(ctx, setDialogState, tc, 'Hoy', () {
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            tempFrom = today;
                            tempTo = today;
                          }),
                          _quickButton(ctx, setDialogState, tc, 'Semana', () {
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            tempFrom = today.subtract(Duration(days: today.weekday - 1));
                            tempTo = tempFrom.add(const Duration(days: 6));
                          }),
                          _quickButton(ctx, setDialogState, tc, 'Este Mes', () {
                            final now = DateTime.now();
                            tempFrom = DateTime(now.year, now.month, 1);
                            tempTo = DateTime(now.year, now.month + 1, 0);
                          }),
                          _quickButton(ctx, setDialogState, tc, '3 Meses', () {
                            final now = DateTime.now();
                            tempFrom = DateTime(now.year, now.month - 2, 1);
                            tempTo = DateTime(now.year, now.month + 1, 0);
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Botones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancelar', style: TextStyle(color: tc.textSecondary)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4A84B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx, DateFilterResult(filter: 'rango', from: tempFrom, to: tempTo));
                            },
                            child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      onChanged(result);
    }
  }

  Widget _dateField(BuildContext context, TaskColors tc, String label, DateTime date, ValueChanged<DateTime> onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tc.isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tc.border.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: tc.textHint)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: const Color(0xFFD4A84B)),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tc.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickButton(BuildContext ctx, StateSetter setDialogState, TaskColors tc, String label, VoidCallback action) {
    return GestureDetector(
      onTap: () {
        setDialogState(() => action());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tc.isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tc.border.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tc.textSecondary)),
      ),
    );
  }
}

class DateFilterResult {
  final String filter;
  final DateTime from;
  final DateTime to;

  const DateFilterResult({required this.filter, required this.from, required this.to});
}
