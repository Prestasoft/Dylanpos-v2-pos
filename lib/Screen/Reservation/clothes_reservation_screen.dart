import 'package:salespro_admin/Provider/servicePackagesProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Provider/product_provider.dart';
import 'package:salespro_admin/Screen/Reservation/customer_selection_modal.dart';
import 'package:salespro_admin/Screen/Reservation/dress_selection_screen_package.dart';
import 'package:salespro_admin/Screen/Reservation/package_reservation_components_screen.dart';
import 'package:salespro_admin/model/ServicePackageModel.dart';
import 'package:salespro_admin/model/customer_model.dart';
import '../../Provider/reservation_provider.dart';
import 'package:go_router/go_router.dart';

class ClothesReservationScreen extends ConsumerStatefulWidget {
  
  const ClothesReservationScreen({
    super.key
  });

  @override
  // ignore: library_private_types_in_public_apiS, library_private_types_in_public_api
  _ClothesReservationScreen createState() => _ClothesReservationScreen();
}

class _ClothesReservationScreen extends ConsumerState<ClothesReservationScreen> {
  bool isSubmitting = false;
  Map<String, Map<String, String>> selectedValues = {};
  List<String> codigosSeleccionados = [];
  List<DressReservation> dressReservations = [];
  DateTime selectedDate = DateTime.now();
  List<String?> _selectedComponents = [null]; // Un dropdown inicial
  CustomerModel? selectedCustomer;
  int _retry = 0;

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatTime(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null && picked != selectedDate) {
      selectedDate = picked;

      // Verificamos disponibilidad para cada vestido con la nueva fecha
      for (int i = 0; i < dressReservations.length; i++) {
        final dress = dressReservations[i];
        final isAvailable = await ref.read(
          isClothesAvailableForRangeProvider({
            'dressReservation': dress.id,
            'startDate': _formatDate(selectedDate),
            'isAdditional': false,
          }).future,
        );

        // Actualizamos el objeto en la lista
        dressReservations[i] = DressReservation(
          id: dress.id,
          name: dress.name,
          branchId: dress.branchId,
          price: dress.price,
          componentName: dress.componentName,
          isAvailable: isAvailable,
        );
      }

      setState(() {
        // Se actualiza selectedDate y también se fuerza el rebuild
      });
    }
  }

  void checkAndUpdateAvailability(String dressId) async {
    final isAvailable = await ref.read(
      isClothesAvailableForRangeProvider({
        'dressReservation': dressId,
        'startDate': _formatDate(selectedDate),
        'isAdditional': false,
      }).future,
    );

    final reservationIndex = dressReservations.indexWhere((r) => r.id == dressId);

    if (reservationIndex != -1) {
      final old = dressReservations[reservationIndex];

      setState(() {
        dressReservations[reservationIndex] = DressReservation(
          id: old.id,
          name: old.name,
          branchId: old.branchId,
          price: old.price,
          componentName: old.componentName,
          isAvailable: isAvailable,
        );
      });
    }
  }

  bool get isConfirmButtonEnabled {
    if (isSubmitting) return false;
    if (dressReservations.isEmpty) return false;
    if (dressReservations.any((r) => r.isAvailable == false)) return false;
    return true;
  }

 void _confirmReservation() async {
    
    setState(() {
      isSubmitting = true;
    });

    final String formattedDate = _formatDate(selectedDate);
    final String formattedTime = _formatTime(TimeOfDay.now());
    final String note = "Reserva de vestimenta para ${selectedCustomer?.customerName ?? 'Cliente'}";  

    final a = ref.read(servicePackagesProvider.notifier).searchPackages("Renta de Vestimenta");
       
    final String packageId= a.firstWhere((e) => e.name == "Renta de Vestimenta").id;
    final String packageName= a.firstWhere((e) => e.name == "Renta de Vestimenta").name;
    
    // Variables temporales para guardar el vestido y la sucursal   
    List<Map<String, String>> multipleDress = [];

    // Logica que guarda segun un o varios vestidos
    if (dressReservations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Por favor selecciona al menos un vestido."),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isSubmitting = false;
      });
      return;
    } else{
        multipleDress = dressReservations.map((dress) {
          return {
            'dress_id': dress.id,
            'branch_id': dress.branchId,
            'dress_name': dress.name,
          };
      }).toList();  
    }

    double totalReservationPrice = selectedValues.values.where((e) => e['vestidoPrice'] != null).map((e) => double.tryParse(e['vestidoPrice'].toString()) ?? 0.0).fold(0.0, (a, b) => a + b);

    // Crear la reserva
    final success = await ref.read(crearReservaProvider({
      'serviceId': packageId,
      'clientId': selectedCustomer?.phoneNumber ?? '',
      'dressId': '',
      'branchId': '',
      'date': formattedDate,
      'time': formattedTime,
      'multiple_dress': multipleDress,
      'note': note,
      'reservation_associated': '',
      'package_price': totalReservationPrice.toString(),
    }).future);

    setState(() {
      isSubmitting = false;
    });

    if (success.statusReservation) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Renta registrada exitosamente!"),
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
              Text("Error al crear la renta. Por favor intenta de nuevo."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    late final ThemeData _theme = Theme.of(context);
    late final ColorScheme _colors = _theme.colorScheme;
    late final TextTheme _textTheme = _theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            child: Column(
              children: TextSummaryPrice(context, _textTheme, _colors),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> TextSummaryPrice(BuildContext context, TextTheme _textTheme, ColorScheme _colors) {
    return [
      // Cabecera de la pantalla
      _buildHeader(context, "Renta de Vestimenta"),
      SizedBox(height: 24),
      // Fecha de la reserva
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
      SizedBox(height: 8),

      // Información del cliente
      Card(
        child: ListTile(
          leading: Icon(Icons.person, color: Theme.of(context).primaryColor),
          title: const Text("Cliente"),
          subtitle: Text(
            selectedCustomer?.customerName ?? "Seleccione un cliente",
            style: TextStyle(
              color: selectedCustomer == null ? Colors.grey : Colors.black,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) => CustomerSelectionModal(
                initialCustomer: selectedCustomer,
                onCustomerSelected: (customer) {
                  setState(() {
                    selectedCustomer = customer;
                  });
                },
              ),
            );
          },
        ),
      ),
      SizedBox(height: 12),

      // Agregado de Combos con Categorias para seleccionar vestimenta
      Card(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Consumer(
            builder: (context, ref, child) {
              final categoriesAsync = ref.watch(categoryProvider);

              return categoriesAsync.when(
                data: (categories) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.content_cut,
                              color: Theme.of(context).primaryColor,
                              size: 20, // tamaño opcional
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Seleccione vestimenta',
                              style: _textTheme.bodyLarge!.copyWith(color: _colors.onSurface),
                            ),
                          ],
                        ),
                      ),
                      ..._selectedComponents.asMap().entries.map((entry) {
                        int index = entry.key;
                        String? selectedComponent = entry.value;
                        bool isLast = index == _selectedComponents.length - 1;

                        return Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: Stack(
                            children: [
                              Card(
                                color: Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 32, bottom: 16, left: 8, right: 8),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          // Dropdown (30%)
                                          Flexible(
                                            flex: 3,
                                            child: DropdownButtonFormField<String>(
                                              value: selectedComponent,
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                hintText: "Seleccione categoría",
                                              ),
                                              items: categories.map((category) {
                                                return DropdownMenuItem<String>(
                                                  value: category.categoryName,
                                                  child: Text(category.categoryName),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedComponents[index] = value;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // TextField (expand)
                                          Expanded(
                                            flex: 5,
                                            child: TextField(
                                              readOnly: true,
                                              controller: TextEditingController(
                                                text: selectedValues[index.toString()]?['vestidoName'] ?? '',
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Seleccione prenda',
                                                border: const OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          SizedBox(
                                            height: 48,
                                            width: 48,
                                            child: ElevatedButton(
                                              onPressed: selectedComponent == null
                                                  ? null
                                                  : () async {
                                                      final selected = await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => DressSelectionPackageScreen(
                                                            packagesAsync: ServicePackageModel(
                                                              id: '',
                                                              name: '',
                                                              components: [],
                                                              type: '',
                                                              description: '',
                                                              price: 0.0,
                                                              category: '',
                                                              branches: [],
                                                              createdAt: DateTime.now(),
                                                              updatedAt: DateTime.now(),
                                                              duration: {
                                                                'days': 0,
                                                                'hours': 0,
                                                                'minutes': 0,
                                                              },
                                                              subcategory: '',
                                                            ),
                                                            dressIds: codigosSeleccionados,
                                                            packageId: '',
                                                            packageName: '',
                                                            CategoryComposite: selectedComponent,
                                                          ),
                                                        ),
                                                      );

                                                      if (selected != null) {
                                                        setState(() {
                                                          selectedValues[index.toString()] = selected;
                                                          codigosSeleccionados = selectedValues.values.map((e) => e['vestidoId'] ?? '').where((id) => id.isNotEmpty).toList();

                                                          dressReservations = selectedValues.entries.map((entry) {
                                                            final value = entry.value;
                                                            final componentIndex = int.tryParse(entry.key);
                                                            final componentName = componentIndex != null && componentIndex < _selectedComponents.length ? _selectedComponents[componentIndex] ?? '' : '';
                                                            return DressReservation(
                                                              id: value['vestidoId'] ?? '',
                                                              name: value['vestidoName'] ?? '',
                                                              branchId: value['branchId'] ?? '',
                                                              price: double.tryParse(value['vestidoPrice'] ?? '0') ?? 0.0,
                                                              componentName: componentName,
                                                            );
                                                          }).toList();
                                                        });

                                                        // ✅ Verificar disponibilidad después de setState
                                                        final dressId = selected['vestidoId'];
                                                        if (dressId != null && dressId.isNotEmpty) {
                                                          checkAndUpdateAvailability(dressId);
                                                        }
                                                      }
                                                    },
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Icon(Icons.search),
                                            ),
                                          )
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Precio
                                          _buildUnitPrice(
                                            double.tryParse(selectedValues[index.toString()]?['vestidoPrice'] ?? '0') ?? 0.0,
                                            _textTheme,
                                          ),
                                          const SizedBox(width: 8),

                                          if (selectedValues[index.toString()]?['vestidoId'] != null)
                                            FutureBuilder<AvailabilityResult>(
                                              future: _buildAvailableClothRetry(
                                                selectedValues[index.toString()]?['vestidoId'] ?? '',
                                                _textTheme,
                                              ),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 4, right: 8),
                                                    child: const CircularProgressIndicator(),
                                                  );
                                                } else if (snapshot.hasError) {
                                                  return const Text('');
                                                } else {
                                                  final result = snapshot.data!;

                                                  // Actualizo el isAvalaible de la lista dressReservations a traves del Id

                                                  final dressId = selectedValues[index.toString()]?['vestidoId'];
                                                  final reservationIndex = dressReservations.indexWhere(
                                                    (reservation) => reservation.id == dressId,
                                                  );
                                                  if (reservationIndex != -1) {
                                                    final oldReservation = dressReservations[reservationIndex];
                                                    dressReservations[reservationIndex] = DressReservation(
                                                      id: oldReservation.id,
                                                      name: oldReservation.name,
                                                      branchId: oldReservation.branchId,
                                                      price: oldReservation.price,
                                                      componentName: oldReservation.componentName,
                                                      isAvailable: result.isAvailable,
                                                    );
                                                  }

                                                  return result.widget;
                                                }
                                              },
                                            )

                                          // Muestra si está disponible
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Botones flotantes (X y +)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Row(
                                  children: [
                                    if (isLast)
                                      IconButton(
                                        icon: const Icon(Icons.add_circle, color: Colors.green),
                                        tooltip: 'Agregar componente',
                                        onPressed: () {
                                          setState(() {
                                            _selectedComponents.add(null);
                                          });
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      tooltip: 'Eliminar componente',
                                      onPressed: () {
                                        setState(() {
                                          _selectedComponents.removeAt(index);
                                          selectedValues.remove(index.toString());
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => Text('Error: $e'),
              );
            },
          ),
        ),
      ),

      const SizedBox(height: 8),

      // Información del paquete seleccionado

      const SizedBox(height: 24),

      // Botón de confirmación
      _buildButtonConfirm(),
    ];
  }

  Widget _buildHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
        ],
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

  Widget _buildUnitPrice(double price, TextTheme _textTheme) {
    if (price <= 0) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(top: 4, left: 8),
        child: Text(
          "Precio Unitario: \$0.00",
          style: _textTheme.bodyLarge!.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Formatear el precio a moneda

    final formatCurrency = NumberFormat.currency(
      locale: 'es_US', // o 'en_US' según el formato deseado
      symbol: '\$',
      decimalDigits: 2,
    );
    final formattedPrice = formatCurrency.format(price);
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(top: 4, left: 8),
      child: Text(
        "Precio Unitario: " + formattedPrice,
        style: _textTheme.bodyLarge!.copyWith(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTotalPrice(dynamic valueSelected) {
    double totalPrice = selectedValues.values.where((e) => e['vestidoPrice'] != null).map((e) => double.tryParse(e['vestidoPrice'].toString()) ?? 0.0).fold(0.0, (a, b) => a + b);

    final formatCurrency = NumberFormat.currency(
      locale: 'es_US', // Cambiá a 'en_US' si querés el formato inglés
      symbol: '\$',
      decimalDigits: 2,
    );

    return Text(
      "Confirmar Reserva (${formatCurrency.format(totalPrice)})",
      style: TextStyle(fontSize: 18),
    );
  }

  Future<AvailabilityResult> _buildAvailableClothRetry(
    String vestidoId,
    TextTheme textTheme,
  ) async {
    try {
      
        final a = ref.read(servicePackagesProvider.notifier).searchPackages("Renta de Vestimenta");

        final clothReservation = ClothReservation(
          packageId: a.firstWhere((e) => e.name == "Renta de Vestimenta").id,
          packageName: a.firstWhere((e) => e.name == "Renta de Vestimenta").name,
          dressId: '',
          dressName: '',
          branchId: '',
          dressReservations: dressReservations,
          clientId: selectedCustomer?.phoneNumber ?? '',
          clientName: selectedCustomer?.customerName ?? '',
          reservationId: '',
          selectedDate: selectedDate,
        );

        final isAvailable = await ref.read(
          isClothesAvailableForRangeProvider({
            'dressReservation': vestidoId,
            'startDate': _formatDate(selectedDate),
            'isAdditional': false,
          }).future,
        );

        final widgetResult = Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(top: 4, right: 8),
          child: Text(
            isAvailable ? "Disponible" : "No Disponible",
            style: textTheme.bodyLarge!.copyWith(
              color: isAvailable ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

        return AvailabilityResult(isAvailable: isAvailable, widget: widgetResult);
     
    } catch (e) {
      // Retry automático luego de 1 segundo
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _retry++;
          });
        }
      });
      rethrow;
    }
  }
  
  Widget _buildButtonConfirm() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
        ),
        onPressed: isConfirmButtonEnabled
            ? () async {
                if (dressReservations.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Por favor selecciona al menos un vestido."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedCustomer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Por favor selecciona un cliente."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Nueva renta
                  var a = ref.read(servicePackagesProvider.notifier).searchPackages("Renta de Vestimenta");

                  ClothReservation clothReservation = ClothReservation(
                    packageId: a.firstWhere((element) => element.name == "Renta de Vestimenta").id,
                    packageName: a.firstWhere((element) => element.name == "Renta de Vestimenta").name,
                    dressId: '',
                    dressName: '',
                    branchId: '',
                    dressReservations: dressReservations,
                    clientId: selectedCustomer?.phoneNumber ?? '',
                    clientName: selectedCustomer?.customerName ?? '',
                    reservationId: '',
                    selectedDate: selectedDate,
                    
                  );

                  // Verificación de disponibilidad (opcional porque ya se hace al seleccionar)
                  for (var dressReservation in dressReservations) {
                    final isAvailable = await ref.read(
                      isClothesAvailableForRangeProvider({
                        'dressReservation': dressReservation.id,
                        'startDate': _formatDate(selectedDate),
                        'isAdditional': false,
                      }).future,
                    );

                    if (isAvailable == false) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("El vestido ${dressReservation.name} no está disponible para la fecha seleccionada."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }

                  // Guardar lógica aquí...
                  _confirmReservation();

              }
            : null,
        child: isSubmitting ? CircularProgressIndicator(color: Colors.white) : _buildTotalPrice(selectedValues),
      ),
    );
  }
}

class ClothReservation {
  final String? reservationId;
  final String packageId;
  final String packageName;
  final String dressId;
  final String dressName;
  final String branchId;
  final List<DressReservation> dressReservations;
  final DateTime selectedDate;
  final String clientId;
  final String clientName;

  ClothReservation({
    required this.packageId,
    required this.packageName,
    required this.dressId,
    required this.dressName,
    required this.branchId,
    required this.dressReservations,
    required this.reservationId,
    required this.selectedDate,
    required this.clientId,
    required this.clientName,
  });
}

class AvailabilityResult {
  final bool isAvailable;
  final Widget widget;

  AvailabilityResult({required this.isAvailable, required this.widget});
}
