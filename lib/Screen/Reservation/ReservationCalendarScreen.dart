import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Provider/reservation_provider.dart';
import 'package:salespro_admin/model/reservation_model.dart';
import 'package:table_calendar/table_calendar.dart';

class ReservationCalendarScreen extends ConsumerStatefulWidget {
  const ReservationCalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReservationCalendarScreen> createState() =>
      _ReservationCalendarScreenState();
}

class _ReservationCalendarScreenState
    extends ConsumerState<ReservationCalendarScreen> {
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
              color: Colors.transparent, // Eliminar fondo del día actual
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.transparent, // Eliminar fondo del día seleccionado
            ),
            cellMargin: EdgeInsets.all(6),
            markersAlignment: Alignment.center,
          ),
          calendarBuilders: CalendarBuilders(
            todayBuilder: (context, day, focusedDay) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt, // Cambiar el ícono a una cámara
                      color: Theme.of(context).primaryColor,
                      size: 16,
                    ),
                    Text(
                      '${day.day}', // Mostrar el número del día
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .checkroom, // Ícono de vestido para el día seleccionado
                      color: Colors.pinkAccent,
                      size: 16,
                    ),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent,
                      ),
                    ),
                  ],
                ),
              );
            },
            defaultBuilder: (context, day, focusedDay) {
              return Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              );
            },
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

  Widget _buildReservationsList(
      AsyncValue<List<ReservationModel>> reservationsValue) {
    return reservationsValue.when(
      data: (allReservations) {
        // Filter reservations for selected day
        final selectedDayKey = DateTime(
            _selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
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
            final reservationDateTime =
                reservationDate != null && reservationTime != null
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
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ReservationDetailView(
                  reservation: reservation,
                  onEdit: () {
                    Navigator.pop(context); // Cierra el modal
                  },
                  onCancel: () {
                    Navigator.pop(context); // Cierra el modal
                    // Lógica para cancelar
                    _showCancelConfirmation(reservation);
                  },
                  onClose: () => Navigator.pop(context), // Cierra el modal
                ),
              ),
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

  void _showCancelConfirmation(ReservationModel reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reservación'),
        content:
            const Text('¿Estás seguro que deseas cancelar esta reservación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              ref.read(ActualizarEstadoReservaProvider({
                'id': [reservation.id],
                'estado': 'cancelado'
              }));
              Navigator.of(context).pop(); // Cierra el diálogo de confirmación
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

class ReservationCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Asigna color, icono y texto según el estado
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

    // Obtenemos los datos completos de la reservación
    final fullReservationAsync =
        ref.watch(fullReservationByIdProviderVQ(reservation.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: fullReservationAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error al cargar datos: $error',
                style: TextStyle(color: Colors.red)),
            data: (fullReservation) {
              final clientName = fullReservation?.client?.customerName ??
                  'Cliente desconocido';

              String dressName = '';

              // Verifica si el vestido es de reserva simple o no
              final dressComposite =
                  fullReservation?.reservation['multiple_dress'] ?? [];

              if (dressComposite.isEmpty) {
                dressName = fullReservation?.dress?['name'] ??
                    'Vestido no especificado';
              }

              final serviceName = fullReservation?.service?['name'] ??
                  'Servicio no especificado';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${reservation.reservationDate} - ${reservation.reservationTime}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(statusText),
                        avatar: Icon(statusIcon, size: 16, color: Colors.white),
                        backgroundColor: statusColor,
                        labelStyle:
                            const TextStyle(color: Colors.white, fontSize: 12),
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
                        child: Text('Cliente: $clientName',
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.checkroom, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      _buildDressName(dressName, dressComposite),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.engineering,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Servicio: $serviceName',
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDressName(String dressName, dynamic dress) {
    // Verifica si el vestido es de reserva simple o no
    if (dress.isEmpty) {
      return Text('Vestido: ' + dressName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ));
    } else if (dress.isNotEmpty) {
      // Si no es de reserva simple, muestra la lista de vestidos
      final fullReservation = dress;

      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Column(
          children: [
            const Text('Vestimenta',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                )),
            _showDressesOption(dress),
          ],
        ),
      );
    } else {
      return const Text('Vestido: Vestido no especificado',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ));
    }
  }
}

Widget _showDressesOption(dynamic dress) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: dress.map<Widget>((item) {
      final dressName = item['dress_name'] ?? 'Sin nombre';
      return _buildInfoItem(dressName); // Asegúrate que retorne un Widget
    }).toList(),
  );
}

Widget _buildInfoItem(String dress) {
  return Text('* ' + dress,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[700], // Esto no puede ser const
      ));
}

class ReservationDetailView extends ConsumerWidget {
  final ReservationModel reservation;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onClose;

  const ReservationDetailView({
    Key? key,
    required this.reservation,
    required this.onEdit,
    required this.onCancel,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullReservationAsync =
        ref.watch(fullReservationByIdProviderVQ(reservation.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Botón de cerrar
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 28, color: Colors.grey),
                  onPressed: onClose,
                ),
              ),

              // Contenido principal
              Padding(
                padding: const EdgeInsets.only(
                    top: 50, left: 16, right: 16, bottom: 16),
                child: fullReservationAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error: $error',
                        style: const TextStyle(color: Colors.red)),
                  ),
                  data: (fullReservation) {
                    if (fullReservation == null) {
                      return const Center(
                          child: Text('No se encontraron detalles'));
                    }

                    final reservationData = fullReservation.reservation;
                    final dress = fullReservation.dress;
                    final service = fullReservation.service;
                    final client = fullReservation.client;

                    // Verifica si el vestido es de reserva simple o no
                    final dressComposite =
                        fullReservation?.reservation['multiple_dress'] ?? [];
                    String dressName = '';

                    if (dressComposite.isEmpty) {
                      dressName = fullReservation?.dress?['name'] ??
                          'Vestido no especificado';
                    }

                    String formattedDate = '';
                    try {
                      final date = DateFormat('yyyy-MM-dd')
                          .parse(reservationData['reservation_date'] ?? '');
                      formattedDate = DateFormat.yMMMMd('es').format(date);
                    } catch (e) {
                      formattedDate = reservationData['reservation_date'] ?? '';
                    }

                    return Column(
                      children: [
                        // Indicador de arrastre
                        Center(
                          child: Container(
                            width: 60,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        // Título
                        Text(
                          'Detalles de la Reservación',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),

                        const SizedBox(height: 16),

                        // Contenido desplazable
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Column(
                              children: [
                                // Imagen del vestido
                                if (dress != null &&
                                    dress['images'] != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _buildDressImage(dress['images']),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Sección de reservación
                                _buildSection(
                                  context,
                                  title: 'Información de la Reservación',
                                  children: [
                                    _buildDetailItem(Icons.calendar_today,
                                        'Fecha', formattedDate),
                                    _buildDetailItem(
                                        Icons.access_time,
                                        'Hora',
                                        reservationData['reservation_time'] ??
                                            ''),
                                    _buildDetailItem(Icons.business, 'Sucursal',
                                        reservationData['branch_id'] ?? ''),
                                  ],
                                ),

                                // Sección del cliente
                                if (client != null)
                                  _buildSection(
                                    context,
                                    title: 'Información del Cliente',
                                    children: [
                                      _buildDetailItem(Icons.person, 'Nombre',
                                          client.customerName),
                                      _buildDetailItem(Icons.phone, 'Teléfono',
                                          client.phoneNumber),
                                      _buildDetailItem(Icons.email, 'Email',
                                          client.emailAddress),
                                      if (client.customerAddress.isNotEmpty)
                                        _buildDetailItem(
                                            Icons.location_on,
                                            'Dirección',
                                            client.customerAddress),
                                    ],
                                  ),

                                // Sección del vestido Reserva Simple
                                if (dress != null)
                                  _buildSection(
                                    context,
                                    title: 'Información del Vestido',
                                    children: [
                                      _buildDetailItem(Icons.checkroom,
                                          'Vestido', dress['name'] ?? ''),
                                      _buildDetailItem(Icons.category,
                                          'Categoría', dress['category'] ?? ''),
                                      if (dress['color'] != null)
                                        _buildDetailItem(Icons.color_lens,
                                            'Color', dress['color']),
                                      if (dress['size'] != null)
                                        _buildDetailItem(Icons.straighten,
                                            'Talla', dress['size']),
                                    ],
                                  ),

                                // Sección del vestido Reserva Compuesta
                                if (fullReservation
                                        .reservation['multiple_dress'] !=
                                    null)
                                  _buildSection(
                                    context,
                                    title: 'Información de Vestimenta',
                                    children: [
                                      Text(
                                        'Vestimenta',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      _buildDetailItemComposite(Icons.checkroom,
                                          'Vestido', dressComposite),
                                      const SizedBox(height: 2),
                                      // Text(
                                      //   'Categoría',
                                      //   style: TextStyle(
                                      //     fontSize: 14,
                                      //     color: Colors.grey[600],
                                      //     fontWeight: FontWeight.bold,
                                      //   ),
                                      // ),
                                      _buildDetailItem(
                                          Icons.category,
                                          'Categoría',
                                          service != null
                                              ? (service['category'] ?? '')
                                              : ''),
                                    ],
                                  ),

                                // Sección del servicio
                                if (service != null)
                                  _buildSection(
                                    context,
                                    title: 'Información del Servicio',
                                    children: [
                                      _buildDetailItem(Icons.engineering,
                                          'Servicio', service['name'] ?? ''),
                                      _buildDetailItem(Icons.timer, 'Duración',
                                          _formatDuration(service['duration'])),
                                      _buildDetailItem(
                                          Icons.attach_money,
                                          'Precio',
                                          '\$${(service['price'] is num ? (service['price'] as num).toDouble() : 0.0).toStringAsFixed(2)}'),
                                      if (service['description'] != null &&
                                          service['description']
                                              .toString()
                                              .isNotEmpty)
                                        _buildDetailItem(
                                            Icons.description,
                                            'Descripción',
                                            service['description']),
                                    ],
                                  ),

                                const SizedBox(height: 24),

                                // Botones de acción
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: onEdit,
                                          icon:
                                              const Icon(Icons.edit, size: 20),
                                          label: const Text('Editar'),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: onCancel,
                                          icon: const Icon(Icons.cancel,
                                              size: 20),
                                          label: const Text('Cancelar'),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItemComposite(
      IconData icon, String title, dynamic dressComposite) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dressComposite.map<Widget>((item) {
        final dressName = item['dress_name'] ?? 'Sin nombre';
        final branchId = item['branch_id'] ?? 'Sin sucursal';

        return Expanded(
          child: _buildInfoItem(dressName, branchId, icon),
        ); // Asegúrate que retorne un Widget
      }).toList(),
    );
  }

  Widget _buildInfoItem(String dressName, String branchId, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dressName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  branchId,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDressImage(dynamic images) {
    String imageUrl = '';

    if (images is String) {
      imageUrl =
          images.split(',').first.trim().replaceAll(RegExp(r'[\[\]"]'), '');
    } else if (images is List && images.isNotEmpty) {
      imageUrl = images.first.toString();
    }

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: imageUrl.isEmpty
          ? Icon(Icons.image_not_supported, color: Colors.grey[400], size: 40)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_not_supported,
                color: Colors.grey[400],
                size: 40,
              ),
            ),
    );
  }

  String _formatDuration(dynamic durationData) {
    if (durationData == null) return 'No disponible';

    try {
      if (durationData is Map<String, dynamic>) {
        final hours = durationData['hours'] ?? 0;
        final minutes = durationData['minutes'] ?? 0;

        String result = '';
        if (hours > 0) {
          result += '$hours ${hours == 1 ? 'hora' : 'horas'}';
        }
        if (minutes > 0) {
          if (result.isNotEmpty) result += ' y ';
          result += '$minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
        }

        return result.isEmpty ? 'No especificada' : result;
      } else if (durationData is String) {
        return durationData;
      }

      return 'No disponible';
    } catch (e) {
      return 'Error en formato';
    }
  }
}
