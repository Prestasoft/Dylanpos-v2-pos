// import 'package:flutter/material.dart';
// import 'package:nb_utils/nb_utils.dart';
// import 'package:salespro_admin/Screen/Reports/daily_transaction.dart';
// import '../../model/sale_transaction_model.dart';
// import 'Widgets/Constant Data/constant.dart';
// import 'Widgets/Footer/footer.dart';
// import 'Widgets/Sidebar/sidebar_widget.dart';
// import 'Widgets/TopBar/top_bar_widget.dart';
// import 'package:salespro_admin/generated/l10n.dart' as lang;
//
// class DailyTransactionScreen extends StatefulWidget {
//   const DailyTransactionScreen({super.key});
//   // static const String route = '/transaction';
//
//   @override
//   State<DailyTransactionScreen> createState() => _DailyTransactionScreenState();
// }
//
// class _DailyTransactionScreenState extends State<DailyTransactionScreen> {
//   List<String> categoryList = [
//     'Sale',
//     'Purchase',
//     'Due',
//     'Current Stock',
//     'Daily Transaction',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   double getTotalDue(List<SaleTransactionModel> transitionModel) {
//     double total = 0.0;
//     for (var element in transitionModel) {
//       total += element.dueAmount!;
//     }
//     return total;
//   }
//
//   double calculateTotalSale(List<SaleTransactionModel> transitionModel) {
//     double total = 0.0;
//     for (var element in transitionModel) {
//       total += element.totalAmount!;
//     }
//     return total;
//   }
//
//   ScrollController mainScroll = ScrollController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kDarkWhite,
//       body: Scrollbar(
//         controller: mainScroll,
//         child: SingleChildScrollView(
//           controller: mainScroll,
//           scrollDirection: Axis.horizontal,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // const SizedBox(
//               //   width: 240,
//               //   child: SideBarWidget(
//               //     index: 12,
//               //     isTab: false,
//               //   ),
//               // ),
//               Container(
//                 width: MediaQuery.of(context).size.width < 1275 ? 1275 - 240 : MediaQuery.of(context).size.width - 240,
//                 // width: context.width() < 1080 ? 1080 - 240 : MediaQuery.of(context).size.width - 240,
//                 decoration: const BoxDecoration(color: kDarkWhite),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       //_______________________________top_bar____________________________
//                       // const TopBar(),
//
//                       const Padding(
//                         padding: EdgeInsets.all(20.0),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             DailyTransaction(),
//                           ],
//                         ),
//                       ),
//                       // Visibility(visible: MediaQuery.of(context).size.height != 0, child: ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
