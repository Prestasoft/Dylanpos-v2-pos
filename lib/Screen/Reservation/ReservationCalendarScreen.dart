import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Provider/reservation_provider.dart';
import 'package:salespro_admin/model/reservation_model.dart';
import 'package:table_calendar/table_calendar.dart';

class ReservationCalendarScreen extends ConsumerStatefulWidget {
  const ReservationCalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReservationCalendarScreen> createState() => _ReservationCalendarScreenState();
}

class _ReservationCalendarScreenState extends ConsumerState<ReservationCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late Map<DateTime, List<ReservationModel>> _reservationsByDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _reservationsByDay = {};
  }

  @override
  Widget build(BuildContext context) {
    final reservationsAsyncValue = ref.watch(reservationsProvider);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Custom Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            color: Theme.of(context).primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reservaciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () => ref.refresh(reservationsProvider),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: _showFilterOptions,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildCalendar(reservationsAsyncValue),
          const Divider(),
          Expanded(
            child: _buildReservationsList(reservationsAsyncValue),
          ),
        ],
      ),
    );

  }

  Widget _buildCalendar(AsyncValue<List<ReservationModel>> reservationsValue) {
    return reservationsValue.when(
      data: (reservations) {
        // Process reservations and organize by day
        _reservationsByDay = {};
        for (var reservation in reservations) {
          final date = _parseDate(reservation.reservationDate);
          if (date != null) {
            final dateKey = DateTime(date.year, date.month, date.day);
            if (!_reservationsByDay.containsKey(dateKey)) {
              _reservationsByDay[dateKey] = [];
            }
            _reservationsByDay[dateKey]!.add(reservation);
          }
        }

        return TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          eventLoader: (day) {
            final dateKey = DateTime(day.year, day.month, day.day);
            return _reservationsByDay[dateKey] ?? [];
          },
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error al cargar reservaciones: $error'),
      ),
    );
  }

  Widget _buildReservationsList(AsyncValue<List<ReservationModel>> reservationsValue) {
    return reservationsValue.when(
      data: (allReservations) {
        // Filter reservations for selected day
        final selectedDayKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
        final reservations = _reservationsByDay[selectedDayKey] ?? [];

        if (reservations.isEmpty) {
          return const Center(
            child: Text(
              'No hay reservaciones para esta fecha',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: reservations.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final reservation = reservations[index];
            final now = DateTime.now();
            final reservationDate = _parseDate(reservation.reservationDate);
            final reservationTime = _parseTime(reservation.reservationTime);

            // Combine date and time
            final reservationDateTime = reservationDate != null && reservationTime != null
                ? DateTime(
              reservationDate.year,
              reservationDate.month,
              reservationDate.day,
              reservationTime.hour,
              reservationTime.minute,
            )
                : null;

            // Determine reservation status
            ReservationStatus status = ReservationStatus.upcoming;
            if (reservationDateTime != null) {
              if (reservationDateTime.isBefore(now)) {
                status = ReservationStatus.past;
              } else if (reservationDateTime.difference(now).inHours < 24) {
                status = ReservationStatus.aboutToExpire;
              }
            }

            return ReservationCard(
              reservation: reservation,
              status: status,
              onTap: () => _showReservationDetails(reservation),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error al cargar reservaciones: $error'),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('Todas las reservaciones'),
            onTap: () {
              Navigator.pop(context);
              // Apply filter
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Próximas'),
            onTap: () {
              Navigator.pop(context);
              // Apply filter
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: const Text('Por vencer'),
            onTap: () {
              Navigator.pop(context);
              // Apply filter
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Pasadas'),
            onTap: () {
              Navigator.pop(context);
              // Apply filter
            },
          ),
        ],
      ),
    );
  }

  void _showReservationDetails(ReservationModel reservation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return ReservationDetailView(
            reservation: reservation,
            scrollController: scrollController,
            onEdit: () {
              Navigator.pop(context);
              // Navigate to edit screen
            },
            onCancel: () {
              // Show confirmation dialog
              _showCancelConfirmation(reservation);
            },
          );
        },
      ),
    );
  }

  void _showCancelConfirmation(ReservationModel reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reservación'),
        content: const Text('¿Estás seguro que deseas cancelar esta reservación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail sheet
              // Cancel reservation
              // _cancelReservation(reservation.id);
            },
            child: const Text('Sí, Cancelar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }


  DateTime? _parseDate(String date) {
    try {
      return DateFormat('yyyy-MM-dd').parse(date);
    } catch (e) {
      return null;
    }
  }

  TimeOfDay? _parseTime(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }
}

enum ReservationStatus {
  past,
  upcoming,
  aboutToExpire,
}

class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final ReservationStatus status;
  final VoidCallback onTap;

  const ReservationCard({
    Key? key,
    required this.reservation,
    required this.status,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case ReservationStatus.past:
        statusColor = Colors.grey;
        statusIcon = Icons.history;
        statusText = 'Pasada';
        break;
      case ReservationStatus.aboutToExpire:
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber_rounded;
        statusText = 'Por vencer';
        break;
      case ReservationStatus.upcoming:
        statusColor = Colors.green;
        statusIcon = Icons.event_available;
        statusText = 'Próxima';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${reservation.reservationDate} - ${reservation.reservationTime}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(statusText),
                    avatar: Icon(statusIcon, size: 16, color: Colors.white),
                    backgroundColor: statusColor,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ID Cliente: ${reservation.clientId}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.checkroom, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ID Vestido: ${reservation.dressId}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sucursal: ${reservation.branchId}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReservationDetailView extends StatelessWidget {
  final ReservationModel reservation;
  final ScrollController scrollController;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const ReservationDetailView({
    Key? key,
    required this.reservation,
    required this.scrollController,
    required this.onEdit,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Text(
            'Detalles de la Reservación',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildDetailItem(Icons.calendar_today, 'Fecha', reservation.reservationDate),
          _buildDetailItem(Icons.access_time, 'Hora', reservation.reservationTime),
          _buildDetailItem(Icons.person, 'Cliente', 'ID: ${reservation.clientId}'),
          _buildDetailItem(Icons.checkroom, 'Vestido', 'ID: ${reservation.dressId}'),
          _buildDetailItem(Icons.business, 'Sucursal', reservation.branchId),
          _buildDetailItem(Icons.engineering, 'Servicio', 'ID: ${reservation.serviceId}'),
          _buildDetailItem(
            Icons.update,
            'Creada',
            DateFormat('dd/MM/yyyy HH:mm').format(reservation.createdAt),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}