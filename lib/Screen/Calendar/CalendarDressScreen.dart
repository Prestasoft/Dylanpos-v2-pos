import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/dress_provider.dart';
import 'package:salespro_admin/Provider/product_provider.dart';
import 'package:salespro_admin/Screen/WareHouse/warehouse_model.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/export_button.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/category_model.dart';
import 'package:salespro_admin/model/dress_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:salespro_admin/model/reservation_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:salespro_admin/Provider/reservation_provider.dart';

import '../../Provider/dress_with_reservations.dart';
import '../../model/FullReservation.dart';
import '../../model/args_dress.dart';

class CalendarDressScreen extends StatefulWidget {
  const CalendarDressScreen({super.key});

  @override
  State<CalendarDressScreen> createState() => _CalendarDressScreen();

  // @override
  // State<CalendarDressScreen> createState() => _CalendarDressScreenState();
}

class _CalendarDressScreen extends State<CalendarDressScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late Map<DateTime, List<ReservationModel>> _reservationsByDay;
  String? selectedMonth;
  String? selectedYear;

  int selectedItem = 10;
  final int currentYear = DateTime.now().year;
  late final List<String> yearList;

  TextEditingController _nameController = TextEditingController();
  String? _selectedCategory;
  WareHouseModel? selectedWareHouse;
  String? _selectedBranch;
  TextEditingController _subcategoryController = TextEditingController();
  ScrollController mainScroll = ScrollController();
  //String searchItem = '';
  TextEditingController searchCtr = TextEditingController();
  bool _isAvailable = true;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<DressModel> showAbleDresses = [];
  // For image handling
  final List<dynamic> _selectedImages =
      []; // Can hold File (mobile) or XFile/Uint8List (web)
  final List<String> _existingImageUrls = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _reservationsByDay = {};
    final int currentMonthIndex = DateTime.now().month - 1;
    selectedMonth = monthList[currentMonthIndex];
    selectedYear = DateTime.now().year.toString();
    yearList = List.generate(6, (index) => (currentYear + index).toString());
  }

  final _horizontalScroll = ScrollController();
  int _itemsPerPage = 10;
  int _currentPage = 1;
  String itemStatus = "Todos";

  // Campo para notas
  // TextEditingController _notasController = TextEditingController();

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
      print('Error picking images: $e');
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
          AsyncValue<List<DressModel>> dressesAsync =
              ref.watch(dressesByStatusProvider(itemStatus));
          return dressesAsync.when(data: (list) {
            List<DressModel> showAbleDresses = [];
            for (var element in list) {
              if (element.name
                  .removeAllWhiteSpace()
                  .toLowerCase()
                  .contains(searchCtr.text.toLowerCase())) {
                showAbleDresses.add(element);
              } else if (searchCtr.text == '') {
                showAbleDresses.add(element);
              }
            }
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
                              //_lang.dresses,
                              "Calendario de Reserva de Vestidos",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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

                    // Search and pagination controls
                    ResponsiveGridRow(
                      rowSegments: 100,
                      children: [
                        ResponsiveGridCol(
                          xs: screenWidth < 360
                              ? 50
                              : screenWidth > 430
                                  ? 33
                                  : 40,
                          md: screenWidth < 768
                              ? 24
                              : screenWidth < 950
                                  ? 20
                                  : 15,
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
                                  )),
                                  DropdownButton<int>(
                                    isDense: true,
                                    padding: EdgeInsets.zero,
                                    underline: const SizedBox(),
                                    value: _itemsPerPage,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.black,
                                    ),
                                    items: [
                                      10,
                                      20,
                                      50,
                                      100,
                                      -1
                                    ].map<DropdownMenuItem<int>>((int value) {
                                      return DropdownMenuItem<int>(
                                        value: value,
                                        child: Text(
                                          value == -1
                                              ? "All"
                                              : value.toString(),
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
                            md: 60,
                            lg: 35,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: TextFormField(
                                controller: searchCtr,
                                //showCursor: true,
                                cursorColor: kTitleColor,
                                onChanged: (value) {
                                  Debouncer(milliseconds: 900).run(
                                    () => setState(
                                      () {
                                        searchCtr.text = value;
                                      },
                                    ),
                                  );
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
                            )),
                        ResponsiveGridCol(
                          xs: screenWidth < 360
                              ? 60
                              : screenWidth > 430
                                  ? 43
                                  : 50,
                          md: screenWidth < 768
                              ? 34
                              : screenWidth < 950
                                  ? 30
                                  : 25,
                          lg: screenWidth < 1700 ? 22 : 18,
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
                                    'Estado - ',
                                    style: theme.textTheme.bodyLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                  DropdownButton<String>(
                                    isDense: true,
                                    padding: EdgeInsets.zero,
                                    underline: const SizedBox(),
                                    value: itemStatus,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.black,
                                    ),
                                    items: [
                                      "Todos",
                                      "Disponibles",
                                      "Reservados",
                                      "Lavanderia",
                                    ].map<DropdownMenuItem<String>>(
                                        (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value.toString(),
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        itemStatus = newValue ?? "";
                                      });
                                    },
                                  ),
                                ],
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
                                                DataColumn(
                                                    label: Text(_lang.branch)),
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
                                                        ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                            child:
                                                                Image.network(
                                                              dress
                                                                  .images.first,
                                                              width: 50,
                                                              height: 50,
                                                              fit: BoxFit.cover,
                                                              loadingBuilder:
                                                                  (context,
                                                                      child,
                                                                      loadingProgress) {
                                                                if (loadingProgress ==
                                                                    null)
                                                                  return child;
                                                                return Container(
                                                                  width: 50,
                                                                  height: 50,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  child: Center(
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      value: loadingProgress.expectedTotalBytes !=
                                                                              null
                                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                                              loadingProgress.expectedTotalBytes!
                                                                          : null,
                                                                      strokeWidth:
                                                                          2,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                print(
                                                                    'Error con Image.network: $error');
                                                                return Container(
                                                                  width: 50,
                                                                  height: 50,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  child: const Icon(
                                                                      Icons
                                                                          .error,
                                                                      color: Colors
                                                                          .red),
                                                                );
                                                              },
                                                            ),
                                                          )
                                                        : Container(
                                                            width: 50,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.grey
                                                                  .shade200,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                            ),
                                                            child: const Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                color: Colors
                                                                    .grey),
                                                          ),
                                                  ),

                                                  // Name
                                                  DataCell(Text(dress.name)),

                                                  // Category
                                                  DataCell(
                                                      Text(dress.category)),

                                                  // Branch
                                                  DataCell(
                                                      Text(dress.branchId)),

                                                  // Actions
                                                  DataCell(
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
                                                        child: PopupMenuButton(
                                                          surfaceTintColor:
                                                              Colors.white,
                                                          padding:
                                                              EdgeInsets.zero,
                                                          itemBuilder:
                                                              (BuildContext
                                                                      bc) =>
                                                                  [
                                                            // Reserve
                                                            PopupMenuItem(
                                                                onTap: () {
                                                                  _showCalendarDressDialog(
                                                                      context,
                                                                      ref,
                                                                      dress);
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    const Icon(
                                                                        IconlyLight
                                                                            .calendar,
                                                                        size:
                                                                            20.0,
                                                                        color:
                                                                            kNeutral500),
                                                                    const SizedBox(
                                                                        width:
                                                                            4.0),
                                                                    Text(
                                                                      "Ver Reservas",
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
                                                          ],
                                                          onSelected: (value) {
                                                            context
                                                                .go('/$value');
                                                          },
                                                          child: Center(
                                                            child: Container(
                                                                height: 18,
                                                                width: 18,
                                                                alignment: Alignment
                                                                    .centerRight,
                                                                child:
                                                                    const Icon(
                                                                  Icons
                                                                      .more_vert_sharp,
                                                                  size: 18,
                                                                )),
                                                          ),
                                                        ),
                                                      ),
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
                                              Colors.blue.withOpacity(0.1),
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
      _isAvailable = true;
      _selectedImages.clear();
      _existingImageUrls.clear();
//      _notasController.clear(); // Limpiar notas
    });
  }

// Show Dialog Calendar Reservations
  // Future<void> _showCalendarDressDialog(
  //     BuildContext context, WidgetRef ref, DressModel dress) async {
  //   // Set form values with existing dress data
  //   _nameController.text = dress.name;
  //   _selectedCategory = dress.category;
  //   _selectedBranch = dress.branchId;
  //   _subcategoryController.text = dress.subcategory;
  //   _isAvailable = dress.available;
  //   _existingImageUrls.addAll(dress.images);
  //   _selectedImages.clear();

  //   selectedMonth ??= monthList[DateTime.now().month - 1];
  //   selectedYear ??= DateTime.now().year.toString();

  //   final reservations =
  //       await ref.read(fullReservationsByDressProvider2(dress.id).future);

  //   // 👉 Asignar valores por defecto (simulando selección manual)
  //   selectedMonth = monthList[DateTime.now().month - 1];
  //   selectedYear = DateTime.now().year.toString();

  //   showDialog(
  //     barrierDismissible: true,
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (context, setState1) {
  //           final reservationsAsyncValue =
  //               ref.watch(fullReservationsByDressProvider2(dress.id));

  //           return Dialog(
  //             surfaceTintColor: kWhite,
  //             shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(10.0)),
  //             child: Container(
  //               width: 800,
  //               constraints: BoxConstraints(
  //                 maxHeight: MediaQuery.of(context).size.height * 0.85,
  //               ),
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Padding(
  //                     padding: const EdgeInsets.all(12.0),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Flexible(
  //                           child: Text(
  //                             'Reservas para vestido: ${dress.name}',
  //                             maxLines: 2,
  //                             overflow: TextOverflow.ellipsis,
  //                             style: Theme.of(context)
  //                                 .textTheme
  //                                 .titleLarge
  //                                 ?.copyWith(
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //                           ),
  //                         ),
  //                         IconButton(
  //                             onPressed: () {
  //                               _clearForm();
  //                               Navigator.pop(context);
  //                             },
  //                             icon: const Icon(
  //                               FeatherIcons.x,
  //                               color: kTitleColor,
  //                               size: 21.0,
  //                             )),
  //                       ],
  //                     ),
  //                   ),
  //                   Padding(
  //                     padding:
  //                         const EdgeInsets.only(left: 100, right: 100, top: 10),
  //                     //child: _buildCalendar(reservationsAsyncValue),
  //                   ),
  //                   const Divider(
  //                     thickness: 1.0,
  //                     height: 1.0,
  //                     color: kNeutral300,
  //                   ),
  //                   Expanded(
  //                     child: SingleChildScrollView(
  //                       padding: const EdgeInsets.all(12.0),
  //                       child: Form(
  //                         key: _formKey,
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             // Images section
  //                             // _buildImagePicker(
  //                             //     existingImages: _existingImageUrls),
  //                             // const SizedBox(height: 16),

  //                             Padding(
  //                               padding: const EdgeInsets.all(10),
  //                               child: Row(
  //                                 mainAxisAlignment:
  //                                     MainAxisAlignment.spaceBetween,
  //                                 children: [
  //                                   // Mes

  //                                   Flexible(
  //                                     flex: 1,
  //                                     child: DropdownButtonFormField<String>(
  //                                       validator: (value) {
  //                                         if (value == null) {
  //                                           return 'Mes requerido';
  //                                         }
  //                                         return null;
  //                                       },
  //                                       decoration: const InputDecoration(
  //                                         labelText: 'Seleccionar Mes',
  //                                       ),
  //                                       value: selectedMonth,
  //                                       hint: const Text('Seleccionar Mes'),
  //                                       items: monthList.map((month) {
  //                                         return DropdownMenuItem(
  //                                           value: month,
  //                                           child: Text(month),
  //                                         );
  //                                       }).toList(),
  //                                       onChanged: (value) {
  //                                         setState1(() {
  //                                           selectedMonth = value!;
  //                                         });
  //                                       },
  //                                       icon: const Icon(Icons.arrow_drop_down,
  //                                           color: Colors.grey),
  //                                       dropdownColor: Colors.white,
  //                                     ),
  //                                   ),

  //                                   const SizedBox(
  //                                       width: 16), // Espacio entre los combos

  //                                   // Año
  //                                   Flexible(
  //                                     flex: 1,
  //                                     child: DropdownButtonFormField<String>(
  //                                       value: selectedYear,
  //                                       decoration: const InputDecoration(
  //                                         labelText: 'Seleccionar Año',
  //                                       ),
  //                                       validator: (value) {
  //                                         if (value == null) {
  //                                           return 'Año requerido';
  //                                         }
  //                                         return null;
  //                                       },
  //                                       items: yearList.map((year) {
  //                                         return DropdownMenuItem<String>(
  //                                           value: year,
  //                                           child: Text(year),
  //                                         );
  //                                       }).toList(),
  //                                       onChanged: (value) {
  //                                         setState1(() {
  //                                           selectedYear = value!;
  //                                         });
  //                                       },
  //                                       icon: const Icon(Icons.arrow_drop_down,
  //                                           color: Colors.grey),
  //                                       dropdownColor: Colors.white,
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),

  //                             const SizedBox(height: 16),

  //                             // Datos de Reservas
  //                             reservationsAsyncValue.when(
  //                               data: (data) {
  //                                 // Convertir mes y año seleccionados a DateTime
  //                                 final selectedMonthIndex =
  //                                     monthList.indexOf(selectedMonth!) + 1;
  //                                 final selectedYearInt =
  //                                     int.parse(selectedYear!);

  //                                 final filteredReservations =
  //                                     data.where((data) {
  //                                   String formattedDate = '';
  //                                   try {
  //                                     final date = DateFormat('yyyy-MM-dd')
  //                                         .parse(data.reservation[
  //                                                 'reservation_date'] ??
  //                                             '');
  //                                     formattedDate =
  //                                         DateFormat.yMMMMd('es').format(date);
  //                                   } catch (e) {
  //                                     formattedDate = data.reservation[
  //                                             'reservation_date'] ??
  //                                         '';
  //                                   }

  //                                   // Convertir la fecha a un objeto DateTime
  //                                   final date = DateTime.parse(
  //                                       data.reservation['reservation_date']);

  //                                   return date.month == selectedMonthIndex &&
  //                                       date.year == selectedYearInt;
  //                                 }).toList();

  //                                 if (filteredReservations.isEmpty) {
  //                                   return const Padding(
  //                                     padding: EdgeInsets.only(top: 16),
  //                                     child: Text(
  //                                         "No reservations for this month."),
  //                                   );
  //                                 }

  //                                 return ListView.builder(
  //                                   shrinkWrap: true,
  //                                   physics:
  //                                       const NeverScrollableScrollPhysics(),
  //                                   itemCount: filteredReservations.length,
  //                                   itemBuilder: (context, index) {
  //                                     final entry = filteredReservations[index];

  //                                     return Card(
  //                                       margin: const EdgeInsets.symmetric(
  //                                           vertical: 8),
  //                                       child: Padding(
  //                                         padding: const EdgeInsets.all(12.0),
  //                                         child: Column(
  //                                           crossAxisAlignment:
  //                                               CrossAxisAlignment.start,
  //                                           children: [
  //                                             const Row(
  //                                               children: [
  //                                                 Icon(Icons.calendar_today,
  //                                                     size: 20),
  //                                                 SizedBox(width: 8),
  //                                                 Text(
  //                                                   'Detalles de la Reserva',
  //                                                   style: TextStyle(
  //                                                     fontWeight:
  //                                                         FontWeight.bold,
  //                                                     fontSize: 16,
  //                                                   ),
  //                                                 ),
  //                                               ],
  //                                             ),
  //                                             const SizedBox(height: 12),

  //                                             /// Estructura personalizada
  //                                             Row(
  //                                               crossAxisAlignment:
  //                                                   CrossAxisAlignment.start,
  //                                               children: [
  //                                                 // Columna izquierda (solo la fecha)
  //                                                 Container(
  //                                                   width: 80,
  //                                                   alignment: Alignment.center,
  //                                                   padding:
  //                                                       const EdgeInsets.all(8),
  //                                                   decoration: BoxDecoration(
  //                                                     color: Colors
  //                                                         .deepPurple.shade50,
  //                                                     borderRadius:
  //                                                         BorderRadius.circular(
  //                                                             8),
  //                                                   ),
  //                                                   child: Text(
  //                                                     // Solo el día en formato dos dígitos
  //                                                     (() {
  //                                                       final dateStr = entry
  //                                                                   .reservation[
  //                                                               'reservation_date'] ??
  //                                                           '';
  //                                                       try {
  //                                                         final date =
  //                                                             DateTime.parse(
  //                                                                 dateStr);
  //                                                         return DateFormat(
  //                                                                 'dd')
  //                                                             .format(
  //                                                                 date); // Solo día
  //                                                       } catch (_) {
  //                                                         return 'N/A';
  //                                                       }
  //                                                     })(),
  //                                                     style: const TextStyle(
  //                                                       fontSize: 20,
  //                                                       fontWeight:
  //                                                           FontWeight.bold,
  //                                                     ),
  //                                                   ),
  //                                                 ),

  //                                                 const SizedBox(width: 16),

  //                                                 // Columnas derechas con detalles
  //                                                 Expanded(
  //                                                   child: Column(
  //                                                     crossAxisAlignment:
  //                                                         CrossAxisAlignment
  //                                                             .start,
  //                                                     children: [
  //                                                       _buildDetailRow(
  //                                                         'Servicio:',
  //                                                         entry.service?[
  //                                                                 'name'] ??
  //                                                             'N/A',
  //                                                       ),
  //                                                       _buildDetailRow(
  //                                                         'Cliente:',
  //                                                         entry.client
  //                                                                 ?.customerName ??
  //                                                             'N/A',
  //                                                       ),
  //                                                       _buildDetailRow(
  //                                                         'Telefono Cliente:',
  //                                                         entry.client
  //                                                                 ?.phoneNumber ??
  //                                                             'N/A',
  //                                                       ),
  //                                                       _buildDetailRow(
  //                                                         'Fecha:',
  //                                                         entry.reservation[
  //                                                                     'reservation_date'] +
  //                                                                 ' - ' +
  //                                                                 entry.reservation[
  //                                                                     'reservation_time'] ??
  //                                                             'N/A',
  //                                                       ),
  //                                                       _buildDetailRow(
  //                                                         'Estado:',
  //                                                         entry.reservation[
  //                                                                 'status'] ??
  //                                                             'Pendiente',
  //                                                       ),
  //                                                     ],
  //                                                   ),
  //                                                 ),
  //                                               ],
  //                                             ),
  //                                           ],
  //                                         ),
  //                                       ),
  //                                     );
  //                                   },
  //                                 );
  //                               },
  //                               loading: () => const Center(
  //                                   child: CircularProgressIndicator()),
  //                               error: (e, _) => Padding(
  //                                 padding: const EdgeInsets.only(top: 16),
  //                                 child: Text('Error loading reservations: $e'),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   const Divider(
  //                     thickness: 1.0,
  //                     height: 1.0,
  //                     color: kNeutral300,
  //                   ),
  //                   Padding(
  //                     padding: const EdgeInsets.all(12.0),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.end,
  //                       children: [
  //                         OutlinedButton(
  //                           onPressed: () {
  //                             _clearForm();
  //                             Navigator.pop(context);
  //                           },
  //                           child: Text(lang.S.of(context).cancel),
  //                         ),
  //                         const SizedBox(width: 10),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Future<void> _showCalendarDressDialog(
      BuildContext context, WidgetRef ref, DressModel dress) async {
    // Set form values with existing dress data
    _nameController.text = dress.name;
    _selectedCategory = dress.category;
    _selectedBranch = dress.branchId;
    _subcategoryController.text = dress.subcategory;
    _isAvailable = dress.available;
    _existingImageUrls.addAll(dress.images);
    _selectedImages.clear();

    // Solo inicializar el año, quitar el mes
    selectedYear ??= DateTime.now().year.toString();

    final reservations =
        await ref.read(fullReservationsByDressProvider2(dress.id).future);

    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState1) {
            final reservationsAsyncValue =
                ref.watch(fullReservationsByDressProvider2(dress.id));

            return Dialog(
              surfaceTintColor: kWhite,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              child: Container(
                width: 800,
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
                              'Reservas para vestido: ${dress.name}',
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
                              // Solo selector de año
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    // Solo el dropdown del año
                                    Flexible(
                                      flex: 1,
                                      child: DropdownButtonFormField<String>(
                                        value: selectedYear,
                                        decoration: const InputDecoration(
                                          labelText: 'Seleccionar Año',
                                          prefixIcon:
                                              Icon(Icons.calendar_today),
                                        ),
                                        validator: (value) {
                                          if (value == null) {
                                            return 'Año requerido';
                                          }
                                          return null;
                                        },
                                        items: yearList.map((year) {
                                          return DropdownMenuItem<String>(
                                            value: year,
                                            child: Text(year),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState1(() {
                                            selectedYear = value!;
                                          });
                                        },
                                        icon: const Icon(Icons.arrow_drop_down,
                                            color: Colors.grey),
                                        dropdownColor: Colors.white,
                                      ),
                                    ),
                                    const Spacer(
                                        flex: 2), // Espacio para centrar
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Lista de reservaciones organizadas por mes
                              reservationsAsyncValue.when(
                                data: (data) {
                                  final selectedYearInt =
                                      int.parse(selectedYear!);

                                  // Filtrar reservaciones del año seleccionado
                                  final yearReservations =
                                      data.where((reservation) {
                                    try {
                                      final date = DateTime.parse(
                                          reservation.reservation[
                                                  'reservation_date'] ??
                                              '');
                                      return date.year == selectedYearInt;
                                    } catch (e) {
                                      return false;
                                    }
                                  }).toList();

                                  // Agrupar reservaciones por mes
                                  final reservationsByMonth =
                                      <int, List<FullReservation>>{};

                                  for (var reservation in yearReservations) {
                                    try {
                                      final date = DateTime.parse(
                                          reservation.reservation[
                                                  'reservation_date'] ??
                                              '');
                                      final month = date.month;

                                      if (!reservationsByMonth
                                          .containsKey(month)) {
                                        reservationsByMonth[month] = [];
                                      }
                                      reservationsByMonth[month]!
                                          .add(reservation);
                                    } catch (e) {
                                      // Ignorar reservaciones con fechas inválidas
                                      continue;
                                    }
                                  }

                                  // Ordenar reservaciones dentro de cada mes por fecha
                                  reservationsByMonth
                                      .forEach((month, reservations) {
                                    reservations.sort((a, b) {
                                      final dateA =
                                          a.reservation['reservation_date'] ??
                                              '';
                                      final dateB =
                                          b.reservation['reservation_date'] ??
                                              '';
                                      final timeA =
                                          a.reservation['reservation_time'] ??
                                              '';
                                      final timeB =
                                          b.reservation['reservation_time'] ??
                                              '';
                                      final dateCompare =
                                          dateA.compareTo(dateB);
                                      return dateCompare != 0
                                          ? dateCompare
                                          : timeA.compareTo(timeB);
                                    });
                                  });

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        monthList.asMap().entries.map((entry) {
                                      final monthIndex = entry.key +
                                          1; // Los meses van de 1-12
                                      final monthName = entry.value;
                                      final monthReservations =
                                          reservationsByMonth[monthIndex] ?? [];

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 24),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Título del mes
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 16),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.deepPurple.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors
                                                      .deepPurple.shade200,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_month,
                                                    color: Colors
                                                        .deepPurple.shade700,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    monthName,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors
                                                          .deepPurple.shade700,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: monthReservations
                                                              .isNotEmpty
                                                          ? Colors
                                                              .green.shade100
                                                          : Colors
                                                              .grey.shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      '${monthReservations.length} reserva${monthReservations.length != 1 ? 's' : ''}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: monthReservations
                                                                .isNotEmpty
                                                            ? Colors
                                                                .green.shade700
                                                            : Colors
                                                                .grey.shade600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(height: 12),

                                            // Contenido del mes
                                            if (monthReservations.isEmpty)
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.all(20),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.event_busy,
                                                      color:
                                                          Colors.grey.shade400,
                                                      size: 32,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'No hay reservaciones este mes',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade600,
                                                        fontSize: 14,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              ...monthReservations
                                                  .map((reservation) {
                                                return Card(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 12),
                                                  elevation: 2,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16.0),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // Fecha destacada
                                                        Container(
                                                          width: 60,
                                                          height: 60,
                                                          alignment:
                                                              Alignment.center,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .deepPurple
                                                                .shade100,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .deepPurple
                                                                  .shade300,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                (() {
                                                                  try {
                                                                    final date =
                                                                        DateTime.parse(reservation.reservation['reservation_date'] ??
                                                                            '');
                                                                    return DateFormat(
                                                                            'dd')
                                                                        .format(
                                                                            date);
                                                                  } catch (_) {
                                                                    return 'N/A';
                                                                  }
                                                                })(),
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .deepPurple
                                                                      .shade700,
                                                                ),
                                                              ),
                                                              Text(
                                                                (() {
                                                                  try {
                                                                    final date =
                                                                        DateTime.parse(reservation.reservation['reservation_date'] ??
                                                                            '');
                                                                    return DateFormat(
                                                                            'MMM',
                                                                            'es')
                                                                        .format(
                                                                            date)
                                                                        .toUpperCase();
                                                                  } catch (_) {
                                                                    return '';
                                                                  }
                                                                })(),
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Colors
                                                                      .deepPurple
                                                                      .shade600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                            width: 16),

                                                        // Detalles de la reservación
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _buildDetailRow(
                                                                'Servicio:',
                                                                reservation.service?[
                                                                        'name'] ??
                                                                    'N/A',
                                                              ),
                                                              _buildDetailRow(
                                                                'Cliente:',
                                                                reservation
                                                                        .client
                                                                        ?.customerName ??
                                                                    'N/A',
                                                              ),
                                                              _buildDetailRow(
                                                                'Teléfono:',
                                                                reservation
                                                                        .client
                                                                        ?.phoneNumber ??
                                                                    'N/A',
                                                              ),
                                                              _buildDetailRow(
                                                                'Hora:',
                                                                reservation.reservation[
                                                                        'reservation_time'] ??
                                                                    'N/A',
                                                              ),
                                                              _buildDetailRow(
                                                                'Estado:',
                                                                reservation.reservation[
                                                                        'status'] ??
                                                                    'Pendiente',
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                                loading: () => const Center(
                                    child: CircularProgressIndicator()),
                                error: (e, _) => Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade400,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Error al cargar las reservaciones',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$e',
                                        style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Campo de notas
                              // Padding(
                              //   padding: const EdgeInsets.symmetric(
                              //       vertical: 8.0, horizontal: 10.0),
                              //   child: TextFormField(
                              //     controller: _notasController,
                              //     minLines: 2,
                              //     maxLines: 4,
                              //     decoration: const InputDecoration(
                              //       labelText: 'Notas',
                              //       border: OutlineInputBorder(),
                              //       hintText: 'Escribe aquí tus notas...',
                              //     ),
                              //   ),
                              // ),
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

// Método auxiliar para construir filas de detalles (si no existe)
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> monthList = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

  // Widget _buildDetailRow(String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 6.0),
  //     child: Row(
  //       children: [
  //         Text(
  //           label,
  //           style: const TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //         const SizedBox(width: 6),
  //         Expanded(
  //           child: Text(value),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
