import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:salespro_admin/Provider/photo_invoice_provider.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/currency.dart';
import 'package:salespro_admin/model/frame_product_model.dart';
import 'package:salespro_admin/model/photo_service_model.dart';

class SearchProductServiceDialog extends ConsumerStatefulWidget {
  const SearchProductServiceDialog({super.key});

  @override
  ConsumerState<SearchProductServiceDialog> createState() => _SearchProductServiceDialogState();
}

class _SearchProductServiceDialogState extends ConsumerState<SearchProductServiceDialog> with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  late TabController _tabController;
  String searchQuery = '';
  bool showNewItemForm = false;
  
  // Controllers para nuevo item
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController materialController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  String selectedType = 'marco';
  String selectedServiceType = 'impresion';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    nameController.dispose();
    priceController.dispose();
    sizeController.dispose();
    materialController.dispose();
    colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usar los streams de Firebase en lugar de las listas estáticas
    final productsAsync = ref.watch(photoProductsStreamProvider);
    final servicesAsync = ref.watch(photoServicesStreamProvider);
    final notifier = ref.read(photoInvoiceProvider.notifier);

    // Obtener listas de productos y servicios desde los streams
    final availableProducts = productsAsync.when(
      data: (products) => products,
      loading: () => <FrameProductModel>[],
      error: (_, __) => <FrameProductModel>[],
    );
    
    final availableServices = servicesAsync.when(
      data: (services) => services,
      loading: () => <PhotoServiceModel>[],
      error: (_, __) => <PhotoServiceModel>[],
    );
    
    // Filtrar items basado en búsqueda
    final filteredProducts = availableProducts.where((p) => 
      p.productName.toLowerCase().contains(searchQuery.toLowerCase()) ||
      (p.size?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
    ).toList();
    
    final filteredServices = availableServices.where((s) => 
      s.serviceName.toLowerCase().contains(searchQuery.toLowerCase()) ||
      s.serviceType.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        width: 700,
        height: 600,
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
                          Icon(MdiIcons.magnify, color: kWhite, size: 24.0),
                          const SizedBox(width: 12.0),
                          Text(
                            showNewItemForm ? 'Agregar Nuevo Item' : 'Buscar Productos y Servicios',
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
                          if (!showNewItemForm)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  showNewItemForm = true;
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
                  if (!showNewItemForm) ...[
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
                          hintText: 'Buscar por nombre, tamaño o tipo...',
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
              child: showNewItemForm
                  ? _buildNewItemForm()
                  : Column(
                      children: [
                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: kDarkWhite,
                            border: Border(
                              bottom: BorderSide(color: kBorderColorTextField),
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: kMainColor,
                            unselectedLabelColor: kGreyTextColor,
                            indicatorColor: kMainColor,
                            indicatorWeight: 3.0,
                            tabs: [
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(MdiIcons.imageFrame, size: 18.0),
                                    const SizedBox(width: 8.0),
                                    const Text('Productos'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(MdiIcons.camera, size: 18.0),
                                    const SizedBox(width: 8.0),
                                    const Text('Servicios'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tab Views
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Productos Tab
                              productsAsync.when(
                                data: (_) => _buildProductsList(filteredProducts, notifier),
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (error, _) => Center(
                                  child: Text('Error cargando productos: $error'),
                                ),
                              ),
                              // Servicios Tab
                              servicesAsync.when(
                                data: (_) => _buildServicesList(filteredServices, notifier),
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (error, _) => Center(
                                  child: Text('Error cargando servicios: $error'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(List<FrameProductModel> products, PhotoInvoiceNotifier notifier) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MdiIcons.imageOff, size: 48.0, color: kGreyTextColor.withAlpha(100)),
            const SizedBox(height: 16.0),
            Text(
              'No se encontraron productos',
              style: kTextStyle.copyWith(color: kGreyTextColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
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
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(MdiIcons.imageFrame, color: Colors.orange, size: 24.0),
            ),
            title: Text(
              product.productName,
              style: kTextStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
                color: kTitleColor,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4.0),
                Text(
                  '${product.size ?? ''} ${product.material ?? ''} ${product.color ?? ''}'.trim(),
                  style: kTextStyle.copyWith(
                    color: kGreyTextColor,
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '$currency${product.productPrice.toStringAsFixed(2)}',
                  style: kTextStyle.copyWith(
                    color: Colors.orange,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () {
                notifier.addProduct(product);
                Navigator.pop(context);
              },
              icon: Icon(FeatherIcons.plus, size: 16.0),
              label: Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServicesList(List<PhotoServiceModel> services, PhotoInvoiceNotifier notifier) {
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MdiIcons.cameraOff, size: 48.0, color: kGreyTextColor.withAlpha(100)),
            const SizedBox(height: 16.0),
            Text(
              'No se encontraron servicios',
              style: kTextStyle.copyWith(color: kGreyTextColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
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
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(MdiIcons.camera, color: Colors.blue, size: 24.0),
            ),
            title: Text(
              service.serviceName,
              style: kTextStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
                color: kTitleColor,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4.0),
                Text(
                  service.size ?? service.serviceType,
                  style: kTextStyle.copyWith(
                    color: kGreyTextColor,
                    fontSize: 14.0,
                  ),
                ),
                if (service.description != null) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    service.description!,
                    style: kTextStyle.copyWith(
                      color: kGreyTextColor,
                      fontSize: 12.0,
                    ),
                  ),
                ],
                const SizedBox(height: 4.0),
                Text(
                  '$currency${service.servicePrice.toStringAsFixed(2)}',
                  style: kTextStyle.copyWith(
                    color: Colors.blue,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () {
                notifier.addService(service);
                Navigator.pop(context);
              },
              icon: Icon(FeatherIcons.plus, size: 16.0),
              label: Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewItemForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo de item
          Text(
            'Tipo de Item',
            style: kTextStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16.0,
              color: kTitleColor,
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Producto'),
                  value: 'producto',
                  groupValue: _tabController.index == 0 ? 'producto' : 'servicio',
                  onChanged: (value) {
                    setState(() {
                      _tabController.index = 0;
                    });
                  },
                  activeColor: kMainColor,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Servicio'),
                  value: 'servicio',
                  groupValue: _tabController.index == 0 ? 'producto' : 'servicio',
                  onChanged: (value) {
                    setState(() {
                      _tabController.index = 1;
                    });
                  },
                  activeColor: kMainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          
          // Nombre
          Text(
            'Nombre',
            style: kTextStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: kTitleColor,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Ingrese el nombre del ${_tabController.index == 0 ? 'producto' : 'servicio'}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Precio
          Text(
            'Precio',
            style: kTextStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: kTitleColor,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: currency,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Campos específicos según el tipo
          if (_tabController.index == 0) ...[
            // Campos para productos
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tamaño',
                        style: kTextStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: kTitleColor,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: sizeController,
                        decoration: InputDecoration(
                          hintText: 'Ej: 8x10',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Material',
                        style: kTextStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: kTitleColor,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: materialController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Madera',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              'Color',
              style: kTextStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: kTitleColor,
              ),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: colorController,
              decoration: InputDecoration(
                hintText: 'Ej: Negro',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ] else ...[
            // Campos para servicios
            Text(
              'Tipo de Servicio',
              style: kTextStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: kTitleColor,
              ),
            ),
            const SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              value: selectedServiceType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'impresion', child: Text('Impresión')),
                DropdownMenuItem(value: 'revelado', child: Text('Revelado')),
                DropdownMenuItem(value: 'digitalizacion', child: Text('Digitalización')),
                DropdownMenuItem(value: 'restauracion', child: Text('Restauración')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedServiceType = value!;
                });
              },
            ),
            const SizedBox(height: 16.0),
            Text(
              'Tamaño (opcional)',
              style: kTextStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: kTitleColor,
              ),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: sizeController,
              decoration: InputDecoration(
                hintText: 'Ej: 4x6',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 32.0),
          
          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    showNewItemForm = false;
                    // Limpiar campos
                    nameController.clear();
                    priceController.clear();
                    sizeController.clear();
                    materialController.clear();
                    colorController.clear();
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
                  // TODO: Implementar guardado del nuevo item
                  // Por ahora solo cerrar
                  Navigator.pop(context);
                },
                icon: Icon(FeatherIcons.save),
                label: Text('Guardar'),
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