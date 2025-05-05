import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../Provider/reservation_provider.dart';
import '../../model/customer_model.dart';
import 'Seleccioncliente.dart';
import 'confirmation_screen.dart';

class DateTimeSelectionScreen extends ConsumerStatefulWidget {
  final String packageId;
  final String packageName;
  final String dressId;
  final String dressName;
  final String branchId;

  const DateTimeSelectionScreen({
    Key? key,
    required this.packageId,
    required this.packageName,
    required this.dressId,
    required this.dressName,
    required this.branchId,
  }) : super(key: key);

  @override
  _DateTimeSelectionScreenState createState() =>
      _DateTimeSelectionScreenState();
}

class _DateTimeSelectionScreenState
    extends ConsumerState<DateTimeSelectionScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  CustomerModel? selectedCustomer;

  String? errorMessage;
  bool isChecking = false;
  Map<String, dynamic>? packageDuration;
  bool isLoadingPackage = true;

  @override
  void initState() {
    super.initState();
    _loadPackageDetails();
  }

  Future<void> _loadPackageDetails() async {
    setState(() {
      isLoadingPackage = true;
    });

    try {
      final packageSnapshot = await FirebaseDatabase.instance
          .ref('Admin Panel/services/${widget.packageId}')
          .get();

      if (packageSnapshot.exists && packageSnapshot.value is Map) {
        final Map<dynamic, dynamic> packageData =
            packageSnapshot.value as Map<dynamic, dynamic>;

        setState(() {
          packageDuration = (packageData['duration'] is Map)
              ? Map<String, dynamic>.from(packageData['duration'])
              : {'value': 1, 'unit': 'days'};
          isLoadingPackage = false;
        });
      } else {
        setState(() {
          packageDuration = {'value': 1, 'unit': 'days'};
          isLoadingPackage = false;
        });
      }
    } catch (e) {
      print('Error cargando detalles del paquete: $e');
      setState(() {
        packageDuration = {'value': 1, 'unit': 'days'};
        isLoadingPackage = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        errorMessage = null;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        errorMessage = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _checkAvailabilityAndContinue() async {
    if (packageDuration == null) {
      setState(() {
        errorMessage = "No se pudo cargar la información del paquete.";
      });
      return;
    }

    setState(() {
      isChecking = true;
      errorMessage = null;
    });

    final String formattedDate = _formatDate(selectedDate);

    // Usar el nuevo proveedor que verifica disponibilidad en un rango
    final availability = await ref.read(isDressAvailableForRangeProvider({
      'dressId': widget.dressId,
      'startDate': formattedDate,
      'duration': packageDuration,
    }).future);

    setState(() {
      isChecking = false;
    });
    if (selectedCustomer == null) {
      setState(() {
        errorMessage = "Por favor, selecciona un cliente.";
      });
      return;
    }

    if (availability) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationScreen(
            packageId: widget.packageId,
            packageName: widget.packageName,
            dressId: widget.dressId,
            dressName: widget.dressName,
            branchId: widget.branchId,
            selectedDate: selectedDate,
            selectedTime: selectedTime,
            clientId: selectedCustomer!.phoneNumber,
          ),
        ),
      );
    } else {
      // Mensaje más específico sobre el problema de disponibilidad
      final String duracionTexto = _getDuracionTexto();
      setState(() {
        errorMessage =
            "Este vestido no está disponible durante el período seleccionado ($duracionTexto).";
      });
    }
  }

  String _getDuracionTexto() {
    if (packageDuration == null) return "";

    final int valor = packageDuration!['value'] ?? 1;
    final String unidad = packageDuration!['unit'] ?? 'days';

    if (unidad == 'days') {
      return valor == 1 ? "1 día" : "$valor días";
    } else if (unidad == 'hours') {
      return valor == 1 ? "1 hora" : "$valor horas";
    }
    return "$valor $unidad";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Agenda tu Sesión"),
      ),
      body: isLoadingPackage
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selecciona fecha y hora para tu sesión con el vestido:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.dressName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Seleeccione cliente",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: CustomerSelector(
                          initialCustomer: selectedCustomer,
                          onCustomerSelected: (CustomerModel) {
                            selectedCustomer = CustomerModel;
                          })),
                  Text(
                    "Duración: ${_getDuracionTexto()}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.calendar_today,
                          color: Theme.of(context).primaryColor),
                      title: Text("Fecha"),
                      subtitle: Text(
                        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.access_time,
                          color: Theme.of(context).primaryColor),
                      title: Text("Hora"),
                      subtitle: Text(selectedTime.format(context)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _selectTime(context),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed:
                          isChecking ? null : _checkAvailabilityAndContinue,
                      child: isChecking
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
