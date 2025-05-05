import 'dart:convert';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/profile_provider.dart';
import 'package:salespro_admin/Repository/login_repo.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/button_global.dart';
import 'package:salespro_admin/currency.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/personal_information_model.dart';
import '../../Route/static_string.dart';
import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';

class ProfileUpdate extends StatefulWidget {
  const ProfileUpdate({
    super.key,
    required this.personalInformationModel,
  });
  final PersonalInformationModel personalInformationModel;

  // static const String route = '/profile-update';

  @override
  State<ProfileUpdate> createState() => _ProfileUpdateState();
}

class _ProfileUpdateState extends State<ProfileUpdate> {
  String initialCountry = 'Bangladesh';
  late String companyName, phoneNumber;
  String profilePicture = 'https://i.imgur.com/jlyGd1j.jpeg';

  Uint8List? image;

  Future<void> uploadFile() async {
    // File file = File(filePath);
    if (kIsWeb) {
      try {
        Uint8List? bytesFromPicker = await ImagePickerWeb.getImageAsBytes();
        // File? file = await ImagePickerWeb.getImageAsFile();
        EasyLoading.show(
          status: 'Uploading... ',
          dismissOnTap: false,
        );
        var snapshot = await FirebaseStorage.instance
            .ref('Profile Picture/${DateTime.now().millisecondsSinceEpoch}')
            .putData(bytesFromPicker!);
        var url = await snapshot.ref.getDownloadURL();
        EasyLoading.showSuccess('Upload Successful!');
        setState(() {
          image = bytesFromPicker;
          profilePicture = url.toString();
        });
      } on firebase_core.FirebaseException catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code.toString(),
            ),
          ),
        );
      }
    }
  }

  List<String> categories = [
    'Select Business Category',
    'Computer Store',
    'Electronic Store',
    'Fashion Store',
    'Meat Store',
    'Sweet Store',
    'Vegetable Store',
  ];

  String dropdownValue = 'Select Business Category';

  DropdownButton<String> getCategories() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in categories) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: dropdownValue,
      onChanged: (value) {
        setState(() {
          dropdownValue = value!;
        });
      },
    );
  }

  List<String> language = [
    'Select A Language',
    'English',
    'Bengali',
    'Hindi',
    'Urdu',
    'Chinese',
    'French',
    'Spanish',
  ];

  String selectedLanguage = 'Select A Language';

  DropdownButton<String> getLanguage() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in language) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedLanguage,
      onChanged: (value) {
        setState(() {
          selectedLanguage = value!;
        });
      },
    );
  }

  GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  bool validateAndSave() {
    final form = globalKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  late String customerKey;

  void getCustomerKey(String phoneNumber) async {
    await FirebaseDatabase.instance
        .ref(await getUserID())
        .child('Customers')
        .orderByKey()
        .get()
        .then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['phoneNumber'].toString() == phoneNumber) {
          customerKey = element.key.toString();
        }
      }
    });
  }

  @override
  void initState() {
    profilePicture = widget.personalInformationModel.pictureUrl;
    selectedLanguage = widget.personalInformationModel.language;
    dropdownValue = widget.personalInformationModel.businessCategory;
    companyNameController.text = widget.personalInformationModel.companyName;
    phoneNumberController.text = widget.personalInformationModel.phoneNumber!;
    addressController.text = widget.personalInformationModel.countryName;
    gstController.text = widget.personalInformationModel.gst;
    shopOpeningBalanceController.text =
        widget.personalInformationModel.shopOpeningBalance.toString();
    getCustomerKey(widget.personalInformationModel.phoneNumber);
    super.initState();
  }

  int opiningBalance = 0;

  TextEditingController companyNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController gstController = TextEditingController();
  TextEditingController shopOpeningBalanceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabAndMobileScreen = isMobileAndTab(screenWidth);
    responsiveValue<double>(context, xs: 24, md: 24, lg: 40);
    responsiveValue<double>(context, xs: 14, md: 14, lg: 20);
    responsiveValue<double>(context, xs: 14, md: 14, lg: 18);
    return Scaffold(
        backgroundColor: kMainColor,
        body: Consumer(builder: (context, ref, watch) {
          ref.watch(logInProvider);
          return Padding(
            padding: screenWidth < 400
                ? const EdgeInsets.all(8)
                : const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(nameLogo, height: 50),
                  Center(
                    child: ResponsiveGridRow(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ResponsiveGridCol(
                              lg: 6,
                              md: 6,
                              sm: 12,
                              xs: 12,
                              child: Center(
                                child: Container(
                                  height: tabAndMobileScreen
                                      ? MediaQuery.of(context).size.width / 1.1
                                      : MediaQuery.of(context).size.height /
                                          1.2,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: AssetImage(tabAndMobileScreen
                                              ? 'images/loginLogo2.png'
                                              : 'images/login logo.png'))),
                                ),
                              )),
                          ResponsiveGridCol(
                            md: 6,
                            sm: 12,
                            lg: 6,
                            xs: 12,
                            child: Padding(
                              padding: screenWidth < 380
                                  ? EdgeInsets.zero
                                  : const EdgeInsets.only(left: 20, right: 25),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      tabAndMobileScreen ? 10 : 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          children: [
                                            Center(
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    .50,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      height: 50,
                                                      width: 100,
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          image: AssetImage(
                                                              appLogo),
                                                        ),
                                                      ),
                                                    ),
                                                    Divider(
                                                      thickness: 1.0,
                                                      color: kGreyTextColor
                                                          .withValues(
                                                              alpha: 0.1),
                                                    ),
                                                    const SizedBox(
                                                        height: 10.0),
                                                    Text(
                                                      lang.S
                                                          .of(context)
                                                          .editYourProfile,
                                                      style: kTextStyle.copyWith(
                                                          color: kGreyTextColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 21.0),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    const SizedBox(
                                                        height: 10.0),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10.0),
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(10.0),
                                                            decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10.0),
                                                                color: kWhite),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                DottedBorderWidget(
                                                                  color:
                                                                      kLitGreyColor,
                                                                  child:
                                                                      ClipRRect(
                                                                    borderRadius:
                                                                        const BorderRadius
                                                                            .all(
                                                                            Radius.circular(12)),
                                                                    child:
                                                                        Container(
                                                                      width: context
                                                                          .width(),
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          10.0),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(20.0),
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment: image !=
                                                                                null
                                                                            ? MainAxisAlignment.spaceBetween
                                                                            : MainAxisAlignment.center,
                                                                        children: [
                                                                          Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.center,
                                                                            children: [
                                                                              Icon(MdiIcons.cloudUpload, size: 50.0, color: kLitGreyColor).onTap(() => uploadFile()),
                                                                              const SizedBox(height: 10.0),
                                                                              RichText(
                                                                                  text: TextSpan(text: lang.S.of(context).uploadAImage, style: kTextStyle.copyWith(color: kGreenTextColor, fontWeight: FontWeight.bold), children: [
                                                                                TextSpan(text: lang.S.of(context).orDragAndDropPng, style: kTextStyle.copyWith(color: kGreyTextColor, fontWeight: FontWeight.bold))
                                                                              ])),
                                                                            ],
                                                                          ),
                                                                          image != null
                                                                              ? Image.memory(
                                                                                  image!,
                                                                                  width: 150,
                                                                                  height: 150,
                                                                                )
                                                                              : SizedBox(),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 10.0),
                                                          // SizedBox(
                                                          //   height: 60.0,
                                                          //   child: FormField(
                                                          //     builder: (FormFieldState<dynamic> field) {
                                                          //       return InputDecorator(
                                                          //         decoration: kInputDecoration.copyWith(
                                                          //             floatingLabelBehavior: FloatingLabelBehavior.never,
                                                          //             labelText: 'Business Category',
                                                          //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0))),
                                                          //         child: DropdownButtonHideUnderline(child: getCategories()),
                                                          //       );
                                                          //     },
                                                          //   ),
                                                          // ),
                                                          // const SizedBox(height: 10.0),
                                                          Form(
                                                              key: globalKey,
                                                              child: Column(
                                                                children: [
                                                                  AppTextField(
                                                                    controller:
                                                                        companyNameController,
                                                                    showCursor:
                                                                        true,
                                                                    cursorColor:
                                                                        kTitleColor,
                                                                    textFieldType:
                                                                        TextFieldType
                                                                            .EMAIL,
                                                                    validator:
                                                                        (value) {
                                                                      if (value ==
                                                                              null ||
                                                                          value
                                                                              .isEmpty) {
                                                                        return 'Company Name can\'n be empty';
                                                                      } else if (!value
                                                                          .contains(
                                                                              '@')) {
                                                                        return 'Please enter a Company Name';
                                                                      }
                                                                      return null;
                                                                    },
                                                                    onChanged:
                                                                        (value) {
                                                                      setState(
                                                                          () {
                                                                        companyName =
                                                                            value;
                                                                      });
                                                                    },
                                                                    decoration:
                                                                        kInputDecoration
                                                                            .copyWith(
                                                                      labelText: lang
                                                                          .S
                                                                          .of(context)
                                                                          .companyName,
                                                                      labelStyle:
                                                                          kTextStyle.copyWith(
                                                                              color: kTitleColor),
                                                                      hintText: lang
                                                                          .S
                                                                          .of(context)
                                                                          .enterYourCompanyName,
                                                                      hintStyle:
                                                                          kTextStyle.copyWith(
                                                                              color: kGreyTextColor),
                                                                      prefixIcon: Icon(
                                                                          MdiIcons
                                                                              .officeBuilding,
                                                                          color:
                                                                              kTitleColor),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          10.0),
                                                                  AppTextField(
                                                                    controller:
                                                                        phoneNumberController,
                                                                    textFieldType:
                                                                        TextFieldType
                                                                            .PHONE,
                                                                    validator:
                                                                        (value) {
                                                                      if (value ==
                                                                              null ||
                                                                          value
                                                                              .isEmpty) {
                                                                        return 'Phone Number can\'n be empty';
                                                                      } else if (!value
                                                                          .contains(
                                                                              '@')) {
                                                                        return 'Please enter Phone Number';
                                                                      }
                                                                      return null;
                                                                    },
                                                                    onChanged:
                                                                        (value) {
                                                                      setState(
                                                                          () {
                                                                        phoneNumber =
                                                                            value;
                                                                      });
                                                                    },
                                                                    decoration:
                                                                        kInputDecoration
                                                                            .copyWith(
                                                                      labelText: lang
                                                                          .S
                                                                          .of(context)
                                                                          .phoneNumber,
                                                                      hintText: lang
                                                                          .S
                                                                          .of(context)
                                                                          .enterYourPhoneNumber,
                                                                      hintStyle:
                                                                          kTextStyle.copyWith(
                                                                              color: kGreyTextColor),
                                                                      floatingLabelBehavior:
                                                                          FloatingLabelBehavior
                                                                              .never,
                                                                      prefixIcon: Icon(
                                                                          MdiIcons
                                                                              .phone,
                                                                          color:
                                                                              kTitleColor),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          10.0),
                                                                  AppTextField(
                                                                    controller:
                                                                        addressController,
                                                                    textFieldType:
                                                                        TextFieldType
                                                                            .ADDRESS,
                                                                    validator:
                                                                        (value) {
                                                                      if (value ==
                                                                              null ||
                                                                          value
                                                                              .isEmpty) {
                                                                        return 'Address can\'n be empty';
                                                                      } else if (!value
                                                                          .contains(
                                                                              '@')) {
                                                                        return 'Please enter Your Address';
                                                                      }
                                                                      return null;
                                                                    },
                                                                    onChanged:
                                                                        (value) {
                                                                      setState(
                                                                          () {
                                                                        initialCountry =
                                                                            value;
                                                                      });
                                                                    },
                                                                    decoration:
                                                                        kInputDecoration
                                                                            .copyWith(
                                                                      labelText: lang
                                                                          .S
                                                                          .of(context)
                                                                          .address,
                                                                      hintText: lang
                                                                          .S
                                                                          .of(context)
                                                                          .enterYourAddress,
                                                                      hintStyle:
                                                                          kTextStyle.copyWith(
                                                                              color: kGreyTextColor),
                                                                      floatingLabelBehavior:
                                                                          FloatingLabelBehavior
                                                                              .never,
                                                                      prefixIcon: Icon(
                                                                          MdiIcons
                                                                              .warehouse,
                                                                          color:
                                                                              kTitleColor),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          10.0),

                                                                  ///_____GST____________________________________________
                                                                  AppTextField(
                                                                    controller:
                                                                        gstController,
                                                                    textFieldType:
                                                                        TextFieldType
                                                                            .NUMBER,
                                                                    validator:
                                                                        (value) {
                                                                      return null;
                                                                    },
                                                                    onChanged:
                                                                        (value) {},
                                                                    decoration:
                                                                        kInputDecoration
                                                                            .copyWith(
                                                                      labelText:
                                                                          'Shop GST',
                                                                      hintText:
                                                                          'Enter your shop GST number',
                                                                      hintStyle:
                                                                          kTextStyle.copyWith(
                                                                              color: kGreyTextColor),
                                                                      floatingLabelBehavior:
                                                                          FloatingLabelBehavior
                                                                              .never,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          10.0),
                                                                  AppTextField(
                                                                    controller:
                                                                        shopOpeningBalanceController,
                                                                    textFieldType:
                                                                        TextFieldType
                                                                            .PHONE,
                                                                    validator:
                                                                        (value) {
                                                                      if (value ==
                                                                              null ||
                                                                          value
                                                                              .isEmpty) {
                                                                        return 'Opening Balance can\'n be empty';
                                                                      } else if (double.tryParse(
                                                                              value) ==
                                                                          null) {
                                                                        return 'Enter a valid amount';
                                                                      }
                                                                      return null;
                                                                    },
                                                                    onChanged:
                                                                        (value) {
                                                                      setState(
                                                                          () {
                                                                        opiningBalance =
                                                                            value.toInt();
                                                                      });
                                                                    },
                                                                    decoration:
                                                                        kInputDecoration
                                                                            .copyWith(
                                                                      labelText: lang
                                                                          .S
                                                                          .of(context)
                                                                          .shopOpeningBalance,
                                                                      hintText: lang
                                                                          .S
                                                                          .of(context)
                                                                          .enterYOurAmount,
                                                                      hintStyle:
                                                                          kTextStyle.copyWith(
                                                                              color: kGreyTextColor),
                                                                      floatingLabelBehavior:
                                                                          FloatingLabelBehavior
                                                                              .never,
                                                                      prefixIcon: SizedBox(
                                                                          width: 40,
                                                                          child: Center(
                                                                              child: Text(
                                                                            currency,
                                                                            style: kTextStyle.copyWith(
                                                                                color: kTitleColor,
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.bold,
                                                                                overflow: TextOverflow.ellipsis),
                                                                          ))),
                                                                    ),
                                                                  ),
                                                                ],
                                                              )),
                                                          // const SizedBox(height: 10.0),
                                                          // SizedBox(
                                                          //   height: 60.0,
                                                          //   child: FormField(
                                                          //     builder: (FormFieldState<dynamic> field) {
                                                          //       return InputDecorator(
                                                          //         decoration: kInputDecoration.copyWith(
                                                          //             floatingLabelBehavior: FloatingLabelBehavior.never,
                                                          //             labelText: 'Select Your Language',
                                                          //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0))),
                                                          //         child: DropdownButtonHideUnderline(child: getLanguage()),
                                                          //       );
                                                          //     },
                                                          //   ),
                                                          // ),
                                                          const SizedBox(
                                                              height: 20.0),
                                                          ButtonGlobal(
                                                            buttontext: lang.S
                                                                .of(context)
                                                                .continu,
                                                            buttonDecoration: kButtonDecoration.copyWith(
                                                                color:
                                                                    kGreenTextColor,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8.0)),
                                                            onPressed:
                                                                () async {
                                                              try {
                                                                EasyLoading.show(
                                                                    status:
                                                                        'Loading...',
                                                                    dismissOnTap:
                                                                        false);
                                                                final DatabaseReference
                                                                    personalInformationRef =
                                                                    FirebaseDatabase
                                                                        .instance
                                                                        .ref()
                                                                        .child(
                                                                            await getUserID())
                                                                        .child(
                                                                            'Personal Information');
                                                                PersonalInformationModel
                                                                    personalInformation =
                                                                    PersonalInformationModel(
                                                                  phoneNumber:
                                                                      phoneNumberController
                                                                          .text,
                                                                  pictureUrl:
                                                                      profilePicture,
                                                                  companyName:
                                                                      companyNameController
                                                                          .text,
                                                                  countryName:
                                                                      addressController
                                                                          .text,
                                                                  language:
                                                                      selectedLanguage,
                                                                  dueInvoiceCounter: widget
                                                                      .personalInformationModel
                                                                      .dueInvoiceCounter,
                                                                  saleInvoiceCounter: widget
                                                                      .personalInformationModel
                                                                      .saleInvoiceCounter,
                                                                  purchaseInvoiceCounter: widget
                                                                      .personalInformationModel
                                                                      .purchaseInvoiceCounter,
                                                                  businessCategory:
                                                                      dropdownValue,
                                                                  shopOpeningBalance:
                                                                      shopOpeningBalanceController
                                                                          .text
                                                                          .toInt(),
                                                                  remainingShopBalance:
                                                                      double.parse(
                                                                          shopOpeningBalanceController
                                                                              .text),
                                                                  currency:
                                                                      '\$',
                                                                  currentLocale:
                                                                      'en',
                                                                  gst:
                                                                      gstController
                                                                          .text,
                                                                );
                                                                await personalInformationRef.set(
                                                                    personalInformation
                                                                        .toJson());

                                                                // EasyLoading.showSuccess('Added Successfully', duration: const Duration(milliseconds: 1000));

                                                                ///_______Seller_info_update___________________________________________
                                                                String?
                                                                    sellerUserRef =
                                                                    await getSaleID(
                                                                        id: await getUserID());
                                                                if (sellerUserRef !=
                                                                    null) {
                                                                  final DatabaseReference
                                                                      superAdminSellerListRepo =
                                                                      FirebaseDatabase
                                                                          .instance
                                                                          .ref()
                                                                          .child(
                                                                              'Admin Panel')
                                                                          .child(
                                                                              'Seller List')
                                                                          .child(
                                                                              sellerUserRef);
                                                                  superAdminSellerListRepo
                                                                      .update({
                                                                    'phoneNumber':
                                                                        phoneNumberController
                                                                            .text,
                                                                    'companyName':
                                                                        companyNameController
                                                                            .text,
                                                                    "businessCategory":
                                                                        dropdownValue,
                                                                    "pictureUrl":
                                                                        profilePicture,
                                                                    'language':
                                                                        selectedLanguage,
                                                                    'countryName':
                                                                        addressController
                                                                            .text,
                                                                  });
                                                                }

                                                                // SellerInfoModel sellerInfoModel = SellerInfoModel(
                                                                //   businessCategory: dropdownValue,
                                                                //   companyName: companyNameController.text,
                                                                //   phoneNumber: phoneNumberController.text,
                                                                //   countryName: addressController.text,
                                                                //   language: selectedLanguage,
                                                                //   pictureUrl: profilePicture,
                                                                //   userID: await getUserID(),
                                                                //   email: '',
                                                                //   userRegistrationDate: DateTime.now().toString(),
                                                                //   subscriptionDate: DateTime.now().toString(),
                                                                //   subscriptionName: 'Free',
                                                                //   subscriptionMethod: 'Not Provided',
                                                                // );
                                                                // await FirebaseDatabase.instance.ref().child('Admin Panel').child('Seller List').push().set(sellerInfoModel.toJson());
                                                                // ignore: unused_result
                                                                ref.refresh(
                                                                    profileDetailsProvider);
                                                                EasyLoading.showSuccess(
                                                                    'Added Successfully',
                                                                    duration: const Duration(
                                                                        milliseconds:
                                                                            1000));
                                                                await Future.delayed(
                                                                    const Duration(
                                                                        milliseconds:
                                                                            1000));
                                                                context.go(
                                                                    '/subscription');
                                                              } catch (e) {
                                                                EasyLoading
                                                                    .dismiss();
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(SnackBar(
                                                                        content:
                                                                            Text(e.toString())));
                                                              }
                                                              // Navigator.pushNamed(context, '/otp');
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        ]),
                  ),
                ],
              ),
            ),
          );
        }));
  }
}
