import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart' as pro;
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../model/home_report_model.dart';
import '../currency/currency_provider.dart';
import 'Constant Data/constant.dart';

class MtTopStock extends StatelessWidget {
  const MtTopStock({
    Key? key,
    required this.report,
  }) : super(key: key);

  final List<TopPurchaseReport> report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 400,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0), color: kWhite),
      child: Column(
        children: [
          Padding(
            padding:
                EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SvgPicture.asset(
                  'images/top_sale.svg',
                  height: 24,
                  width: 24,
                ),
                const SizedBox(width: 8.0),
                Flexible(
                  child: Text(
                    lang.S.of(context).fivePurchase,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            thickness: 1,
            color: kNeutral300,
            height: 1,
          ),
          report.isNotEmpty
              ? ListView.builder(
                  itemCount: report.length < 5 ? report.length : 5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (_, i) {
                    report
                        .sort((a, b) => b.stock!.compareTo(a.stock.toString()));
                    return (ListTile(
                      leading: Container(
                        height: 40.0,
                        width: 40.0,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(report[i].image ?? ''),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: kBorderColorTextField),
                            shape: BoxShape.circle),
                      ),
                      title: Text(
                        report[i].name ?? '',
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        report[i].category ?? '',
                        style: theme.textTheme.titleSmall,
                      ),
                      trailing: Text(
                        myFormat.format(
                            double.tryParse(report[i].stock ?? '') ?? 0),
                        style: theme.textTheme.titleMedium,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      horizontalTitleGap: 12,
                    ));
                  })
              : const Center(
                  child: Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text('List is empty'),
                )),
        ],
      ),
    );
  }
}

class TopSellingProduct extends StatelessWidget {
  const TopSellingProduct({
    super.key,
    required this.report,
  });

  final List<TopSellReport> report;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    return Container(
      height: 400,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0), color: kWhite),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SvgPicture.asset(
                  'images/top_sale.svg',
                  height: 24,
                  width: 24,
                ),
                const SizedBox(width: 8.0),
                Text(
                  lang.S.of(context).topSellingProduct,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            thickness: 1,
            color: kNeutral300,
            height: 1,
          ),
          ListView.builder(
              itemCount: report.length < 5 ? report.length : 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (_, i) {
                return (ListTile(
                  leading: Container(
                    height: 40.0,
                    width: 40.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.0),
                      image: DecorationImage(
                          image: NetworkImage(report[i].productImage ?? ''),
                          fit: BoxFit.cover),
                      border: Border.all(color: kBorderColorTextField),
                    ),
                  ),
                  // leading: Container(
                  //   height: 50.0,
                  //   width: 50.0,
                  //   decoration: const BoxDecoration(
                  //       color: Color(0xFF8424FF),
                  //       // border: Border.all(color: kBorderColorTextField),
                  //       shape: BoxShape.circle),
                  //   child: Center(
                  //     child: Text(
                  //       report[i].name?.substring(0, 2) ?? '',
                  //       style: kTextStyle.copyWith(color: kWhiteTextColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                  //     ),
                  //   ),
                  // ),
                  title: Text(
                    report[i].name ?? '',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${lang.S.of(context).totalSale}: ${report[i].stock ?? ''}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: kNeutral600,
                    ),
                  ),
                  trailing: Text(
                    "$globalCurrency ${myFormat.format(double.tryParse(report[i].amount ?? '') ?? 0)}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: kNeutral900,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  horizontalTitleGap: 12,
                ));
              })
        ],
      ),
    );
  }
}

class TopCustomerTable extends StatelessWidget {
  const TopCustomerTable({
    super.key,
    required this.report,
  });

  final List<TopCustomer> report;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    return Container(
      height: 400,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0), color: kWhite),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedUserGroup,
                  color: Colors.black,
                  size: 24.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  lang.S.of(context).customerOfTheMonth,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                ),
              ],
            ),
          ),
          Divider(
            thickness: 1.0,
            color: kNeutral300,
            height: 1,
          ),
          report.isNotEmpty
              ? ListView.builder(
                  itemCount: report.length < 5 ? report.length : 5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (_, i) {
                    return (ListTile(
                      leading: Container(
                        height: 40.0,
                        width: 40.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          image: DecorationImage(
                              image: NetworkImage(report[i].image ?? ''),
                              fit: BoxFit.cover),
                          border: Border.all(color: kBorderColorTextField),
                        ),
                      ),
                      title: Text(
                        report[i].name ?? '',
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        report[i].phone ?? '',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: kNeutral600,
                        ),
                      ),
                      trailing: Text(
                        "$globalCurrency ${myFormat.format(double.tryParse(report[i].amount ?? '') ?? 0)}",
                        style: theme.textTheme.titleMedium,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      horizontalTitleGap: 12,
                    ));
                  },
                )
              : const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text('List is empty')),
                )
        ],
      ),
    );
  }
}
