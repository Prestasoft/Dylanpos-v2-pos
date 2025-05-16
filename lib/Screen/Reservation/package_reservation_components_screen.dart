import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Screen/Reservation/date_time_selection_screen.dart';
import 'package:salespro_admin/Screen/Reservation/dress_selection_screen_package.dart';
import 'package:salespro_admin/model/ServicePackageModel.dart';
import '../../Provider/reservation_provider.dart';

class PackageReservationScreen extends ConsumerStatefulWidget {
  final ServicePackageModel packagesAsync;

  // final String packageId;
  // final String packageName;
  // final String dressId;
  // final String dressName;
  // final String branchId;
  // final DateTime selectedDate;
  // final TimeOfDay selectedTime;
  // final String clientId;

  const PackageReservationScreen({Key? key, required this.packagesAsync
      // required this.packageId,
      // required this.packageName,
      // required this.dressId,
      // required this.dressName,
      // required this.branchId,
      // required this.selectedDate,
      // required this.selectedTime,
      // required this.clientId
      })
      : super(key: key);

  @override
  _PackageReservationScreen createState() => _PackageReservationScreen();
}

class _PackageReservationScreen
    extends ConsumerState<PackageReservationScreen> {
  bool isSubmitting = false;
  Map<String, Map<String, String>> selectedValues = {};
  List<String> codigosSeleccionados = [];
  List<DressReservation> dressReservations = [];

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

    //final String formattedDate = _formatDate(widget.selectedDate);
    //final String formattedTime = _formatTime(widget.selectedTime);

    // Verificar una vez más que esté disponible
    final isAvailable = await ref.read(isDressAvailableProvider({
      'dressId': widget.packagesAsync.components,
      //'date': formattedDate,
      //'time': formattedTime,
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

    setState(() {
      isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reserva de Paquetes"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Reservas de Paquetes - Múltiples Items",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            _buildInfoItem(
                Icons.camera_alt, "Paquete", widget.packagesAsync.name),
            SizedBox(height: 16),

            // Muestra de todos los componentes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics:
                      NeverScrollableScrollPhysics(), // Evita scroll interno
                  itemCount: widget.packagesAsync.components.length,
                  itemBuilder: (context, index) {
                    final component = widget.packagesAsync.components[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fila con nombre y botón
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                component ?? 'Componente vacío',
                                style: TextStyle(fontSize: 16),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final selected = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DressSelectionPackageScreen(
                                        packagesAsync: widget.packagesAsync,
                                        dressIds: codigosSeleccionados,
                                        packageId: widget.packagesAsync.id,
                                        packageName: widget.packagesAsync.name,
                                        CategoryComposite: widget.packagesAsync.components[index],
                                       
                                      ),
                                    ),
                                  );

                                  if (selected != null) {
                                    setState(() {
                                      selectedValues[index.toString()] =
                                          selected;
                                      codigosSeleccionados = selectedValues
                                          .values
                                          .map((e) => e['vestidoId'] ?? '')
                                          .where((id) => id.isNotEmpty)
                                          .toList();

                                      dressReservations =
                                          selectedValues.entries.map((entry) {
                                        final value = entry.value;
                                        final componentIndex =
                                            int.tryParse(entry.key);
                                        final componentName =
                                            componentIndex != null &&
                                                    componentIndex <
                                                        widget.packagesAsync
                                                            .components.length
                                                ? widget.packagesAsync
                                                    .components[componentIndex]
                                                : '';

                                        return DressReservation(
                                          id: value['vestidoId'] ?? '',
                                          name: value['vestidoName'] ?? '',
                                          branchId: value['branchId'] ?? '',
                                          componentName: componentName,
                                        );
                                      }).toList();
                                    });
                                    print(
                                        'Seleccionados: $codigosSeleccionados');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 6),
                                ),
                                child: Text('Ver'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // TextField debajo del componente
                          Row(
                            children: [
                              // Container(
                              //   width: 150,
                              //   height: 50,
                              //   child: TextField(
                              //     readOnly: true,
                              //     controller: TextEditingController(
                              //       text: selectedValues[index.toString()]
                              //               ?['vestidoId'] ??
                              //           '',
                              //     ),
                              //     decoration: InputDecoration(
                              //       labelText: "Código $component",
                              //       border: OutlineInputBorder(),
                              //     ),
                              //   ),
                              // ),
                              // SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: selectedValues[index.toString()]
                                            ?['vestidoName'] ??
                                        '',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: "Nombre $component",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón de confirmación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Seleccionar Fecha",
                          style: TextStyle(fontSize: 18),
                        ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DateTimeSelectionScreen(
                          packageId: widget.packagesAsync.id,
                          packageName: widget.packagesAsync.name,
                          dressId: '',
                          dressName: '',
                          branchId: '',
                          dressReservations: [
                            ...dressReservations,
                          ],
                        ),
                      ),
                    );
                  }

                  //isSubmitting ? null : _confirmReservation,
                  // child: isSubmitting
                  //     ? CircularProgressIndicator(color: Colors.white)
                  //     : Text(
                  //         "Confirmar Reserva",
                  //         style: TextStyle(fontSize: 18),
                  //       ),
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

class DressReservation {
  final String id;
  final String name;
  final String branchId;
  final String componentName;

  DressReservation(
      {required this.id,
      required this.name,
      required this.branchId,
      required this.componentName});
}
