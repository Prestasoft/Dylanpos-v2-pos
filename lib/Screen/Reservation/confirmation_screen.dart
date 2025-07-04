import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro_admin/Provider/customer_provider.dart';
import 'package:salespro_admin/Provider/servicePackagesProvider.dart';
import 'package:salespro_admin/Screen/Reservation/package_reservation_components_screen.dart';
import 'package:salespro_admin/model/customer_model.dart';
import '../../Provider/reservation_provider.dart';
import '../../const.dart';
class ConfirmationScreen extends ConsumerStatefulWidget {
  final String packageId;
  final String packageName;
  final String dressId;
  final String dressName;
  final String branchId;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String clientId;
  final List<DressReservation> dressReservations;
  // Campos opcionales para la segunda fecha/hora de fiesta
  final DateTime? fiestaDate;
  final TimeOfDay? fiestaTime;

  const ConfirmationScreen({
    Key? key,
    required this.packageId,
    required this.packageName,
    required this.dressId,
    required this.dressName,
    required this.branchId,
    required this.selectedDate,
    required this.selectedTime,
    required this.clientId,
    required this.dressReservations,
    this.fiestaDate,
    this.fiestaTime,
  }) : super(key: key);

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  bool isSubmitting = false;

  TextEditingController lugarController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatTime(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }  void _confirmReservation() async {
    setState(() {
      isSubmitting = true;
    });

    final String formattedDate = _formatDate(widget.selectedDate);
    final String formattedTime = _formatTime(widget.selectedTime);

    // Verificar si es un plan PRE-QUINCE FIESTA
    String _normalize(String s) {
      final withNoSpaces = s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final withNoAccents = withNoSpaces
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
      final withoutPlan = withNoAccents.replaceFirst(RegExp(r'^plan [a-z]\s*'), '');
      return withoutPlan;
    }
    final normalizedName = _normalize(widget.packageName);
    final isPreQuinceFiesta = normalizedName.contains('pre-quince y fiesta') ||
                             normalizedName.contains('pre-quince fiesta') ||
                             normalizedName.contains('pre quince y fiesta') ||
                             normalizedName.contains('pre quince fiesta') ||
                             normalizedName.contains('quinceanera y fiesta');

    double packagePrice = 0.0;

    final packages = ref.watch(servicePackagesProvider);
    if (packages.hasValue) {
      final package = packages.value!.firstWhere(
        (p) => p.id == widget.packageId,
      );
      packagePrice = package.price;
    }

    // Verificar disponibilidad para la fecha principal
    bool isAvailable = true;

    if (widget.dressReservations.isEmpty) {
      isAvailable = await ref.read(isDressAvailableProvider({
        'dressId': widget.dressId,
        'date': formattedDate,
        'time': formattedTime,
      }).future);
    } else {
      for (var dress in widget.dressReservations) {
        bool available = true;

        if (dress.componentName != "Sin Vestimenta") {
          available = await ref.read(
            isDressAvailableProvider({
              'dressId': dress.id,
              'date': formattedDate,
              'time': formattedTime,
            }).future,
          );
        }

        if (!available) {
          isAvailable = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El vestido "${dress.name}" ya fue reservado para la sesión de pre-quince.'),
            ),
          );
          break;
        }
      }
    }

    // Si es PRE-QUINCE FIESTA, verificar también la disponibilidad para la fecha de la fiesta
    bool isFiestaAvailable = true;
    if (isPreQuinceFiesta && widget.fiestaDate != null && widget.fiestaTime != null) {
      final String formattedFiestaDate = _formatDate(widget.fiestaDate!);
      final String formattedFiestaTime = _formatTime(widget.fiestaTime!);

      if (widget.dressReservations.isEmpty) {
        isFiestaAvailable = await ref.read(isDressAvailableProvider({
          'dressId': widget.dressId,
          'date': formattedFiestaDate,
          'time': formattedFiestaTime,
        }).future);
      } else {
        for (var dress in widget.dressReservations) {
          bool available = true;

          if (dress.componentName != "Sin Vestimenta") {
            available = await ref.read(
              isDressAvailableProvider({
                'dressId': dress.id,
                'date': formattedFiestaDate,
                'time': formattedFiestaTime,
              }).future,
            );
          }

          if (!available) {
            isFiestaAvailable = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('El vestido "${dress.name}" ya fue reservado para la fecha de la fiesta.'),
              ),
            );
            break;
          }
        }
      }
    }

    if (!isAvailable || !isFiestaAvailable) {
      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Lo sentimos, este vestido ya fue reservado. Por favor elige otra fecha u hora."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String dressIdTmp = "";
    String branchIdTmp = "";
    List<Map<String, String>> multipleDress = [];

    // Logica que guarda segun un o varios vestidos
    if (widget.dressName.isNotEmpty) {
      // Si solo hay un vestido
      dressIdTmp = widget.dressId;
      branchIdTmp = widget.branchId;
    } else {
      // Si hay varios vestidos
      multipleDress = widget.dressReservations.map((dress) {
        return {
          'dress_id': dress.id,
          'branch_id': dress.branchId,
          'dress_name': dress.name,
        };
      }).toList();
    }

    // Preparar datos para la reserva
    final Map<String, dynamic> reservationData = {
      'serviceId': widget.packageId,
      'clientId': widget.clientId,
      'dressId': dressIdTmp,
      'branchId': branchIdTmp,
      'date': formattedDate,
      'time': formattedTime,
      'multiple_dress': multipleDress,
      'estado_factura': false,
      'note': noteController.text,
      'package_price': packagePrice.toString(), // Precio completo, sin dividir
      'place': lugarController.text,
      'seller_name': isSubUser ? constSubUserTitle : 'Admin',
      'session_type': isPreQuinceFiesta ? 'pre-quince-fiesta' : 'normal',
    };

    // Si es PRE-QUINCE FIESTA, agregar los campos de fecha fiesta
    if (isPreQuinceFiesta && widget.fiestaDate != null && widget.fiestaTime != null) {
      final String formattedFiestaDate = _formatDate(widget.fiestaDate!);
      final String formattedFiestaTime = _formatTime(widget.fiestaTime!);
      
      reservationData['fiesta_date'] = formattedFiestaDate;
      reservationData['fiesta_time'] = formattedFiestaTime;
    }

    // Crear la reserva única
    final success = await ref.read(crearReservaProvider(reservationData).future);

    setState(() {
      isSubmitting = false;
    });

    if (success.statusReservation) {
      // Show success message
      String successMessage = isPreQuinceFiesta 
        ? "¡Reserva de PRE-QUINCE y FIESTA registrada exitosamente!"
        : "¡Reserva registrada exitosamente!";
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
        ),
      );

      // Agregar cuadro de dialogo si quiero añadir adicionales
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Adicionales para las reservas'),
          content: const Text('Desea agregar adicionales a la reservación?'),
          actions: [
            TextButton(
              onPressed: () async {
                // Navigate to the POS sales screen
                if (mounted) {
                  // Actualiza el estado del menú lateral
                  // ref.read(sidebarProvider.notifier)
                  // ..expandMenu('/reservations') // Expande el menú de Ventas
                  // ..selectItem('/reservations/rent-clothes'); // Selecciona el ítem

                  // Navega a la pantalla
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  //Navigator.of(context).pop(); // Cierra el diálogo de confirmación
                  final customerList = ref.watch(allCustomerProvider);
                  String clientName = "";
                  if (customerList.hasValue) {
                    List<CustomerModel> customersList = customerList.value!
                        .where((c) => c.type != 'Supplier')
                        .toList();
                    final client = customersList
                        .firstWhere((c) => c.phoneNumber == widget.clientId);

                    clientName = client.customerName;
                  }

                  // Navega a la pantalla de ClothesReservationScreen
                  context.go('/reservations/list2', extra: {
                    'packageId': widget.packageId,
                    'packageName': widget.packageName,
                    'selectedDate': widget.selectedDate,
                    'selectedTime': widget.selectedTime,
                    'clientId': widget.clientId,
                    'clientName': clientName,
                    'reservationId': success.reservationId,
                    'package_price': packagePrice.toString(),
                  });
                }
              },
              child: const Text('Si'),
            ),
            TextButton(
              onPressed: () async {
                // Navigate to the POS sales screen
                if (mounted) {
                  // Actualiza el estado del menú lateral
                  Navigator.of(context)
                      .pop(); // Cierra el diálogo de confirmación

                  ref.read(sidebarProvider.notifier)
                    ..expandMenu('/reservations') // Expande el menú de Ventas
                    ..selectItem(
                        '/reservations/calendario'); // Selecciona el ítem

                  // Navega a la pantalla
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  context.go('/reservations/calendario');
                }
              },
              child: const Text('No'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Error al crear la reserva. Por favor intenta de nuevo."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Normalización para detectar "pre-quince y fiesta" en cualquier variante de plan
    String _normalize(String s) {
      final withNoSpaces = s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final withNoAccents = withNoSpaces
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
      final withoutPlan = withNoAccents.replaceFirst(RegExp(r'^plan [a-z]\s*'), '');
      return withoutPlan;
    }
    final normalizedName = _normalize(widget.packageName);
    final isPreQuinceFiesta = normalizedName.contains('pre-quince y fiesta') ||
                             normalizedName.contains('pre-quince fiesta') ||
                             normalizedName.contains('pre quince y fiesta') ||
                             normalizedName.contains('pre quince fiesta') ||
                             normalizedName.contains('quinceanera y fiesta');

    return Scaffold(
      appBar: AppBar(
        title: Text("Confirmar Reserva"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Resumen de tu Reserva",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              _buildInfoItem(Icons.camera_alt, "Paquete", widget.packageName),
              SizedBox(height: 16),
              _showDressesOption(Icons.content_cut),
              SizedBox(height: 16),
              _buildInfoItem(
                Icons.calendar_today,
                "Fecha",
                "${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}",
              ),
              SizedBox(height: 16),
              _buildInfoItem(
                Icons.access_time,
                "Hora",
                widget.selectedTime.format(context),
              ),
              if (isPreQuinceFiesta && widget.fiestaDate != null && widget.fiestaTime != null) ...[
                SizedBox(height: 24),
                Text(
                  "Datos de la Fiesta",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple[700]),
                ),
                SizedBox(height: 8),
                _buildInfoItem(
                  Icons.celebration,
                  "Fecha de la Fiesta",
                  "${widget.fiestaDate!.day}/${widget.fiestaDate!.month}/${widget.fiestaDate!.year}",
                ),
                SizedBox(height: 8),
                _buildInfoItem(
                  Icons.access_time,
                  "Hora de la Fiesta",
                  widget.fiestaTime!.format(context),
                ),
              ],
              SizedBox(height: 16),
              _buildNote(Icons.textsms_outlined, "Nota"),
              _buildPlace(Icons.place, "Lugar"),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  onPressed: isSubmitting ? null : _confirmReservation,
                  child: isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Confirmar Reserva",
                          style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Card _buildNote(IconData icon, String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: noteController,
                          decoration: InputDecoration(
                            labelText: "Nota opcional",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Card _buildPlace(IconData icon, String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: lugarController,
                          decoration: InputDecoration(
                            labelText: "Lugar",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 28),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _showDressesOption(IconData icon) {
    if (widget.dressName.isNotEmpty) {
      return _buildInfoItem(icon, "Vestido", widget.dressName);
    } else if (widget.dressReservations.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.dressReservations
            .map((dress) =>
                _buildInfoItem(icon, dress.componentName, dress.name))
            .toList(),
      );
    } else {
      return Text(
        "No hay vestidos seleccionados",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    }
  }
}
