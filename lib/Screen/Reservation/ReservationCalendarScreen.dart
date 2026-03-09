import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/Provider/reservation_provider.dart';
import 'package:salespro_admin/Provider/servicePackagesProvider.dart';
import 'package:salespro_admin/Provider/profile_provider.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/model/reservation_model.dart';
import 'package:salespro_admin/model/dress_model.dart';
import 'package:salespro_admin/Provider/dress_with_reservations.dart';
import 'package:salespro_admin/PDF/print_pdf.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/model/customer_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:salespro_admin/services/deletion_password_service.dart';
import 'package:salespro_admin/Screen/Reservation/dress_selection_screen_package.dart';
import 'package:salespro_admin/model/ServicePackageModel.dart';

//------------------- ENUM Y CARD -------------------
enum ReservationStatus {
  past,
  upcoming,
  aboutToExpire,
}

/// Helper estático para formatear fechas de reservación
/// Convierte formato ISO 8601 (PostgreSQL: 2026-01-06T00:00:00.000Z) a formato legible (2026-01-06)
String formatReservationDate(String date) {
  if (date.isEmpty) return date;
  try {
    // Si contiene 'T' (formato ISO), parsear y reformatear
    if (date.contains('T')) {
      final parsedDate = DateTime.parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    }
    // Si ya está en formato simple, devolverlo tal cual
    return date;
  } catch (e) {
    // Si falla el parsing, devolver la fecha original
    return date;
  }
}

/// Helper estático para formatear hora de reservación a formato 12h AM/PM
/// Convierte formato 24h (09:00, 14:30) a formato 12h (9:00 AM, 2:30 PM)
String formatReservationTime(String time) {
  if (time.isEmpty) return time;
  try {
    // Parsear la hora en formato HH:mm
    final parts = time.split(':');
    if (parts.length >= 2) {
      int hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');

      // Determinar AM/PM
      final period = hour >= 12 ? 'PM' : 'AM';

      // Convertir a formato 12h
      if (hour == 0) {
        hour = 12;  // 00:00 -> 12:00 AM
      } else if (hour > 12) {
        hour = hour - 12;  // 13:00 -> 1:00 PM
      }
      // Si hour == 12, se queda como 12 PM

      return '$hour:$minute $period';
    }
    return time;
  } catch (e) {
    // Si falla el parsing, devolver la hora original
    return time;
  }
}

class ReservationCard extends ConsumerWidget {
  final ReservationModel reservation;
  final ReservationStatus status;
  final VoidCallback onTap;

  Widget _buildDressName(String dressName, dynamic dressComposite) {
    if (dressComposite is List && dressComposite.isNotEmpty) {
      // Extraer los nombres de los vestidos del array
      final dressNames = dressComposite.map((d) {
        if (d is Map) {
          return d['dress_name']?.toString() ?? d['name']?.toString() ?? '';
        }
        return '';
      }).where((name) => name.isNotEmpty).toList();

      if (dressNames.isEmpty) {
        return Text('Vestido: $dressName', style: const TextStyle(fontSize: 14));
      } else if (dressNames.length == 1) {
        return Text('Vestido: ${dressNames.first}', style: const TextStyle(fontSize: 14));
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vestidos (${dressNames.length}):', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ...dressNames.map((name) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('• $name', style: const TextStyle(fontSize: 13)),
            )),
          ],
        );
      }
    } else {
      return Text('Vestido: $dressName', style: const TextStyle(fontSize: 14));
    }
  }

  const ReservationCard({
    Key? key,
    required this.reservation,
    required this.status,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    Color? cardBgColor;
    Color iconColor = Colors.white;

    final packagesAsync = ref.read(servicePackagesProvider);
    String? serviceName;
    if (packagesAsync is AsyncData && packagesAsync.value != null) {
      final packageList = packagesAsync.value!;
      final package = packageList.where((pkg) => pkg.id == reservation.serviceId).toList();
      if (package.isNotEmpty) {
        serviceName = package.first.name;
      }
    }
    final lowerName = serviceName?.toLowerCase() ?? '';

    // Para planes "Pre-Quince y Fiesta", diferenciar por isFiestaDate:
    // - isFiestaDate=true → Es la fecha de la FIESTA
    // - isFiestaDate=false → Es la fecha del PRE-QUINCE (estudio)
    final isPreQuinceFiesta = lowerName.contains('pre-quince') && lowerName.contains('fiesta');
    final isFiesta = isPreQuinceFiesta
        ? reservation.isFiestaDate  // Solo es "fiesta" si es la fecha de fiesta
        : lowerName.contains('fiesta');
    final isEstudio = isPreQuinceFiesta
        ? !reservation.isFiestaDate  // Es "estudio" si NO es la fecha de fiesta (es pre-quince)
        : lowerName.contains('estudio');
    final isExterior = lowerName.contains('exterior');
    final isRenta = lowerName.contains('renta') || lowerName.contains('vestimenta') || lowerName.contains('vestido');

    switch (status) {
      case ReservationStatus.past:
        if (isFiesta) {
          statusColor = Colors.amber;
          statusIcon = Icons.celebration;
          statusText = 'Fiesta pasada';
          cardBgColor = Colors.amber.withValues(alpha: 0.10);
        } else if (isEstudio) {
          statusColor = Colors.blue;
          statusIcon = Icons.camera_alt;
          statusText = 'Estudio pasado';
          cardBgColor = Colors.blue.withValues(alpha: 0.10);
        } else if (isExterior) {
          statusColor = Colors.purple;
          statusIcon = Icons.landscape;
          statusText = 'Exterior pasado';
          cardBgColor = Colors.purple.withValues(alpha: 0.10);
        } else if (isRenta) {
          // Renta de vestimenta pasada
          statusColor = const Color(0xFF4CAF50).withValues(alpha: 0.7); // Verde elegante más opaco para pasadas
          statusIcon = Icons.checkroom;
          statusText = 'Renta pasada';
          cardBgColor = const Color(0xFF4CAF50).withValues(alpha: 0.05); // Muy suave para pasadas
        } else {
          statusColor = Colors.grey;
          statusIcon = Icons.history;
          statusText = 'Pasada';
          cardBgColor = Colors.grey.withValues(alpha: 0.08);
        }
        break;
      case ReservationStatus.aboutToExpire:
        if (isFiesta) {
          statusColor = Colors.amber;
          statusIcon = Icons.celebration;
          statusText = 'Fiesta por vencer';
          cardBgColor = Colors.amber.withValues(alpha: 0.10);
        } else if (isEstudio) {
          statusColor = Colors.blue;
          statusIcon = Icons.camera_alt;
          statusText = 'Estudio por vencer';
          cardBgColor = Colors.blue.withValues(alpha: 0.10);
        } else if (isExterior) {
          statusColor = Colors.purple;
          statusIcon = Icons.landscape;
          statusText = 'Exterior por vencer';
          cardBgColor = Colors.purple.withValues(alpha: 0.10);
        } else if (isRenta) {
          // Renta de vestimenta por vencer
          statusColor = const Color(0xFF4CAF50); // Verde elegante
          statusIcon = Icons.checkroom;
          statusText = 'Renta por vencer';
          cardBgColor = const Color(0xFF4CAF50).withValues(alpha: 0.15); // Un poco más intenso por ser próxima
        } else {
          statusColor = Colors.orange;
          statusIcon = Icons.warning_amber_rounded;
          statusText = 'Por vencer';
          cardBgColor = Colors.orange.withValues(alpha: 0.10);
        }
        break;
      case ReservationStatus.upcoming:
        if (isFiesta) {
          statusColor = Colors.amber;
          statusIcon = Icons.celebration;
          statusText = 'Fiesta próxima';
          cardBgColor = Colors.amber.withValues(alpha: 0.10);
        } else if (isEstudio) {
          statusColor = Colors.blue;
          statusIcon = Icons.camera_alt;
          statusText = 'Estudio próximo';
          cardBgColor = Colors.blue.withValues(alpha: 0.10);
        } else if (isExterior) {
          statusColor = Colors.purple;
          statusIcon = Icons.landscape;
          statusText = 'Exterior próximo';
          cardBgColor = Colors.purple.withValues(alpha: 0.10);
        } else if (isRenta) {
          statusColor = const Color(0xFF4CAF50); // Verde elegante y suave
          statusIcon = Icons.checkroom; // Icono de percha para renta de ropa
          statusText = 'Renta próxima';
          cardBgColor = const Color(0xFF4CAF50).withValues(alpha: 0.12); // Verde elegante suave
        } else {
          statusColor = Colors.green;
          statusIcon = Icons.event_available;
          statusText = 'Próxima';
          cardBgColor = Colors.green.withValues(alpha: 0.10);
        }
        break;
    }

    final fullReservationAsync = ref.watch(fullReservationByIdProviderVQ(reservation.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: cardBgColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: fullReservationAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error al cargar datos: $error', style: TextStyle(color: Colors.red)),
            data: (fullReservation) {
              // Usar customer_name de PostgreSQL primero, luego lookup, luego client_id
              final clientId = fullReservation?.reservation['client_id']?.toString();
              final customerNameFromDb = fullReservation?.reservation['customer_name']?.toString();
              final clientName = customerNameFromDb ??
                  fullReservation?.client?.customerName ??
                  (clientId != null && clientId.isNotEmpty ? clientId : 'Cliente desconocido');
              String dressName = '';
              // Buscar vestidos en multiple_dress (Firebase), dresses_data (PostgreSQL con nombres), o dress_ids (PostgreSQL solo IDs)
              var dressComposite = fullReservation?.reservation['multiple_dress'] ?? [];
              if (dressComposite is! List || dressComposite.isEmpty) {
                dressComposite = fullReservation?.reservation['dresses_data'] ?? [];
              }
              // Si dresses_data está vacío, intentar dress_ids
              bool usedDressIds = false;
              if (dressComposite is! List || dressComposite.isEmpty) {
                dressComposite = fullReservation?.reservation['dress_ids'] ?? [];
                usedDressIds = true;
              }
              // Si usamos dress_ids (solo UUIDs sin nombres), o si todo está vacío, obtener nombre del dress asociado
              if (dressComposite is! List || dressComposite.isEmpty || usedDressIds) {
                // Intentar vestido de PostgreSQL primero, luego lookup del dress
                final vestidoFromDb = fullReservation?.reservation['vestido']?.toString();
                dressName = vestidoFromDb ?? fullReservation?.dress?['name'] ?? 'Vestido no especificado';
                // Si usamos dress_ids pero no hay dress asociado, limpiar dressComposite para que use dressName
                if (usedDressIds && dressName != 'Vestido no especificado') {
                  dressComposite = []; // Forzar uso del dressName del dress asociado
                }
              }
              // Usar service_name de PostgreSQL primero, luego lookup del servicio
              final serviceNameFromDb = fullReservation?.reservation['service_name']?.toString();
              final serviceName = serviceNameFromDb ??
                  fullReservation?.service?['name'] ?? 'Servicio no especificado';
              final note = fullReservation?.reservation['nota'] ?? 'Sin notas';
              final place = fullReservation?.reservation['place'] ?? 'Sin lugar';
              final hasAditionals = (fullReservation?.reservation['aditionals'] != null && 
                                   (fullReservation!.reservation['aditionals'] as List).isNotEmpty);
              
              // Verificar si es una reserva de tipo PRE-QUINCE FIESTA
              final sessionType = fullReservation?.reservation['session_type']?.toString() ?? '';
              final isPreQuinceFiesta = sessionType.toLowerCase().contains('pre-quince-fiesta');
              final isPreQuinceDate = isPreQuinceFiesta && !reservation.isFiestaDate;

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${formatReservationDate(reservation.reservationDate)} - ${formatReservationTime(reservation.reservationTime)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (reservation.isFiestaDate)
                                    Text(
                                      '(Fecha de fiesta)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color.fromARGB(255, 73, 47, 1),
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (isPreQuinceDate)
                                    Text(
                                      '(Fecha pre-quince)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.purple[700],
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  // Mostrar número de factura si existe
                                  // CRÍTICO: Usar saleTransactionByReservationProvider para evitar límite de 100 ventas
                                  Consumer(
                                    builder: (context, ref, child) {
                                      // Usar provider directo que busca por reservation_id (sin límite de 100)
                                      final saleTransactionAsync = ref.watch(saleTransactionByReservationProvider(reservation.id));
                                      final settingProvider = ref.watch(generalSettingProvider);
                                      final profile = ref.watch(profileDetailsProvider);

                                      return saleTransactionAsync.when(
                                        data: (currentTransaction) {
                                          if (currentTransaction != null && currentTransaction.invoiceNumber.isNotEmpty) {
                                            final invoiceNumber = currentTransaction.invoiceNumber;

                                            final hasDueAmount =
                                                double.parse(currentTransaction.dueAmount.toString()) > 0;
                                            
                                            return InkWell(
                                              onTap: () async {
                                                try {
                                                  final setting = settingProvider.value;
                                                  final profileInfo = profile.value;
                                                  
                                                  if (setting != null && profileInfo != null && currentTransaction != null && context.mounted) {
                                                    EasyLoading.show(status: 'Preparando vista previa...');
                                                    // Generar y mostrar el PDF
                                                    await GeneratePdfAndPrint().printSaleInvoice(
                                                      setting: setting,
                                                      personalInformationModel: profileInfo,
                                                      saleTransactionModel: currentTransaction,
                                                      context: context,
                                                      printType: 'normal',
                                                      fromSaleReports: true,
                                                      post: currentTransaction,
                                                    );
                                                    EasyLoading.dismiss();
                                                  } else if (setting == null || profileInfo == null) {
                                                    EasyLoading.showError('No se pudo cargar la configuración o el perfil');
                                                  }
                                                } catch (error) {
                                                  EasyLoading.dismiss();
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Error: $error')),
                                                    );
                                                  }
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: hasDueAmount
                                                        ? [
                                                            const Color(0xFFE57373), // Rojo suave
                                                            const Color(0xFFEF5350), // Rojo suave más oscuro
                                                          ]
                                                        : [
                                                            const Color(0xFF66BB6A), // Verde suave
                                                            const Color(0xFF4CAF50), // Verde más oscuro
                                                          ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: (hasDueAmount
                                                          ? const Color(0xFFE57373)
                                                          : const Color(0xFF66BB6A)).withValues(alpha: 0.4),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      hasDueAmount
                                                          ? Icons.payment
                                                          : Icons.check_circle,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Factura: $invoiceNumber',
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.w700,
                                                            letterSpacing: 0.3,
                                                          ),
                                                        ),
                                                        if (hasDueAmount && currentTransaction != null)
                                                          Text(
                                                            'Saldo: \$${myFormat.format(double.parse(currentTransaction.dueAmount.toString()))}',
                                                            style: const TextStyle(
                                                              fontSize: 9,
                                                              color: Colors.white70,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                        loading: () => const SizedBox.shrink(),
                                        error: (_, __) => const SizedBox.shrink(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (hasAditionals)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Tooltip(
                                message: 'Esta reserva tiene adicionales',
                                child: Icon(Icons.add_circle_outline, color: Colors.blue, size: 20),
                              ),
                            ),
                          Chip(
                            label: Text(statusText),
                            avatar: Icon(statusIcon, size: 16, color: iconColor),
                            backgroundColor: statusColor,
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Cliente: $clientName', style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.checkroom, size: 16, color: iconColor),
                      const SizedBox(width: 8),
                      _buildDressName(dressName, dressComposite),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.engineering, size: 16, color: iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Servicio: $serviceName', style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.place, size: 16, color: iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Lugar: $place', style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.textsms_outlined, size: 16, color: iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Nota: $note', style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                  // Badge de vestimentas pendientes
                  if (fullReservation?.service != null) Builder(
                    builder: (context) {
                      final serviceComponents = fullReservation!.service!['components'];
                      if (serviceComponents is List && serviceComponents.isNotEmpty) {
                        final totalRequired = serviceComponents.length;
                        final totalSelected = (dressComposite is List) ? dressComposite.length : 0;
                        final pending = totalRequired - totalSelected;
                        if (pending > 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD32F2F)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$pending vestimenta${pending > 1 ? 's' : ''} pendiente${pending > 1 ? 's' : ''}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'Vestimentas completas',
                                    style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


class ReservationCalendarScreen extends ConsumerStatefulWidget {
  const ReservationCalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReservationCalendarScreen> createState() => _ReservationCalendarScreenState();
}

class _ReservationCalendarScreenState extends ConsumerState<ReservationCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ReservationModel>> _reservationsByDay = {};
  String? packageRentaId;
  
  // Controladores para la búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _reservationsByDay = {};
    Future.microtask(() => _loadRentaId());
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRentaId() async {
    final packagesAsync = ref.read(servicePackagesProvider);

    if (packagesAsync is AsyncData) {
      final rentas = packagesAsync.value
          ?.where((e) => e.name == "Renta de Vestimenta")
          .toList();
      if (rentas!.isNotEmpty) {
        setState(() {
          packageRentaId = rentas.first.id;
        });
      } else {
      }
    } else {
      // Esperar a que cargue, o volver a intentarlo
      await Future.delayed(const Duration(milliseconds: 200));
      _loadRentaId(); // reintentar (opcional: ponle un contador para no entrar en loop infinito)
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservationsAsyncValue = ref.watch(reservationsProvider);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de búsqueda
          _buildSearchBar(reservationsAsyncValue),
          const SizedBox(height: 16),
          
          // Si está en vista "Día", el scroll y la lista se manejan en _buildCalendar
          if (_calendarView == 'dia') 
            Expanded(
              child: _buildCalendar(reservationsAsyncValue),
            )
          else ...[
            // Semana/Mes: mostrar calendario y lista general
            _buildCalendar(reservationsAsyncValue),
            const Divider(),
            Expanded(
              child: _buildReservationsList(reservationsAsyncValue),
            ),
          ],
        ],
      ),
    );
  }




  // Estado para el filtro de vista: 'dia', 'semana', 'mes'
  String _calendarView = 'mes';
  
  // Flag para controlar la inicialización del estado
  bool _isInitialized = false;

  Widget _buildCalendar(AsyncValue<List<ReservationModel>> reservationsValue) {
    // Asegurar inicialización consistente del estado
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    }
    
    return reservationsValue.when(
      data: (allReservations) {
        // Cargar datos de clientes si no están en caché
        _loadClientsData(allReservations);
        
        // Filtrar las reservaciones según la búsqueda
        final reservations = _filterReservations(allReservations);
        
        // Agrupar reservas por día
        _reservationsByDay = {};
        
        for (var reservation in reservations) {
          final date = _parseDate(reservation.reservationDate);
          final fiestaDate = _parseDate(reservation.fiestaDate ?? '');
          
          // Agregar la fecha principal de reserva
          if (date != null) {
            // Si es del paquete de renta, añadir +-1 día también
            if (reservation.serviceId == packageRentaId) {
              for (int i = -1; i <= 1; i++) {
                DateTime dateFechasRentas = date.add(Duration(days: i));
                final dateKey = DateTime(dateFechasRentas.year,
                    dateFechasRentas.month, dateFechasRentas.day);
                _reservationsByDay
                    .putIfAbsent(dateKey, () => [])
                    .add(reservation);
              }
            } else {
              final dateKey = DateTime(date.year, date.month, date.day);
              _reservationsByDay
                  .putIfAbsent(dateKey, () => [])
                  .add(reservation);
            }
          }
          
          // Agregar también la fecha de fiesta si existe
          if (fiestaDate != null) {
            final fiestaDateKey = DateTime(fiestaDate.year, fiestaDate.month, fiestaDate.day);
            _reservationsByDay
                .putIfAbsent(fiestaDateKey, () => [])
                .add(reservation.copyWith(
                  isFiestaDate: true,
                  reservationDate: reservation.fiestaDate!,
                  reservationTime: reservation.fiestaTime ?? reservation.reservationTime,
                ));
          }
        }
        
        // En un segundo paso, procesar las fechas de fiesta de forma asíncrona
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _processPreQuinceFiestaReservations(reservations);
        });

        // Botones de formato de calendario: Día, Semana, Mes
        Widget formatButtons = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCustomViewButton('Día', 'dia'),
            const SizedBox(width: 8),
            _buildCustomViewButton('Semana', 'semana'),
            const SizedBox(width: 8),
            _buildCustomViewButton('Mes', 'mes'),
          ],
        );

        // Leyenda de colores para los tipos de eventos
        Widget colorLegend = Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(const Color(0xFF4CAF50), 'Renta'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.amber, 'Fiesta'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.blue, 'Estudio'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.purple, 'Exterior'),
              ],
            ),
          ),
        );

        List<Widget> children = [
          formatButtons,
          colorLegend,
        ];

        if (_calendarView == 'dia') {
          // Mostrar solo la lista de eventos del día seleccionado y aprovechar el espacio en blanco
          final selectedDayKey = DateTime(
            _selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
          final reservations = List<ReservationModel>.from(_reservationsByDay[selectedDayKey] ?? []);
          children.add(
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: reservations.isEmpty
                    ? Center(
                        child: Text(
                          'No hay reservaciones para este día',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: reservations.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final reservation = reservations[index];
                          final now = DateTime.now();
                          final reservationDate = _parseDate(reservation.reservationDate);
                          final reservationTime = _parseTime(reservation.reservationTime);
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
                            onTap: () => showDialog(
                              context: context,
                              builder: (context) => ReservationDetailView(
                                reservation: reservation,
                                onEdit: () {
                                  Navigator.pop(context);
                                },
                                onCancel: () {
                                  Navigator.pop(context);
                                  _showCancelConfirmation(reservation);
                                },
                                onClose: () => Navigator.pop(context),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        } else {
          // Mostrar TableCalendar en modo semana o mes
          children.add(
            TableCalendar(
              firstDay: DateTime(2020), // Sin límite práctico hacia atrás
              lastDay: DateTime(2100), // Sin límite práctico hacia adelante
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarView == 'semana' ? CalendarFormat.week : CalendarFormat.month,
              eventLoader: (day) {
                final dateKey = DateTime(day.year, day.month, day.day);
                return _reservationsByDay[dateKey] ?? [];
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.transparent,
                ),
                cellMargin: const EdgeInsets.all(6),
                markersAlignment: Alignment.center,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return const SizedBox();

                  // Filtrar solo eventos válidos
                  final validEvents = events.whereType<ReservationModel>().toList();

                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Wrap(
                      spacing: 2, // espacio entre puntos
                      alignment: WrapAlignment.center,
                      children: validEvents.map((event) {
                        // Buscar el nombre del servicio usando el serviceId y la lista de paquetes
                        Color dotColor = Theme.of(context).primaryColor;
                        final packagesAsync = ref.read(servicePackagesProvider);
                        String? serviceName;
                        if (packagesAsync is AsyncData && packagesAsync.value != null) {
                          final packageList = packagesAsync.value!;
                          final package = packageList.where((pkg) => pkg.id == event.serviceId).toList();
                          if (package.isNotEmpty) {
                            serviceName = package.first.name;
                          }
                        }
                        // Si es renta, verde
                        if (event.serviceId == packageRentaId) {
                          dotColor = const Color(0xFF4CAF50); // Verde elegante para renta
                        } else if (serviceName != null) {
                          final lowerName = serviceName.toLowerCase();
                          if (lowerName.contains('fiesta')) {
                            dotColor = Colors.amber;
                          } else if (lowerName.contains('estudio')) {
                            dotColor = Colors.blue;
                          } else if (lowerName.contains('exterior')) {
                            dotColor = Colors.purple;
                          }
                        }
                        // Debug
                        return Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: Theme.of(context).primaryColor,
                          size: 16,
                        ),
                        Text(
                          '${day.day}',
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
                          Icons.checkroom,
                          color: Colors.pinkAccent,
                          size: 16,
                        ),
                        Text(
                          '${day.day}',
                          style: const TextStyle(
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
                      style: const TextStyle(
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
              onFormatChanged: null, // Oculta el botón de cambiar formato
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              locale: 'es',
              daysOfWeekHeight: 24,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mes',
                CalendarFormat.week: 'Semana',
              },
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (date, locale) {
                  // Formato corto en español
                  switch (date.weekday) {
                    case DateTime.monday:
                      return 'Lun';
                    case DateTime.tuesday:
                      return 'Mar';
                    case DateTime.wednesday:
                      return 'Mié';
                    case DateTime.thursday:
                      return 'Jue';
                    case DateTime.friday:
                      return 'Vie';
                    case DateTime.saturday:
                      return 'Sáb';
                    case DateTime.sunday:
                      return 'Dom';
                    default:
                      return '';
                  }
                },
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
              ),
            ),
          );
        }

        // Solución: el widget padre ya es un Expanded, aquí solo devolvemos un Column
        return Column(
          children: children,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error al cargar reservaciones: $error'),
      ),
    );
  }

  // Botón personalizado para cambiar la vista (día, semana, mes)
  // Widget para la barra de búsqueda
  Widget _buildSearchBar(AsyncValue<List<ReservationModel>> reservationsValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, teléfono, notas o vendedor...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                
                // Auto-jump mientras escribe
                if (value.trim().isNotEmpty && reservationsValue is AsyncData) {
                  final filtered = _filterReservations(reservationsValue.value!);
                  if (filtered.isNotEmpty) {
                    final Set<DateTime> uniqueDates = {};
                    for (var res in filtered) {
                      final date = _parseDate(res.reservationDate);
                      if (date != null) uniqueDates.add(DateTime(date.year, date.month, date.day));
                      if (res.fiestaDate != null && res.fiestaDate!.isNotEmpty) {
                        final fDate = _parseDate(res.fiestaDate!);
                        if (fDate != null) uniqueDates.add(DateTime(fDate.year, fDate.month, fDate.day));
                      }
                    }
                    
                    if (uniqueDates.isNotEmpty) {
                      // Saltar automáticamente a la fecha de la primera coincidencia (ordenadas cronológicamente)
                      final datesList = uniqueDates.toList()..sort();
                      final targetDate = datesList.first;
                      
                      // Solo actualizar si no estamos ya en esa fecha para evitar rebuilds excesivos
                      if (!isSameDay(_selectedDay, targetDate)) {
                        setState(() {
                          _focusedDay = targetDate;
                          _selectedDay = targetDate;
                        });
                      }
                    }
                  }
                }
              },
              onSubmitted: (value) {
                _handleSearchSubmit(value, reservationsValue);
              },
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Color(0xFFD59345)),
              tooltip: 'Ir a la reservación',
              onPressed: () {
                 _handleSearchSubmit(_searchQuery, reservationsValue);
              },
            ),
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey.shade600),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
          ]
        ],
      ),
    );
  }

  // Estado para almacenar la información de clientes
  final Map<String, CustomerModel?> _clientsCache = {};
  
  // Extraer la acción de buscar a una función
  void _handleSearchSubmit(String query, AsyncValue<List<ReservationModel>> reservationsValue) {
    if (query.trim().isEmpty) return;
    
    if (reservationsValue is AsyncData) {
      final allReservations = reservationsValue.value!;
      final filtered = _filterReservations(allReservations);
      
      if (filtered.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron reservaciones.'), duration: Duration(seconds: 2)),
        );
        return;
      }
      
      // Recopilar fechas únicas
      final Set<DateTime> uniqueDates = {};
      final Map<DateTime, List<ReservationModel>> resByDate = {};
      
      for (var res in filtered) {
        final date = _parseDate(res.reservationDate);
        if (date != null) {
          final key = DateTime(date.year, date.month, date.day);
          uniqueDates.add(key);
          resByDate.putIfAbsent(key, () => []).add(res);
        }
        
        // Considerar también fiestaDate
        if (res.fiestaDate != null && res.fiestaDate!.isNotEmpty) {
          final fDate = _parseDate(res.fiestaDate!);
          if (fDate != null) {
            final key = DateTime(fDate.year, fDate.month, fDate.day);
            uniqueDates.add(key);
            resByDate.putIfAbsent(key, () => []).add(res);
          }
        }
      }
      
      if (uniqueDates.isEmpty) return;
      
      if (uniqueDates.length == 1) {
        // Solo una fecha encontrada: saltar directo a ella
        final targetDate = uniqueDates.first;
        setState(() {
          _focusedDay = targetDate;
          _selectedDay = targetDate;
        });
      } else {
        // Múltiples fechas: mostrar modal para elegir
        final datesList = uniqueDates.toList()..sort();
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Múltiples fechas encontradas', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: datesList.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final date = datesList[index];
                    final formattedDate = DateFormat.yMMMMd('es').format(date);
                    final reservationsForDate = resByDate[date] ?? [];
                    
                    return ListTile(
                      leading: const Icon(Icons.calendar_today, color: Color(0xFFD59345)),
                      title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${reservationsForDate.length} reservación(es)\n' + 
                                // Extraer un resumen (nombres de servicios)
                                reservationsForDate.map((r) => r.serviceName?.isNotEmpty == true ? r.serviceName! : 'Servicio').join(', ')),
                      onTap: () {
                        Navigator.pop(context); // Cerrar dialog
                        setState(() {
                          _focusedDay = date;
                          _selectedDay = date;
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Cargar los datos de clientes cuando se cargan las reservaciones
  Future<void> _loadClientsData(List<ReservationModel> reservations) async {
    // Solo cargar clientes que no están en caché
    final reservationsToLoad = reservations
        .where((r) => !_clientsCache.containsKey(r.id))
        .toList();
    
    if (reservationsToLoad.isEmpty) return;
    
    // Cargar clientes en lotes para mejorar el rendimiento
    const batchSize = 10;
    for (int i = 0; i < reservationsToLoad.length; i += batchSize) {
      final batch = reservationsToLoad.skip(i).take(batchSize);
      final futures = batch.map((reservation) async {
        try {
          final fullReservation = await ref.read(
            fullReservationByIdProviderVQ(reservation.id).future
          );
          _clientsCache[reservation.id] = fullReservation?.client;
        } catch (e) {
          _clientsCache[reservation.id] = null;
        }
      });
      
      await Future.wait(futures);
      
      // Actualizar la UI después de cada lote
      if (mounted) {
        setState(() {});
      }
    }
  }
  
  // Función para filtrar reservaciones según la búsqueda
  List<ReservationModel> _filterReservations(List<ReservationModel> reservations) {
    if (_searchQuery.isEmpty) {
      return reservations;
    }
    
    final query = _searchQuery.toLowerCase().trim();
    
    return reservations.where((reservation) {
      // Buscar en el ID de la reservación
      final idMatch = reservation.id.toLowerCase().contains(query);
      
      // Buscar en las notas
      final notesMatch = (reservation.nota ?? '').toLowerCase().contains(query);
      
      // Buscar en el lugar
      final placeMatch = (reservation.place ?? '').toLowerCase().contains(query);
      
      // Buscar en el nombre del vendedor
      final sellerMatch = reservation.sellerName.toLowerCase().contains(query);
      
      // Buscar en el nombre del cliente (usando el cache)
      bool clientMatch = false;
      final client = _clientsCache[reservation.id];
      if (client != null) {
        final clientName = client.customerName.toLowerCase();
        final clientPhone = client.phoneNumber.toLowerCase();
        clientMatch = clientName.contains(query) || clientPhone.contains(query);
      }
      
      return idMatch || notesMatch || placeMatch || sellerMatch || clientMatch;
    }).toList();
  }
  

  Widget _buildCustomViewButton(String label, String view) {
    final bool isSelected = _calendarView == view;
    
    // Usar el color principal de la aplicación directamente para evitar problemas en producción
    const Color primaryColor = Color(0xFFD59345); // kMainColor del tema de la aplicación
        
    return OutlinedButton(
      onPressed: () {
        // Asegurar que siempre podemos cambiar de vista
        if (!mounted) {
          return;
        }
        
        try {
          setState(() {
            _calendarView = view;
          });
          
          // Si cambiamos a la vista "Día", cerramos el Drawer si está abierto
          if (view == 'dia') {
            // Espera un frame para evitar errores si no hay Drawer
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final scaffoldState = Scaffold.maybeOf(context);
                if (scaffoldState != null && scaffoldState.isDrawerOpen) {
                  Navigator.of(context).maybePop();
                }
              }
            });
          }
        } catch (e) {
          // Error manejado silenciosamente
        }
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? primaryColor : Colors.white,
        foregroundColor: isSelected ? Colors.white : primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: isSelected ? 2 : 0,
        shadowColor: primaryColor.withValues(alpha: 0.3),
      ),
      child: Text(
        label, 
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // Botón personalizado para cambiar el formato del calendario

  Widget _buildReservationsList(
      AsyncValue<List<ReservationModel>> reservationsValue) {
    return reservationsValue.when(
      data: (allReservations) {
        final selectedDayKey = DateTime(
          _selectedDay?.year ?? DateTime.now().year,
          _selectedDay?.month ?? DateTime.now().month,
          _selectedDay?.day ?? DateTime.now().day,
        );
        final reservations = List<ReservationModel>.from(_reservationsByDay[selectedDayKey] ?? []);

        // Ordenar por hora ascendente
        reservations.sort((a, b) {
          final timeA = _parseTime(a.reservationTime);
          final timeB = _parseTime(b.reservationTime);
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeA.hour != timeB.hour
              ? timeA.hour.compareTo(timeB.hour)
              : timeA.minute.compareTo(timeB.minute);
        });

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

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ReservationCard(
                reservation: reservation,
                status: status,
                onTap: () => showDialog(
                context: context,
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

  void _showCancelConfirmation(ReservationModel reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reservación'),
        content:
            const Text('¿Estás seguro que deseas cancelar esta reservación?'),
        actions: [
          TextButton(
            key: const Key('cancel_reservation_no_button'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            key: const Key('cancel_reservation_confirm_button'),
            onPressed: () {
              // En lugar de cancelar directamente, mostramos el diálogo de contraseña
              Navigator.of(context).pop(); // Cierra el diálogo de confirmación
              _showPasswordDialog(context, reservation);
            },
            child: const Text('Sí, Cancelar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  // Método para verificar la contraseña antes de cancelar
  void _showPasswordDialog(BuildContext context, ReservationModel reservation) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingrese la contraseña'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese la contraseña';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Validar contraseña con Firebase
                final isValid = await DeletionPasswordService.validatePassword(
                  passwordController.text,
                );

                if (!isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contraseña incorrecta'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop(); // Cierra el diálogo de contraseña

                // Procede a cancelar la reservación
                await ref.read(cancelReservationProvider(reservation.id).future);
              }
            },
            child: const Text('Confirmar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String date) {
    if (date.isEmpty) return null;
    try {
      // Primero intentar formato ISO 8601 completo (PostgreSQL: 2026-01-03T00:00:00.000Z)
      if (date.contains('T')) {
        return DateTime.parse(date);
      }
      // Luego intentar formato simple (Firebase: yyyy-MM-dd)
      return DateFormat('yyyy-MM-dd').parse(date);
    } catch (e) {
      // Si falla, intentar DateTime.parse como fallback
      try {
        return DateTime.parse(date);
      } catch (_) {
        return null;
      }
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

  // _buildDressName se usa en ReservationCard, no es necesario eliminarlo
  
  // Método para procesar las fechas de fiesta de reservas PRE-QUINCE FIESTA
  void _processPreQuinceFiestaReservations(List<ReservationModel> reservations) async {
    bool needsRefresh = false;
    
    for (var reservation in reservations) {
      try {
        final fullReservation = await ref.read(fullReservationByIdProviderVQ(reservation.id).future);
        
        if (fullReservation != null && 
            fullReservation.reservation['session_type'] == 'pre-quince-fiesta') {
          final fiestaDateStr = fullReservation.reservation['fiesta_date']?.toString();
          if (fiestaDateStr != null && fiestaDateStr.isNotEmpty) {
            final fiestaDate = _parseDate(fiestaDateStr);
            if (fiestaDate != null) {
              final fiestaDateKey = DateTime(fiestaDate.year, fiestaDate.month, fiestaDate.day);
              
              // Verificar que no esté ya agregada (con isFiestaDate=true)
              final existingReservations = _reservationsByDay[fiestaDateKey] ?? [];
              if (!existingReservations.any((r) => r.id == reservation.id && r.isFiestaDate)) {
                _reservationsByDay
                    .putIfAbsent(fiestaDateKey, () => [])
                    .add(reservation.copyWith(
                      isFiestaDate: true,
                      reservationDate: fiestaDateStr,
                      reservationTime: fullReservation.reservation['fiesta_time']?.toString() ?? reservation.reservationTime,
                    ));
                needsRefresh = true;
              }
            }
          }
        }
      } catch (e) {
      }
    }
    
    // Si se agregó alguna fecha de fiesta, actualizar la UI
    if (needsRefresh && mounted) {
      setState(() {});
    }
  }

  // Método para construir un elemento de la leyenda de colores
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class ReservationDetailView extends ConsumerWidget {
  final ReservationModel reservation;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onClose;

  const ReservationDetailView({
    required this.reservation,
    required this.onEdit,
    required this.onCancel,
    required this.onClose,
  });

  void _showImageDialog(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: InteractiveViewer(
        panEnabled: true,
        minScale: 0.5,
        maxScale: 4,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullReservationAsync =
        ref.watch(fullReservationByIdProviderVQ(reservation.id));

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650, // o el tamaño que desees
          maxHeight: 700, // opcional
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
                    final aditionals = reservationData['aditionals'] as List<dynamic>? ?? [];
                    final hasAditionals = aditionals.isNotEmpty;
                    final dress = fullReservation.dress;
                    final service = fullReservation.service;
                    final client = fullReservation.client;
                    // Buscar vestidos en multiple_dress (Firebase), dresses_data o dress_ids (PostgreSQL)
                    var dressComposite = reservationData['multiple_dress'] ?? [];
                    if (dressComposite is! List || dressComposite.isEmpty) {
                      dressComposite = reservationData['dresses_data'] ?? [];
                    }
                    if (dressComposite is! List || dressComposite.isEmpty) {
                      dressComposite = reservationData['dress_ids'] ?? [];
                    }

                    // Obtener service_name desde PostgreSQL o Firebase
                    final serviceName = reservationData['service_name'] ??
                                        (service != null ? (service['name'] ?? service['serviceName'] ?? '') : '');

                    String formattedDate;
                    try {
                      final date = DateFormat('yyyy-MM-dd')
                          .parse(reservationData['reservation_date'] ?? '');
                      formattedDate = DateFormat.yMMMMd('es').format(date);
                    } catch (e) {
                      formattedDate = reservationData['reservation_date'] ?? '';
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        const SizedBox(height: 16),
                        Text(
                          'Detalles de la Reservación',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        if (client != null &&
                            client.dueAmount.toDouble() > 0) ...[
                          Text(
                            'El cliente tiene un balance pendiente',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                          ),
                          // Botón "Añadir Pago" oculto
                        ],

                        const SizedBox(height: 12),

                        // Contenido scrollable
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                if (dress != null &&
                                    dress['images'] != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _buildDressImage(dress['images']),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                _buildSection(
                                  context,
                                  title: 'Información de la Reservación',
                                  children: [
                                    _buildDetailItem(Icons.calendar_today,
                                        'Fecha', formattedDate),
                                    _buildDetailItem(
                                        Icons.access_time,
                                        'Hora',
                                        formatReservationTime(reservationData['reservation_time'] ?? '')),
                                    _buildDetailItem(Icons.business, 'Sucursal',
                                        reservationData['branch_id'] ?? ''),
                                    _buildDetailItem(
                                        Icons.place,
                                        'Lugar',
                                        reservationData['place'] ??
                                            'Sin lugar'),
                                    _buildDetailItem(
                                        Icons.textsms_outlined,
                                        'Notas',
                                        reservationData['nota'] ?? 'Sin notas'),
                                  ],
                                ),

                                // Información del Cliente - usar datos de PostgreSQL o lookup
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
                                  )
                                else if (reservationData['customer_name'] != null)
                                  _buildSection(
                                    context,
                                    title: 'Información del Cliente',
                                    children: [
                                      _buildDetailItem(Icons.person, 'Nombre',
                                          reservationData['customer_name']?.toString() ?? ''),
                                      _buildDetailItem(Icons.phone, 'Teléfono',
                                          reservationData['customer_phone']?.toString() ?? reservationData['client_id']?.toString() ?? ''),
                                    ],
                                  ),
                                // Información del Vestido - usar datos de PostgreSQL o lookup
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
                                  )
                                else if (reservationData['vestido'] != null && reservationData['vestido'].toString().isNotEmpty)
                                  _buildSection(
                                    context,
                                    title: 'Información del Vestido',
                                    children: [
                                      _buildDetailItem(Icons.checkroom,
                                          'Vestido', reservationData['vestido']?.toString() ?? ''),
                                    ],
                                  ),
                                // Mostrar sección de vestimenta si hay vestidos o servicio
                              if ((dressComposite is List && dressComposite.isNotEmpty) || serviceName.isNotEmpty)
                                  _buildSection(
                                    context,
                                    title: 'Información de Vestimenta y Paquete',
                                    children: [
                                      if (dressComposite is List && dressComposite.isNotEmpty)
                                        _buildDetailItemComposite(context, Icons.checkroom,
                                            'Vestido', dressComposite),
                                      if (serviceName.isNotEmpty)
                                        _buildDetailItem(Icons.photo_camera, 'Paquete/Servicio', serviceName),
                                      _buildDetailItem(
                                          Icons.category,
                                          'Categoría',
                                          service != null
                                              ? (service['category'] ?? '')
                                              : ''),
                                    ],
                                  ),

                                  if (hasAditionals)
                                    _buildSection(
                                      context,
                                      title: 'Adicionales',
                                      children: [
                                        ...aditionals.map((aditional) {
                                          final nota = aditional['nota']?.toString() ?? 'Sin notas';
                                          final packagePrice = aditional['package_price']?.toString() ?? '0';
                                          final reservationDate = aditional['reservation_date']?.toString() ?? '';
                                          final reservationTime = aditional['reservation_time']?.toString() ?? '';
                                          // Vestidos: Firebase usa multiple_dress, PostgreSQL usa dresses_data o dress_ids
                                          var dressCompositeAditional = aditional['multiple_dress'] as List<dynamic>? ?? [];
                                          if (dressCompositeAditional.isEmpty) {
                                            dressCompositeAditional = aditional['dresses_data'] as List<dynamic>? ?? [];
                                          }
                                          if (dressCompositeAditional.isEmpty) {
                                            dressCompositeAditional = aditional['dress_ids'] as List<dynamic>? ?? [];
                                          }
                                          final dressCompositeAdit = dressCompositeAditional; // Used below for additionals display

                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(Icons.add_circle_outline, size: 22, color: Colors.blue),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Adicional de vestimenta - \$$packagePrice', // Aquí agregamos el precio
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          if (reservationDate.isNotEmpty && reservationTime.isNotEmpty)
                                                            Text(
                                                              'Fecha: $reservationDate - ${formatReservationTime(reservationTime)}',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors.grey[600],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                
                                                if (nota.isNotEmpty && nota != 'Sin notas')
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4, left: 34),
                                                    child: Text(
                                                      'Notas: $nota',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),

                                                if (dressCompositeAdit.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 8, left: 34),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          'Items incluidos:',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        ...dressCompositeAdit.map((dress) {
                                                          final dressName = dress['dress_name']?.toString() ?? 'Sin nombre';
                                                          final branchId = dress['branch_id']?.toString() ?? 'Sin sucursal';
                                                          
                                                          return Consumer(
                                                            builder: (context, ref, _) {
                                                              final dressesAsync = ref.watch(dressesByStatusProvider('Todos'));
                                                              
                                                              return dressesAsync.when(
                                                                loading: () => const CircularProgressIndicator(),
                                                                error: (e, _) => Text('Error: $e'),
                                                                data: (dressesList) {
                                                                  DressModel? matchedDress;
                                                                  try {
                                                                    matchedDress = dressesList.firstWhere(
                                                                      (d) =>
                                                                          d.name.toString().removeAllWhiteSpace().toLowerCase() ==
                                                                          dressName.removeAllWhiteSpace().toLowerCase() &&
                                                                          d.branchId.toString() == branchId,
                                                                    );
                                                                  } catch (_) {
                                                                    matchedDress = null;
                                                                  }
                                                                  
                                                                  String imageUrl = '';
                                                                  if (matchedDress != null && matchedDress.images.isNotEmpty) {
                                                                    imageUrl = matchedDress.images.first;
                                                                  }

                                                                  return Padding(
                                                                    padding: const EdgeInsets.only(top: 8),
                                                                    child: Row(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        if (imageUrl.isNotEmpty)
                                                                          GestureDetector(
                                                                            onTap: () => _showImageDialog(context, imageUrl),
                                                                            child: ClipRRect(
                                                                              borderRadius: BorderRadius.circular(6),
                                                                              child: CachedNetworkImage(
                                                                                imageUrl: imageUrl,
                                                                                width: 40,
                                                                                height: 40,
                                                                                fit: BoxFit.cover,
                                                                                errorWidget: (_, __, ___) => Icon(
                                                                                  Icons.image_not_supported,
                                                                                  color: Colors.grey[400],
                                                                                  size: 24,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        if (imageUrl.isNotEmpty) const SizedBox(width: 10),
                                                                        Expanded(
                                                                          child: Column(
                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                            children: [
                                                                              Text(
                                                                                '• $dressName',
                                                                                style: TextStyle(
                                                                                  fontSize: 14,
                                                                                  color: Colors.grey[600],
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                branchId,
                                                                                style: TextStyle(
                                                                                  fontSize: 12,
                                                                                  color: Colors.grey[500],
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            },
                                                          );
                                                        }).toList(),
                                                      ],
                                                    ),
                                                  ),
                                                const Divider(height: 20),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
  ),
                                
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
                                const SizedBox(height: 16),

                                // ─── SECCIÓN: Estado de Vestimentas ───
                                if (service != null && service['components'] is List && (service['components'] as List).isNotEmpty)
                                  _buildGarmentStatusSection(
                                    context,
                                    ref,
                                    service: service,
                                    dressComposite: dressComposite,
                                    reservationId: fullReservation!.id,
                                    reservationDate: reservationData['reservation_date'] ?? '',
                                  ),

                                const SizedBox(height: 8),

                                // ─── BOTÓN: Cambiar Fecha ───
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.calendar_month, size: 20),
                                      label: const Text('Cambiar Fecha'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.deepPurple,
                                        side: const BorderSide(color: Colors.deepPurple),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final authorized = await _showPasswordDialog(context, 'Cambiar Fecha');
                                        if (!authorized || !context.mounted) return;
                                        _showRescheduleDialog(
                                          context,
                                          ref,
                                          reservationId: fullReservation.id,
                                          currentDate: reservationData['reservation_date'] ?? '',
                                          currentTime: reservationData['reservation_time'] ?? '',
                                          dressComposite: dressComposite,
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          key: const Key('reservation_edit_button'),
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
                                          key: const Key('reservation_cancel_button'),
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
        ),
      ),
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
      BuildContext context, IconData icon, String title, dynamic dressComposite) {
    // Usar Consumer para obtener la lista de vestidos
    return Consumer(
      builder: (context, ref, _) {
        final dressesAsync = ref.watch(dressesByStatusProvider('Todos'));
        // Validar que dressComposite sea una lista
        final List<dynamic> compositeList =
            (dressComposite is List) ? dressComposite : [];
        return dressesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error al cargar vestidos: $e'),
          data: (dressesList) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: compositeList.map<Widget>((item) {
                String dressName = (item['dress_name'] ?? '').toString();
                final branchId = (item['branch_id'] ?? '').toString();
                final dressId = (item['dress_id'] ?? '').toString();
                
                // Buscar el modelo DressModel por dress_id primero, luego por nombre
                DressModel? match;
                
                // 1. Buscar por dress_id (más confiable)
                if (dressId.isNotEmpty) {
                  try {
                    match = dressesList.firstWhere((d) => d.id == dressId);
                  } catch (_) {}
                }
                
                // 2. Fallback: buscar por nombre + branch
                if (match == null && dressName.isNotEmpty) {
                  try {
                    match = dressesList.firstWhere(
                      (d) =>
                          d.name.toString().removeAllWhiteSpace().toLowerCase() ==
                          dressName.removeAllWhiteSpace().toLowerCase() &&
                          d.branchId.toString() == branchId,
                    );
                  } catch (_) {
                    match = null;
                  }
                }
                
                // Resolver nombre del vestido desde el modelo
                if (match != null && (dressName.isEmpty || dressName == 'Sin nombre')) {
                  dressName = match.name;
                }
                if (dressName.isEmpty) dressName = 'Sin nombre';
                String imageUrl = '';
                String? dressState;
                if (match != null && match.images.isNotEmpty) {
                  imageUrl = match.images.first.toString();
                  dressState = match.state;
                } else if (item['image'] != null && item['image'].toString().isNotEmpty) {
                  imageUrl = item['image'].toString();
                  dressState = item['state']?.toString();
                } else if (item['images'] != null) {
                  if (item['images'] is List && (item['images'] as List).isNotEmpty) {
                    imageUrl = item['images'][0].toString();
                  } else if (item['images'] is String && item['images'].toString().isNotEmpty) {
                    imageUrl = item['images'].toString().split(',').first.trim().replaceAll(RegExp(r'[\[\]"]'), '');
                  }
                  dressState = item['state']?.toString();
                }

                // Lógica para mostrar el estado "En Sesión" solo si la hora ya llegó
                // Eliminada variable local no usada showState;
                if (dressState != null && dressState.toLowerCase() == 'sesión') {
                  // Buscar la hora de la sesión
                  String? sessionTime = item['session_time']?.toString();
                  String? sessionDate = item['session_date']?.toString();
                  // Si no hay hora/fecha en el item, intentar usar reservation_time/reservation_date
                  sessionTime ??= item['reservation_time']?.toString();
                  sessionDate ??= item['reservation_date']?.toString();
                  if (sessionTime != null && sessionDate != null) {
                    try {
                      final now = DateTime.now();
                      final date = DateFormat('yyyy-MM-dd').parse(sessionDate);
                      final timeParts = sessionTime.split(':');
                      final sessionDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        int.parse(timeParts[0]),
                        int.parse(timeParts[1]),
                      );
                  if (now.isAfter(sessionDateTime)) {
                    // Solo mostrar el estado, no usar variable showState
                  }
                    } catch (_) {}
                  }
                } else if (dressState != null && dressState.isNotEmpty && dressState.toLowerCase() != 'disponible') {
                  // Solo mostrar el estado, no usar variable showState
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 22, color: Colors.grey[700]),
                      const SizedBox(width: 12),
                      if (imageUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => Dialog(
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    InteractiveViewer(
                                      panEnabled: true,
                                      minScale: 0.5,
                                      maxScale: 4,
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error, color: Colors.red, size: 80),
                                      ),
                                    ),
                                    Positioned(
                                      top: 20,
                                      right: 20,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red, size: 30),
                                        onPressed: () => Navigator.pop(dialogContext),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.image_not_supported, color: Colors.grey[400], size: 24),
                            ),
                          ),
                        ),
                      if (imageUrl.isNotEmpty) const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  dressName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  branchId,
                                  style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 3, 3, 3)),
                                ),
                                // Mostrar solo si la hora de la sesión ya llegó
                                if (dressState != null && dressState.toLowerCase() == 'sesión') ...[
                                  const SizedBox(width: 8),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.all(Radius.circular(6)),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      child: Text(
                                        'En Sesión',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // _buildInfoItem eliminado porque no se utiliza

  Widget _buildDressImage(dynamic images, {BuildContext? parentContext}) {
    String imageUrl = '';

    if (images is String) {
      imageUrl =
          images.split(',').first.trim().replaceAll(RegExp(r'[\[\]"]'), '');
    } else if (images is List && images.isNotEmpty) {
      imageUrl = images.first.toString();
    }

    return Builder(
      builder: (context) {
        final effectiveContext = parentContext ?? context;
        return GestureDetector(
          onTap: imageUrl.isNotEmpty
              ? () {
                  showDialog(
                    context: effectiveContext,
                    builder: (dialogContext) => Dialog(
                      insetPadding: EdgeInsets.zero,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4,
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) =>
                                  const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error, color: Colors.red, size: 80),
                            ),
                          ),
                          Positioned(
                            top: 20,
                            right: 20,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 30),
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              : null,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: imageUrl.isEmpty
                ? Icon(Icons.image_not_supported, color: Colors.grey[400], size: 40)
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.image_not_supported, color: Colors.grey[400], size: 40),
                  ),
          ),
        );
      },
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

  // ─── MÉTODO: Estado de Vestimentas ───
  Widget _buildGarmentStatusSection(
    BuildContext context,
    WidgetRef ref, {
    required Map<String, dynamic> service,
    required dynamic dressComposite,
    required String reservationId,
    required String reservationDate,
  }) {
    final components = service['components'] as List;
    final selectedDresses = (dressComposite is List) ? dressComposite : [];
    
    // Obtener el ServicePackageModel para el selector de vestidos
    final serviceId = service['id']?.toString() ?? service['firebase_id']?.toString() ?? '';
    final packagesAsync = ref.watch(servicePackagesProvider);
    
    ServicePackageModel? packageModel;
    if (packagesAsync is AsyncData<List<ServicePackageModel>>) {
      try {
        packageModel = packagesAsync.value?.firstWhere(
          (p) => p.id == serviceId || p.name == (service['name'] ?? ''),
        );
      } catch (_) {
        packageModel = null;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checkroom, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Estado de Vestimentas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: selectedDresses.length >= components.length
                        ? Colors.green.withValues(alpha: 0.15)
                        : const Color(0xFFD32F2F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedDresses.length}/${components.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selectedDresses.length >= components.length ? Colors.green : const Color(0xFFD32F2F),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            ...List.generate(components.length, (index) {
              final componentName = components[index]?.toString() ?? 'Componente';
              
              // Buscar si este componente ya tiene un vestido asignado
              Map<String, dynamic>? matchedDress;
              if (index < selectedDresses.length) {
                matchedDress = (selectedDresses[index] is Map) 
                    ? Map<String, dynamic>.from(selectedDresses[index]) 
                    : null;
              }
              
              final isSelected = matchedDress != null;
              final dressName = matchedDress?['dress_name']?.toString() ?? 
                               matchedDress?['name']?.toString() ?? '';
              final branchId = matchedDress?['branch_id']?.toString() ?? '';
              final dressId = matchedDress?['dress_id']?.toString() ?? '';

              // Buscar imagen del vestido y nombre real
              String imageUrl = '';
              String resolvedDressName = dressName;
              if (isSelected) {
                final dressesAsync = ref.watch(dressesByStatusProvider('Todos'));
                if (dressesAsync is AsyncData<List<DressModel>>) {
                  DressModel? matchModel;
                  
                  // 1. Buscar por dress_id (más confiable)
                  if (dressId.isNotEmpty) {
                    try {
                      matchModel = dressesAsync.value!.firstWhere(
                        (d) => d.id == dressId,
                      );
                    } catch (_) {}
                  }
                  
                  // 2. Fallback: buscar por nombre + branch
                  if (matchModel == null && dressName.isNotEmpty) {
                    try {
                      matchModel = dressesAsync.value!.firstWhere(
                        (d) => d.name.toString().trim().toLowerCase() == dressName.trim().toLowerCase() &&
                               (branchId.isEmpty || d.branchId.toString() == branchId),
                      );
                    } catch (_) {
                      try {
                        matchModel = dressesAsync.value!.firstWhere(
                          (d) => d.name.toString().trim().toLowerCase() == dressName.trim().toLowerCase(),
                        );
                      } catch (_) {}
                    }
                  }
                  
                  if (matchModel != null) {
                    if (matchModel.images.isNotEmpty) {
                      imageUrl = matchModel.images.first.toString();
                    }
                    if (resolvedDressName.isEmpty) {
                      resolvedDressName = matchModel.name;
                    }
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Thumbnail o ícono de estado
                    if (isSelected && imageUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showImageDialog(context, imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.checkroom, size: 20, color: Colors.green),
                            ),
                          ),
                        ),
                      )
                    else if (isSelected)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.checkroom, size: 20, color: Colors.green),
                      )
                    else
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.checkroom, size: 20, color: Colors.grey[400]),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            componentName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                          if (isSelected && resolvedDressName.isNotEmpty)
                            Text(
                              resolvedDressName,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                        ],
                      ),
                    ),
                    if (!isSelected && packageModel != null)
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () async {
                            final selected = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DressSelectionPackageScreen(
                                  packagesAsync: packageModel!,
                                  dressIds: selectedDresses.map((d) => (d is Map) ? d['dress_id']?.toString() ?? '' : '').toList().cast<String>(),
                                  packageId: packageModel.id,
                                  packageName: packageModel.name,
                                  CategoryComposite: componentName,
                                ),
                              ),
                            );

                            if (selected != null && selected is Map) {
                              // Agregar el nuevo vestido al array existente
                              final newDressEntry = {
                                'dress_id': selected['vestidoId'] ?? '',
                                'branch_id': selected['branchId'] ?? '',
                                'dress_name': selected['vestidoName'] ?? '',
                              };

                              final newDressId = newDressEntry['dress_id']?.toString() ?? '';
                              final newDressName = newDressEntry['dress_name']?.toString() ?? 'Vestido';

                              // ─── Validar si el vestido ya está reservado en esta fecha ───
                              if (newDressId.isNotEmpty) {
                                EasyLoading.show(status: 'Verificando disponibilidad...');
                                ref.invalidate(fullReservationsProvider);
                                final allReservations = await ref.read(fullReservationsProvider.future);
                                final normalizedDate = reservationDate.length >= 10 ? reservationDate.substring(0, 10) : reservationDate;
                                final reservationsOnDate = allReservations.where((r) {
                                  final resDate = r.reservation['reservation_date']?.toString() ?? '';
                                  final nd = resDate.length >= 10 ? resDate.substring(0, 10) : resDate;
                                  return nd == normalizedDate && r.id != reservationId;
                                }).toList();

                                bool dressConflict = false;
                                for (final existingRes in reservationsOnDate) {
                                  final Set<String> existingIds = {};
                                  for (final key in ['multiple_dress', 'dress_ids', 'dresses_data']) {
                                    final data = existingRes.reservation[key];
                                    if (data is List) {
                                      for (final d in data) {
                                        if (d is Map) {
                                          final id = d['dress_id']?.toString() ?? '';
                                          if (id.isNotEmpty) existingIds.add(id);
                                        }
                                      }
                                    }
                                  }
                                  final singleId = existingRes.reservation['dress_id']?.toString() ?? '';
                                  if (singleId.isNotEmpty) existingIds.add(singleId);
                                  if (existingIds.contains(newDressId)) {
                                    dressConflict = true;
                                    break;
                                  }
                                }
                                EasyLoading.dismiss();

                                if (dressConflict && context.mounted) {
                                  final proceed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Row(
                                        children: [
                                          Icon(Icons.warning_amber, color: Color(0xFFD32F2F)),
                                          SizedBox(width: 8),
                                          Expanded(child: Text('Vestimenta Reservada', style: TextStyle(fontSize: 18))),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('La vestimenta "$newDressName" ya está reservada para esta fecha.'),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.info_outline, size: 16, color: Color(0xFFD32F2F)),
                                                SizedBox(width: 8),
                                                Expanded(child: Text('¿Desea continuar de todas formas?', style: TextStyle(fontSize: 13, color: Color(0xFFD32F2F)))),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Sí, continuar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (proceed != true) return;
                                }
                              }

                              final updatedDresses = List<Map<String, dynamic>>.from(
                                selectedDresses.map((d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{}),
                              );
                              updatedDresses.add(newDressEntry);

                              // Actualizar en la base de datos
                              EasyLoading.show(status: 'Guardando...');
                              try {
                                final success = await ref.read(
                                  updateReservationProvider({
                                    'reservationId': reservationId,
                                    'updateData': {
                                      'dress_ids': updatedDresses.map((d) => <String, dynamic>{
                                        'dress_id': d['dress_id']?.toString() ?? '',
                                        'branch_id': d['branch_id']?.toString() ?? '',
                                        'dress_name': d['dress_name']?.toString() ?? '',
                                      }).toList(),
                                      'dresses_data': updatedDresses,
                                    },
                                  }).future,
                                );

                                EasyLoading.dismiss();
                                if (success) {
                                  EasyLoading.showSuccess('Vestimenta agregada');
                                  // Invalidar providers para refrescar
                                  ref.invalidate(fullReservationByIdProviderVQ(reservationId));
                                  ref.invalidate(fullReservationsProvider);
                                } else {
                                  EasyLoading.showError('Error al guardar');
                                }
                              } catch (e) {
                                EasyLoading.dismiss();
                                EasyLoading.showError('Error: $e');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text('Elegir', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    if (isSelected)
                      SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.swap_horiz, size: 14),
                          label: const Text('Cambiar', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            side: const BorderSide(color: Colors.deepPurple, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: packageModel == null ? null : () async {
                            final authorized = await _showPasswordDialog(context, 'Cambiar Vestimenta');
                            if (!authorized || !context.mounted) return;
                            final selected = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DressSelectionPackageScreen(
                                  packagesAsync: packageModel!,
                                  dressIds: selectedDresses
                                      .where((d) => d is Map && selectedDresses.indexOf(d) != index)
                                      .map((d) => (d is Map) ? d['dress_id']?.toString() ?? '' : '')
                                      .toList()
                                      .cast<String>(),
                                  packageId: packageModel.id,
                                  packageName: packageModel.name,
                                  CategoryComposite: componentName,
                                ),
                              ),
                            );

                            if (selected != null && selected is Map) {
                              final newDressEntry = {
                                'dress_id': selected['vestidoId'] ?? '',
                                'branch_id': selected['branchId'] ?? '',
                                'dress_name': selected['vestidoName'] ?? '',
                              };

                              final newDressId = newDressEntry['dress_id']?.toString() ?? '';
                              final newDressName = newDressEntry['dress_name']?.toString() ?? 'Vestido';

                              // ─── Validar si el vestido ya está reservado en esta fecha ───
                              if (newDressId.isNotEmpty) {
                                EasyLoading.show(status: 'Verificando disponibilidad...');
                                ref.invalidate(fullReservationsProvider);
                                final allReservations = await ref.read(fullReservationsProvider.future);
                                final normalizedDate = reservationDate.length >= 10 ? reservationDate.substring(0, 10) : reservationDate;
                                final reservationsOnDate = allReservations.where((r) {
                                  final resDate = r.reservation['reservation_date']?.toString() ?? '';
                                  final nd = resDate.length >= 10 ? resDate.substring(0, 10) : resDate;
                                  return nd == normalizedDate && r.id != reservationId;
                                }).toList();

                                bool dressConflict = false;
                                for (final existingRes in reservationsOnDate) {
                                  final Set<String> existingIds = {};
                                  for (final key in ['multiple_dress', 'dress_ids', 'dresses_data']) {
                                    final data = existingRes.reservation[key];
                                    if (data is List) {
                                      for (final d in data) {
                                        if (d is Map) {
                                          final id = d['dress_id']?.toString() ?? '';
                                          if (id.isNotEmpty) existingIds.add(id);
                                        }
                                      }
                                    }
                                  }
                                  final singleId = existingRes.reservation['dress_id']?.toString() ?? '';
                                  if (singleId.isNotEmpty) existingIds.add(singleId);
                                  if (existingIds.contains(newDressId)) {
                                    dressConflict = true;
                                    break;
                                  }
                                }
                                EasyLoading.dismiss();

                                if (dressConflict && context.mounted) {
                                  final proceed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Row(
                                        children: [
                                          Icon(Icons.warning_amber, color: Color(0xFFD32F2F)),
                                          SizedBox(width: 8),
                                          Expanded(child: Text('Vestimenta Reservada', style: TextStyle(fontSize: 18))),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('La vestimenta "$newDressName" ya está reservada para esta fecha.'),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.info_outline, size: 16, color: Color(0xFFD32F2F)),
                                                SizedBox(width: 8),
                                                Expanded(child: Text('¿Desea continuar de todas formas?', style: TextStyle(fontSize: 13, color: Color(0xFFD32F2F)))),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Sí, continuar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (proceed != true) return;
                                }
                              }

                              final updatedDresses = List<Map<String, dynamic>>.from(
                                selectedDresses.map((d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{}),
                              );
                              // Reemplazar en el índice correspondiente
                              updatedDresses[index] = newDressEntry;

                              EasyLoading.show(status: 'Cambiando vestimenta...');
                              try {
                                final success = await ref.read(
                                  updateReservationProvider({
                                    'reservationId': reservationId,
                                    'updateData': {
                                      'dress_ids': updatedDresses.map((d) => <String, dynamic>{
                                        'dress_id': d['dress_id']?.toString() ?? '',
                                        'branch_id': d['branch_id']?.toString() ?? '',
                                        'dress_name': d['dress_name']?.toString() ?? '',
                                      }).toList(),
                                      'dresses_data': updatedDresses,
                                    },
                                  }).future,
                                );

                                EasyLoading.dismiss();
                                if (success) {
                                  EasyLoading.showSuccess('Vestimenta cambiada');
                                  ref.invalidate(fullReservationByIdProviderVQ(reservationId));
                                  ref.invalidate(fullReservationsProvider);
                                } else {
                                  EasyLoading.showError('Error al cambiar');
                                }
                              } catch (e) {
                                EasyLoading.dismiss();
                                EasyLoading.showError('Error: $e');
                              }
                            }
                          },
                        ),
                      ),
                    if (isSelected)
                      const SizedBox(width: 4),
                    if (isSelected)
                      SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 14),
                          label: const Text('Quitar', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD32F2F),
                            side: const BorderSide(color: Color(0xFFD32F2F), width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () async {
                            final authorized = await _showPasswordDialog(context, 'Quitar Vestimenta');
                            if (!authorized || !context.mounted) return;
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Row(
                                  children: [
                                    Icon(Icons.warning_amber, color: Color(0xFFD32F2F)),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('Quitar Vestimenta', style: TextStyle(fontSize: 18))),
                                  ],
                                ),
                                content: Text(
                                  '¿Está seguro de quitar "${resolvedDressName.isNotEmpty ? resolvedDressName : componentName}" de esta reserva?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD32F2F),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Sí, quitar'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirm == true) {
                              final updatedDresses = List<Map<String, dynamic>>.from(
                                selectedDresses.map((d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{}),
                              );
                              updatedDresses.removeAt(index);

                              EasyLoading.show(status: 'Quitando vestimenta...');
                              try {
                                final success = await ref.read(
                                  updateReservationProvider({
                                    'reservationId': reservationId,
                                    'updateData': {
                                      'dress_ids': updatedDresses.map((d) => <String, dynamic>{
                                        'dress_id': d['dress_id']?.toString() ?? '',
                                        'branch_id': d['branch_id']?.toString() ?? '',
                                        'dress_name': d['dress_name']?.toString() ?? '',
                                      }).toList(),
                                      'dresses_data': updatedDresses,
                                    },
                                  }).future,
                                );

                                EasyLoading.dismiss();
                                if (success) {
                                  EasyLoading.showSuccess('Vestimenta quitada');
                                  ref.invalidate(fullReservationByIdProviderVQ(reservationId));
                                  ref.invalidate(fullReservationsProvider);
                                } else {
                                  EasyLoading.showError('Error al quitar');
                                }
                              } catch (e) {
                                EasyLoading.dismiss();
                                EasyLoading.showError('Error: $e');
                              }
                            }
                          },
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── MÉTODO: Diálogo de Contraseña de Autorización ───
  Future<bool> _showPasswordDialog(BuildContext context, String actionName) async {
    final passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Expanded(child: Text(actionName, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingrese la clave de autorización:'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Clave',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              onSubmitted: (_) async {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  EasyLoading.showError('Ingrese la clave');
                  return;
                }
                final isValid = await DeletionPasswordService.validatePassword(password);
                if (isValid) {
                  Navigator.pop(ctx, true);
                } else {
                  EasyLoading.showError('Clave incorrecta');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) {
                EasyLoading.showError('Ingrese la clave');
                return;
              }
              final isValid = await DeletionPasswordService.validatePassword(password);
              if (isValid) {
                Navigator.pop(ctx, true);
              } else {
                EasyLoading.showError('Clave incorrecta');
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    return result == true;
  }

  // ─── MÉTODO: Diálogo de Reprogramación ───
  void _showRescheduleDialog(
    BuildContext context,
    WidgetRef ref, {
    required String reservationId,
    required String currentDate,
    required String currentTime,
    required dynamic dressComposite,
  }) {
    DateTime selectedDate;
    try {
      selectedDate = DateTime.parse(currentDate);
    } catch (_) {
      selectedDate = DateTime.now();
    }
    
    TimeOfDay selectedTime;
    try {
      final parts = currentTime.split(':');
      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts.length > 1 ? parts[1] : '0'),
      );
    } catch (_) {
      selectedTime = TimeOfDay.now();
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  const Text('Cambiar Fecha'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha actual: ${formatReservationDate(currentDate)} - ${formatReservationTime(currentTime)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selector de fecha
                  ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                    title: Text(
                      'Nueva fecha: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  
                  // Selector de hora
                  ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.deepPurple),
                    title: Text(
                      'Nueva hora: ${selectedTime.format(context)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Se verificará la disponibilidad de las vestimentas en la nueva fecha.',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final newDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                    final newTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                    // Verificar disponibilidad de vestidos en la nueva fecha
                    EasyLoading.show(status: 'Verificando disponibilidad...');
                    
                    try {
                      // Obtener los vestidos DIRECTAMENTE de la reserva (no del parámetro dressComposite que puede estar vacío)
                      List<dynamic> dressesFromReservation = [];
                      try {
                        final fullRes = await ref.read(
                          fullReservationByIdProviderVQ(reservationId).future,
                        );
                        if (fullRes != null) {
                          final resData = fullRes.reservation;
                          // Buscar en todas las fuentes posibles
                          var md = resData['multiple_dress'];
                          if (md is List && md.isNotEmpty) {
                            dressesFromReservation = md;
                          }
                          if (dressesFromReservation.isEmpty) {
                            var dd = resData['dresses_data'];
                            if (dd is List && dd.isNotEmpty) {
                              dressesFromReservation = dd;
                            }
                          }
                          if (dressesFromReservation.isEmpty) {
                            var di = resData['dress_ids'];
                            if (di is List && di.isNotEmpty) {
                              dressesFromReservation = di;
                            }
                          }
                          debugPrint('🔍 [VALIDACIÓN] Vestidos de la reserva: ${dressesFromReservation.length}');
                          debugPrint('🔍 [VALIDACIÓN] Datos: $dressesFromReservation');
                        }
                      } catch (e) {
                        debugPrint('🔍 [VALIDACIÓN] Error obteniendo reserva: $e');
                      }
                      
                      final dresses = dressesFromReservation;
                      bool hasConflict = false;
                      List<String> conflictingDresses = [];

                      if (dresses.isNotEmpty) {
                        // Invalidar cache para obtener datos frescos
                        ref.invalidate(fullReservationsProvider);
                        // Obtener TODAS las reservas con datos completos
                        final allReservations = await ref.read(
                          fullReservationsProvider.future,
                        );

                        // Filtrar reservas de la nueva fecha (excluyendo la actual)
                        // Manejar formato ISO y simple
                        final reservationsOnDate = allReservations.where((r) {
                          final resDate = r.reservation['reservation_date']?.toString() ?? '';
                          // Comparar solo los primeros 10 chars (YYYY-MM-DD) para manejar ISO 8601
                          final normalizedResDate = resDate.length >= 10 ? resDate.substring(0, 10) : resDate;
                          final normalizedNewDate = newDate.length >= 10 ? newDate.substring(0, 10) : newDate;
                          return normalizedResDate == normalizedNewDate && r.id != reservationId;
                        }).toList();

                        debugPrint('🔍 [VALIDACIÓN] Fecha nueva: $newDate');
                        debugPrint('🔍 [VALIDACIÓN] Reservas en esa fecha: ${reservationsOnDate.length}');
                        debugPrint('🔍 [VALIDACIÓN] Vestidos a verificar: ${dresses.length}');

                        // Obtener lista de vestidos para resolver nombres
                        final dressesListAsync = ref.read(dressesByStatusProvider('Todos'));
                        final dressesList = dressesListAsync.valueOrNull ?? [];

                        for (final dress in dresses) {
                          if (dress is Map) {
                            final dressId = dress['dress_id']?.toString() ?? '';
                            String dressName = dress['dress_name']?.toString() ?? dress['name']?.toString() ?? '';
                            
                            // Resolver nombre del vestido si está vacío
                            if ((dressName.isEmpty || dressName == 'Sin nombre') && dressId.isNotEmpty) {
                              try {
                                final matchedDress = dressesList.firstWhere((d) => d.id == dressId);
                                dressName = matchedDress.name;
                              } catch (_) {
                                dressName = 'Vestido ID: $dressId';
                              }
                            }
                            
                            if (dressId.isEmpty) continue;
                            
                            debugPrint('🔍 [VALIDACIÓN] Verificando vestido: $dressName (ID: $dressId)');
                            
                            // Verificar si este vestido está en otra reserva del mismo día
                            for (final existingRes in reservationsOnDate) {
                              // Extraer TODOS los dress IDs de la reserva existente
                              final Set<String> existingDressIds = {};
                              
                              // 1. Buscar en multiple_dress
                              final multipleDress = existingRes.reservation['multiple_dress'];
                              if (multipleDress is List) {
                                for (final d in multipleDress) {
                                  if (d is Map) {
                                    final id = d['dress_id']?.toString() ?? '';
                                    if (id.isNotEmpty) existingDressIds.add(id);
                                  }
                                }
                              }
                              
                              // 2. Buscar en dress_ids
                              final rawDressIds = existingRes.reservation['dress_ids'];
                              if (rawDressIds is List) {
                                for (final d in rawDressIds) {
                                  if (d is Map) {
                                    final id = d['dress_id']?.toString() ?? '';
                                    if (id.isNotEmpty) existingDressIds.add(id);
                                  } else if (d is String && d.isNotEmpty) {
                                    existingDressIds.add(d);
                                  }
                                }
                              }
                              
                              // 3. Buscar en dresses_data
                              final rawDressesData = existingRes.reservation['dresses_data'];
                              if (rawDressesData is List) {
                                for (final d in rawDressesData) {
                                  if (d is Map) {
                                    final id = d['dress_id']?.toString() ?? '';
                                    if (id.isNotEmpty) existingDressIds.add(id);
                                  }
                                }
                              }
                              
                              // 4. Buscar dress_id singular (reserva con 1 solo vestido)
                              final singleDressId = existingRes.reservation['dress_id']?.toString() ?? '';
                              if (singleDressId.isNotEmpty) existingDressIds.add(singleDressId);
                              
                              debugPrint('🔍 [VALIDACIÓN] Reserva ${existingRes.id} tiene IDs: $existingDressIds');
                              
                              if (existingDressIds.contains(dressId)) {
                                hasConflict = true;
                                if (!conflictingDresses.contains(dressName)) {
                                  conflictingDresses.add(dressName);
                                }
                                debugPrint('⚠️ [VALIDACIÓN] ¡CONFLICTO! $dressName ya reservado');
                              }
                            }
                          }
                        }
                      }

                      debugPrint('🔍 [VALIDACIÓN] Resultado: hasConflict=$hasConflict, conflictos=${conflictingDresses.length}');

                      EasyLoading.dismiss();

                      if (hasConflict && context.mounted) {
                        final proceed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.warning_amber, color: Color(0xFFD32F2F)),
                                SizedBox(width: 8),
                                Expanded(child: Text('Conflicto de Vestimentas', style: TextStyle(fontSize: 18))),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Las siguientes vestimentas ya están reservadas para el $newDate:',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                ...conflictingDresses.map((name) => Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, size: 8, color: Color(0xFFD32F2F)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                    ],
                                  ),
                                )),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 16, color: Color(0xFFD32F2F)),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '¿Desea continuar de todas formas?',
                                          style: TextStyle(fontSize: 13, color: Color(0xFFD32F2F)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sí, continuar'),
                              ),
                            ],
                          ),
                        );

                        if (proceed != true) return;
                      }

                      // Cerrar el diálogo de selección de fecha
                      if (context.mounted) Navigator.pop(dialogContext);

                      // Actualizar la reserva
                      EasyLoading.show(status: 'Actualizando fecha...');
                      final success = await ref.read(
                        updateReservationProvider({
                          'reservationId': reservationId,
                          'updateData': {
                            'reservation_date': newDate,
                            'reservation_time': newTime,
                          },
                        }).future,
                      );

                      EasyLoading.dismiss();
                      if (success) {
                        EasyLoading.showSuccess('Fecha actualizada a $newDate $newTime');
                        ref.invalidate(fullReservationByIdProviderVQ(reservationId));
                        ref.invalidate(fullReservationsProvider);
                      } else {
                        EasyLoading.showError('Error al actualizar la fecha');
                      }
                    } catch (e) {
                      EasyLoading.dismiss();
                      EasyLoading.showError('Error: $e');
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
