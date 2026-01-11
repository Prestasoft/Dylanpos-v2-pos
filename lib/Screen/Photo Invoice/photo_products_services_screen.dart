import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Provider/photo_invoice_provider.dart';
import 'package:salespro_admin/Repository/photo_products_services_repository.dart';
import 'package:salespro_admin/Repository/photo_types_repository.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/model/frame_product_model.dart';
import 'package:salespro_admin/model/photo_service_model.dart';
import 'package:salespro_admin/services/audit_service.dart';
import 'package:salespro_admin/model/audit_model.dart';
import 'package:salespro_admin/Provider/profile_provider.dart';

class PhotoProductsServicesScreen extends ConsumerStatefulWidget {
  const PhotoProductsServicesScreen({super.key});

  static const String route = '/photo-products-services';

  @override
  ConsumerState<PhotoProductsServicesScreen> createState() => _PhotoProductsServicesScreenState();
}

class _PhotoProductsServicesScreenState extends ConsumerState<PhotoProductsServicesScreen> {
  late PhotoProductsServicesRepository repository;
  late PhotoTypesRepository typesRepository;
  bool showProducts = true;
  
  @override
  void initState() {
    super.initState();
    // El repositorio se inicializará cuando tengamos el userId
  }

  @override
  Widget build(BuildContext context) {
    final personalData = ref.watch(profileDetailsProvider);
    
    // Check loading state
    if (personalData.isLoading) {
      return Scaffold(
        backgroundColor: kDarkWhite,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return personalData.when(
      data: (personalInfo) {
        // Inicializar los repositorios con el userId
        repository = PhotoProductsServicesRepository(
          userId: personalInfo.phoneNumber,
        );
        typesRepository = PhotoTypesRepository(
          userId: personalInfo.phoneNumber,
        );
            
            return Scaffold(
              backgroundColor: kDarkWhite,
              appBar: AppBar(
                backgroundColor: kWhite,
                elevation: 0,
                title: Text(
                  'Gestión de Productos y Servicios',
                  style: kTextStyle.copyWith(
                    color: kTitleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  // Botón para nueva impresión
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/photo-invoice');
                      },
                      icon: const Icon(Icons.add_photo_alternate, size: 20),
                      label: const Text('Agregar Impresión'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  // Botón para importar datos predefinidos
                  TextButton.icon(
                    onPressed: _importDefaultData,
                    icon: const Icon(Icons.download),
                    label: const Text('Importar Predefinidos'),
                    style: TextButton.styleFrom(
                      foregroundColor: kMainColor,
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                        
                                        // Tabs para cambiar entre productos y servicios
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: kBorderColorTextField),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () => setState(() => showProducts = true),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(15),
                                                    decoration: BoxDecoration(
                                                      color: showProducts ? kMainColor : Colors.transparent,
                                                      borderRadius: const BorderRadius.only(
                                                        topLeft: Radius.circular(10),
                                                        bottomLeft: Radius.circular(10),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Productos',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: showProducts ? Colors.white : kTitleColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () => setState(() => showProducts = false),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(15),
                                                    decoration: BoxDecoration(
                                                      color: !showProducts ? kMainColor : Colors.transparent,
                                                      borderRadius: const BorderRadius.only(
                                                        topRight: Radius.circular(10),
                                                        bottomRight: Radius.circular(10),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Servicios',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: !showProducts ? Colors.white : kTitleColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        // Contenido principal
                                        showProducts
                                            ? _buildProductsSection()
                                            : _buildServicesSection(),
                        ],
                      ),
                    ),
                  ),
                );
              },
          loading: () => Scaffold(
            backgroundColor: kDarkWhite,
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => Scaffold(
            backgroundColor: kDarkWhite,
            body: Center(child: Text('Error: $e')),
          ),
        );
  }

  Widget _buildProductsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lista de Productos',
              style: kTextStyle.copyWith(
                color: kTitleColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showProductDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar Producto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        StreamBuilder<List<FrameProductModel>>(
          stream: repository.getProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: kBorderColorTextField),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'No hay productos registrados.\nPuede importar los datos predefinidos o agregar nuevos productos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kGreyTextColor),
                  ),
                ),
              );
            }
            
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: kBorderColorTextField),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(kMainColor.withValues(alpha: 0.1)),
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Tamaño')),
                  DataColumn(label: Text('Material')),
                  DataColumn(label: Text('Precio')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: snapshot.data!.map((product) {
                  return DataRow(
                    cells: [
                      DataCell(Text(product.productName)),
                      DataCell(Text(product.productType.toUpperCase())),
                      DataCell(Text(product.size ?? '-')),
                      DataCell(Text(product.material ?? '-')),
                      DataCell(Text('\$${product.productPrice.toStringAsFixed(2)}')),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: kMainColor),
                              onPressed: () => _showProductDialog(product: product),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(
                                isProduct: true,
                                id: product.productId!,
                                name: product.productName,
                              ),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lista de Servicios',
              style: kTextStyle.copyWith(
                color: kTitleColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showServiceDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar Servicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        StreamBuilder<List<PhotoServiceModel>>(
          stream: repository.getServices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: kBorderColorTextField),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'No hay servicios registrados.\nPuede importar los datos predefinidos o agregar nuevos servicios.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kGreyTextColor),
                  ),
                ),
              );
            }
            
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: kBorderColorTextField),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(kMainColor.withValues(alpha: 0.1)),
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Tamaño')),
                  DataColumn(label: Text('Descripción')),
                  DataColumn(label: Text('Precio')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: snapshot.data!.map((service) {
                  return DataRow(
                    cells: [
                      DataCell(Text(service.serviceName)),
                      DataCell(Text(service.serviceType.toUpperCase())),
                      DataCell(Text(service.size ?? '-')),
                      DataCell(
                        Tooltip(
                          message: service.description ?? '-',
                          child: Text(
                            service.description ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text('\$${service.servicePrice.toStringAsFixed(2)}')),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: kMainColor),
                              onPressed: () => _showServiceDialog(service: service),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(
                                isProduct: false,
                                id: service.serviceId!,
                                name: service.serviceName,
                              ),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showProductDialog({FrameProductModel? product}) async {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?.productName);
    final priceController = TextEditingController(
      text: product?.productPrice.toStringAsFixed(2) ?? '',
    );
    final sizeController = TextEditingController(text: product?.size);
    final materialController = TextEditingController(text: product?.material);
    final colorController = TextEditingController(text: product?.color);
    
    String productType = product?.productType ?? 'marco';
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Editar Producto' : 'Agregar Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto *',
                  hintText: 'Ej: Marco de Madera Clásico',
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: typesRepository.getProductTypes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return DropdownButtonFormField<String>(
                      value: null,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Producto *',
                      ),
                      items: const [],
                      onChanged: null,
                    );
                  }
                  
                  final types = snapshot.data!;
                  if (types.isEmpty) {
                    return const Text(
                      'No hay tipos de productos. Por favor, agregue tipos primero.',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  
                  // Verificar si el tipo actual existe en la lista
                  if (!types.any((t) => t['id'] == productType) && types.isNotEmpty) {
                    productType = types.first['id'];
                  }
                  
                  return DropdownButtonFormField<String>(
                    value: productType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Producto *',
                    ),
                    items: types.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['id'],
                        child: Text(type['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      productType = value!;
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio *',
                  hintText: '0.00',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sizeController,
                decoration: const InputDecoration(
                  labelText: 'Tamaño',
                  hintText: 'Ej: 8x10, 11x14',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: materialController,
                decoration: const InputDecoration(
                  labelText: 'Material',
                  hintText: 'Ej: madera, metal, plástico',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  hintText: 'Ej: Negro, Blanco, Natural',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || priceController.text.isEmpty) {
                toast('Por favor complete los campos obligatorios');
                return;
              }
              
              final price = double.tryParse(priceController.text);
              if (price == null || price <= 0) {
                toast('Por favor ingrese un precio válido');
                return;
              }
              
              Navigator.pop(context);
              
              try {
                EasyLoading.show(status: 'Guardando...');
                
                final newProduct = FrameProductModel(
                  productId: product?.productId,
                  productName: nameController.text,
                  productType: productType,
                  productPrice: price,
                  size: sizeController.text.isNotEmpty ? sizeController.text : null,
                  material: materialController.text.isNotEmpty ? materialController.text : null,
                  color: colorController.text.isNotEmpty ? colorController.text : null,
                );
                
                if (isEdit) {
                  // Obtener producto anterior para comparación
                  final beforeData = product != null ? {
                    'productName': product.productName,
                    'productPrice': product.productPrice,
                    'size': product.size,
                    'material': product.material,
                    'color': product.color,
                  } : null;
                  
                  await repository.updateProduct(newProduct);
                  
                  // Registrar en auditoría
                  try {
                    await AuditService().logUpdate(
                      module: AuditModule.products,
                      itemName: 'Producto Photo Invoice',
                      itemId: newProduct.productName,
                      beforeData: beforeData,
                      afterData: {
                        'productName': newProduct.productName,
                        'productPrice': newProduct.productPrice,
                        'size': newProduct.size,
                        'material': newProduct.material,
                        'color': newProduct.color,
                      },
                    );
                  } catch (auditError) {
                    // No interrumpir si falla la auditoría
                  }
                  
                  toast('Producto actualizado correctamente');
                } else {
                  await repository.saveProduct(newProduct);
                  
                  // Registrar en auditoría
                  try {
                    await AuditService().logCreate(
                      module: AuditModule.products,
                      itemName: 'Producto Photo Invoice',
                      itemId: newProduct.productName,
                      data: {
                        'productName': newProduct.productName,
                        'productType': newProduct.productType,
                        'productPrice': newProduct.productPrice,
                        'size': newProduct.size,
                        'material': newProduct.material,
                        'color': newProduct.color,
                      },
                    );
                  } catch (auditError) {
                    // No interrumpir si falla la auditoría
                  }
                  
                  toast('Producto agregado correctamente');
                }
                
                EasyLoading.dismiss();
              } catch (e) {
                EasyLoading.dismiss();
                toast('Error: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
            child: Text(isEdit ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showServiceDialog({PhotoServiceModel? service}) async {
    final isEdit = service != null;
    final nameController = TextEditingController(text: service?.serviceName);
    final priceController = TextEditingController(
      text: service?.servicePrice.toStringAsFixed(2) ?? '',
    );
    final sizeController = TextEditingController(text: service?.size);
    final descriptionController = TextEditingController(text: service?.description);
    
    String serviceType = service?.serviceType ?? 'impresion';
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Editar Servicio' : 'Agregar Servicio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Servicio *',
                  hintText: 'Ej: Impresión Estándar',
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: typesRepository.getServiceTypes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return DropdownButtonFormField<String>(
                      value: null,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Servicio *',
                      ),
                      items: const [],
                      onChanged: null,
                    );
                  }
                  
                  final types = snapshot.data!;
                  if (types.isEmpty) {
                    return const Text(
                      'No hay tipos de servicios. Por favor, agregue tipos primero.',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  
                  // Verificar si el tipo actual existe en la lista
                  if (!types.any((t) => t['id'] == serviceType) && types.isNotEmpty) {
                    serviceType = types.first['id'];
                  }
                  
                  return DropdownButtonFormField<String>(
                    value: serviceType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Servicio *',
                    ),
                    items: types.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['id'],
                        child: Text(type['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      serviceType = value!;
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio *',
                  hintText: '0.00',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sizeController,
                decoration: const InputDecoration(
                  labelText: 'Tamaño',
                  hintText: 'Ej: 4x6, 8x10',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Descripción del servicio',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || priceController.text.isEmpty) {
                toast('Por favor complete los campos obligatorios');
                return;
              }
              
              final price = double.tryParse(priceController.text);
              if (price == null || price < 0) {
                toast('Por favor ingrese un precio válido');
                return;
              }
              
              Navigator.pop(context);
              
              try {
                EasyLoading.show(status: 'Guardando...');
                
                final newService = PhotoServiceModel(
                  serviceId: service?.serviceId,
                  serviceName: nameController.text,
                  serviceType: serviceType,
                  servicePrice: price,
                  size: sizeController.text.isNotEmpty ? sizeController.text : null,
                  description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                );
                
                if (isEdit) {
                  // Obtener servicio anterior para comparación
                  final beforeData = service != null ? {
                    'serviceName': service.serviceName,
                    'servicePrice': service.servicePrice,
                    'size': service.size,
                    'description': service.description,
                  } : null;
                  
                  await repository.updateService(newService);
                  
                  // Registrar en auditoría
                  try {
                    await AuditService().logUpdate(
                      module: AuditModule.products,
                      itemName: 'Servicio Photo Invoice',
                      itemId: newService.serviceName,
                      beforeData: beforeData,
                      afterData: {
                        'serviceName': newService.serviceName,
                        'servicePrice': newService.servicePrice,
                        'size': newService.size,
                        'description': newService.description,
                      },
                    );
                  } catch (auditError) {
                    // No interrumpir si falla la auditoría
                  }
                  
                  toast('Servicio actualizado correctamente');
                } else {
                  await repository.saveService(newService);
                  
                  // Registrar en auditoría
                  try {
                    await AuditService().logCreate(
                      module: AuditModule.products,
                      itemName: 'Servicio Photo Invoice',
                      itemId: newService.serviceName,
                      data: {
                        'serviceName': newService.serviceName,
                        'serviceType': newService.serviceType,
                        'servicePrice': newService.servicePrice,
                        'size': newService.size,
                        'description': newService.description,
                      },
                    );
                  } catch (auditError) {
                    // No interrumpir si falla la auditoría
                  }
                  
                  toast('Servicio agregado correctamente');
                }
                
                EasyLoading.dismiss();
              } catch (e) {
                EasyLoading.dismiss();
                toast('Error: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
            child: Text(isEdit ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete({
    required bool isProduct,
    required String id,
    required String name,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Está seguro que desea eliminar ${isProduct ? 'el producto' : 'el servicio'} "$name"?\n\n'
          'Nota: No se puede eliminar si tiene ventas registradas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        EasyLoading.show(status: 'Eliminando...');
        
        if (isProduct) {
          await repository.deleteProduct(id);
          
          // Registrar en auditoría
          try {
            await AuditService().logDelete(
              module: AuditModule.products,
              itemName: 'Producto Photo Invoice',
              itemId: name,
              data: {
                'productName': name,
                'productId': id,
                'deletedAt': DateTime.now().toIso8601String(),
              },
            );
          } catch (auditError) {
            // No interrumpir si falla la auditoría
          }
        } else {
          await repository.deleteService(id);
          
          // Registrar en auditoría
          try {
            await AuditService().logDelete(
              module: AuditModule.products,
              itemName: 'Servicio Photo Invoice',
              itemId: name,
              data: {
                'serviceName': name,
                'serviceId': id,
                'deletedAt': DateTime.now().toIso8601String(),
              },
            );
          } catch (auditError) {
            // No interrumpir si falla la auditoría
          }
        }
        
        EasyLoading.dismiss();
        toast('${isProduct ? 'Producto' : 'Servicio'} eliminado correctamente');
      } catch (e) {
        EasyLoading.dismiss();
        toast('Error: $e');
      }
    }
  }

  Future<void> _importDefaultData() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar Datos Predefinidos'),
        content: const Text(
          'Esto importará los productos y servicios predefinidos del sistema.\n\n'
          '¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        EasyLoading.show(status: 'Importando datos...');
        
        // Obtener los datos predefinidos del provider
        final container = ProviderScope.containerOf(context);
        final defaultProducts = container.read(availableFrameProductsProvider);
        final defaultServices = container.read(availablePhotoServicesProvider);
        
        await repository.importDefaultProducts(defaultProducts);
        await repository.importDefaultServices(defaultServices);
        
        EasyLoading.dismiss();
        if (mounted) {
          toast('Datos importados correctamente');
        }
      } catch (e) {
        EasyLoading.dismiss();
        if (mounted) {
          toast('Error al importar: $e');
        }
      }
    }
  }
}