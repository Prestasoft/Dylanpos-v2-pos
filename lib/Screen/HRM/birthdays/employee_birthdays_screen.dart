import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';
import 'package:salespro_admin/Screen/HRM/employees/employee_profile_screen.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';

/// Provider de empleados
final employeesProvider = FutureProvider<List<EmployeeModel>>((ref) async {
  return EmployeeRepository().getAllEmployees();
});

/// Pantalla de Cumpleaños de Empleados con calendario mensual
class EmployeeBirthdaysScreen extends ConsumerStatefulWidget {
  const EmployeeBirthdaysScreen({super.key});

  @override
  ConsumerState<EmployeeBirthdaysScreen> createState() => _EmployeeBirthdaysScreenState();
}

class _EmployeeBirthdaysScreenState extends ConsumerState<EmployeeBirthdaysScreen> {
  DateTime _selectedMonth = DateTime.now();
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Fondo gris claro en lugar de negro
      body: employeesAsync.when(
        data: (employees) => _buildContent(context, employees),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(employeesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<EmployeeModel> employees) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1240;

    // Calcular estadísticas de cumpleaños
    final stats = _calculateBirthdayStats(employees);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con selector de mes
          _buildHeader(context),
          const SizedBox(height: 24),

          // Cards de resumen
          _buildSummaryCards(stats, isDesktop),
          const SizedBox(height: 24),

          // Calendario mensual
          _buildMonthlyCalendar(employees, isDesktop),
          const SizedBox(height: 24),

          // Cumpleaños de hoy (si hay)
          if (stats['todayBirthdays'].isNotEmpty) ...[
            _buildTodayBirthdays(stats['todayBirthdays']),
            const SizedBox(height: 24),
          ],

          // Próximos cumpleaños (7 días)
          _buildUpcomingBirthdays(stats['upcomingBirthdays']),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎂 CUMPLEAÑOS DE EMPLEADOS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kMainColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Calendario de cumpleaños del equipo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        // Selector de mes/año
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM yyyy', 'es').format(_selectedMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats, bool isDesktop) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(
          icon: Icons.cake,
          title: 'Este Mes',
          value: stats['monthBirthdays'].toString(),
          color: Colors.blue,
          width: isDesktop ? 280 : null,
        ),
        _buildStatCard(
          icon: Icons.celebration,
          title: 'Hoy',
          value: stats['todayBirthdays'].length.toString(),
          color: Colors.orange,
          width: isDesktop ? 280 : null,
        ),
        _buildStatCard(
          icon: Icons.alarm,
          title: 'Próximos 7 días',
          value: stats['upcomingBirthdays'].length.toString(),
          color: Colors.green,
          width: isDesktop ? 280 : null,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(25), color.withAlpha(51)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar(List<EmployeeModel> employees, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: kMainColor),
              const SizedBox(width: 12),
              Text(
                'CALENDARIO - ${DateFormat('MMMM yyyy', 'es').format(_selectedMonth).toUpperCase()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kMainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCalendarGrid(employees),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<EmployeeModel> employees) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Domingo

    final today = DateTime.now();
    final isCurrentMonth = today.year == _selectedMonth.year && today.month == _selectedMonth.month;

    return Column(
      children: [
        // Header de días de la semana
        Table(
          children: [
            TableRow(
              children: ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'].map((day) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: kMainColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const Divider(),
        // Grid de días
        _buildDaysGrid(employees, daysInMonth, startWeekday, isCurrentMonth ? today.day : -1),
      ],
    );
  }

  Widget _buildDaysGrid(List<EmployeeModel> employees, int daysInMonth, int startWeekday, int todayDay) {
    final List<Widget> dayWidgets = [];

    // Espacios vacíos antes del primer día
    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(Container());
    }

    // Días del mes
    for (int day = 1; day <= daysInMonth; day++) {
      final birthdaysOnDay = _getBirthdaysOnDay(employees, day);
      final isToday = day == todayDay;

      dayWidgets.add(_buildDayCell(day, birthdaysOnDay, isToday));
    }

    // Crear filas de 7 columnas
    final rows = <TableRow>[];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      final rowCells = dayWidgets.sublist(i, i + 7 > dayWidgets.length ? dayWidgets.length : i + 7);
      while (rowCells.length < 7) {
        rowCells.add(Container());
      }
      rows.add(TableRow(children: rowCells));
    }

    return Table(children: rows);
  }

  Widget _buildDayCell(int day, List<EmployeeModel> birthdays, bool isToday) {
    final hasMultiple = birthdays.length > 1;
    final hasBirthdays = birthdays.isNotEmpty;

    return InkWell(
      onTap: hasBirthdays
          ? () {
              setState(() {
                _selectedDay = day;
              });
              _showBirthdaysDialog(birthdays, day);
            }
          : null,
      child: Container(
        height: 90, // Aumentado de 80 a 90 para más espacio
        margin: const EdgeInsets.all(3), // Aumentado de 2 a 3 para más separación
        decoration: BoxDecoration(
          color: isToday
              ? Colors.orange.withAlpha(76) // Más intenso para hoy
              : hasBirthdays
                  ? Colors.blue.withAlpha(38) // Más visible
                  : Colors.grey.withAlpha(13),
          borderRadius: BorderRadius.circular(10), // Más redondeado
          border: Border.all(
            color: isToday
                ? Colors.orange
                : hasBirthdays
                    ? Colors.blue.withAlpha(128) // Borde más visible
                    : Colors.grey.withAlpha(51),
            width: isToday ? 3 : 1.5, // Borde más grueso
          ),
          boxShadow: hasBirthdays || isToday
              ? [
                  BoxShadow(
                    color: isToday ? Colors.orange.withAlpha(51) : Colors.blue.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Número del día
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                  color: isToday ? Colors.orange : Colors.black87,
                ),
              ),
            ),
            if (isToday)
              const Text(
                'HOY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            // Nombres o badge de cumpleaños
            if (hasBirthdays)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: hasMultiple
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '🎂×${birthdays.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            birthdays.first.fullName.split(' ').first,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayBirthdays(List<EmployeeModel> todayBirthdays) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withAlpha(25), Colors.yellow.withAlpha(25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withAlpha(51),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Text(
                '👥 CUMPLEAÑOS DE HOY (${DateFormat('d MMMM', 'es').format(DateTime.now())})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...todayBirthdays.map((employee) => _buildBirthdayCard(employee, isToday: true)),
        ],
      ),
    );
  }

  Widget _buildUpcomingBirthdays(List<Map<String, dynamic>> upcomingBirthdays) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm, color: kMainColor),
              const SizedBox(width: 12),
              const Text(
                'PRÓXIMOS CUMPLEAÑOS (Siguientes 7 días)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kMainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (upcomingBirthdays.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No hay cumpleaños en los próximos 7 días',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...upcomingBirthdays.map((item) => _buildUpcomingBirthdayItem(item)),
        ],
      ),
    );
  }

  Widget _buildBirthdayCard(EmployeeModel employee, {bool isToday = false}) {
    final age = _calculateAge(employee.birthDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isToday ? Colors.orange.withAlpha(128) : Colors.grey.withAlpha(76)),
      ),
      child: Row(
        children: [
          // Foto del empleado
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: kMainColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kMainColor, width: 2),
            ),
            child: employee.photoUrl != null && employee.photoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      employee.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 30, color: kMainColor),
                    ),
                  )
                : const Icon(Icons.person, size: 30, color: kMainColor),
          ),
          const SizedBox(width: 16),
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        employee.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '🎂 $age años',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${employee.designation} • ${employee.department}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Botones de acción en horizontal (más compactos)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar envío de felicitación
                },
                icon: const Icon(Icons.mail_outline, size: 16),
                label: const Text('Felicitar', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EmployeeProfileScreen(employee: employee),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Ver Perfil', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBirthdayItem(Map<String, dynamic> item) {
    final employee = item['employee'] as EmployeeModel;
    final date = item['date'] as DateTime;
    final age = _calculateAge(employee.birthDate);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EmployeeProfileScreen(employee: employee),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withAlpha(51)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date.day.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    DateFormat('MMM', 'es').format(date).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${employee.fullName} (${employee.designation}) - $age años',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showBirthdaysDialog(List<EmployeeModel> birthdays, int day) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 650, // Más ancho para acomodar mejor
          constraints: const BoxConstraints(maxHeight: 600), // Altura máxima
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.cake, color: Colors.orange, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cumpleaños - $day ${DateFormat('MMMM', 'es').format(_selectedMonth)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kMainColor,
                            ),
                          ),
                          Text(
                            '${birthdays.length} ${birthdays.length == 1 ? 'empleado' : 'empleados'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Lista con scroll
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: birthdays.length,
                  itemBuilder: (context, index) => _buildCompactBirthdayCard(birthdays[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card compacta para el diálogo
  Widget _buildCompactBirthdayCard(EmployeeModel employee) {
    final age = _calculateAge(employee.birthDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Row(
        children: [
          // Foto del empleado (más pequeña)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: kMainColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kMainColor, width: 1.5),
            ),
            child: employee.photoUrl != null && employee.photoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      employee.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 24, color: kMainColor),
                    ),
                  )
                : const Icon(Icons.person, size: 24, color: kMainColor),
          ),
          const SizedBox(width: 12),
          // Información (más compacta)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        employee.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withAlpha(128)),
                      ),
                      child: Text(
                        '🎂 $age años',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${employee.designation} • ${employee.department}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Botones compactos en horizontal
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  // TODO: Implementar envío de felicitación
                },
                icon: const Icon(Icons.mail_outline, size: 18),
                tooltip: 'Felicitar',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.withAlpha(25),
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  // Guardar el navigator antes de cerrar el diálogo
                  final navigator = Navigator.of(context);

                  // Cerrar el diálogo
                  navigator.pop();

                  // Usar Future.microtask para navegar después de que el pop se complete
                  Future.microtask(() {
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) => EmployeeProfileScreen(employee: employee),
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.visibility_outlined, size: 18),
                tooltip: 'Ver Perfil',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.withAlpha(25),
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<EmployeeModel> _getBirthdaysOnDay(List<EmployeeModel> employees, int day) {
    return employees.where((employee) {
      final birthdate = employee.birthDate;
      return birthdate.month == _selectedMonth.month && birthdate.day == day;
    }).toList();
  }

  Map<String, dynamic> _calculateBirthdayStats(List<EmployeeModel> employees) {
    final now = DateTime.now();
    final todayBirthdays = <EmployeeModel>[];
    final upcomingBirthdays = <Map<String, dynamic>>[];
    int monthBirthdays = 0;

    for (var employee in employees) {
      final birthdate = employee.birthDate;

      // Cumpleaños de hoy
      if (birthdate.month == now.month && birthdate.day == now.day) {
        todayBirthdays.add(employee);
      }

      // Cumpleaños del mes seleccionado
      if (birthdate.month == _selectedMonth.month) {
        monthBirthdays++;
      }

      // Próximos cumpleaños (7 días)
      final nextBirthday = DateTime(now.year, birthdate.month, birthdate.day);
      final adjustedBirthday = nextBirthday.isBefore(now)
          ? DateTime(now.year + 1, birthdate.month, birthdate.day)
          : nextBirthday;

      final daysUntil = adjustedBirthday.difference(now).inDays;
      if (daysUntil > 0 && daysUntil <= 7) {
        upcomingBirthdays.add({
          'employee': employee,
          'date': adjustedBirthday,
          'daysUntil': daysUntil,
        });
      }
    }

    // Ordenar próximos cumpleaños por fecha
    upcomingBirthdays.sort((a, b) => (a['daysUntil'] as int).compareTo(b['daysUntil'] as int));

    return {
      'todayBirthdays': todayBirthdays,
      'upcomingBirthdays': upcomingBirthdays,
      'monthBirthdays': monthBirthdays,
    };
  }

  int _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month || (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }
}
