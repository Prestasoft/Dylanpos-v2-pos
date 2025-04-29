// ignore_for_file: unused_result, use_build_context_synchronously

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
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/category_model.dart';

import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({super.key});

  static const String route = '/category-list';

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  int selectedItem = 10;
  int itemCount = 10;
  TextEditingController itemCategoryController = TextEditingController();
  ScrollController mainScroll = ScrollController();
  String searchItem = '';
  bool isSize = false;
  bool isColor = false;
  bool isWeight = false;
  bool isCapacity = false;
  bool isType = false;
  bool isWarranty = false;
  GlobalKey<FormState> categoryNameKey = GlobalKey<FormState>();

  bool categoryValidateAndSave() {
    final form = categoryNameKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  int _categoryPerPage = 10; // Default number of items to display
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
            AsyncValue<List<CategoryModel>> categories = ref.watch(categoryProvider);
            return categories.when(data: (list) {
              List<CategoryModel> categoryLists = [];
              List<CategoryModel> showAbleCategories = [];
              List<String> categoryNames = [];
              for (var element in list) {
                if (element.categoryName.removeAllWhiteSpace().toLowerCase().contains(searchItem.toLowerCase())) {
                  showAbleCategories.add(element);
                } else if (searchItem == '') {
                  showAbleCategories.add(element);
                  categoryNames.add(element.categoryName.removeAllWhiteSpace().toLowerCase());
                }
              }
              final pages = (showAbleCategories.length / _categoryPerPage).ceil();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  // padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
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
                                lang.S.of(context).categories,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
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
                                                          lang.S.of(context).addItemCategory,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: theme.textTheme.titleLarge?.copyWith(
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      Flexible(
                                                        child: IconButton(
                                                            onPressed: () {
                                                              itemCategoryController.clear();
                                                              isSize = false;
                                                              isColor = false;
                                                              isWeight = false;
                                                              isCapacity = false;
                                                              isType = false;
                                                              isWarranty = false;
                                                              finish(context);
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
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                                        ResponsiveGridCol(
                                                          xs: 12,
                                                          md: 6,
                                                          lg: 6,
                                                          child: Padding(
                                                            padding: EdgeInsets.only(bottom: screenWidth < 570 ? 10 : 0),
                                                            child: Text(
                                                              lang.S.of(context).categoryName,
                                                              style: theme.textTheme.bodyLarge,
                                                            ),
                                                          ),
                                                        ),
                                                        ResponsiveGridCol(
                                                          xs: 12,
                                                          md: 6,
                                                          lg: 6,
                                                          child: Form(
                                                            key: categoryNameKey,
                                                            child: TextFormField(
                                                              controller: itemCategoryController,
                                                              validator: (value) {
                                                                if (value.isEmptyOrNull) {
                                                                  //return 'Category name is required.';
                                                                  return '${lang.S.of(context).categoryNameIsRequired}.';
                                                                } else if (categoryNames.contains(value.removeAllWhiteSpace().toLowerCase())) {
                                                                  //return 'Category name is already exist.';
                                                                  return '${lang.S.of(context).categoryNameIsAlreadyExist}.';
                                                                } else {
                                                                  return null;
                                                                }
                                                              },
                                                              showCursor: true,
                                                              cursorColor: kTitleColor,
                                                              decoration: InputDecoration(
                                                                hintText: lang.S.of(context).enterCategoryName,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      ]),
                                                      const SizedBox(height: 20.0),
                                                      Text(
                                                        lang.S.of(context).selectVariations,
                                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                                      ),
                                                      ResponsiveGridRow(children: [
                                                        ResponsiveGridCol(
                                                          xs: 12,
                                                          md: 6,
                                                          lg: 6,
                                                          child: ListTile(
                                                            leading: Checkbox(
                                                              activeColor: kMainColor,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(30.0),
                                                              ),
                                                              value: isSize,
                                                              onChanged: (val) {
                                                                setState1(
                                                                  () {
                                                                    isSize = val!;
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                            title: Text(
                                                              lang.S.of(context).size,
                                                              style: theme.textTheme.bodyLarge,
                                                            ),
                                                          ),
                                                        ),
                                                        ResponsiveGridCol(
                                                            xs: 12,
                                                            md: 6,
                                                            lg: 6,
                                                            child: ListTile(
                                                              leading: Checkbox(
                                                                activeColor: kMainColor,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(30.0),
                                                                ),
                                                                value: isColor,
                                                                onChanged: (val) {
                                                                  setState1(() {
                                                                    isColor = val!;
                                                                  });
                                                                },
                                                              ),
                                                              title: Text(
                                                                lang.S.of(context).color,
                                                                style: theme.textTheme.bodyLarge,
                                                              ),
                                                            )),
                                                      ]),
                                                      ResponsiveGridRow(children: [
                                                        ResponsiveGridCol(
                                                            xs: 12,
                                                            md: 6,
                                                            lg: 6,
                                                            child: ListTile(
                                                              leading: Checkbox(
                                                                activeColor: kMainColor,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(30.0),
                                                                ),
                                                                value: isWeight,
                                                                onChanged: (val) {
                                                                  setState1(() {
                                                                    isWeight = val!;
                                                                  });
                                                                },
                                                              ),
                                                              title: Text(
                                                                lang.S.of(context).wight,
                                                                style: theme.textTheme.bodyLarge,
                                                              ),
                                                            )),
                                                        ResponsiveGridCol(
                                                          xs: 12,
                                                          md: 6,
                                                          lg: 6,
                                                          child: ListTile(
                                                            leading: Checkbox(
                                                              activeColor: kMainColor,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(30.0),
                                                              ),
                                                              value: isCapacity,
                                                              onChanged: (val) {
                                                                setState1(
                                                                  () {
                                                                    isCapacity = val!;
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                            title: Text(
                                                              lang.S.of(context).capacity,
                                                              style: theme.textTheme.bodyLarge,
                                                            ),
                                                          ),
                                                        ),
                                                      ]),
                                                      ResponsiveGridRow(children: [
                                                        ResponsiveGridCol(
                                                            xs: 12,
                                                            md: 6,
                                                            lg: 6,
                                                            child: ListTile(
                                                              leading: Checkbox(
                                                                activeColor: kMainColor,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(30.0),
                                                                ),
                                                                value: isType,
                                                                onChanged: (val) {
                                                                  setState1(
                                                                    () {
                                                                      isType = val!;
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                              title: Text(
                                                                lang.S.of(context).type,
                                                                style: theme.textTheme.bodyLarge,
                                                              ),
                                                            )),
                                                        ResponsiveGridCol(
                                                            xs: 12,
                                                            md: 6,
                                                            lg: 6,
                                                            child: ListTile(
                                                              leading: Checkbox(
                                                                activeColor: kMainColor,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(30.0),
                                                                ),
                                                                value: isWarranty,
                                                                onChanged: (val) {
                                                                  setState1(
                                                                    () {
                                                                      isWarranty = val!;
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                              title: Text(
                                                                lang.S.of(context).warranty,
                                                                style: theme.textTheme.bodyLarge,
                                                              ),
                                                            )),
                                                      ]),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.red,
                                                            ),
                                                            onPressed: () {
                                                              itemCategoryController.clear();
                                                              isSize = false;
                                                              isColor = false;
                                                              isWeight = false;
                                                              isCapacity = false;
                                                              isType = false;
                                                              isWarranty = false;

                                                              finish(context);
                                                            },
                                                            child: Text(
                                                              lang.S.of(context).cancel,
                                                            ),
                                                          ),
                                                          SizedBox(width: screenWidth <= 570 ? 10 : 30.0),
                                                          ElevatedButton(
                                                            onPressed: () async {
                                                              if (categoryValidateAndSave()) {
                                                                EasyLoading.show(status: lang.S.of(context).addingCategory);
                                                                final DatabaseReference categoryInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Categories');
                                                                CategoryModel categoryModel = CategoryModel(
                                                                  categoryName: itemCategoryController.text,
                                                                  size: isSize,
                                                                  color: isColor,
                                                                  capacity: isCapacity,
                                                                  type: isType,
                                                                  weight: isWeight,
                                                                  warranty: isWarranty,
                                                                );
                                                                await categoryInformationRef.push().set(categoryModel.toJson());
                                                                ref.refresh(categoryProvider);
                                                                itemCategoryController.clear();
                                                                isSize = false;
                                                                isColor = false;
                                                                isWeight = false;
                                                                isCapacity = false;
                                                                isType = false;
                                                                isWarranty = false;
                                                                //EasyLoading.showSuccess("Successfully Added");
                                                                EasyLoading.showSuccess(lang.S.of(context).successfullyAdded);
                                                                finish(context);

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
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      });
                                    });
                              },
                              icon: const Icon(FeatherIcons.plus, color: kWhite, size: 18.0),
                              label: Text(
                                lang.S.of(context).addCategory,
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
                      //---------------------search---------------------------
                      const SizedBox(height: 10),

                      ResponsiveGridRow(rowSegments: 100, children: [
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
                                    value: _categoryPerPage,
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
                                          _categoryPerPage = -1; // Set to -1 for "All"
                                        } else {
                                          _categoryPerPage = newValue ?? 10;
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
                                  hintText: (lang.S.of(context).searchByNameOrPhone),
                                  suffixIcon: const Icon(
                                    FeatherIcons.search,
                                    color: kNeutral400,
                                  ),
                                ),
                              ),
                            )),
                      ]),

                      ///__________Customer_List________________________________________________

                      const SizedBox(height: 20.0),
                      showAbleCategories.isNotEmpty
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
                                                  DataColumn(label: Text(_lang.categoryName)),
                                                  DataColumn(label: Text(_lang.type)),
                                                  DataColumn(label: Text(_lang.size)),
                                                  DataColumn(label: Text(_lang.color)),
                                                  DataColumn(label: Text(_lang.capacity)),
                                                  const DataColumn(label: Icon(FeatherIcons.settings)),
                                                ],
                                                rows: List.generate(
                                                    _categoryPerPage == -1
                                                        ? showAbleCategories.length
                                                        : (_currentPage - 1) * _categoryPerPage + _categoryPerPage <= showAbleCategories.length
                                                            ? _categoryPerPage
                                                            : showAbleCategories.length - (_currentPage - 1) * _categoryPerPage, (index) {
                                                  final dataIndex = (_currentPage - 1) * _categoryPerPage + index;
                                                  return DataRow(cells: [
                                                    ///______________S.L__________________________________________________
                                                    DataCell(
                                                      Text('${(_currentPage - 1) * _categoryPerPage + index + 1}'),
                                                    ),

                                                    ///______________name__________________________________________________
                                                    DataCell(
                                                      Text(
                                                        showAbleCategories[index].categoryName,
                                                      ),
                                                    ),

                                                    ///____________type_________________________________________________
                                                    DataCell(
                                                      Text(
                                                        showAbleCategories[index].type.toString(),
                                                      ),
                                                    ),

                                                    ///______Phone___________________________________________________________
                                                    DataCell(
                                                      Text(
                                                        showAbleCategories[index].size.toString(),
                                                      ),
                                                    ),

                                                    ///___________Email____________________________________________________
                                                    DataCell(
                                                      Text(
                                                        showAbleCategories[index].color.toString(),
                                                      ),
                                                    ),

                                                    ///___________Due____________________________________________________

                                                    DataCell(
                                                      Text(
                                                        showAbleCategories[index].capacity.toString(),
                                                      ),
                                                    ),

                                                    ///_______________actions_________________________________________________
                                                    DataCell(
                                                      Theme(
                                                        data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                        child: SizedBox(
                                                          width: 20,
                                                          child: PopupMenuButton(
                                                            surfaceTintColor: Colors.white,
                                                            padding: EdgeInsets.zero,
                                                            itemBuilder: (BuildContext bc) => [
                                                              ///____________Edit____________________________________________________
                                                              PopupMenuItem(
                                                                  onTap: () {
                                                                    itemCategoryController.text = showAbleCategories[index].categoryName;
                                                                    setState(() {
                                                                      isSize = showAbleCategories[index].size;
                                                                      isColor = showAbleCategories[index].color;
                                                                      isWeight = showAbleCategories[index].weight;
                                                                      isCapacity = showAbleCategories[index].capacity;
                                                                      isType = showAbleCategories[index].type;
                                                                      isWarranty = showAbleCategories[index].warranty;
                                                                    });

                                                                    showDialog(
                                                                        barrierDismissible: false,
                                                                        context: context,
                                                                        builder: (BuildContext dialogContext) {
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
                                                                                      padding: const EdgeInsets.all(12),
                                                                                      child: Row(
                                                                                        children: [
                                                                                          Text(
                                                                                            lang.S.of(context).editCategory,
                                                                                            style: theme.textTheme.titleLarge?.copyWith(
                                                                                              fontWeight: FontWeight.w600,
                                                                                            ),
                                                                                          ),
                                                                                          const Spacer(),
                                                                                          IconButton(
                                                                                              onPressed: () {
                                                                                                itemCategoryController.clear();
                                                                                                isSize = false;
                                                                                                isColor = false;
                                                                                                isWeight = false;
                                                                                                isCapacity = false;
                                                                                                isType = false;
                                                                                                isWarranty = false;
                                                                                                finish(context);
                                                                                              },
                                                                                              icon: const Icon(
                                                                                                FeatherIcons.x,
                                                                                                color: kTitleColor,
                                                                                                size: 21.0,
                                                                                              ))
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                    // const SizedBox(height: 20.0),
                                                                                    const Divider(
                                                                                      thickness: 1.0,
                                                                                      color: kNeutral300,
                                                                                      height: 1,
                                                                                    ),
                                                                                    // const SizedBox(height: 10.0),
                                                                                    Padding(
                                                                                      padding: const EdgeInsets.all(12.0),
                                                                                      child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                                                                            ResponsiveGridCol(
                                                                                              xs: 12,
                                                                                              md: 4,
                                                                                              lg: 4,
                                                                                              child: Padding(
                                                                                                padding: EdgeInsets.only(
                                                                                                  bottom: MediaQuery.of(context).size.width < 570 ? 10 : 0,
                                                                                                ),
                                                                                                child: Text(
                                                                                                  lang.S.of(context).categoryName,
                                                                                                  style: theme.textTheme.bodyLarge,
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            ResponsiveGridCol(
                                                                                              xs: 12,
                                                                                              md: 8,
                                                                                              lg: 8,
                                                                                              child: Form(
                                                                                                key: categoryNameKey,
                                                                                                child: TextFormField(
                                                                                                  controller: itemCategoryController,
                                                                                                  validator: (value) {
                                                                                                    if (value.isEmptyOrNull) {
                                                                                                      //return 'Category name is required.';
                                                                                                      return '${lang.S.of(context).categoryNameIsRequired}.';
                                                                                                    } else if (categoryNames.contains(value.removeAllWhiteSpace().toLowerCase())) {
                                                                                                      //return 'Category name is already exist.';
                                                                                                      return '${lang.S.of(context).categoryNameIsAlreadyExist}.';
                                                                                                    } else {
                                                                                                      return null;
                                                                                                    }
                                                                                                  },
                                                                                                  showCursor: true,
                                                                                                  cursorColor: kTitleColor,
                                                                                                  decoration: InputDecoration(
                                                                                                    // labelText: lang.S.of(context).categoryName,
                                                                                                    hintText: lang.S.of(context).enterCategoryName,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                          ]),
                                                                                          const SizedBox(height: 20.0),
                                                                                          Text(
                                                                                            lang.S.of(context).selectVariations,
                                                                                            style: theme.textTheme.titleMedium?.copyWith(
                                                                                              fontWeight: FontWeight.w600,
                                                                                              fontSize: 18,
                                                                                            ),
                                                                                          ),
                                                                                          ResponsiveGridRow(children: [
                                                                                            ResponsiveGridCol(
                                                                                                xs: 12,
                                                                                                md: 6,
                                                                                                lg: 6,
                                                                                                child: ListTile(
                                                                                                  leading: Checkbox(
                                                                                                    activeColor: kMainColor,
                                                                                                    shape: RoundedRectangleBorder(
                                                                                                      borderRadius: BorderRadius.circular(30.0),
                                                                                                    ),
                                                                                                    value: isSize,
                                                                                                    onChanged: (val) {
                                                                                                      setState1(
                                                                                                        () {
                                                                                                          isSize = val!;
                                                                                                        },
                                                                                                      );
                                                                                                    },
                                                                                                  ),
                                                                                                  title: Text(
                                                                                                    lang.S.of(context).size,
                                                                                                    style: theme.textTheme.titleMedium,
                                                                                                  ),
                                                                                                )),
                                                                                            ResponsiveGridCol(
                                                                                                xs: 12,
                                                                                                md: 6,
                                                                                                lg: 6,
                                                                                                child: ListTile(
                                                                                                  leading: Checkbox(
                                                                                                    activeColor: kMainColor,
                                                                                                    shape: RoundedRectangleBorder(
                                                                                                      borderRadius: BorderRadius.circular(30.0),
                                                                                                    ),
                                                                                                    value: isColor,
                                                                                                    onChanged: (val) {
                                                                                                      setState1(() {
                                                                                                        isColor = val!;
                                                                                                      });
                                                                                                    },
                                                                                                  ),
                                                                                                  title: Text(
                                                                                                    lang.S.of(context).color,
                                                                                                    style: theme.textTheme.titleMedium,
                                                                                                  ),
                                                                                                ))
                                                                                          ]),
                                                                                          ResponsiveGridRow(children: [
                                                                                            ResponsiveGridCol(
                                                                                                xs: 12,
                                                                                                md: 6,
                                                                                                lg: 6,
                                                                                                child: ListTile(
                                                                                                  leading: Checkbox(
                                                                                                    activeColor: kMainColor,
                                                                                                    shape: RoundedRectangleBorder(
                                                                                                      borderRadius: BorderRadius.circular(30.0),
                                                                                                    ),
                                                                                                    value: isWeight,
                                                                                                    onChanged: (val) {
                                                                                                      setState1(() {
                                                                                                        isWeight = val!;
                                                                                                      });
                                                                                                    },
                                                                                                  ),
                                                                                                  title: Text(
                                                                                                    lang.S.of(context).wight,
                                                                                                    style: theme.textTheme.titleMedium,
                                                                                                  ),
                                                                                                )),
                                                                                            ResponsiveGridCol(
                                                                                              xs: 12,
                                                                                              md: 6,
                                                                                              lg: 6,
                                                                                              child: ListTile(
                                                                                                leading: Checkbox(
                                                                                                  activeColor: kMainColor,
                                                                                                  shape: RoundedRectangleBorder(
                                                                                                    borderRadius: BorderRadius.circular(30.0),
                                                                                                  ),
                                                                                                  value: isCapacity,
                                                                                                  onChanged: (val) {
                                                                                                    setState1(
                                                                                                      () {
                                                                                                        isCapacity = val!;
                                                                                                      },
                                                                                                    );
                                                                                                  },
                                                                                                ),
                                                                                                title: Text(
                                                                                                  lang.S.of(context).capacity,
                                                                                                  style: theme.textTheme.titleMedium,
                                                                                                ),
                                                                                              ),
                                                                                            )
                                                                                          ]),
                                                                                          ResponsiveGridRow(children: [
                                                                                            ResponsiveGridCol(
                                                                                                xs: 12,
                                                                                                md: 6,
                                                                                                lg: 6,
                                                                                                child: ListTile(
                                                                                                  leading: Checkbox(
                                                                                                    activeColor: kMainColor,
                                                                                                    shape: RoundedRectangleBorder(
                                                                                                      borderRadius: BorderRadius.circular(30.0),
                                                                                                    ),
                                                                                                    value: isType,
                                                                                                    onChanged: (val) {
                                                                                                      setState1(
                                                                                                        () {
                                                                                                          isType = val!;
                                                                                                        },
                                                                                                      );
                                                                                                    },
                                                                                                  ),
                                                                                                  title: Text(lang.S.of(context).type),
                                                                                                )),
                                                                                            ResponsiveGridCol(
                                                                                                xs: 12,
                                                                                                md: 6,
                                                                                                lg: 6,
                                                                                                child: ListTile(
                                                                                                  leading: Checkbox(
                                                                                                    activeColor: kMainColor,
                                                                                                    shape: RoundedRectangleBorder(
                                                                                                      borderRadius: BorderRadius.circular(30.0),
                                                                                                    ),
                                                                                                    value: isWarranty,
                                                                                                    onChanged: (val) {
                                                                                                      setState1(
                                                                                                        () {
                                                                                                          isWarranty = val!;
                                                                                                        },
                                                                                                      );
                                                                                                    },
                                                                                                  ),
                                                                                                  title: Text(
                                                                                                    lang.S.of(context).warranty,
                                                                                                    style: theme.textTheme.titleMedium,
                                                                                                  ),
                                                                                                ))
                                                                                          ]),
                                                                                          const SizedBox(height: 16),
                                                                                          Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                                            children: [
                                                                                              ElevatedButton(
                                                                                                style: ElevatedButton.styleFrom(
                                                                                                  backgroundColor: Colors.red,
                                                                                                ),
                                                                                                onPressed: () {
                                                                                                  itemCategoryController.clear();
                                                                                                  isSize = false;
                                                                                                  isColor = false;
                                                                                                  isWeight = false;
                                                                                                  isCapacity = false;
                                                                                                  isType = false;
                                                                                                  isWarranty = false;
                                                                                                  finish(context);
                                                                                                },
                                                                                                child: Text(
                                                                                                  lang.S.of(context).cancel,
                                                                                                  maxLines: 2, // Limit the text to a maximum of 2 lines
                                                                                                  overflow: TextOverflow.ellipsis,
                                                                                                ),
                                                                                              ),
                                                                                              SizedBox(width: screenWidth <= 570 ? 10 : 30.0),
                                                                                              ElevatedButton(
                                                                                                onPressed: () async {
                                                                                                  if (categoryValidateAndSave()) {
                                                                                                    EasyLoading.show(status: lang.S.of(context).addingCategory);
                                                                                                    try {
                                                                                                      await FirebaseDatabase.instance.ref().child(await getUserID()).child('Categories').orderByChild('categoryName').once().then((DatabaseEvent event) async {
                                                                                                        if (event.snapshot.value != null) {
                                                                                                          Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;
                                                                                                          for (var entry in values.entries) {
                                                                                                            if (entry.value['categoryName'] == showAbleCategories[index].categoryName) {
                                                                                                              await FirebaseDatabase.instance.ref().child(await getUserID()).child('Categories').child(entry.key).update({
                                                                                                                'categoryName': itemCategoryController.text,
                                                                                                                'variationSize': isSize,
                                                                                                                'variationColor': isColor,
                                                                                                                'variationWeight': isWeight,
                                                                                                                'variationCapacity': isCapacity,
                                                                                                                'variationType': isType,
                                                                                                              });
                                                                                                            }
                                                                                                          }
                                                                                                        }
                                                                                                      });

                                                                                                      ref.refresh(categoryProvider);
                                                                                                      EasyLoading.showSuccess('Updated Successfully');

                                                                                                      // Ensure safe popping
                                                                                                      if (Navigator.canPop(context)) {
                                                                                                        GoRouter.of(context).pop();
                                                                                                      }

                                                                                                      context.go(CategoryList.route);
                                                                                                    } catch (e) {
                                                                                                      print('---------------${e.toString()}------------');
                                                                                                      EasyLoading.showError(lang.S.of(context).error);
                                                                                                    }
                                                                                                  }
                                                                                                },

                                                                                                // onPressed: () async {
                                                                                                //   if (categoryValidateAndSave()) {
                                                                                                //     EasyLoading.show(status: lang.S.of(context).addingCategory);
                                                                                                //     try {
                                                                                                //       await FirebaseDatabase.instance
                                                                                                //           .ref()
                                                                                                //           .child(await getUserID())
                                                                                                //           .child('Categories')
                                                                                                //           .orderByChild('categoryName')
                                                                                                //           .once()
                                                                                                //           .then((DatabaseEvent event) {
                                                                                                //         if (event.snapshot.value != null) {
                                                                                                //           Map<dynamic, dynamic> values =
                                                                                                //               event.snapshot.value as Map<dynamic, dynamic>;
                                                                                                //           values.forEach((key, value) async {
                                                                                                //             if (value['categoryName'] == showAbleCategories[index].categoryName) {
                                                                                                //               FirebaseDatabase.instance
                                                                                                //                   .ref()
                                                                                                //                   .child(await getUserID())
                                                                                                //                   .child('Categories')
                                                                                                //                   .child(key)
                                                                                                //                   .update({
                                                                                                //                 'categoryName': itemCategoryController.text,
                                                                                                //                 'variationSize': isSize,
                                                                                                //                 'variationColor': isColor,
                                                                                                //                 'variationWeight': isWeight,
                                                                                                //                 'variationCapacity': isCapacity,
                                                                                                //                 'variationType': isType,
                                                                                                //               });
                                                                                                //             }
                                                                                                //           });
                                                                                                //         }
                                                                                                //       });
                                                                                                //       ref.refresh(categoryProvider);
                                                                                                //       EasyLoading.showSuccess('Updated Successfully');
                                                                                                //       GoRouter.of(context).pop(dialogContext);
                                                                                                //       GoRouter.of(context).pop(bc);
                                                                                                //       context.go(CategoryList.route);
                                                                                                //     } catch (e) {
                                                                                                //       print('---------------${e.toString()}------------');
                                                                                                //       EasyLoading.showError(lang.S.of(context).error);
                                                                                                //     }
                                                                                                //   }
                                                                                                // },
                                                                                                child: Text(
                                                                                                  lang.S.of(context).submit,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                          const SizedBox(height: 12),
                                                                                        ],
                                                                                      ),
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            );
                                                                          });
                                                                        });
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      const Icon(IconlyLight.edit, size: 20.0, color: kNeutral500),
                                                                      const SizedBox(width: 4.0),
                                                                      Text(
                                                                        lang.S.of(context).edit,
                                                                        style: theme.textTheme.bodyLarge?.copyWith(
                                                                          color: kNeutral500,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )),

                                                              ///____________delete___________________________________________________
                                                              PopupMenuItem(
                                                                onTap: () {
                                                                  if (true) {
                                                                    showDialog(
                                                                        barrierDismissible: false,
                                                                        context: context,
                                                                        builder: (BuildContext dialogContext) {
                                                                          return Center(
                                                                            child: Container(
                                                                              decoration: const BoxDecoration(
                                                                                color: Colors.white,
                                                                                borderRadius: BorderRadius.all(
                                                                                  Radius.circular(15),
                                                                                ),
                                                                              ),
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.all(20.0),
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                  children: [
                                                                                    Text(
                                                                                      lang.S.of(context).areYouWantToDeleteThisCustomer,
                                                                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                                                                    ),
                                                                                    const SizedBox(height: 20),
                                                                                    Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: [
                                                                                        ElevatedButton(
                                                                                          style: ElevatedButton.styleFrom(
                                                                                            backgroundColor: Colors.red,
                                                                                          ),
                                                                                          onPressed: () {
                                                                                            GoRouter.of(context).pop();
                                                                                          },
                                                                                          child: Text(
                                                                                            lang.S.of(context).cancel,
                                                                                          ),
                                                                                        ),
                                                                                        SizedBox(width: screenWidth < 570 ? 10 : 30),
                                                                                        ElevatedButton(
                                                                                          onPressed: () async {
                                                                                            if (!isDemo) {
                                                                                              // Fetch the categories from Firebase
                                                                                              DatabaseEvent event = await FirebaseDatabase.instance.ref().child(await getUserID()).child('Categories').orderByChild('categoryName').once();

                                                                                              if (event.snapshot.value != null) {
                                                                                                Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;

                                                                                                for (var key in values.keys) {
                                                                                                  if (values[key]['categoryName'] == showAbleCategories[index].categoryName) {
                                                                                                    // Delete the category from Firebase
                                                                                                    await FirebaseDatabase.instance.ref().child(await getUserID()).child('Categories').child(key).remove();

                                                                                                    ref.refresh(categoryProvider);

                                                                                                    // Show success message
                                                                                                    EasyLoading.showSuccess('Deleted Successfully');

                                                                                                    // Navigate back and then to the category list
                                                                                                    GoRouter.of(context).pop();
                                                                                                    context.go(CategoryList.route);

                                                                                                    // Exit the loop once the category is found and deleted
                                                                                                    break;
                                                                                                  }
                                                                                                }
                                                                                              }
                                                                                            } else {
                                                                                              EasyLoading.showInfo(demoText);
                                                                                            }
                                                                                          },
                                                                                          child: Text(
                                                                                            lang.S.of(context).delete,
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          );
                                                                        });
                                                                  }
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
                                                                      lang.S.of(context).delete,
                                                                      style: theme.textTheme.bodyLarge?.copyWith(color: kNeutral500),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                            onSelected: (value) {
                                                              // Navigator.pushNamed(context, '$value');
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
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${_lang.showing} ${((_currentPage - 1) * _categoryPerPage + 1).toString()} to ${((_currentPage - 1) * _categoryPerPage + _categoryPerPage).clamp(0, showAbleCategories.length)} of ${showAbleCategories.length} entries',
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
                                            onTap: _currentPage * _categoryPerPage < showAbleCategories.length ? () => setState(() => _currentPage++) : null,
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
                          : EmptyWidget(title: lang.S.of(context).noCustomerFound)
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
          })),
    );
  }
}
