import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro_admin/Provider/dress_provider.dart';
import 'package:salespro_admin/model/ServicePackageModel.dart';
import 'package:salespro_admin/model/dress_model.dart';
import 'date_time_selection_screen.dart';

class DressSelectionScreen extends ConsumerStatefulWidget {
  final ServicePackageModel packagesAsync;
  final String packageId;
  final String packageName;
  final List<String> dressIds;

  const DressSelectionScreen({
    Key? key,
    required this.packagesAsync,
    required this.packageId,
    required this.packageName,
    required this.dressIds,
  }) : super(key: key);

  @override
  ConsumerState<DressSelectionScreen> createState() => _DressSelectionScreenState();
}

class _DressSelectionScreenState extends ConsumerState<DressSelectionScreen> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isUsingOneTimeProvider = false; // Flag para alternar entre proveedores

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Función para cambiar al proveedor alternativo si el principal tarda mucho
  void _switchToOneTimeProvider() {
    if (mounted && !isUsingOneTimeProvider) {
      setState(() {
        isUsingOneTimeProvider = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Programamos un cambio automático si tarda más de 5 segundos
    Future.delayed(Duration(seconds: 5), _switchToOneTimeProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Seleccionamos el proveedor a usar basado en la bandera
    final dressesAsync = isUsingOneTimeProvider
        ? ref.watch(dressesOnceProvider(widget.packagesAsync.category))
        : ref.watch(availableDressesByComponentsProvider(widget.packagesAsync.category));

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Selecciona tu vestido',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          // Botón para recargar/alternar entre proveedores
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isUsingOneTimeProvider = !isUsingOneTimeProvider;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar vestidos...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor, width: 1),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: dressesAsync.when(
        loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: theme.primaryColor),
                SizedBox(height: 16),
                Text(
                  isUsingOneTimeProvider
                      ? 'Cargando vestidos...'
                      : 'Buscando vestidos disponibles...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                // Botón para cambiar manualmente de proveedor si está tardando
                if (!isUsingOneTimeProvider)
                  TextButton(
                    onPressed: _switchToOneTimeProvider,
                    child: Text('¿Carga lenta? Toca aquí'),
                  )
              ],
            )
        ),
        error: (e, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              SizedBox(height: 16),
              Text(
                'Error al cargar vestidos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text('$e', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isUsingOneTimeProvider = !isUsingOneTimeProvider;
                  });
                },
                child: Text('Intentar otra vez'),
              ),
            ],
          ),
        ),
        data: (dresses) {
          final filteredDresses = dresses.where((dress) {
            return dress.name.toLowerCase().contains(searchQuery) ||
                (dress.name?.toLowerCase().contains(searchQuery) ?? false);
          }).toList();

          return filteredDresses.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  searchQuery.isEmpty
                      ? 'No hay vestidos disponibles'
                      : 'No se encontraron resultados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          )
              : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredDresses.length,
              itemBuilder: (context, index) {
                final dress = filteredDresses[index];
                final isAvailable = dress.available;
                final firstImage = dress.images.isNotEmpty ? dress.images.first : '';

                return GestureDetector(
                  onTap: isAvailable
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DateTimeSelectionScreen(
                          packageId: widget.packageId,
                          packageName: widget.packageName,
                          dressId: dress.id,
                          dressName: dress.name,
                          branchId: dress.branchId,
                        ),
                      ),
                    );
                  }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Contenedor de imagen con carga optimizada y manejo de errores
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            color: Colors.grey[100],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (firstImage.isNotEmpty)
                                  _OptimizedImageWidget(imageUrl: firstImage)
                                else
                                  Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.grey[400],
                                      size: 40,
                                    ),
                                  ),

                                if (!isAvailable)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'RESERVADO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),

                                if (dress.images.length > 1)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _showImageGallery(context, dress),
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.collections,
                                          color: theme.primaryColor,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Información del vestido
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dress.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              DressStatusBadge(
                                isAvailable: isAvailable,
                                timeLeft: null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showImageGallery(BuildContext context, DressModel dress) {
    if (dress.images.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        int currentIndex = 0;

        return StatefulBuilder(
          builder: (builderContext, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(10),
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${currentIndex + 1}/${dress.images.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: Colors.grey[700]),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 280,
                        height: 250,
                        child: _OptimizedImageWidget(imageUrl: dress.images[currentIndex]),
                      ),
                    ),

                    if (dress.images.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios_new, size: 20),
                              onPressed: currentIndex > 0
                                  ? () => setState(() => currentIndex--)
                                  : null,
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_forward_ios, size: 20),
                              onPressed: currentIndex < dress.images.length - 1
                                  ? () => setState(() => currentIndex++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Widget optimizado para cargar imágenes con manejo de memoria y errores
class _OptimizedImageWidget extends StatelessWidget {
  final String imageUrl;

  const _OptimizedImageWidget({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      // Añadimos un framework de caché para mejorar rendimiento
      cacheWidth: 300, // Para optimizar el uso de memoria
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
        ),
      ),
    );
  }
}

class DressStatusBadge extends StatelessWidget {
  final bool isAvailable;
  final int? timeLeft;

  const DressStatusBadge({
    Key? key,
    required this.isAvailable,
    this.timeLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isAvailable) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.green),
            SizedBox(width: 4),
            Text(
              'Disponible',
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else {
      String timeText = 'No disponible';
      if (timeLeft != null && timeLeft! > 0) {
        final duration = Duration(milliseconds: timeLeft!);
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;

        if (hours > 0) {
          timeText = '$hours h $minutes m';
        } else {
          timeText = '$minutes m';
        }
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, size: 14, color: Colors.red),
            SizedBox(width: 4),
            Text(
              timeLeft != null ? 'Reservado ($timeText)' : 'No disponible',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }
}