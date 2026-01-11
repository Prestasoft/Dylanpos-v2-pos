import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/Repository/photo_types_repository.dart';
import 'package:salespro_admin/Provider/profile_provider.dart';
import 'package:salespro_admin/services/audit_service.dart';
import 'package:salespro_admin/model/audit_model.dart';

class PhotoProductServiceTypesScreen extends ConsumerStatefulWidget {
  const PhotoProductServiceTypesScreen({super.key});

  static const String route = '/sales/photo-product-service-types';

  @override
  ConsumerState<PhotoProductServiceTypesScreen> createState() => _PhotoProductServiceTypesScreenState();
}

class _PhotoProductServiceTypesScreenState extends ConsumerState<PhotoProductServiceTypesScreen> {
  bool showProductTypes = true;
  late PhotoTypesRepository repository;
  
  // Mapeo de nombres de iconos a IconData
  final Map<String, IconData> iconMap = {
    'crop_square': Icons.crop_square,
    'photo_album': Icons.photo_album,
    'image': Icons.image,
    'print': Icons.print,
    'photo': Icons.photo,
    'scanner': Icons.scanner,
    'healing': Icons.healing,
    'more_horiz': Icons.more_horiz,
    'camera': Icons.camera_alt,
    'portrait': Icons.portrait,
    'landscape': Icons.landscape,
    'burst_mode': Icons.burst_mode,
    'photo_size_select_large': Icons.photo_size_select_large,
    'filter': Icons.filter,
    'edit': Icons.edit,
    'brush': Icons.brush,
  };

  @override
  Widget build(BuildContext context) {
    final personalData = ref.watch(profileDetailsProvider);
    
    if (personalData.isLoading) {
      return Scaffold(
        backgroundColor: kDarkWhite,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return personalData.when(
      data: (personalInfo) {
        repository = PhotoTypesRepository(userId: personalInfo.phoneNumber);
        
        return Scaffold(
          backgroundColor: kDarkWhite,
          appBar: AppBar(
            backgroundColor: kWhite,
            elevation: 0,
            title: Text(
              'Tipos de Productos y Servicios',
              style: kTextStyle.copyWith(
                color: kTitleColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  print('Test: Probando agregar tipo directamente');
                  try {
                    await repository.addProductType('Test', 'more_horiz');
                    toast('Test agregado exitosamente');
                  } catch (e) {
                    print('Test Error: $e');
                    toast('Error en test: $e');
                  }
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Test Add'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  print('Test: Probando editar tipo directamente');
                  try {
                    // Primero agregar un tipo de prueba
                    await repository.addProductType('TestEdit', 'camera');
                    // Luego editarlo
                    await repository.updateProductType('testedit', 'TestEdit Modificado', 'edit');
                    toast('Test de edición exitoso');
                  } catch (e) {
                    print('Test Edit Error: $e');
                    toast('Error en test de edición: $e');
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Test Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
              TextButton.icon(
                onPressed: _importDefaultTypes,
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
                  // Tabs para cambiar entre tipos de productos y servicios
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBorderColorTextField),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => showProductTypes = true),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: showProductTypes ? kMainColor : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Tipos de Productos',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: showProductTypes ? Colors.white : kTitleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => showProductTypes = false),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: !showProductTypes ? kMainColor : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Tipos de Servicios',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !showProductTypes ? Colors.white : kTitleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Contenido principal
                  showProductTypes ? _buildProductTypesSection() : _buildServiceTypesSection(),
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

  Widget _buildProductTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipos de Productos',
                  style: kTextStyle.copyWith(
                    color: kTitleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Gestiona las categorías de productos disponibles',
                  style: kTextStyle.copyWith(
                    color: kGreyTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(true, null),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar Tipo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: repository.getProductTypes(),
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
                    'No hay tipos de productos registrados.\nPuede importar los predefinidos o agregar nuevos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kGreyTextColor),
                  ),
                ),
              );
            }
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final type = snapshot.data![index];
                return _buildTypeCard(type, true);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipos de Servicios',
                  style: kTextStyle.copyWith(
                    color: kTitleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Gestiona las categorías de servicios disponibles',
                  style: kTextStyle.copyWith(
                    color: kGreyTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(false, null),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar Tipo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: repository.getServiceTypes(),
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
                    'No hay tipos de servicios registrados.\nPuede importar los predefinidos o agregar nuevos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kGreyTextColor),
                  ),
                ),
              );
            }
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final type = snapshot.data![index];
                return _buildTypeCard(type, false);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypeCard(Map<String, dynamic> type, bool isProduct) {
    final iconString = type['icon'] ?? 'more_horiz';
    final icon = iconMap[iconString] ?? Icons.more_horiz;
    
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColorTextField),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showTypeOptions(type, isProduct),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kMainColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: kMainColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        type['name'] ?? '',
                        style: kTextStyle.copyWith(
                          color: kTitleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'ID: ${type['id'] ?? ''}',
                        style: kTextStyle.copyWith(
                          color: kGreyTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  color: kGreyTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTypeOptions(Map<String, dynamic> type, bool isProduct) {
    print('_showTypeOptions: type = $type, isProduct = $isProduct');
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: kMainColor),
              title: const Text('Editar'),
              onTap: () {
                print('_showTypeOptions: Editando tipo con isProduct = $isProduct y type = $type');
                Navigator.pop(context);
                _showAddEditDialog(isProduct, type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(type, isProduct);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog(bool isProduct, Map<String, dynamic>? type) async {
    final isEdit = type != null;
    
    // Hacer una copia local del type para evitar problemas de referencia
    final Map<String, dynamic>? typeData = type != null ? Map<String, dynamic>.from(type) : null;
    
    // Debug: Imprimir el contenido del type cuando es edición
    if (isEdit) {
      print('_showAddEditDialog: Modo edición activado');
      print('_showAddEditDialog: type original = $type');
      print('_showAddEditDialog: typeData copia = $typeData');
      print('_showAddEditDialog: type.id = ${typeData?['id']}');
      print('_showAddEditDialog: type.name = ${typeData?['name']}');
      print('_showAddEditDialog: type.icon = ${typeData?['icon']}');
      print('_showAddEditDialog: isProduct = $isProduct');
    } else {
      print('_showAddEditDialog: Modo creación activado');
      print('_showAddEditDialog: isProduct = $isProduct');
    }
    
    final nameController = TextEditingController(text: typeData?['name'] ?? '');
    String selectedIcon = typeData?['icon'] ?? 'more_horiz';
    
    // Verificar que el repositorio esté inicializado
    if (!mounted) return;
    
    final localRepository = repository;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setStateDialog) => AlertDialog(
          title: Text(
            isEdit 
              ? 'Editar Tipo de ${isProduct ? "Producto" : "Servicio"}' 
              : 'Agregar Tipo de ${isProduct ? "Producto" : "Servicio"}'
          ),
          content: Container(
            width: 350,
            constraints: const BoxConstraints(
              maxHeight: 400,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Tipo *',
                    hintText: 'Ej: Marco, Impresión, etc.',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Selecciona un ícono:',
                  style: kTextStyle.copyWith(
                    color: kTitleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  width: 300,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: iconMap.length,
                    itemBuilder: (context, index) {
                      final iconName = iconMap.keys.elementAt(index);
                      final icon = iconMap.values.elementAt(index);
                      final isSelected = selectedIcon == iconName;
                      
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            selectedIcon = iconName;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? kMainColor : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? kMainColor : kBorderColorTextField,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? Colors.white : kTitleColor,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  toast('Por favor ingrese un nombre');
                  return;
                }
                
                Navigator.pop(dialogContext);
                
                try {
                  EasyLoading.show(status: 'Guardando...');
                  
                  if (isEdit && typeData != null) {
                    // Debug adicional antes de actualizar
                    print('DEBUG: Antes de actualizar');
                    print('DEBUG: typeData = $typeData');
                    print('DEBUG: typeData.runtimeType = ${typeData.runtimeType}');
                    print('DEBUG: typeData.id existe? = ${typeData.containsKey('id')}');
                    print('DEBUG: typeData.id valor = ${typeData['id']}');
                    
                    // Verificar que el ID existe
                    if (!typeData.containsKey('id') || typeData['id'] == null) {
                      throw Exception('El tipo no tiene un ID válido');
                    }
                    
                    final String typeId = typeData['id'].toString();
                    print('DEBUG: typeId a usar = $typeId');
                    
                    if (isProduct) {
                      await localRepository.updateProductType(
                        typeId,
                        nameController.text,
                        selectedIcon,
                      );
                    } else {
                      await localRepository.updateServiceType(
                        typeId,
                        nameController.text,
                        selectedIcon,
                      );
                    }
                    
                    // Registrar en auditoría
                    await AuditService().logUpdate(
                      module: AuditModule.products,
                      itemName: 'Tipo de ${isProduct ? "Producto" : "Servicio"}',
                      itemId: typeId,
                      beforeData: typeData,
                      afterData: {
                        'name': nameController.text,
                        'icon': selectedIcon,
                      },
                    );
                    
                    toast('Tipo actualizado correctamente');
                  } else {
                    if (isProduct) {
                      await localRepository.addProductType(
                        nameController.text,
                        selectedIcon,
                      );
                    } else {
                      await localRepository.addServiceType(
                        nameController.text,
                        selectedIcon,
                      );
                    }
                    
                    // Registrar en auditoría
                    await AuditService().logCreate(
                      module: AuditModule.products,
                      itemName: 'Tipo de ${isProduct ? "Producto" : "Servicio"}',
                      itemId: nameController.text.toLowerCase().replaceAll(' ', '_'),
                      data: {
                        'name': nameController.text,
                        'icon': selectedIcon,
                      },
                    );
                    
                    toast('Tipo agregado correctamente');
                  }
                  
                  EasyLoading.dismiss();
                } catch (e, stackTrace) {
                  EasyLoading.dismiss();
                  print('Error al guardar tipo: $e');
                  print('Stack trace: $stackTrace');
                  
                  // Mostrar información más detallada del error
                  String errorMessage = 'Error: $e';
                  if (e.toString().contains('permission-denied')) {
                    errorMessage = 'Error: No tiene permisos para realizar esta acción';
                  } else if (e.toString().contains('network')) {
                    errorMessage = 'Error: Problema de conexión a internet';
                  }
                  
                  toast(errorMessage);
                  
                  // Log adicional para debugging
                  print('DEBUG: Error completo');
                  print('DEBUG: isEdit = $isEdit');
                  print('DEBUG: isProduct = $isProduct');
                  if (isEdit) {
                    print('DEBUG: typeData al momento del error = $typeData');
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
              child: Text(isEdit ? 'Actualizar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> type, bool isProduct) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Está seguro que desea eliminar el tipo "${type['name']}"?\n\n'
          'Nota: No se puede eliminar si hay ${isProduct ? "productos" : "servicios"} usando este tipo.',
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
          await repository.deleteProductType(type['id']);
        } else {
          await repository.deleteServiceType(type['id']);
        }
        
        // Registrar en auditoría
        await AuditService().logDelete(
          module: AuditModule.products,
          itemName: 'Tipo de ${isProduct ? "Producto" : "Servicio"}',
          itemId: type['id'],
          data: type,
        );
        
        EasyLoading.dismiss();
        toast('Tipo eliminado correctamente');
      } catch (e) {
        EasyLoading.dismiss();
        toast('Error: $e');
      }
    }
  }

  Future<void> _importDefaultTypes() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar Tipos Predefinidos'),
        content: const Text(
          'Esto importará los tipos de productos y servicios predefinidos del sistema.\n\n'
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
        EasyLoading.show(status: 'Importando tipos...');
        
        await repository.importDefaultProductTypes();
        await repository.importDefaultServiceTypes();
        
        EasyLoading.dismiss();
        toast('Tipos importados correctamente');
      } catch (e) {
        EasyLoading.dismiss();
        toast('Error al importar: $e');
      }
    }
  }
}