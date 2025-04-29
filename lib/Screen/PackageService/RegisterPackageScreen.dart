import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/product_provider.dart';
import 'package:salespro_admin/Provider/servicePackagesProvider.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/export_button.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/ServicePackageModel.dart';

class ServicePackageList extends StatefulWidget {
  const ServicePackageList({super.key});

  static const String route = '/service-packages';

  @override
  State<ServicePackageList> createState() => _ServicePackageListState();
}

class _ServicePackageListState extends State<ServicePackageList> {
  int selectedItem = 10;
  int itemCount = 10;

  TextEditingController _nameController = TextEditingController();
  String? _selectedCategory;
  TextEditingController _subcategoryController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _durationValueController = TextEditingController();
  ScrollController mainScroll = ScrollController();
  String searchItem = '';
  String _durationUnit = 'hours';
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final _lang = lang.S.of(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (_, ref, watch) {
          AsyncValue<List<ServicePackageModel>> packages = ref.watch(servicePackagesProvider);
          return packages.when(data: (list) {
            List<ServicePackageModel> showAblePackages = [];

            for (var element in list) {
              if (element.name.removeAllWhiteSpace().toLowerCase().contains(searchItem.toLowerCase())) {
                showAblePackages.add(element);
              } else if (searchItem == '') {
                showAblePackages.add(element);
              }
            }

            final pages = (showAblePackages.length / _itemsPerPage).ceil();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0), color: kWhite),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _lang.servicePackages,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              _showAddPackageDialog(context, ref);
                            },
                            icon: const Icon(FeatherIcons.plus, color: kWhite, size: 18.0),
                            label: Text(
                              _lang.addServicePackage,
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

                    // Search and pagination controls
                    ResponsiveGridRow(rowSegments: 100, children: [
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
                          )),
                    ]),

                    const SizedBox(height: 20.0),
                    showAblePackages.isNotEmpty
                        ? Column(
                      children: [
                        LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
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
                                      dividerTheme: const DividerThemeData(color: Colors.transparent),
                                    ),
                                    child: DataTable(
                                        border: const TableBorder(
                                          horizontalInside: BorderSide(
                                            width: 1,
                                            color: kNeutral300,
                                          ),
                                        ),
                                        dataRowColor: const WidgetStatePropertyAll(Colors.white),
                                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                        showBottomBorder: false,
                                        dividerThickness: 0.0,
                                        headingTextStyle: theme.textTheme.titleMedium,
                                        columns: [
                                          DataColumn(label: Text(_lang.SL)),
                                          DataColumn(label: Text(_lang.name)),
                                          DataColumn(label: Text(_lang.category)),
                                          DataColumn(label: Text(_lang.subcategory)),
                                          DataColumn(label: Text(_lang.price)),
                                          DataColumn(label: Text(_lang.duration)),
                                          const DataColumn(label: Icon(FeatherIcons.settings)),
                                        ],
                                        rows: List.generate(
                                            _itemsPerPage == -1
                                                ? showAblePackages.length
                                                : (_currentPage - 1) * _itemsPerPage + _itemsPerPage <= showAblePackages.length
                                                ? _itemsPerPage
                                                : showAblePackages.length - (_currentPage - 1) * _itemsPerPage, (index) {
                                          final dataIndex = (_currentPage - 1) * _itemsPerPage + index;
                                          final package = showAblePackages[dataIndex];
                                          return DataRow(cells: [
                                            // SL Number
                                            DataCell(Text('${(_currentPage - 1) * _itemsPerPage + index + 1}')),

                                            // Name
                                            DataCell(Text(package.name)),

                                            // Category
                                            DataCell(Text(package.category)),

                                            // Subcategory
                                            DataCell(Text(package.subcategory)),

                                            // Price
                                            DataCell(Text('\$${package.price.toStringAsFixed(2)}')),

                                            // Duration
                                            DataCell(Text('${package.duration['value']} ${package.duration['unit']}')),

                                            // Actions
                                            DataCell(
                                              Theme(
                                                data: ThemeData(
                                                    highlightColor: dropdownItemColor,
                                                    focusColor: dropdownItemColor,
                                                    hoverColor: dropdownItemColor),
                                                child: SizedBox(
                                                  width: 20,
                                                  child: PopupMenuButton(
                                                    surfaceTintColor: Colors.white,
                                                    padding: EdgeInsets.zero,
                                                    itemBuilder: (BuildContext bc) => [
                                                      // Edit
                                                      PopupMenuItem(
                                                          onTap: () {
                                                            _showEditPackageDialog(context, ref, package);
                                                          },
                                                          child: Row(
                                                            children: [
                                                              const Icon(IconlyLight.edit, size: 20.0, color: kNeutral500),
                                                              const SizedBox(width: 4.0),
                                                              Text(
                                                                _lang.edit,
                                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                                  color: kNeutral500,
                                                                ),
                                                              ),
                                                            ],
                                                          )),

                                                      // Delete
                                                      PopupMenuItem(
                                                        onTap: () {
                                                          _showDeleteConfirmation(context, ref, package);
                                                        },
                                                        child: Row(
                                                          children: [
                                                            HugeIcon(
                                                              icon: HugeIcons.strokeRoundedDelete02,
                                                              color: kNeutral500,
                                                              size: 20.0,
                                                            ),
                                                            const SizedBox(width: 4.0),
                                                            Text(
                                                              _lang.delete,
                                                              style: theme.textTheme.bodyLarge?.copyWith(color: kNeutral500),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                    onSelected: (value) {
                                                      context.go('/$value');
                                                    },
                                                    child: Center(
                                                      child: Container(
                                                          height: 18,
                                                          width: 18,
                                                          alignment: Alignment.centerRight,
                                                          child: const Icon(
                                                            Icons.more_vert_sharp,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${_lang.showing} ${((_currentPage - 1) * _itemsPerPage + 1).toString()} to ${((_currentPage - 1) * _itemsPerPage + _itemsPerPage).clamp(0, showAblePackages.length)} of ${showAblePackages.length} entries',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  InkWell(
                                    overlayColor: WidgetStateProperty.all<Color>(Colors.grey),
                                    hoverColor: Colors.grey,
                                    onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                                    child: Container(
                                      height: 32,
                                      width: 90,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: kBorderColorTextField),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(4.0),
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
                                      border: Border.all(color: kBorderColorTextField),
                                      color: kMainColor,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$_currentPage',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 32,
                                    width: 32,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: kBorderColorTextField),
                                      color: Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$pages',
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    hoverColor: Colors.blue.withOpacity(0.1),
                                    overlayColor: MaterialStateProperty.all<Color>(Colors.blue),
                                    onTap: _currentPage * _itemsPerPage < showAblePackages.length ? () => setState(() => _currentPage++) : null,
                                    child: Container(
                                      height: 32,
                                      width: 90,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: kBorderColorTextField),
                                        borderRadius: const BorderRadius.only(
                                          bottomRight: Radius.circular(4.0),
                                          topRight: Radius.circular(4.0),
                                        ),
                                      ),
                                      child: const Center(child: Text('Next')),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                        : EmptyWidget(title: _lang.noServicePackagesFound)
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

  void _showAddPackageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState1) {
          return Dialog(
            surfaceTintColor: kWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            child: SizedBox(
              width: 600,
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
                            lang.S.of(context).addServicePackage,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Flexible(
                          child: IconButton(
                              onPressed: () {
                                _clearForm();
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                FeatherIcons.x,
                                color: kTitleColor,
                                size: 21.0,
                              )),
                        )
                      ],
                    ),
                  ),
                  const Divider(
                    thickness: 1.0,
                    height: 1.0,
                    color: kNeutral300,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).packageName,
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return lang.S.of(context).packageNameRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Category - Changed to DropdownButtonFormField
                          Consumer(
                            builder: (context, ref, child) {
                              final categoriesAsync = ref.watch(categoryProvider);
                              return categoriesAsync.when(
                                data: (categories) {
                                  if (categories.isEmpty) {
                                    return Text('No categories available');
                                  }
                                  return DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: InputDecoration(
                                      labelText: lang.S.of(context).category,
                                      border: OutlineInputBorder(),
                                    ),
                                    items: categories.map((category) {
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
                                        return lang.S.of(context).categoryRequired;
                                      }
                                      return null;
                                    },
                                  );
                                },
                                loading: () => CircularProgressIndicator(),
                                error: (error, stack) => Text('Error: $error'),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Subcategory
                          TextFormField(
                            controller: _subcategoryController,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).subcategory,
                              border: OutlineInputBorder(),
                              hintText: lang.S.of(context).subcategoryHint,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).description,
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
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

                          // Duration
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _durationValueController,
                                  decoration: InputDecoration(
                                    labelText: lang.S.of(context).duration,
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return lang.S.of(context).durationRequired;
                                    }
                                    if (int.tryParse(value) == null) {
                                      return lang.S.of(context).invalidInteger;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  value: _durationUnit,
                                  decoration: InputDecoration(
                                    labelText: lang.S.of(context).unit,
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                        value: 'hours', child: Text(lang.S.of(context).hours)),
                                    DropdownMenuItem(
                                        value: 'days', child: Text(lang.S.of(context).days)),
                                  ],
                                  onChanged: (value) {
                                    setState1(() {
                                      _durationUnit = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  _clearForm();
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  lang.S.of(context).cancel,
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width <= 570 ? 10 : 30.0),
                              ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    EasyLoading.show(status: lang.S.of(context).addingPackage);
                                    final newPackage = ServicePackageModel(
                                      id: '', // Will be assigned by Firebase
                                      type: 'service',
                                      name: _nameController.text,
                                      category: _selectedCategory ?? '',
                                      subcategory: _subcategoryController.text,
                                      description: _descriptionController.text,
                                      price: double.tryParse(_priceController.text) ?? 0.0,
                                      duration: {
                                        'value': int.tryParse(_durationValueController.text) ?? 0,
                                        'unit': _durationUnit,
                                      },
                                      components: [],
                                      branches: [],
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    );

                                    try {
                                      final result = await ref.read(servicePackagesProvider.notifier).addPackage(newPackage);
                                      if (result) {
                                        EasyLoading.showSuccess(lang.S.of(context).packageAddedSuccess);
                                        _clearForm();
                                        Navigator.pop(context);
                                      } else {
                                        EasyLoading.showError(lang.S.of(context).failedToAddPackage);
                                      }
                                    } catch (e) {
                                      EasyLoading.showError('${lang.S.of(context).error}: $e');
                                    }
                                  }
                                },
                                child: Text(
                                  lang.S.of(context).submit,
                                  style: kTextStyle.copyWith(color: kWhite),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12)
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showEditPackageDialog(BuildContext context, WidgetRef ref, ServicePackageModel package) {
    // Fill form with existing package data
    _nameController.text = package.name;
    _selectedCategory = package.category;
    _subcategoryController.text = package.subcategory;
    _descriptionController.text = package.description;
    _priceController.text = package.price.toString();
    _durationValueController.text = package.duration['value'].toString();
    _durationUnit = package.duration['unit'];

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState1) {
          return Dialog(
            surfaceTintColor: kWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            child: SizedBox(
              width: 600,
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
                            lang.S.of(context).editPackage,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Flexible(
                          child: IconButton(
                              onPressed: () {
                                _clearForm();
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                FeatherIcons.x,
                                color: kTitleColor,
                                size: 21.0,
                              )),
                        )
                      ],
                    ),
                  ),
                  const Divider(
                    thickness: 1.0,
                    height: 1.0,
                    color: kNeutral300,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).packageName,
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return lang.S.of(context).packageNameRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Category - Changed to DropdownButtonFormField
                          Consumer(
                            builder: (context, ref, child) {
                              final categoriesAsync = ref.watch(categoryProvider);
                              return categoriesAsync.when(
                                data: (categories) {
                                  if (categories.isEmpty) {
                                    return Text('No categories available');
                                  }
                                  return DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: InputDecoration(
                                      labelText: lang.S.of(context).category,
                                      border: OutlineInputBorder(),
                                    ),
                                    items: categories.map((category) {
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
                                        return lang.S.of(context).categoryRequired;
                                      }
                                      return null;
                                    },
                                  );
                                },
                                loading: () => CircularProgressIndicator(),
                                error: (error, stack) => Text('Error: $error'),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Subcategory
                          TextFormField(
                            controller: _subcategoryController,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).subcategory,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).description,
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
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

                          // Duration
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _durationValueController,
                                  decoration: InputDecoration(
                                    labelText: lang.S.of(context).duration,
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return lang.S.of(context).durationRequired;
                                    }
                                    if (int.tryParse(value) == null) {
                                      return lang.S.of(context).invalidInteger;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  value: _durationUnit,
                                  decoration: InputDecoration(
                                    labelText: lang.S.of(context).unit,
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                        value: 'hours', child: Text(lang.S.of(context).hours)),
                                    DropdownMenuItem(
                                        value: 'days', child: Text(lang.S.of(context).days)),
                                  ],
                                  onChanged: (value) {
                                    setState1(() {
                                      _durationUnit = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  _clearForm();
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  lang.S.of(context).cancel,
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width <= 570 ? 10 : 30.0),
                              ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    EasyLoading.show(status: lang.S.of(context).updatingPackage);
                                    final updatedPackage = package.copyWith(
                                      name: _nameController.text,
                                      category: _selectedCategory ?? '',
                                      subcategory: _subcategoryController.text,
                                      description: _descriptionController.text,
                                      price: double.tryParse(_priceController.text) ?? 0.0,
                                      duration: {
                                        'value': int.tryParse(_durationValueController.text) ?? 0,
                                        'unit': _durationUnit,
                                      },
                                      updatedAt: DateTime.now(),
                                    );

                                    try {
                                      final result = await ref.read(servicePackagesProvider.notifier).updatePackage(updatedPackage);
                                      if (result) {
                                        EasyLoading.showSuccess(lang.S.of(context).packageUpdatedSuccess);
                                        _clearForm();
                                        Navigator.pop(context);
                                      } else {
                                        EasyLoading.showError(lang.S.of(context).failedToUpdatePackage);
                                      }
                                    } catch (e) {
                                      EasyLoading.showError('${lang.S.of(context).error}: $e');
                                    }
                                  }
                                },
                                child: Text(
                                  lang.S.of(context).update,
                                  style: kTextStyle.copyWith(color: kWhite),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12)
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, ServicePackageModel package) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(lang.S.of(context).confirmDelete),
          content: Text(lang.S.of(context).deletePackageConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.S.of(context).cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                EasyLoading.show(status: lang.S.of(context).deleting);
                try {
                  final result = await ref.read(servicePackagesProvider.notifier).deletePackage(package.id);
                  if (result) {
                    EasyLoading.showSuccess(lang.S.of(context).packageDeletedSuccess);
                  } else {
                    EasyLoading.showError(lang.S.of(context).failedToDeletePackage);
                  }
                } catch (e) {
                  EasyLoading.showError('${lang.S.of(context).error}: $e');
                }
              },
              child: Text(lang.S.of(context).delete, style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _nameController.clear();
    _selectedCategory = null;
    _subcategoryController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _durationValueController.clear();
    _durationUnit = 'hours';
  }
}