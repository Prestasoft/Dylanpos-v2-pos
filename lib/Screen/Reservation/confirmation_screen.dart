import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  const ConfirmationScreen(
      {Key? key,
      required this.packageId,
      required this.packageName,
      required this.dressId,
      required this.dressName,
      required this.branchId,
      required this.selectedDate,
      required this.selectedTime,
      required this.clientId})
      : super(key: key);

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  bool isSubmitting = false;

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
    final isAvailable = await ref.read(isDressAvailableProvider({
      'dressId': widget.dressId,
      'date': formattedDate,
      'time': formattedTime,
    }).future);

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

    // Crear la reserva
    final success = await ref.read(crearReservaProvider({
      'serviceId': widget.packageId,
      'clientId': widget.clientId,
      'dressId': widget.dressId,
      'branchId': widget.branchId,
      'date': formattedDate,
      'time': formattedTime,
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
            _buildInfoItem(Icons.content_cut, "Vestido", widget.dressName),
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
            Spacer(),
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
}
