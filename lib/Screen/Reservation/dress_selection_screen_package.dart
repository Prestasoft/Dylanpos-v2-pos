import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Provider/dress_provider.dart';
import 'package:salespro_admin/model/ServicePackageModel.dart';
import 'package:salespro_admin/model/dress_model.dart';
import 'date_time_selection_screen.dart';

class DressSelectionPackageScreen extends ConsumerStatefulWidget {
  final ServicePackageModel packagesAsync;
  final String packageId;
  final String packageName;
  final List<String> dressIds;
  final String CategoryComposite;

  const DressSelectionPackageScreen({
    Key? key,
    required this.packagesAsync,
    required this.packageId,
    required this.packageName,
    required this.dressIds,
    required this.CategoryComposite,
  }) : super(key: key);

  @override
  ConsumerState<DressSelectionPackageScreen> createState() =>
      _DressSelectionPackageScreenState();
}

class _DressSelectionPackageScreenState
    extends ConsumerState<DressSelectionPackageScreen> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isUsingOneTimeProvider = true;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _itemsPerPage = 200; // Múltiplo de 4 para mejor alineación
  List<DressModel> _allDresses = [];
  List<DressModel> _displayedDresses = [];
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    Future.delayed(Duration(seconds: 5), _switchToOneTimeProvider);
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _switchToOneTimeProvider() {
    if (mounted && !isUsingOneTimeProvider) {
      setState(() {
        isUsingOneTimeProvider = true;
      });
    }
  }

  void _loadMoreItems() {
    if (_isLoadingMore || !_hasMoreItems) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;
    final startIndex = nextPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _allDresses.length) {
      setState(() {
        _hasMoreItems = false;
        _isLoadingMore = false;
      });
      return;
    }

    Future.delayed(Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        _displayedDresses.addAll(_allDresses.sublist(
          startIndex,
          endIndex > _allDresses.length ? _allDresses.length : endIndex,
        ));
        _currentPage = nextPage;
        _isLoadingMore = false;
      });
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreItems();
    }
  }

  void _filterDresses(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      _displayedDresses = _allDresses
          .where((dress) => dress.name.toLowerCase().contains(searchQuery))
          .toList();
      _currentPage = 0;
      _hasMoreItems = _displayedDresses.length > _itemsPerPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dressesAsync = isUsingOneTimeProvider
        ? ref.watch(dressesOnceProvider(widget.CategoryComposite))
        : ref.watch(availableDressesByComponentsProvider(
            widget.CategoryComposite));

    ref.watch(availableDressesByComponentsProvider(widget.CategoryComposite));
    //ref.watch(dressesOnceProvider(widget.CategoryComposite));

    
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 4 - 16; // 4 items por fila con margen

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
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isUsingOneTimeProvider = !isUsingOneTimeProvider;
                _allDresses = [];
                _displayedDresses = [];
                _currentPage = 0;
                _hasMoreItems = true;
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
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor, width: 1),
                ),
              ),
              onChanged: _filterDresses,
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
            if (!isUsingOneTimeProvider)
              TextButton(
                onPressed: _switchToOneTimeProvider,
                child: Text('¿Carga lenta? Toca aquí'),
              )
          ],
        )),
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
              Text('$e',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
          if (_allDresses.length != dresses.length) {
            _allDresses = dresses;
            _displayedDresses = _allDresses
                .where(
                    (dress) => dress.name.toLowerCase().contains(searchQuery))
                .toList();
            _currentPage = 0;
            _hasMoreItems = _displayedDresses.length > _itemsPerPage;
          }

          final itemsToDisplay = _displayedDresses.length > _itemsPerPage
              ? _displayedDresses.sublist(
                  0,
                  (_currentPage + 1) * _itemsPerPage > _displayedDresses.length
                      ? _displayedDresses.length
                      : (_currentPage + 1) * _itemsPerPage,
                )
              : _displayedDresses;

          return itemsToDisplay.isEmpty
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: GridView.builder(
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // 4 items por fila
                      childAspectRatio: 0.7, // Más cuadrados
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: itemsToDisplay.length + (_hasMoreItems ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= itemsToDisplay.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final dress = itemsToDisplay[index];
                      final isAvailable = dress.available;
                      final firstImage =
                          dress.images.isNotEmpty ? dress.images.first : '';

                      return GestureDetector(
                        onTap: isAvailable
                            ? () {
                                if (widget.dressIds.contains(dress.id)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Este vestido ya fue usado en esta reserva.'),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pop(
                                  context,
                                  {
                                    'vestidoName': dress.name,
                                    'vestidoId': dress.id,
                                    'branchId': dress.branchId,
                                    'vestidoPrice': dress.price.toString(),
                                  },

                                  // MaterialPageRoute(
                                  //   builder: (context) =>
                                  //       DateTimeSelectionScreen(
                                  //     packageId: widget.packageId,
                                  //     packageName: widget.packageName,
                                  //     dressId: dress.id,
                                  //     dressName: dress.name,
                                  //     branchId: dress.branchId,
                                  //   ),
                                  // ),
                                );
                              }
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Contenedor de imagen más pequeño
                              Container(
                                height: itemWidth *
                                    0.9, // Altura proporcional al ancho
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(8)),
                                  color: Colors.grey[100],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(8)),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (firstImage.isNotEmpty)
                                        _OptimizedImageWidget(
                                          imageUrl: firstImage,
                                          width: itemWidth.toInt(),
                                          height: (itemWidth * 0.9).toInt(),
                                        )
                                      else
                                        Container(
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.image,
                                            color: Colors.grey[400],
                                            size: 24,
                                          ),
                                        ),
                                      if (!isAvailable)
                                        Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.4),
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(8)),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'RESERVADO',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // Información del vestido (más compacta)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dress.name,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    DressStatusBadge(
                                      isAvailable: isAvailable,
                                      timeLeft: null,
                                      compact:
                                          true, // Versión compacta del badge
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
}

class _OptimizedImageWidget extends StatelessWidget {
  final String imageUrl;
  final int width;
  final int height;

  const _OptimizedImageWidget({
    required this.imageUrl,
    this.width = 150,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: width.toDouble(),
      height: height.toDouble(),
      cacheWidth: width, // Optimización de memoria
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 1,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.broken_image, size: 24, color: Colors.grey[400]),
        ),
      ),
    );
  }
}

class DressStatusBadge extends StatelessWidget {
  final bool isAvailable;
  final int? timeLeft;
  final bool compact;

  const DressStatusBadge({
    Key? key,
    required this.isAvailable,
    this.timeLeft,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    if (isAvailable) {
      return Container(
        padding: compact
            ? EdgeInsets.symmetric(horizontal: 6, vertical: 2)
            : EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(compact ? 8 : 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: compact ? 12 : 14,
              color: Colors.green,
            ),
            SizedBox(width: compact ? 2 : 4),
            Text(
              'Disponible',
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
                fontSize: compact ? 10 : 12,
              ),
            ),
          ],
        ),
      );
    } else {
      // ignore: unused_local_variable
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
        padding: compact
            ? EdgeInsets.symmetric(horizontal: 6, vertical: 2)
            : EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(compact ? 8 : 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer,
              size: compact ? 12 : 14,
              color: Colors.red,
            ),
            SizedBox(width: compact ? 2 : 4),
            Text(
              timeLeft != null ? 'Reservado' : 'No disponible',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
                fontSize: compact ? 10 : 12,
              ),
            ),
          ],
        ),
      );
    }
  }
}
