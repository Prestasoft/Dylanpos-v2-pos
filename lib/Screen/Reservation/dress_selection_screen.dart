// ARCHIVO 1: dress_selection_screen.dart (versión mejorada)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dressesAsync = ref.watch(availableDressesByComponentsProvider(widget.packagesAsync.category));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Vestidos disponibles',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar vestidos...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(vertical: 12),
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
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
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
            ],
          ),
        ),
        data: (dresses) {
          // Filtrar vestidos según la búsqueda
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75, // Ajustado para imágenes más pequeñas
                crossAxisSpacing: 12,
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
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black26,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contenedor de imagen más pequeño
                        Container(
                          height: 150, // Altura fija más pequeña
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                firstImage.isNotEmpty
                                    ? Image.network(
                                  firstImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey[200],
                                        child: Icon(Icons.image_not_supported,
                                            color: Colors.grey[400], size: 40),
                                      ),
                                )
                                    : Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image,
                                      color: Colors.grey[400], size: 40),
                                ),
                                if (!isAvailable)
                                  Container(
                                    color: Colors.black.withOpacity(0.3),
                                    child: Center(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'No disponible',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (dress.images.length > 1)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        _showImageGallery(context, dress);
                                      },
                                      child: Container(
                                        height: 28,
                                        width: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.collections,
                                          color: theme.primaryColor,
                                          size: 16,
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
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dress.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6),
                              DressStatusBadge(
                                isAvailable: isAvailable,
                                timeLeft: null,
                              ),
                              // if (dress.price != null) ...[
                              //   SizedBox(height: 6),
                              //   Text(
                              //     '\$${dress.price!.toStringAsFixed(2)}',
                              //     style: TextStyle(
                              //       fontSize: 14,
                              //       fontWeight: FontWeight.w600,
                              //       color: theme.primaryColor,
                              //     ),
                              //   ),
                              // ],
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
      builder: (dialogContext) {
        int currentIndex = 0;

        return StatefulBuilder(
          builder: (builderContext, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${currentIndex + 1}/${dress.images.length}',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(dialogContext).pop(),
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 300, // Tamaño más pequeño para el carrusel
                            child: CarouselSlider.builder(
                              itemCount: dress.images.length,
                              options: CarouselOptions(
                                height: 300,
                                viewportFraction: 1.0,
                                enableInfiniteScroll: dress.images.length > 1,
                                autoPlay: false,
                                enlargeCenterPage: true,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    currentIndex = index;
                                  });
                                },
                              ),
                              itemBuilder: (context, index, _) {
                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: 5),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      dress.images[index],
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                            color: Colors.grey[800],
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.broken_image,
                                                      size: 40, color: Colors.white60),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Error al cargar imagen',
                                                    style: TextStyle(color: Colors.white60),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              dress.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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

// Mantener la clase DressStatusBadge igual que en la versión original
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
    if (isAvailable) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade300, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 12, color: Colors.green),
            SizedBox(width: 4),
            Text(
              'Disponible',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 10,
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
          timeText = '$minutes m ${duration.inSeconds % 60} s';
        }
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, size: 12, color: Colors.red),
            SizedBox(width: 4),
            Text(
              timeLeft != null ? 'Reservado: $timeText' : 'No disponible',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }
  }
}