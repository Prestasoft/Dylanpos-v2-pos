

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/services/api_service.dart';
import 'package:salespro_admin/Screen/Reservation/package_reservation_components_screen.dart';
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
  final List<DressReservation> dressReservations;

  const DateTimeSelectionScreen({
    Key? key,
    required this.packageId,
    required this.packageName,
    required this.dressId,
    required this.dressName,
    required this.branchId,
    required this.dressReservations,
  }) : super(key: key);

  @override
  _DateTimeSelectionScreenState createState() => _DateTimeSelectionScreenState();
}

class _DateTimeSelectionScreenState extends ConsumerState<DateTimeSelectionScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  // Para la segunda fecha y hora de fiesta (solo si aplica)
  DateTime? selectedFiestaDate;
  TimeOfDay? selectedFiestaTime;
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
      final apiService = ApiService();
      final response = await apiService.get('services/${widget.packageId}');

      if (response.success && response.data != null) {
        final data = response.data;
        Map<String, dynamic>? packageData;

        if (data is Map) {
          if (data['service'] != null) {
            packageData = Map<String, dynamic>.from(data['service']);
          } else {
            packageData = Map<String, dynamic>.from(data);
          }
        }

        if (packageData != null) {
          setState(() {
            packageDuration = (packageData!['duration'] is Map)
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
      } else {
        setState(() {
          packageDuration = {'value': 1, 'unit': 'days'};
          isLoadingPackage = false;
        });
      }
    } catch (e) {
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

  Future<void> _selectFiestaDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedFiestaDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != selectedFiestaDate) {
      setState(() {
        selectedFiestaDate = picked;
        errorMessage = null;
      });
    }
  }

  Future<void> _selectFiestaTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedFiestaTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedFiestaTime) {
      setState(() {
        selectedFiestaTime = picked;
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
    bool isDressAvailable = true;

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

    if (widget.dressName.isNotEmpty && widget.dressId.isNotEmpty) {
      isDressAvailable = await ref.read(isDressAvailableForRangeProvider({
        'dressId': widget.dressId,
        'startDate': formattedDate,
        'duration': packageDuration,
      }).future);
    } else if (widget.dressReservations.isEmpty) {
      // Si no hay vestidos seleccionados, se puede proceder sin verificar disponibilidad
      isDressAvailable = true;
    } else {
      for (var dress in widget.dressReservations) {
        bool available = true;

        if (dress.componentName != "Sin Vestimenta") {
          available = await ref.read(
            isDressAvailableForRangeProvider({
              'dressId': dress.id,
              'startDate': formattedDate,
              'duration': packageDuration,
            }).future,
          );
        }

        if (!available) {
          // Si alguno no está disponible, se puede actuar
          isDressAvailable = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El vestido "${dress.name}" no está disponible.'),
            ),
          );
          break;
        }
      }
    }

    setState(() {
      isChecking = false;
    });

    if (selectedCustomer == null) {
      setState(() {
        errorMessage = "Por favor, selecciona un cliente.";
        return;
      });
    } else {
      if (isDressAvailable) {
        // Normalización para detectar "pre-quince y fiesta" en cualquier variante de plan
        String _normalize(String s) {
          final withNoSpaces = s.trim().toLowerCase().replaceAll(RegExp(r'\\s+'), ' ');
          final withNoAccents = withNoSpaces
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u');
          final withoutPlan = withNoAccents.replaceFirst(RegExp(r'^plan [a-z]\\s*'), '');
          return withoutPlan;
        }
        final normalizedName = _normalize(widget.packageName);
        final isPreQuinceFiesta = normalizedName.contains('pre-quince y fiesta');

        DateTime? fiestaDateToSend;
        TimeOfDay? fiestaTimeToSend;
        if (isPreQuinceFiesta) {
          fiestaDateToSend = selectedFiestaDate;
          fiestaTimeToSend = selectedFiestaTime;
        }

        if (widget.dressReservations.isEmpty) {
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
                dressReservations: [],
                fiestaDate: fiestaDateToSend,
                fiestaTime: fiestaTimeToSend,
              ),
            ),
          );
        } else {
          // Si hay varios vestidos seleccionados, se puede proceder a la pantalla de confirmación
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmationScreen(
                packageId: widget.packageId,
                packageName: widget.packageName,
                dressId: '',
                dressName: '',
                branchId: '',
                selectedDate: selectedDate,
                selectedTime: selectedTime,
                clientId: selectedCustomer!.phoneNumber,
                dressReservations: widget.dressReservations,
                fiestaDate: fiestaDateToSend,
                fiestaTime: fiestaTimeToSend,
              ),
            ),
          );
        }
      } else {
        // Mensaje más específico sobre el problema de disponibilidad
        final String duracionTexto = _getDuracionTexto();
        setState(() {
          errorMessage = "Este vestido no está disponible durante el período seleccionado ($duracionTexto).";
        });
      }
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
    // Mostrar si el nombre contiene "pre-quince y fiesta" ignorando mayúsculas/minúsculas, espacios, tildes y letras de plan (A, B, C, etc.)
    String _normalize(String s) {
      final withNoSpaces = s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      // Quitar tildes
      final withNoAccents = withNoSpaces
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
      // Quitar "plan a ", "plan b ", "plan c ", etc. al inicio
      final withoutPlan = withNoAccents.replaceFirst(RegExp(r'^plan [a-z]\s*'), '');
      return withoutPlan;
    }
    final normalizedName = _normalize(widget.packageName);
    final isPreQuinceFiesta = normalizedName.contains('pre-quince y fiesta');
    // Debug: imprime el nombre recibido y normalizado
    return Scaffold(
      appBar: AppBar(
        title: Text("Agenda tu Sesión"),
      ),
      body: isLoadingPackage
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
    // (Eliminado el título de arriba, solo se muestra debajo de 'Seleccione cliente')
    _showDressesOption(context),
    SizedBox(height: 8),
    Text(
      "Seleccione cliente",
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
    Padding(
        padding: const EdgeInsets.all(12),
        child: CustomerSelector(
            initialCustomer: selectedCustomer,
            onCustomerSelected: (customer) {
              setState(() {
                selectedCustomer = customer;
              });
            })),
    if (isPreQuinceFiesta) ...[
      SizedBox(height: 16),
      Text(
        "Selecciona la fecha y la hora de Pre-quince:",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue[800]),
      ),
      SizedBox(height: 8),
    ],
    Text(
      "Duración: ${_getDuracionTexto()}",
      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
    ),
    SizedBox(height: 24),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
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
                        leading: Icon(Icons.access_time, color: Theme.of(context).primaryColor),
                        title: Text("Hora"),
                        subtitle: Text(selectedTime.format(context)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _selectTime(context),
                      ),
                    ),
                    if (isPreQuinceFiesta) ...[
                      SizedBox(height: 24),
                      Text(
                        "Selecciona la fecha y hora de la fiesta:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple[700]),
                      ),
                      SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.celebration, color: Colors.purple[700]),
                          title: Text("Fecha de la Fiesta"),
                          subtitle: Text(selectedFiestaDate != null
                              ? "${selectedFiestaDate!.day}/${selectedFiestaDate!.month}/${selectedFiestaDate!.year}"
                              : "Selecciona la fecha de la fiesta"),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _selectFiestaDate(context),
                        ),
                      ),
                      SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.access_time, color: Colors.purple[700]),
                          title: Text("Hora de la Fiesta"),
                          subtitle: Text(selectedFiestaTime != null
                              ? selectedFiestaTime!.format(context)
                              : "Selecciona la hora de la fiesta"),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _selectFiestaTime(context),
                        ),
                      ),
                    ],
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
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: isChecking ? null : _checkAvailabilityAndContinue,
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
            ),
    );
  }

  Widget _showDressesOption(BuildContext context) {
    if (widget.dressReservations.isEmpty) {
      return Text(
        widget.dressName == "" ? "No hay vestidos seleccionados" : widget.dressName,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    } else if (widget.dressReservations.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.dressReservations
            .map((dress) => Text(
                  dress.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ))
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
