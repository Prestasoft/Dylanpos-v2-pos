import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:hugeicons/hugeicons.dart'; // Eliminado
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/dress_provider.dart';
import 'package:salespro_admin/Provider/dress_with_reservations.dart';
import 'package:salespro_admin/Provider/product_provider.dart';
import 'package:salespro_admin/Screen/WareHouse/warehouse_model.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/export_button.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/category_model.dart';
import 'package:salespro_admin/model/dress_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DressScreen extends StatefulWidget {
  const DressScreen({super.key});

  static const String route = '/dresses';

  @override
  State<DressScreen> createState() => _DressScreenState();
}

class _DressScreenState extends State<DressScreen> {
  String? _selectedCategoryFilter;
  int selectedItem = 10;
  int itemCount = 10;

  TextEditingController _nameController = TextEditingController();
  String? _selectedCategory;
  WareHouseModel? selectedWareHouse;
  String? _selectedBranch;
  TextEditingController _subcategoryController = TextEditingController();
  ScrollController mainScroll = ScrollController();
  String searchItem = '';
  bool _isAvailable = true;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _priceController = TextEditingController();

  // For image handling
  final List<dynamic> _selectedImages =
      []; // Can hold File (mobile) or XFile/Uint8List (web)
  final List<String> _existingImageUrls = [];

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  int _itemsPerPage = 10;
  int _currentPage = 1;

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedImages = await ImagePicker().pickMultiImage();
      if (pickedImages.isNotEmpty) {
        setState(() {
          if (kIsWeb) {
            // For web, store XFile objects directly
            _selectedImages.addAll(pickedImages);
          } else {
            // For mobile, convert to File objects
            _selectedImages
                .addAll(pickedImages.map((xFile) => File(xFile.path)));
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final _lang = lang.S.of(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (_, ref, watch) {
          AsyncValue<List<DressModel>> dresses = ref.watch(dressesProvider);
          // Cargar categorías desde el endpoint dedicado (incluye TODAS las categorías)
          final categoriesAsync = ref.watch(dressCategoriesProvider);
          final allCategories = categoriesAsync.valueOrNull ?? [];

          return dresses.when(data: (list) {

            List<DressModel> showAbleDresses = [];
            for (var element in list) {
              final matchesName = element.name.removeAllWhiteSpace().toLowerCase().contains(searchItem.toLowerCase()) || searchItem == '';
              final matchesCategory = _selectedCategoryFilter == null || _selectedCategoryFilter == '' || element.category == _selectedCategoryFilter;
              if (matchesName && matchesCategory) {
                showAbleDresses.add(element);
              }
            }

            // Ordenar por los últimos 3 dígitos del nombre de forma ascendente (siempre 3 dígitos al final)
            showAbleDresses.sort((a, b) {
              int getLast3Digits(String name) {
                if (name.length >= 3) {
                  final last3 = name.substring(name.length - 3);
                  final n = int.tryParse(last3);
                  return n ?? 0;
                }
                return 0;
              }
              return getLast3Digits(a.name).compareTo(getLast3Digits(b.name));
            });

            final pages = (showAbleDresses.length / _itemsPerPage).ceil();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0), color: kWhite),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 12, right: 12, top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _lang.dresses,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Botón Agregar - Solo visible si tiene permiso de edición
                          if (checkUserRoleEditPermissionV2(type: 'register_clothing'))
                          ElevatedButton.icon(
                            onPressed: () async {
                              _showAddDressDialog(context, ref);
                            },
                            icon: const Icon(FeatherIcons.plus,
                                color: kWhite, size: 18.0),
                            label: Text(
                              _lang.addDress,
                              style: kTextStyle.copyWith(color: kWhite),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(
                      height: 1,
                      thickness: 1.0,
                      color: kDividerColor,
                    ),
                    const SizedBox(height: 10),

                    // Search, filter and pagination controls
                    ResponsiveGridRow(
                      rowSegments: 100,
                      children: [
                        ResponsiveGridCol(
                          xs: screenWidth < 360 ? 50 : screenWidth > 430 ? 33 : 40,
                          md: screenWidth < 768 ? 24 : screenWidth < 950 ? 20 : 15,
                          lg: screenWidth < 1700 ? 15 : 10,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              alignment: Alignment.center,
                              height: 48,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: kNeutral300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Show-',
                                      style: theme.textTheme.bodyLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownButton<int>(
                                    isDense: true,
                                    padding: EdgeInsets.zero,
                                    underline: const SizedBox(),
                                    value: _itemsPerPage,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.black,
                                    ),
                                    items: [10, 20, 50, 100, -1].map<DropdownMenuItem<int>>((int value) {
                                      return DropdownMenuItem<int>(
                                        value: value,
                                        child: Text(
                                          value == -1 ? "All" : value.toString(),
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (int? newValue) {
                                      setState(() {
                                        if (newValue == -1) {
                                          _itemsPerPage = -1;
                                        } else {
                                          _itemsPerPage = newValue ?? 10;
                                        }
                                        _currentPage = 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          xs: 100,
                          md: 40,
                          lg: 25,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategoryFilter,
                              isExpanded: true,
                              decoration: kInputDecoration.copyWith(
                                contentPadding: const EdgeInsets.all(10.0),
                                hintText: 'Filtrar por categoría',
                              ),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Todas las categorías'),
                                ),
                                // Usar allCategories del endpoint dedicado (incluye TODAS las categorías)
                                ...allCategories.map((cat) => DropdownMenuItem<String>(
                                      value: cat,
                                      child: Text(cat),
                                    ))
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryFilter = value;
                                  _currentPage = 1;
                                });
                              },
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          xs: 100,
                          md: 60,
                          lg: 35,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: TextFormField(
                              showCursor: true,
                              cursorColor: kTitleColor,
                              onChanged: (value) {
                                setState(() {
                                  searchItem = value;
                                });
                              },
                              keyboardType: TextInputType.name,
                              decoration: kInputDecoration.copyWith(
                                contentPadding: const EdgeInsets.all(10.0),
                                hintText: (_lang.searchByName),
                                suffixIcon: const Icon(
                                  FeatherIcons.search,
                                  color: kNeutral400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20.0),
                    showAbleDresses.isNotEmpty
                        ? Column(
                            children: [
                              LayoutBuilder(
                                builder: (BuildContext context,
                                    BoxConstraints constraints) {
                                  final kWidth = constraints.maxWidth;
                                  return Scrollbar(
                                    controller: _horizontalScroll,
                                    thumbVisibility: true,
                                    radius: const Radius.circular(8),
                                    thickness: 8,
                                    child: SingleChildScrollView(
                                      controller: _horizontalScroll,
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: kWidth,
                                        ),
                                        child: Theme(
                                          data: theme.copyWith(
                                            dividerColor: Colors.transparent,
                                            dividerTheme:
                                                const DividerThemeData(
                                                    color: Colors.transparent),
                                          ),
                                          child: DataTable(
                                              border: const TableBorder(
                                                horizontalInside: BorderSide(
                                                  width: 1,
                                                  color: kNeutral300,
                                                ),
                                              ),
                                              dataRowColor:
                                                  const WidgetStatePropertyAll(
                                                      Colors.white),
                                              headingRowColor:
                                                  WidgetStateProperty.all(
                                                      const Color(0xFFF8F3FF)),
                                              showBottomBorder: false,
                                              dividerThickness: 0.0,
                                              headingTextStyle:
                                                  theme.textTheme.titleMedium,
                                              columns: [
                                                DataColumn(
                                                    label: Text(_lang.SL)),
                                                DataColumn(
                                                    label: Text(_lang.image)),
                                                DataColumn(
                                                    label: Text(_lang.name)),
                                                DataColumn(
                                                    label:
                                                        Text(_lang.category)),
                                                // DataColumn(
                                                //     label: Text(
                                                //         _lang.subcategory)),
                                                DataColumn(
                                                    label: Text(_lang.branch)),
                                                DataColumn(
                                                    label: Text("Precio")),
                                                DataColumn(
                                                    label: Text("Estado")),
                                                // DataColumn(
                                                //     label:
                                                //         Text(_lang.available)),
                                                const DataColumn(
                                                    label: Icon(
                                                        FeatherIcons.settings)),
                                              ],
                                              rows: List.generate(
                                                  _itemsPerPage == -1
                                                      ? showAbleDresses.length
                                                      : (_currentPage - 1) *
                                                                      _itemsPerPage +
                                                                  _itemsPerPage <=
                                                              showAbleDresses
                                                                  .length
                                                          ? _itemsPerPage
                                                          : showAbleDresses
                                                                  .length -
                                                              (_currentPage -
                                                                      1) *
                                                                  _itemsPerPage,
                                                  (index) {
                                                final dataIndex =
                                                    (_currentPage - 1) *
                                                            _itemsPerPage +
                                                        index;
                                                final dress =
                                                    showAbleDresses[dataIndex];
                                                return DataRow(cells: [
                                                  // SL Number
                                                  DataCell(Text(
                                                      '${(_currentPage - 1) * _itemsPerPage + index + 1}')),

                                                  // Image (Thumbnail)
                                                  DataCell(
                                                    dress.images.isNotEmpty
                                                        ? GestureDetector(
                                                            onTap: () {
                                                              _showFullScreenImage(context, dress.images.first);
                                                            },
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(4),
                                                              child: Image.network(
                                                                dress.images.first,
                                                                width: 50,
                                                                height: 50,
                                                                fit: BoxFit.cover,
                                                                loadingBuilder: (context, child, loadingProgress) {
                                                                  if (loadingProgress == null) return child;
                                                                  return Container(
                                                                    width: 50,
                                                                    height: 50,
                                                                    color: Colors.grey.shade200,
                                                                    child: Center(
                                                                      child: CircularProgressIndicator(
                                                                        value: loadingProgress.expectedTotalBytes != null
                                                                            ? loadingProgress.cumulativeBytesLoaded /
                                                                                loadingProgress.expectedTotalBytes!
                                                                            : null,
                                                                        strokeWidth: 2,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                errorBuilder: (context, error, stackTrace) {
                                                                  return Container(
                                                                    width: 50,
                                                                    height: 50,
                                                                    color: Colors.grey.shade200,
                                                                    child: const Icon(Icons.error, color: Colors.red),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          )
                                                        : Container(
                                                            width: 50,
                                                            height: 50,
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey.shade200,
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: const Icon(
                                                                Icons.image_not_supported,
                                                                color: Colors.grey),
                                                          ),
                                                  ),

                                                  // Name
                                                  DataCell(Text(dress.name)),

                                                  // Category
                                                  DataCell(
                                                      Text(dress.category)),

                                                  // Subcategory
                                                  // DataCell(
                                                  //     Text(dress.subcategory)),

                                                  // Branch
                                                  DataCell(
                                                      Text(dress.branchId)),

                                                  // Precio
                                                  DataCell(
                                                    Text(
                                                      dress.price > 0
                                                        ? 'RD\$${dress.price.toStringAsFixed(0)}'
                                                        : '-',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        color: dress.price > 0 ? Colors.green[700] : Colors.grey,
                                                      ),
                                                    ),
                                                  ),

                                                  // Estado
                                                  DataCell(
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: dress.state ==
                                                                'Disponible'
                                                            ? Colors.green
                                                                .withValues(alpha: 
                                                                    0.2)
                                                            : dress.state ==
                                                                    'Averiado'
                                                                ? Colors.orange
                                                                    .withValues(alpha: 
                                                                        0.2)
                                                                : dress.state ==
                                                                        'Lavandería'
                                                                    ? Colors
                                                                        .blue
                                                                        .withValues(alpha: 
                                                                            0.2)
                                                                    : Colors.red
                                                                        .withValues(alpha: 
                                                                            0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        dress.state,
                                                        style: TextStyle(
                                                          color: dress.state ==
                                                                  'Disponible'
                                                              ? Colors.green
                                                              : dress.state ==
                                                                      'Averiado'
                                                                  ? Colors
                                                                      .orangeAccent
                                                                  : dress.state ==
                                                                          'Lavandería'
                                                                      ? Colors
                                                                          .blue
                                                                      : Colors
                                                                          .red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Available
                                                  // DataCell(
                                                  //   Switch(
                                                  //     value: dress.available,
                                                  //     activeColor: kMainColor,
                                                  //     onChanged: (value) async {
                                                  //       _toggleDressAvailability(
                                                  //           context,
                                                  //           ref,
                                                  //           dress,
                                                  //           value);
                                                  //     },
                                                  //   ),
                                                  // ),

                                                  // Actions
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.build,
                                                              color: Colors
                                                                  .orange),
                                                          tooltip:
                                                              'Marcar como Averiado',
                                                          onPressed: () async {
                                                            final confirm =
                                                                await _confirmChangeState(
                                                              '¿Marcar vestido como averiado?',
                                                              'Esta acción cambiará el estado del vestido a "Averiado". ¿Deseas continuar?',
                                                            );
                                                            if (confirm) {
                                                              _changeDressAvailability(
                                                                  context,
                                                                  ref,
                                                                  dress,
                                                                  false,
                                                                  "Averiado");
                                                            }
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.camera_alt,
                                                            color: Color(0xFF795548), // Marrón
                                                          ),
                                                          tooltip: 'Marcar como en Sesión',
                                                          onPressed: () async {
                                                            final confirm =
                                                                await _confirmChangeState(
                                                              '¿Marcar vestido como en sesión?',
                                                              'Esta acción cambiará el estado del vestido a "Sesión". ¿Deseas continuar?',
                                                            );
                                                            if (confirm) {
                                                              _changeDressAvailability(
                                                                  context,
                                                                  ref,
                                                                  dress,
                                                                  false,
                                                                  "Sesión");
                                                            }
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons
                                                                  .dry_cleaning_rounded,
                                                              color:
                                                                  Colors.blue),
                                                          tooltip:
                                                              'Marcar como en Lavandería',
                                                          onPressed: () async {
                                                            final confirm =
                                                                await _confirmChangeState(
                                                              '¿Marcar vestido como en lavandería?',
                                                              'Esta acción cambiará el estado del vestido a "Lavandería". ¿Deseas continuar?',
                                                            );
                                                            if (confirm) {
                                                              _changeDressAvailability(
                                                                  context,
                                                                  ref,
                                                                  dress,
                                                                  false,
                                                                  "Lavandería");
                                                            }
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.green),
                                                          tooltip:
                                                              'Marcar como Disponible',
                                                          onPressed: () async {
                                                            final confirm =
                                                                await _confirmChangeState(
                                                              '¿Marcar vestido como disponible?',
                                                              'Esta acción cambiará el estado del vestido a "Disponible". ¿Deseas continuar?',
                                                            );
                                                            if (confirm) {
                                                              _changeDressAvailability(
                                                                  context,
                                                                  ref,
                                                                  dress,
                                                                  true,
                                                                  "Disponible");
                                                            }
                                                          },
                                                        ),
                                                        Theme(
                                                          data: ThemeData(
                                                              highlightColor:
                                                                  dropdownItemColor,
                                                              focusColor:
                                                                  dropdownItemColor,
                                                              hoverColor:
                                                                  dropdownItemColor),
                                                          child: SizedBox(
                                                            width: 20,
                                                            child:
                                                                PopupMenuButton(
                                                              surfaceTintColor:
                                                                  Colors.white,
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              itemBuilder:
                                                                  (BuildContext
                                                                          bc) =>
                                                                      [
                                                                // Edit
                                                                // Edit - Solo visible si tiene permiso
                                                                if (checkUserRoleEditPermissionV2(type: 'register_clothing'))
                                                                PopupMenuItem(
                                                                    onTap: () {
                                                                      _showEditDressDialog(
                                                                          context,
                                                                          ref,
                                                                          dress);
                                                                    },
                                                                    child: Row(
                                                                      children: [
                                                                        const Icon(
                                                                            IconlyLight
                                                                                .edit,
                                                                            size:
                                                                                20.0,
                                                                            color:
                                                                                kNeutral500),
                                                                        const SizedBox(
                                                                            width:
                                                                                4.0),
                                                                        Text(
                                                                          _lang
                                                                              .edit,
                                                                          style: theme
                                                                              .textTheme
                                                                              .bodyLarge
                                                                              ?.copyWith(
                                                                            color:
                                                                                kNeutral500,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    )),

                                                                // View Images
                                                                PopupMenuItem(
                                                                    onTap: () {
                                                                      _showImagesGallery(
                                                                          context,
                                                                          dress);
                                                                    },
                                                                    child: Row(
                                                                      children: [
                                                                        const Icon(
                                                                            IconlyLight
                                                                                .image,
                                                                            size:
                                                                                20.0,
                                                                            color:
                                                                                kNeutral500),
                                                                        const SizedBox(
                                                                            width:
                                                                                4.0),
                                                                        Text(
                                                                          _lang
                                                                              .viewImages,
                                                                          style: theme
                                                                              .textTheme
                                                                              .bodyLarge
                                                                              ?.copyWith(
                                                                            color:
                                                                                kNeutral500,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    )),

                                                                // Delete - Solo visible si tiene permiso
                                                                if (checkUserRoleDeletePermissionV2(type: 'register_clothing'))
                                                                PopupMenuItem(
                                                                  onTap: () {
                                                                    _showDeleteConfirmation(
                                                                        context,
                                                                        ref,
                                                                        dress);
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons.delete_outline,
                                                                        color: kNeutral500,
                                                                        size: 20.0,
                                                                      ),
                                                                      const SizedBox(
                                                                          width:
                                                                              4.0),
                                                                      Text(
                                                                        _lang
                                                                            .delete,
                                                                        style: theme
                                                                            .textTheme
                                                                            .bodyLarge
                                                                            ?.copyWith(color: kNeutral500),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                              onSelected:
                                                                  (value) {
                                                                context.go(
                                                                    '/$value');
                                                              },
                                                              child: Center(
                                                                child:
                                                                    Container(
                                                                        height:
                                                                            18,
                                                                        width:
                                                                            18,
                                                                        alignment:
                                                                            Alignment
                                                                                .centerRight,
                                                                        child:
                                                                            const Icon(
                                                                          Icons
                                                                              .more_vert_sharp,
                                                                          size:
                                                                              18,
                                                                        )),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ]);
                                              })),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Pagination controls
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${_lang.showing} ${((_currentPage - 1) * _itemsPerPage + 1).toString()} to ${((_currentPage - 1) * _itemsPerPage + _itemsPerPage).clamp(0, showAbleDresses.length)} of ${showAbleDresses.length} entries',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          overlayColor:
                                              WidgetStateProperty.all<Color>(
                                                  Colors.grey),
                                          hoverColor: Colors.grey,
                                          onTap: _currentPage > 1
                                              ? () =>
                                                  setState(() => _currentPage--)
                                              : null,
                                          child: Container(
                                            height: 32,
                                            width: 90,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: kBorderColorTextField),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                bottomLeft:
                                                    Radius.circular(4.0),
                                                topLeft: Radius.circular(4.0),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(_lang.previous),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 32,
                                          width: 32,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kBorderColorTextField),
                                            color: kMainColor,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$_currentPage',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 32,
                                          width: 32,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kBorderColorTextField),
                                            color: Colors.transparent,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$pages',
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          hoverColor:
                                              Colors.blue.withValues(alpha: 0.1),
                                          overlayColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.blue),
                                          onTap: _currentPage * _itemsPerPage <
                                                  showAbleDresses.length
                                              ? () =>
                                                  setState(() => _currentPage++)
                                              : null,
                                          child: Container(
                                            height: 32,
                                            width: 90,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: kBorderColorTextField),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                bottomRight:
                                                    Radius.circular(4.0),
                                                topRight: Radius.circular(4.0),
                                              ),
                                            ),
                                            child: const Center(
                                                child: Text('Next')),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          )
                        : EmptyWidget(title: _lang.noDressesFound)
                  ],
                ),
              ),
            );
          }, error: (e, stack) {
            return Center(
              child: Text(e.toString()),
            );
          }, loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          });
        }),
      ),
    );
  }

  Widget _buildImagePicker({List<String>? existingImages}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Existing images
        if (existingImages != null && existingImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: existingImages.length,
              itemBuilder: (context, index) {
                return _buildImageItem(existingImages[index]);
              },
            ),
          ),

        // Selected new images
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return _buildImageItem(_selectedImages[index]);
              },
            ),
          ),

        ElevatedButton(
          onPressed: _pickImages,
          child: Text('Add Images'),
        ),
      ],
    );
  }

  Widget _buildImageItem(dynamic image) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(image),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  if (image is String) {
                    _existingImageUrls.remove(image);
                  } else {
                    _selectedImages.remove(image);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(dynamic image) {
    try {
      if (image is String) {
        // Network image - para URLs de Firebase Storage
        return CachedNetworkImage(
          imageUrl: image,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildErrorWidget(),
        );
      } else if (image is File) {
        // File image - para archivos locales en mobile/desktop
        if (kIsWeb) {
          // En web, File no funciona directamente, necesitamos convertirlo
          return FutureBuilder<Uint8List>(
            future: image.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildErrorWidget(),
                );
              }
              return _buildPlaceholder();
            },
          );
        } else {
          return Image.file(
            image,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          );
        }
      } else if (image is XFile) {
        // XFile image - para imágenes seleccionadas con image_picker
        return FutureBuilder<Uint8List>(
          future: image.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildErrorWidget(),
              );
            }
            return _buildPlaceholder();
          },
        );
      } else if (image is Uint8List) {
        // Uint8List image - para datos de imagen en memoria
        return Image.memory(
          image,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      }
    } catch (e) {
      debugPrint('Error displaying image: $e');
    }
    return _buildErrorWidget();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 30),
          const SizedBox(height: 4),
          Text(
            'Error',
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showImagesGallery(BuildContext context, DressModel dress) {
    if (dress.images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.S.of(context).noImagesAvailable)));
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${lang.S.of(context).imagesFor}: ${dress.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: dress.images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _showFullScreenImage(context, dress.images[index]);
                        },
                        child: CachedNetworkImage(
                          imageUrl: dress.images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.red),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Clear form fields for adding or editing dresses
  void _clearForm() {
    setState(() {
      _nameController.text = '';
      _selectedCategory = null;
      _selectedBranch = null;
      _subcategoryController.text = '';
      _priceController.text = '';  // IMPORTANTE: Limpiar el precio también
      _isAvailable = true;
      _selectedImages.clear();
      _existingImageUrls.clear();
    });
  }

// Show confirmation dialog before deleting a dress
  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, DressModel dress) {
    final _lang = lang.S.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_lang.confirmDelete),
          content: Text('${_lang.areYouSureDeleteDress} "${dress.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_lang.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                EasyLoading.show(status: _lang.deleting);

                final result =
                    await ref.read(deleteDressProvider(dress.id).future);

                EasyLoading.dismiss();
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_lang.dress} ${_lang.deleted}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_lang.errorDeletingDress}')),
                  );
                }
              },
              child:
                  Text(_lang.delete, style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

// Toggle dress availability (enable/disable)
  void _toggleDressAvailability(
      BuildContext context, WidgetRef ref, DressModel dress, bool value) async {
    final _lang = lang.S.of(context);

    EasyLoading.show(status: _lang.updating);

    final result = await ref.read(toggleDressAvailabilityProvider(
        {'dressId': dress.id, 'available': value}).future);

    EasyLoading.dismiss();

    if (result) {
      // Refresca los providers para que la UI y el calendario se actualicen automáticamente
      ref.invalidate(dressesProvider);
      ref.invalidate(dressesByStatusProvider('Todos'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${_lang.dressAvailability} ${value ? _lang.enabled : _lang.disabled}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_lang.errorUpdatingAvailability}')),
      );
    }
  }

//Change state dress
  void _changeDressAvailability(BuildContext context, WidgetRef ref,
      DressModel dress, bool _unusedValue, String state) async {
    final _lang = lang.S.of(context);

    // Lógica automática de disponibilidad
    bool value;
    if (state == 'Disponible') {
      value = true;
    } else {
      value = false;
    }

    EasyLoading.show(status: _lang.updating);

    final result = await ref.read(changeStateProvider(
        {'dressId': dress.id, 'available': value, 'state': state}).future);

    EasyLoading.dismiss();

    if (result) {
      // Refresca los providers para que la UI y el calendario se actualicen automáticamente
      ref.invalidate(dressesProvider);
      ref.invalidate(dressesByStatusProvider('Todos'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado de vestimenta cambiado a: $state')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error al actualizar el estado')));
    }
  }

  /// Convierte el nombre de sucursal a ID técnico para compatibilidad
  /// con vestidos antiguos que tienen el nombre en lugar del ID
  String _convertBranchNameToId(String branchIdOrName) {
    // Si ya es un ID técnico válido (stg, sde, sdo, rom), devolverlo tal cual
    final validIds = ['stg', 'sde', 'sdo', 'rom'];
    if (validIds.contains(branchIdOrName.toLowerCase())) {
      return branchIdOrName.toLowerCase();
    }

    // Mapeo de nombres comunes a IDs técnicos
    final nameToId = {
      'victor guzmán santiago': 'stg',
      'victor guzman santiago': 'stg',
      'santiago': 'stg',
      'victor guzmán santo domingo este': 'sde',
      'victor guzman santo domingo este': 'sde',
      'santo domingo este': 'sde',
      'victor guzmán santo domingo oeste': 'sdo',
      'victor guzman santo domingo oeste': 'sdo',
      'santo domingo oeste': 'sdo',
      'romana': 'rom',
      'la romana': 'rom',
    };

    final normalized = branchIdOrName.toLowerCase().trim();
    return nameToId[normalized] ?? branchIdOrName;
  }

// Show dialog to edit an existing dress
  void _showEditDressDialog(
      BuildContext context, WidgetRef ref, DressModel dress) {
    // Set form values with existing dress data
    _nameController.text = dress.name;
    _selectedCategory = dress.category;
    // Compatibilidad: convertir nombre de sucursal a ID si es necesario
    // Los vestidos antiguos pueden tener branch_id con el nombre (ej: "Victor Guzmán Santiago")
    // pero ahora necesitamos el ID técnico (ej: "stg")
    _selectedBranch = _convertBranchNameToId(dress.branchId);
    _subcategoryController.text = dress.subcategory;
    _isAvailable = dress.available;
    _priceController.text = dress.price.toStringAsFixed(2);
    _existingImageUrls.addAll(dress.images);
    _selectedImages.clear();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState1) {
            return Dialog(
              surfaceTintColor: kWhite,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              child: Container(
                width: 600,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${lang.S.of(context).edit} ${dress.name}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          IconButton(
                              onPressed: () {
                                _clearForm();
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                FeatherIcons.x,
                                color: kTitleColor,
                                size: 21.0,
                              )),
                        ],
                      ),
                    ),
                    const Divider(
                      thickness: 1.0,
                      height: 1.0,
                      color: kNeutral300,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Images section
                              _buildImagePicker(
                                  existingImages: _existingImageUrls),
                              const SizedBox(height: 16),

                              // Name field
                              TextFormField(
                                controller: _nameController,
                                decoration: kInputDecoration.copyWith(
                                  labelText: lang.S.of(context).name,
                                  hintText: lang.S.of(context).enterDressName,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return lang.S.of(context).nameRequired;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Category dropdown
                              Consumer(
                                builder: (_, ref, __) {
                                  AsyncValue<List<CategoryModel>> categories =
                                      ref.watch(categoryProvider);
                                  return categories.when(
                                    data: (categoryList) {
                                      return DropdownButtonFormField<String>(
                                        value: _selectedCategory,
                                        decoration: kInputDecoration.copyWith(
                                          labelText:
                                              lang.S.of(context).category,
                                          hintText:
                                              lang.S.of(context).selectCategory,
                                        ),
                                        items: categoryList.map((category) {
                                          return DropdownMenuItem<String>(
                                            value: category.categoryName,
                                            child: Text(category.categoryName),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState1(() {
                                            _selectedCategory = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return lang.S
                                                .of(context)
                                                .categoryRequired;
                                          }
                                          return null;
                                        },
                                      );
                                    },
                                    loading: () =>
                                        const CircularProgressIndicator(),
                                    error: (error, stack) =>
                                        Text('Error: $error'),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Subcategory field
                              TextFormField(
                                controller: _subcategoryController,
                                decoration: kInputDecoration.copyWith(
                                  labelText: lang.S.of(context).subcategory,
                                  hintText: lang.S.of(context).enterSubcategory,
                                ),
                              ),
                              const SizedBox(height: 16),

                              Consumer(
                                builder: (_, ref, __) {
                                  AsyncValue<List<WareHouseModel>> warehouses =
                                      ref.watch(warehouseProvider);
                                  return warehouses.when(
                                    data: (warehouseList) {
                                      return DropdownButtonFormField<String>(
                                        value: _selectedBranch,
                                        decoration: kInputDecoration.copyWith(
                                          labelText: lang.S.of(context).branch,
                                          hintText:
                                              lang.S.of(context).selectBranch,
                                        ),
                                        items: warehouseList.map((warehouse) {
                                          return DropdownMenuItem<String>(
                                            // CRÍTICO: Usar warehouse.id (ej: "stg") como valor
                                            // en lugar de warehouseName para el sistema multi-tenant
                                            value: warehouse.id,
                                            child:
                                                Text(warehouse.warehouseName),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState1(() {
                                            _selectedBranch = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return lang.S
                                                .of(context)
                                                .branchRequired;
                                          }
                                          return null;
                                        },
                                      );
                                    },
                                    loading: () =>
                                        const CircularProgressIndicator(),
                                    error: (error, stack) =>
                                        Text('Error: $error'),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Price
                              TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  labelText: lang.S.of(context).price,
                                  border: OutlineInputBorder(),
                                  prefixText: '\$',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return lang.S.of(context).priceRequired;
                                  }
                                  if (double.tryParse(value) == null) {
                                    return lang.S.of(context).invalidNumber;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Available switch
                              SwitchListTile(
                                title: Text(lang.S.of(context).available),
                                value: _isAvailable,
                                onChanged: (value) {
                                  setState1(() {
                                    _isAvailable = value;
                                  });
                                },
                                activeColor: kMainColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(
                      thickness: 1.0,
                      height: 1.0,
                      color: kNeutral300,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              _clearForm();
                              Navigator.pop(context);
                            },
                            child: Text(lang.S.of(context).cancel),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // Debug: Log precio antes de crear el modelo
                                debugPrint('🔍 [EditDress] Precio en TextField: "${_priceController.text}"');
                                final parsedPrice = double.tryParse(_priceController.text) ?? 0.0;
                                debugPrint('🔍 [EditDress] Precio parseado: $parsedPrice');

                                // Update the dress
                                final updatedDress = DressModel(
                                  id: dress.id,
                                  name: _nameController.text,
                                  category: _selectedCategory!,
                                  subcategory: _subcategoryController.text,
                                  branchId: _selectedBranch!,
                                  available: _isAvailable,
                                  createdAt: dress.createdAt,
                                  updatedAt: DateTime.now(),
                                  state: 'Disponible',
                                  images: _existingImageUrls,
                                  price: parsedPrice,
                                );

                                debugPrint('🔍 [EditDress] DressModel creado - price: ${updatedDress.price}');

                                EasyLoading.show(
                                    status: lang.S.of(context).updating);

                                final result = await ref.read(updateDressProvider({
                                  'dress': updatedDress,
                                  'imageFiles': _selectedImages,
                                }).future);

                                EasyLoading.dismiss();

                                if (result) {
                                  // Invalidar el provider y ESPERAR a que recargue datos frescos
                                  ref.invalidate(dressesProvider);
                                  await ref.read(dressesProvider.future);

                                  _clearForm();

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Error al actualizar vestido')),
                                    );
                                  }
                                }
                              }
                            },
                            child: Text(lang.S.of(context).update),
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

// Complete the implementation of _showAddDressDialog
  void _showAddDressDialog(BuildContext context, WidgetRef ref) {
    // Clear the form and image selections
    _clearForm();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState1) {
            return Dialog(
              surfaceTintColor: kWhite,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              child: Container(
                width: 600,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              lang.S.of(context).addDress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          IconButton(
                              onPressed: () {
                                _clearForm();
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                FeatherIcons.x,
                                color: kTitleColor,
                                size: 21.0,
                              )),
                        ],
                      ),
                    ),
                    const Divider(
                      thickness: 1.0,
                      height: 1.0,
                      color: kNeutral300,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Images
                              _buildImagePicker(),
                              const SizedBox(height: 16),

                              // Name field
                              TextFormField(
                                controller: _nameController,
                                decoration: kInputDecoration.copyWith(
                                  labelText: lang.S.of(context).name,
                                  hintText: lang.S.of(context).enterDressName,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return lang.S.of(context).nameRequired;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Category dropdown
                              Consumer(
                                builder: (_, ref, __) {
                                  AsyncValue<List<CategoryModel>> categories =
                                      ref.watch(categoryProvider);
                                  return categories.when(
                                    data: (categoryList) {
                                      return DropdownButtonFormField<String>(
                                        value: _selectedCategory,
                                        decoration: kInputDecoration.copyWith(
                                          labelText:
                                              lang.S.of(context).category,
                                          hintText:
                                              lang.S.of(context).selectCategory,
                                        ),
                                        items: categoryList.map((category) {
                                          return DropdownMenuItem<String>(
                                            value: category.categoryName,
                                            child: Text(category.categoryName),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState1(() {
                                            _selectedCategory = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return lang.S
                                                .of(context)
                                                .categoryRequired;
                                          }
                                          return null;
                                        },
                                      );
                                    },
                                    loading: () =>
                                        const CircularProgressIndicator(),
                                    error: (error, stack) =>
                                        Text('Error: $error'),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Subcategory field
                              TextFormField(
                                controller: _subcategoryController,
                                decoration: kInputDecoration.copyWith(
                                  labelText: lang.S.of(context).subcategory,
                                  hintText: lang.S.of(context).enterSubcategory,
                                ),
                              ),
                              const SizedBox(height: 16),

                              Consumer(
                                builder: (_, ref, __) {
                                  AsyncValue<List<WareHouseModel>> warehouses =
                                      ref.watch(warehouseProvider);
                                  return warehouses.when(
                                    data: (warehouseList) {
                                      return DropdownButtonFormField<String>(
                                        value: _selectedBranch,
                                        decoration: kInputDecoration.copyWith(
                                          labelText: lang.S.of(context).branch,
                                          hintText:
                                              lang.S.of(context).selectBranch,
                                        ),
                                        items: warehouseList.map((warehouse) {
                                          return DropdownMenuItem<String>(
                                            // CRÍTICO: Usar warehouse.id (ej: "stg") como valor
                                            // en lugar de warehouseName para el sistema multi-tenant
                                            value: warehouse.id,
                                            child:
                                                Text(warehouse.warehouseName),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState1(() {
                                            _selectedBranch = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return lang.S
                                                .of(context)
                                                .branchRequired;
                                          }
                                          return null;
                                        },
                                      );
                                    },
                                    loading: () =>
                                        const CircularProgressIndicator(),
                                    error: (error, stack) =>
                                        Text('Error: $error'),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Mount field
                              TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  labelText: lang.S.of(context).price,
                                  border: OutlineInputBorder(),
                                  prefixText: '\$',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return lang.S.of(context).priceRequired;
                                  }
                                  if (double.tryParse(value) == null) {
                                    return lang.S.of(context).invalidNumber;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Available switch
                              SwitchListTile(
                                title: Text(lang.S.of(context).available),
                                value: _isAvailable,
                                onChanged: (value) {
                                  setState1(() {
                                    _isAvailable = value;
                                  });
                                },
                                activeColor: kMainColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(
                      thickness: 1.0,
                      height: 1.0,
                      color: kNeutral300,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              _clearForm();
                              Navigator.pop(context);
                            },
                            child: Text(lang.S.of(context).cancel),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                if (_selectedImages.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(lang.S
                                            .of(context)
                                            .pleaseSelectAtLeastOneImage)),
                                  );
                                  return;
                                }

                                final dressId =
                                    'dress_${DateTime.now().millisecondsSinceEpoch}';
                                final newDress = DressModel(
                                  id: dressId,
                                  name: _nameController.text,
                                  category: _selectedCategory!,
                                  subcategory: _subcategoryController.text,
                                  branchId: _selectedBranch!,
                                  available: _isAvailable,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  state: 'Disponible',
                                  images: [],
                                  price: double.tryParse(
                                          _priceController.text) ??
                                      0.0, // Use parsed price or default to 0.0
                                );

                                Navigator.pop(context);
                                EasyLoading.show(
                                    status: lang.S.of(context).adding);

                                final result = await ref.read(addDressProvider({
                                  'dress': newDress,
                                  'imageFiles':
                                      _selectedImages, // This is now List<dynamic>
                                }).future);

                                EasyLoading.dismiss();
                                if (result) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            lang.S.of(context).dressAdded)),
                                  );
                                  _clearForm();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(lang.S
                                            .of(context)
                                            .errorAddingDress)),
                                  );
                                }
                              }
                            },
                            child: Text(lang.S.of(context).add),
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

  Future<bool> _confirmChangeState(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(lang.S.of(context).cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
