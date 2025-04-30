
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/product_provider.dart';
import 'package:salespro_admin/Screen/Product/WarebasedProduct.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';

class ProductSearchWidget extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final List<String> allProductsCodeList;
  final List<WarehouseBasedProductModel> warehouseBasedProductModel;

  const ProductSearchWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.allProductsCodeList,
    required this.warehouseBasedProductModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productList = ref.watch(productProvider);

    return productList.when(
      data: (product) {
        return ResponsiveGridCol(
          xs: 120,
          md: 40,
          lg: 24,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              height: 40,
              child: AppTextField(
                controller: controller,
                showCursor: true,
                focus: focusNode,
                autoFocus: true,
                cursorColor: kTitleColor,
                onChanged: onChanged,
                onFieldSubmitted: onSubmitted,
                textFieldType: TextFieldType.NAME,
                decoration: InputDecoration(
                  prefixIcon: Icon(MdiIcons.barcode, color: kTitleColor, size: 18.0),
                  suffixIcon: Container(
                    height: 10,
                    width: 10,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5)),
                      color: kBlueTextColor,
                    ),
                    child: const Center(
                      child: Icon(FeatherIcons.plusSquare, color: Colors.white, size: 18.0),
                    ),
                  ).onTap(() => context.push(
                    '/product/add-product',
                    extra: {
                      'allProductsCodeList': allProductsCodeList,
                      'warehouseBasedProductModel': [],
                    },
                  )),
                  hintText: 'Search product name or code',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        );
      },
      error: (e, stack) => Center(child: Text(e.toString())),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}