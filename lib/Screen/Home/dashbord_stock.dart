import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/product_provider.dart';
import '../../model/product_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';

class DashboardStockWidget extends StatefulWidget {
  const DashboardStockWidget({
    super.key,
  });

  @override
  State<DashboardStockWidget> createState() => _StatisticsDataState();
}

class _StatisticsDataState extends State<DashboardStockWidget> {
  final ScrollController stockInventoryScrollController = ScrollController();

  int totalStock = 0;
  double totalSalePrice = 0;
  double totalParPrice = 0;

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    return Consumer(
      builder: (_, ref, watch) {
        List<ProductModel> stockList = [];
        final product = ref.watch(productProvider);
        return Container(
          height: 400,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: whiteColor, boxShadow: [BoxShadow(color: kBorderColorTextField.withOpacity(0.7), blurRadius: 4, blurStyle: BlurStyle.inner, spreadRadius: 1, offset: const Offset(0, 1))]),
          child: product.when(
            data: (productLis) {
              for (var element in productLis) {
                if (element.productStock.toInt() < 100) {
                  stockList.add(element);
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Text(
                          lang.S.of(context).stockValues,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$globalCurrency ${myFormat.format(double.tryParse(totalSalePrice.toString()) ?? 0)}',
                          style: textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: kSuccessColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    thickness: 1,
                    color: kNeutral300,
                    height: 1.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
                    child: Text(
                      lang.S.of(context).lowStock,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 15.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(left: 10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: kBorderColorTextField),
                        ),
                        child: ScrollbarTheme(
                          data: ScrollbarThemeData(
                            interactive: true,
                            radius: const Radius.circular(10.0),
                            thumbColor: WidgetStateProperty.all(Colors.white),
                            thickness: WidgetStateProperty.all(8.0),
                            minThumbLength: 100,
                            trackColor: WidgetStateProperty.all(kBorderColorTextField),
                          ),
                          child: Scrollbar(
                            trackVisibility: true,
                            thickness: 4.0,
                            interactive: true,
                            scrollbarOrientation: ScrollbarOrientation.right,
                            radius: const Radius.circular(20),
                            controller: stockInventoryScrollController,
                            thumbVisibility: true,
                            child: stockList.isNotEmpty
                                ? ListView.builder(
                                    controller: stockInventoryScrollController,
                                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0, right: 20.0),
                                    itemCount: stockList.length,
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder: (_, i) {
                                      return Visibility(
                                        visible: stockList[i].productStock.toInt() < 100,
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          visualDensity: const VisualDensity(vertical: -4),
                                          title: Text(
                                            stockList[i].productName,
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: kNeutral600,
                                            ),
                                          ),
                                          trailing: Text(
                                            stockList[i].productStock,
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: kErrorColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      lang.S.of(context).stockIsMoreThenLowLimit,
                                      // 'Stock is more then low limit',
                                      style: kTextStyle.copyWith(color: kGreyTextColor),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              );
            },
            error: (e, stack) {
              return Center(
                child: Text(e.toString()),
              );
            },
            loading: () {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        );
      },
    );
  }
}
