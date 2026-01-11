import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:salespro_admin/Provider/customer_provider.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/model/customer_model.dart';

class CustomerSearchDialog extends ConsumerStatefulWidget {
  const CustomerSearchDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends ConsumerState<CustomerSearchDialog> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool showNewCustomerForm = false;
  
  // Controllers para nuevo cliente
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomerProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        width: 600,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kMainColor, kMainColor.withAlpha(200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            showNewCustomerForm ? FeatherIcons.userPlus : FeatherIcons.users,
                            color: kWhite,
                            size: 24.0,
                          ),
                          const SizedBox(width: 12.0),
                          Text(
                            showNewCustomerForm ? 'Nuevo Cliente' : 'Buscar Cliente',
                            style: kTextStyle.copyWith(
                              color: kWhite,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (!showNewCustomerForm)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  showNewCustomerForm = true;
                                });
                              },
                              icon: Icon(FeatherIcons.plus, color: kWhite, size: 16.0),
                              label: Text(
                                'Nuevo',
                                style: kTextStyle.copyWith(color: kWhite),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: kWhite.withAlpha(30),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8.0),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(FeatherIcons.x, color: kWhite),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!showNewCustomerForm) ...[
                    const SizedBox(height: 16.0),
                    // Barra de búsqueda
                    Container(
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o número de teléfono...',
                          hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                          prefixIcon: Icon(FeatherIcons.search, color: kGreyTextColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: showNewCustomerForm
                  ? _buildNewCustomerForm()
                  : customersAsync.when(
                      data: (customers) {
                        // Filtrar clientes
                        final filteredCustomers = customers.where((c) =>
                          c.customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          c.phoneNumber.contains(searchQuery)
                        ).toList();

                        if (filteredCustomers.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  MdiIcons.accountOff,
                                  size: 48.0,
                                  color: kGreyTextColor.withAlpha(100),
                                ),
                                const SizedBox(height: 16.0),
                                Text(
                                  'No se encontraron clientes',
                                  style: kTextStyle.copyWith(color: kGreyTextColor),
                                ),
                                const SizedBox(height: 8.0),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      showNewCustomerForm = true;
                                    });
                                  },
                                  icon: Icon(FeatherIcons.plus),
                                  label: Text('Agregar Nuevo Cliente'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: kMainColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = filteredCustomers[index];
                            return _buildCustomerTile(customer);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FeatherIcons.alertCircle,
                              size: 48.0,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'Error al cargar clientes',
                              style: kTextStyle.copyWith(color: Colors.red),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              error.toString(),
                              style: kTextStyle.copyWith(
                                color: kGreyTextColor,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerTile(CustomerModel customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: kBorderColorTextField),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.pop(context, customer),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: kMainColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    customer.customerName.isNotEmpty
                        ? customer.customerName[0].toUpperCase()
                        : '?',
                    style: kTextStyle.copyWith(
                      color: kMainColor,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.customerName,
                      style: kTextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                        color: kTitleColor,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(FeatherIcons.phone, size: 14.0, color: kGreyTextColor),
                        const SizedBox(width: 6.0),
                        Text(
                          customer.phoneNumber,
                          style: kTextStyle.copyWith(
                            color: kGreyTextColor,
                            fontSize: 14.0,
                          ),
                        ),
                        if (customer.emailAddress.isNotEmpty) ...[
                          const SizedBox(width: 16.0),
                          Icon(FeatherIcons.mail, size: 14.0, color: kGreyTextColor),
                          const SizedBox(width: 6.0),
                          Expanded(
                            child: Text(
                              customer.emailAddress,
                              style: kTextStyle.copyWith(
                                color: kGreyTextColor,
                                fontSize: 14.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (customer.customerAddress.isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Icon(FeatherIcons.mapPin, size: 14.0, color: kGreyTextColor),
                          const SizedBox(width: 6.0),
                          Expanded(
                            child: Text(
                              customer.customerAddress,
                              style: kTextStyle.copyWith(
                                color: kGreyTextColor,
                                fontSize: 12.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (double.tryParse(customer.dueAmount) != null && double.parse(customer.dueAmount) > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    'Debe: \$${double.parse(customer.dueAmount).toStringAsFixed(2)}',
                    style: kTextStyle.copyWith(
                      color: Colors.red,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8.0),
              Icon(FeatherIcons.chevronRight, color: kMainColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewCustomerForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre
          Text(
            'Nombre Completo',
            style: kTextStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16.0,
              color: kTitleColor,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Ingrese el nombre del cliente',
              prefixIcon: Icon(FeatherIcons.user, color: kGreyTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Teléfono
          Text(
            'Número de Teléfono',
            style: kTextStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16.0,
              color: kTitleColor,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Ej: 809-555-1234',
              prefixIcon: Icon(FeatherIcons.phone, color: kGreyTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Email
          Text(
            'Correo Electrónico (opcional)',
            style: kTextStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16.0,
              color: kTitleColor,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'ejemplo@correo.com',
              prefixIcon: Icon(FeatherIcons.mail, color: kGreyTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Dirección
          Text(
            'Dirección (opcional)',
            style: kTextStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16.0,
              color: kTitleColor,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: addressController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ingrese la dirección del cliente',
              prefixIcon: Icon(FeatherIcons.mapPin, color: kGreyTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          
          const SizedBox(height: 32.0),
          
          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    showNewCustomerForm = false;
                    // Limpiar campos
                    nameController.clear();
                    phoneController.clear();
                    emailController.clear();
                    addressController.clear();
                  });
                },
                child: Text('Cancelar'),
                style: TextButton.styleFrom(
                  foregroundColor: kGreyTextColor,
                ),
              ),
              const SizedBox(width: 16.0),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar guardado del nuevo cliente
                  // Por ahora solo cerrar
                  Navigator.pop(context);
                },
                icon: Icon(FeatherIcons.save),
                label: Text('Guardar Cliente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  foregroundColor: kWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}