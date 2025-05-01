import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Provider/servicePackagesProvider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/ServicePackageModel.dart';
import 'package:salespro_admin/model/customer_model.dart';
import 'Seleccioncliente.dart';
import 'dress_selection_screen.dart';
import '../../commas.dart';

// Proveedor para almacenar el texto de búsqueda
final searchQueryProvider = StateProvider<String>((ref) => '');

// Proveedor para filtrar por categoría
final categoryFilterProvider = StateProvider<String?>((ref) => null);

// Proveedor para los paquetes filtrados
final filteredPackagesProvider = Provider<AsyncValue<List<ServicePackageModel>>>((ref) {
  final packages = ref.watch(servicePackagesProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final categoryFilter = ref.watch(categoryFilterProvider);

  return packages.whenData((data) {
    return data.where((package) {
      // Filtrar por texto de búsqueda
      final matchesSearch = searchQuery.isEmpty ||
          package.name.toLowerCase().contains(searchQuery) ||
          package.category.toLowerCase().contains(searchQuery) ||
          package.subcategory.toLowerCase().contains(searchQuery);

      // Filtrar por categoría
      final matchesCategory = categoryFilter == null ||
          package.category == categoryFilter;

      return matchesSearch && matchesCategory;
    }).toList();
  });
});

// Proveedor para las categorías disponibles
final availableCategoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final packages = ref.watch(servicePackagesProvider);

  return packages.whenData((data) {
    final categories = data.map((e) => e.category).toSet().toList();
    categories.sort();
    return categories;
  });
});

class PackageListScreen extends ConsumerWidget {
  const PackageListScreen({Key? key}) : super(key: key);

  static const String route = '/list';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredPackages = ref.watch(filteredPackagesProvider);
    final categories = ref.watch(availableCategoriesProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Scaffold(
          body: Column(
            children: [
              _buildHeader(context, ref),
              //Cliente(ref),
              _buildSearchBar(ref),

              _buildCategoryFilter(ref, categories, context),

              Expanded(
                child: filteredPackages.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error: $error', style: TextStyle(color: Colors.red)),
                  ),
                  data: (packages) {
                    if (packages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'No se encontraron paquetes',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                ref.read(searchQueryProvider.notifier).state = '';
                                ref.read(categoryFilterProvider.notifier).state = null;
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Limpiar filtros'),
                            )
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => ref.read(servicePackagesProvider.notifier).loadPackages(),
                      child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Diseño responsivo - ajustar columnas según el ancho disponible
                            final crossAxisCount = _calculateColumnCount(constraints.maxWidth);

                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: packages.length,
                                itemBuilder: (context, index) {
                                  return _buildPackageCard(context, packages[index]);
                                },
                              ),
                            );
                          }
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => ref.read(servicePackagesProvider.notifier).loadPackages(),
            child: const Icon(Icons.refresh),
            backgroundColor: Colors.black,
            tooltip: 'Actualizar paquetes',
          ),
        ),
      ),
    );
  }

  int _calculateColumnCount(double width) {
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
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
            "Paquetes de Servicio",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
          Row(
            children: [
              Text(
                "Disponible: ",
                style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.7)),
              ),
              ref.watch(servicePackagesProvider).when(
                loading: () => SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                  ),
                ),
                error: (_, __) => Icon(Icons.error, color: colorScheme.error),
                data: (data) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${data.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Cliente(WidgetRef ref){
  //   CustomerModel? selectedCustomer;
  //     return Padding(
  //               padding: const EdgeInsets.all(12),
  //               child: CustomerSelector(initialCustomer : selectedCustomer, onCustomerSelected: (CustomerModel ) {
  //           },),
  //     );
  // }
  Widget _buildSearchBar(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: 'Buscar paquetes...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              ref.read(searchQueryProvider.notifier).state = '';
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(WidgetRef ref, AsyncValue<List<String>> categoriesAsync, BuildContext context) {
    final selectedCategory = ref.watch(categoryFilterProvider);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: categoriesAsync.when(
        loading: () => const SizedBox(),
        error: (_, __) => const SizedBox(),
        data: (categories) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: selectedCategory == null,
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selectedCategory == null
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onSelected: (_) {
                    ref.read(categoryFilterProvider.notifier).state = null;
                  },
                ),
                const SizedBox(width: 8),
                ...categories.map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onSelected: (_) {
                        ref.read(categoryFilterProvider.notifier).state =
                        isSelected ? null : category;
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildPackageCard(BuildContext context, ServicePackageModel package) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DressSelectionScreen(
                packagesAsync: package,
                packageId: package.id,
                packageName: package.name,
                dressIds: package.components,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado de la tarjeta
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor,
              child: Text(
                package.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Cuerpo de la tarjeta
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.category, package.category),
                    const SizedBox(height: 2),
                    _buildInfoRow(Icons.description, package.subcategory),
                    const SizedBox(height: 2),
                    _buildInfoRow(Icons.category, package.description),

                    const SizedBox(height: 2),
                    _buildInfoRow(
                      Icons.attach_money,
                      '\$${myFormat.format(package.price)}',
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        Icons.timer,
                        '${package.duration['value']} ${package.duration['unit']}'
                    ),
                  ],
                ),
              ),
            ),

            // Botón de selección
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DressSelectionScreen(
                        packagesAsync: package,
                        packageId: package.id,
                        packageName: package.name,
                        dressIds: package.components,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Seleccionar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInfoRow(IconData icon, String text, {bool isHighlighted = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlighted ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isHighlighted ? 16 : 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.green.shade800 : Colors.black87,
            ),
            // Changed from maxLines: 1 to maxLines: 2 to allow more text
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }}