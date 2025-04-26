import 'package:flutter/material.dart';
import 'package:salespro_admin/Screen/tax%20rates/tax_rates_widget.dart';

import '../Widgets/Constant Data/constant.dart';

class TaxRates extends StatefulWidget {
  const TaxRates({super.key});
  // static const String route = '/taxRates';

  @override
  State<TaxRates> createState() => _TaxRatesState();
}

class _TaxRatesState extends State<TaxRates> {
  ScrollController mainScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kDarkWhite,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //_______________________________top_bar____________________________
            // TopBar(),
            TaxRatesWidget(),
            // Visibility(visible: MediaQuery.of(context).size.height != 0, child: ),
          ],
        ),
      ),
    );
  }
}
