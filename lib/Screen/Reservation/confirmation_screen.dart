import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro_admin/Screen/Reservation/package_reservation_components_screen.dart';
import '../../Provider/reservation_provider.dart';

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
  }) : super(key: key);

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  bool isSubmitting = false;

  TextEditingController noteController = TextEditingController();

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatTime(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  void _confirmReservation() async {
    setState(() {
      isSubmitting = true;
    });

    final String formattedDate = _formatDate(widget.selectedDate);
    final String formattedTime = _formatTime(widget.selectedTime);

    // Verificar una vez más que esté disponible
    bool isAvailable = true;

    if (widget.dressReservations.isEmpty) {
      isAvailable = await ref.read(isDressAvailableProvider({
        'dressId': widget.dressId,
        'date': formattedDate,
        'time': formattedTime,
      }).future);
    } else {
      for (var dress in widget.dressReservations) {
        final available = await ref.read(
          isDressAvailableProvider({
            'dressId': dress.id,
            'date': formattedDate,
            'time': formattedTime,
          }).future,
        );

        if (!available) {
          // Si alguno no está disponible, se puede actuar
          isAvailable = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El vestido "${dress.name}" ya fue reservado.'),
            ),
          );
          break;
        } else {
          // Si está disponible, se puede proceder
          print('El vestido "${dress.name}" está disponible.');
        }
      }
    }

    if (!isAvailable) {
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

    // Crear la reserva
    final success = await ref.read(crearReservaProvider({
      'serviceId': widget.packageId,
      'clientId': widget.clientId,
      'dressId': dressIdTmp,
      'branchId': branchIdTmp,
      'date': formattedDate,
      'time': formattedTime,
      'multiple_dress': multipleDress,
      'note': noteController.text,
    }).future);

    setState(() {
      isSubmitting = false;
    });

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("¡Reserva registrada exitosamente!"),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the POS sales screen
      if (mounted) {
        // Actualiza el estado del menú lateral
        ref.read(sidebarProvider.notifier)
          ..expandMenu('/sales') // Expande el menú de Ventas
          ..selectItem('/sales/inventory-sales'); // Selecciona el ítem

        // Navega a la pantalla
        Navigator.of(context).popUntil((route) => route.isFirst);
        context.go('/sales/inventory-sales');
      }
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

              // Se mostrara el/los vestidos seleccionado/s
              _showDressesOption(Icons.content_cut),
              //_buildInfoItem(Icons.content_cut, "Vestido", widget.dressName),
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
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.textsms_outlined,
                          color: Theme.of(context).primaryColor, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nota",
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
              ),
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
                      : Text(
                          "Confirmar Reserva",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
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
