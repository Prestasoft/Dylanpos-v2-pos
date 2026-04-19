import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_theme.dart';

/// Barra de filtro de fechas reutilizable: Hoy | Semana | Rango personalizado
class DateFilterBar extends StatelessWidget {
  final DateTime dateFrom;
  final DateTime dateTo;
  final String activeFilter; // 'hoy', 'semana', 'rango'
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
          border: Border.all(
            color: isActive ? const Color(0xFFD4A84B) : tc.border.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : tc.textHint),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : tc.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeChip(BuildContext context, TaskColors tc) {
    final isActive = activeFilter == 'rango';
    final label = '${DateFormat('dd MMM').format(dateFrom)} - ${DateFormat('dd MMM').format(dateTo)}';

    return GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
          initialDateRange: DateTimeRange(start: dateFrom, end: dateTo),
        );
        if (picked != null) {
          onChanged(DateFilterResult(filter: 'rango', from: picked.start, to: picked.end));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4A84B) : tc.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFFD4A84B) : tc.border.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 14, color: isActive ? Colors.white : tc.textHint),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : tc.textSecondary,
              ),
            ),
          ],
        ),
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
