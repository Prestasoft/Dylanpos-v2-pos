import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salespro_admin/model/daily_transaction_model.dart';

import '../../../const.dart';

String paypalClientId = '';
String paypalClientSecret = '';
const bool sandbox = true;
// const String currency = 'USD';
String countryName = 'Bangladesh';
String selectedCountry = 'English';

// const kMainColor = Color(0xFF3F8CFF);
const kMainColor = Color(0xff8424FF);
const kMainColor100 = Color(0xffF8F1FF);
const kDarkGreyColor = Color(0xFF2E2E3E);
const kBackgroundColor = Color(0xffF4F4F4);
const kBorderColor = Color(0xff98A2B3);
const kLitGreyColor = Color(0xFFD4D4D8);
const kGreyTextColor = Color(0xFF585865);
const kChartColor = Color(0xff2E2E3E);
const kBorderColorTextField = Color(0xFFE8E7E5);
const kDarkWhite = Color(0xFFF2F6F8);
const kbgColor = Color(0xFFF8F3FF);
const kWhite = Color(0xFFFFFFFF);
const kRedTextColor = Color(0xFFFE2525);
const kBlueTextColor = Color(0xff8424FF);
const kYellowColor = Color(0xFFFF8C00);
const kGreenTextColor = Color(0xff8424FF);
const kTitleColor = Color(0xFF2E2E3E);
const kPremiumPlanColor = Color(0xFF8752EE);
const kSuccessColor = Colors.green;
const kErrorColor = Colors.red;
const kPremiumPlanColor2 = Color(0xFFFF5F00);
const lightGreyColor = Color(0xFFF8F3FF);
const dropdownItemColor = Color(0xFFF2F6F8);
const kOutlineColor = Color(0xFFF2F6F8);
const kDividerColor = Color(0xffDEDEDE);
const kTextSecondaryColor = Color(0xff585865);
const kTextPrimaryColor = Color(0xff000000);
const kNeutral600 = Color(0xff525252);
const kNeutral300 = Color(0xffDCDCDC);
const kThemeOutlineColor = Color(0xffD7D9DE);
const kNeutral100 = Color(0xffF5F5F5);
const kNeutral400 = Color(0xffA3A3A3);
const kNeutral700 = Color(0xff404040);
const kNeutral800 = Color(0xff262626);
const kNeutral500 = Color(0xff667085);
const kNeutral900 = Color(0xff171717);
final kTextStyle = GoogleFonts.manrope(
  color: Colors.white,
);
final bTextStyle = GoogleFonts.manrope(
  color: Colors.black,
);
const kButtonDecoration = BoxDecoration(
  color: kMainColor,
  borderRadius: BorderRadius.all(
    Radius.circular(40.0),
  ),
);

const kInputDecoration = InputDecoration(
    hintStyle: TextStyle(color: kNeutral700, fontSize: 16),
    labelStyle: TextStyle(color: kTitleColor, fontSize: 16),
    // filled: true,
    // fillColor: Colors.white70,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6.0)),
      borderSide: BorderSide(color: kBorderColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6.0)),
      borderSide: BorderSide(color: kBorderColor, width: 1),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6.0)),
      borderSide: BorderSide(color: Colors.red, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6.0)),
      borderSide: BorderSide(color: Colors.red, width: 2),
    ));

const bInputDecoration = InputDecoration(
  hintStyle: TextStyle(color: kGreyTextColor),
  filled: true,
  fillColor: Colors.white70,
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    borderSide: BorderSide(color: kBorderColorTextField, width: 1),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(6.0)),
    borderSide: BorderSide(color: kBorderColorTextField, width: 1),
  ),
);

OutlineInputBorder outlineInputBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(10.0),
    borderSide: const BorderSide(color: kBorderColorTextField),
  );
}

final otpInputDecoration = InputDecoration(
  contentPadding: const EdgeInsets.symmetric(vertical: 5.0),
  border: outlineInputBorder(),
  focusedBorder: outlineInputBorder(),
  enabledBorder: outlineInputBorder(),
);

List<String> businessCategory = [
  'Fashion Store',
  'Electronics Store',
  'Computer Store',
  'Vegetable Store',
  'Sweet Store',
  'Meat Store'
];
List<String> language = [
  'English',
  'Bengali',
  'Hindi',
  'Urdu',
  'French',
  'Spanish'
];

List<String> productCategory = [
  'Fashion',
  'Electronics',
  'Computer',
  'Gadgets',
  'Watches',
  'Cloths'
];

List<String> userRole = [
  'Super Admin',
  'Admin',
  'User',
];

List<String> paymentType = [
  'Cheque',
  'Deposit',
  'Cash',
  'Transfer',
  'Sales',
];
List<String> posStats = [
  'Daily',
  'Monthly',
  'Yearly',
];
List<String> saleStats = [
  'Weekly',
  'Monthly',
  'Yearly',
];

void updateInvoice(
    {required String typeOfInvoice, required int invoice}) async {
  ///_______invoice_Update_____________________________________________
  final DatabaseReference personalInformationRef = FirebaseDatabase.instance
      .ref()
      .child(await getUserID())
      .child('Personal Information');

  await personalInformationRef.update({typeOfInvoice: invoice});
}

Future<void> postDailyTransaction(
    {required DailyTransactionModel dailyTransactionModel}) async {
  final DatabaseReference personalInformationRef = FirebaseDatabase.instance
      .ref()
      .child(await getUserID())
      .child('Personal Information');
  double remainingBalance = 0;

  await personalInformationRef.orderByKey().get().then((value) {
    var data = jsonDecode(jsonEncode(value.value));
    remainingBalance = data['remainingShopBalance'];
  });

  if (dailyTransactionModel.type == 'Sale' ||
      dailyTransactionModel.type == 'Due Collection' ||
      dailyTransactionModel.type == 'Income' ||
      dailyTransactionModel.type == 'Purchase Return') {
    remainingBalance += dailyTransactionModel.paymentIn;
  } else {
    remainingBalance -= dailyTransactionModel.paymentOut;
  }

  dailyTransactionModel.remainingBalance = remainingBalance;

  ///________post_remaining Balance_on_personal_information___________________________________________________
  await personalInformationRef
      .update({'remainingShopBalance': remainingBalance});

  ///_________dailyTransaction_Posting________________________________________________________________________
  DatabaseReference dailyTransactionRef =
      FirebaseDatabase.instance.ref("${await getUserID()}/Daily Transaction");
  await dailyTransactionRef.push().set(dailyTransactionModel.toJson());
}
