import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/model/product_model.dart';

import '../../const.dart';
import '../../model/add_to_cart_model.dart';
import '../../model/customer_model.dart';
import '../../model/home_report_model.dart';
import '../../model/purchase_transation_model.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/topselling_table_widget.dart';

class TopReportWidget extends StatelessWidget {
  final AsyncValue<List<SaleTransactionModel>> transactionReport;
  final AsyncValue<List<PurchaseTransactionModel>> purchaseTransactionReport;
  final String reportType; // "TopSelling", "TopCustomer", or "TopPurchasing"

  const TopReportWidget({
    Key? key,
    required this.transactionReport,
    required this.purchaseTransactionReport,
    required this.reportType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return transactionReport.when(
      data: (topSell) {
        List<AddToCartModel> saleProductList = [];
        List<CustomerModel> currentMonthCustomerList = [];

        // Helper functions
        bool isContain({required AddToCartModel element}) {
          for (var p in saleProductList) {
            if (p.productName == element.productName &&
                p.productId == element.productId) {
              p.quantity += element.quantity;
              return true;
            }
          }
          return false;
        }

        bool isContainCustomer({required SaleTransactionModel element}) {
          for (var p in currentMonthCustomerList) {
            if (p.customerName == element.customerName &&
                p.phoneNumber == element.customerPhone) {
              p.openingBalance = (double.parse(p.openingBalance) +
                      double.parse(element.totalAmount.toString()))
                  .toString();
              return true;
            }
          }
          return false;
        }

        // Process top selling products and customers
        for (var element in topSell) {
          final saleData = DateTime.tryParse(element.purchaseDate.toString()) ??
              DateTime.now();
          if (isAfterFirstDayOfCurrentMonth(saleData)) {
            // Process customers
            if (!isContainCustomer(element: element)) {
              currentMonthCustomerList.add(CustomerModel(
                customerName: element.customerName,
                phoneNumber: element.customerPhone,
                type: element.customerType,
                profilePicture: element.customerImage,
                emailAddress: '',
                customerAddress: element.customerAddress,
                dueAmount: element.dueAmount.toString(),
                openingBalance: element.totalAmount.toString(),
                remainedBalance: element.dueAmount.toString(),
                gst: element.customerGst,
              ));
            }

            // Process products
            for (var product in element.productList ?? []) {
              if (!isContain(element: product)) {
                AddToCartModel a = AddToCartModel(
                  warehouseId: product.warehouseId,
                  warehouseName: product.warehouseName,
                  productPurchasePrice: product.productPurchasePrice,
                  productImage: product.productImage,
                  productBrandName: product.productBrandName,
                  productDetails: product.productDetails,
                  productId: product.productId,
                  productName: product.productName,
                  productWarranty: product.productWarranty,
                  quantity: product.quantity,
                  serialNumber: product.serialNumber,
                  stock: product.stock,
                  subTotal: product.subTotal,
                  uniqueCheck: product.uniqueCheck,
                  unitPrice: product.unitPrice,
                  uuid: product.uuid,
                  itemCartIndex: product.itemCartIndex,
                  subTaxes: product.subTaxes,
                  excTax: product.excTax,
                  groupTaxName: product.groupTaxName,
                  groupTaxRate: product.groupTaxRate,
                  incTax: product.incTax,
                  margin: product.margin,
                  taxType: product.taxType,
                );
                saleProductList.add(a);
              }
            }
          }
        }

        saleProductList.sort((a, b) => b.quantity.compareTo(a.quantity));
        currentMonthCustomerList.sort((a, b) => double.parse(b.openingBalance)
            .compareTo(double.parse(a.openingBalance)));

        if (reportType == "TopSelling") {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: TopSellingProduct(
              report: getTopSellingReport(saleProductList),
            ),
          );
        } else if (reportType == "TopCustomer") {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: TopCustomerTable(
              report: getTopCustomer(currentMonthCustomerList),
            ),
          );
        } else if (reportType == "TopPurchasing") {
          return purchaseTransactionReport.when(
            data: (purchase) {
              List<ProductModel> purchaseProductList = [];

              bool isContainPurchase({required ProductModel element}) {
                for (var p in purchaseProductList) {
                  if (p.productCode == element.productCode) {
                    p.productStock = ((int.tryParse(p.productStock) ?? 0) +
                            (int.tryParse(element.productStock) ?? 0))
                        .toString();
                    return true;
                  }
                }
                return false;
              }

              for (var element in purchase) {
                final saleData =
                    DateTime.tryParse(element.purchaseDate.toString()) ??
                        DateTime.now();
                if (isAfterFirstDayOfCurrentMonth(saleData)) {
                  for (var product in element.productList ?? []) {
                    if (!isContainPurchase(element: product)) {
                      purchaseProductList.add(ProductModel(
                        product.productName,
                        product.productCategory,
                        product.size,
                        product.color,
                        '',
                        '',
                        '',
                        '',
                        '',
                        product.productCode,
                        product.productStock,
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        product.warehouseName,
                        product.warehouseId,
                        product.productPicture,
                        [],
                        expiringDate: '',
                        lowerStockAlert: 0,
                        manufacturingDate: '',
                        taxType: '',
                        margin: 0,
                        excTax: 0,
                        incTax: 0,
                        groupTaxName: '',
                        groupTaxRate: 0,
                        subTaxes: [],
                      ));
                    }
                  }
                }
              }

              purchaseProductList.sort((a, b) => int.parse(b.productStock)
                  .compareTo(int.parse(a.productStock)));

              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: MtTopStock(
                    report: getTopPurchaseReport(purchaseProductList)),
              );
            },
            error: (e, stack) {
              return Center(child: Text(e.toString()));
            },
            loading: () {
              return const Center(child: CircularProgressIndicator());
            },
          );
        }
        return Container(); // Fallback
      },
      error: (e, stack) {
        return Center(child: Text(e.toString()));
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  List<TopPurchaseReport> getTopPurchaseReport(List<ProductModel> model) {
    return model
        .map(
          (element) => TopPurchaseReport(
            element.productName,
            element.productPurchasePrice.toString(),
            element.productCategory,
            element.productPicture,
            element.productStock,
          ),
        )
        .toList();
  }

  List<TopCustomer> getTopCustomer(List<CustomerModel> model) {
    return model
        .map(
          (element) => TopCustomer(
            element.customerName,
            element.openingBalance.toString(),
            element.phoneNumber,
            element.profilePicture.toString(),
          ),
        )
        .toList();
  }

  List<TopSellReport> getTopSellingReport(List<AddToCartModel> model) {
    return model
        .map(
          (element) => TopSellReport(
            element.productName,
            element.productPurchasePrice.toString(),
            element.productBrandName,
            element.quantity.toString(),
            element.productImage,
          ),
        )
        .toList();
  }

  bool isAfterFirstDayOfCurrentMonth(DateTime date) {
    return date.isAfter(firstDayOfCurrentMonth);
  }
}
